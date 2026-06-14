package coreserver

import (
	"context"
	"io/fs"
	"log"
	"net/http"
	"time"

	"github.com/improbable-eng/grpc-web/go/grpcweb"
)

// startWebUI serves the StageSync gRPC API over gRPC-Web alongside a static
// web UI (the Flutter web build) on addr. If dir is non-empty, static files
// are served from that filesystem path; otherwise the embedded placeholder
// (or embedded Flutter build, if copied into ./webui/) is used.
func (s *Server) startWebUI(addr string, dir string) error {
	wrapped := grpcweb.WrapServer(s.grpc,
		grpcweb.WithOriginFunc(func(origin string) bool { return true }),
		grpcweb.WithWebsockets(true),
		grpcweb.WithWebsocketOriginFunc(func(*http.Request) bool { return true }),
	)

	var staticHandler http.Handler
	if dir != "" {
		staticHandler = http.FileServer(http.Dir(dir))
	} else {
		sub, err := fs.Sub(embeddedWebUI, "webui")
		if err != nil {
			return err
		}
		staticHandler = http.FileServer(http.FS(sub))
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if wrapped.IsGrpcWebRequest(r) || wrapped.IsAcceptableGrpcCorsRequest(r) || wrapped.IsGrpcWebSocketRequest(r) {
			wrapped.ServeHTTP(w, r)
			return
		}
		staticHandler.ServeHTTP(w, r)
	})

	srv := &http.Server{
		Addr:    addr,
		Handler: mux,
	}
	s.webServer = srv

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Printf("[coreserver] web UI server error: %v", err)
		}
	}()
	log.Printf("[coreserver] web UI listening on %s", addr)
	return nil
}

// stopWebUI shuts the web UI server down, if running.
func (s *Server) stopWebUI() {
	if s.webServer == nil {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := s.webServer.Shutdown(ctx); err != nil {
		s.webServer.Close()
	}
}
