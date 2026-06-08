// Package coreserver assembles all CGo-free StageSync services into a
// runnable gRPC server. It is the shared foundation used by both the
// standalone binary (cmd/server) and the embeddable library (cmd/corelib).
//
// CGo-heavy packages (audioengine, audionode, midinode) are intentionally
// absent here so that this package can be compiled via gomobile or as a
// plain c-shared library without native audio dependencies.
package coreserver

import (
	"context"
	"fmt"
	"log"
	"net"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	pb "stagesync-server/gen/go/stagesync/v1"
	grpchandlers "stagesync-server/internal/grpc"
	"stagesync-server/internal/busengine"
	"stagesync-server/internal/discovery"
	"stagesync-server/internal/grid"
	"stagesync-server/internal/media"
	"stagesync-server/internal/node"
	"stagesync-server/internal/peaks"
	"stagesync-server/internal/session"
	"stagesync-server/internal/showcontrol"
	"stagesync-server/internal/talkback"
)

// Config holds all runtime parameters for the core server.
type Config struct {
	Port        int
	DataDir     string
	ServiceName string
	// RamCacheBytes is the RAM budget for the audio PCM cache (0 → 2 GiB).
	RamCacheBytes int64
}

func (c *Config) ramCacheBytes() int64 {
	if c.RamCacheBytes > 0 {
		return c.RamCacheBytes
	}
	return 2048 * 1024 * 1024
}

func (c *Config) port() int {
	if c.Port > 0 {
		return c.Port
	}
	return 50051
}

func (c *Config) serviceName() string {
	if c.ServiceName != "" {
		return c.ServiceName
	}
	return "StageSync"
}

// Server holds the running gRPC server and its core services.
// Use Start to create one; call Stop to shut it down gracefully.
type Server struct {
	grpc               *grpc.Server
	showControlHandler *grpchandlers.ShowControlHandler
	gridHandler        *grpchandlers.GridHandler
	mediaStore         *media.Store
	mediaCache         *media.Cache
	storeWarmer        *media.StoreWarmer
	sessionMgr         *session.Manager
	dispatcher         *node.Dispatcher
}

// ShowControlHandler exposes the inner handler so callers (e.g. cmd/server)
// can attach optional extensions like a SilenceDetector or TalkbackRelay.
func (s *Server) ShowControlHandler() *grpchandlers.ShowControlHandler {
	return s.showControlHandler
}

// MediaStore returns the media store so callers can pass it to an audio node.
func (s *Server) MediaStore() *media.Store {
	return s.mediaStore
}

// MediaCache returns the media cache.
func (s *Server) MediaCache() *media.Cache {
	return s.mediaCache
}

// StoreWarmer returns the store warmer.
func (s *Server) StoreWarmer() *media.StoreWarmer {
	return s.storeWarmer
}

// GridHandler returns the grid handler (implements midinode.GridLauncher).
func (s *Server) GridHandler() *grpchandlers.GridHandler {
	return s.gridHandler
}

// SessionManager returns the session manager.
func (s *Server) SessionManager() *session.Manager {
	return s.sessionMgr
}

// Dispatcher returns the node dispatcher.
func (s *Server) Dispatcher() *node.Dispatcher {
	return s.dispatcher
}

// GracefulStop shuts the gRPC server down, waiting up to 5 s.
func (s *Server) GracefulStop() {
	done := make(chan struct{})
	go func() {
		s.grpc.GracefulStop()
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		s.grpc.Stop()
	}
}

// Start builds and starts the core gRPC server. It returns once the server
// is listening. The server runs until ctx is cancelled; callers should also
// call GracefulStop after ctx is done.
func Start(ctx context.Context, cfg Config) (*Server, error) {
	dataDir := cfg.DataDir
	if dataDir == "" {
		dataDir = "./data"
	}
	log.Printf("[coreserver] data dir: %s", dataDir)

	sessionMgr := session.NewManager(dataDir)
	dispatcher := node.NewDispatcher()
	persistence := showcontrol.NewPersistence(dataDir)

	mediaStore, err := media.NewStore(fmt.Sprintf("%s/media", dataDir))
	if err != nil {
		return nil, fmt.Errorf("media store: %w", err)
	}

	mediaCache := media.NewCache(cfg.ramCacheBytes())
	mediaGRPC := media.NewGRPCHandler(mediaStore, mediaCache)
	storeWarmer := media.NewStoreWarmer(mediaCache, mediaStore)

	used, max, _ := mediaCache.Stats()
	log.Printf("[coreserver] audio cache: %d MiB budget (%d MiB used)", max>>20, used>>20)

	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", cfg.port()))
	if err != nil {
		return nil, fmt.Errorf("listen :%d: %w", cfg.port(), err)
	}

	grpcServer := grpc.NewServer(
		grpc.ChainUnaryInterceptor(loggingInterceptor),
		grpc.ChainStreamInterceptor(loggingStreamInterceptor),
		grpc.MaxRecvMsgSize(512*1024*1024),
		grpc.MaxSendMsgSize(512*1024*1024),
	)

	busRouter := busengine.NewRouter()
	talkbackRelay := talkback.NewRelay(busRouter, dispatcher)
	talkbackHandler := talkback.NewHandler(sessionMgr, talkbackRelay, busRouter)

	pb.RegisterSessionServiceServer(grpcServer, grpchandlers.NewSessionHandler(sessionMgr))

	nodeHandler := grpchandlers.NewNodeHandler(sessionMgr, dispatcher)
	pb.RegisterNodeServiceServer(grpcServer, nodeHandler)

	showControlHandler := grpchandlers.NewShowControlHandler(sessionMgr, dispatcher, persistence, mediaStore)
	showControlHandler.SetWarmer(storeWarmer)
	showControlHandler.SetBusRouter(busRouter)
	showControlHandler.SetTalkbackRelay(talkbackRelay)
	nodeHandler.SetCueTrackStopper(showControlHandler)
	pb.RegisterShowControlServiceServer(grpcServer, showControlHandler)

	pb.RegisterMediaServiceServer(grpcServer, mediaGRPC)
	pb.RegisterTalkbackServiceServer(grpcServer, talkbackHandler)

	gridPersistence := grid.NewPersistence(dataDir)
	peaksService := peaks.NewService(mediaStore, fmt.Sprintf("%s/media", dataDir))
	gridHandler := grpchandlers.NewGridHandler(sessionMgr, dispatcher, gridPersistence, peaksService)
	gridHandler.SetCueLauncher(showControlHandler.LaunchCueRef)
	pb.RegisterGridServiceServer(grpcServer, gridHandler)

	reflection.Register(grpcServer)

	txtRecords := []string{"version=1", fmt.Sprintf("port=%d", cfg.port())}
	if _, err := discovery.Announce(ctx, cfg.serviceName(), cfg.port(), txtRecords); err != nil {
		log.Printf("[coreserver] mDNS announce failed (non-fatal): %v", err)
	}

	log.Printf("[coreserver] listening on :%d", cfg.port())
	go func() {
		if err := grpcServer.Serve(lis); err != nil {
			log.Printf("[coreserver] gRPC serve error: %v", err)
		}
	}()

	return &Server{
		grpc:               grpcServer,
		showControlHandler: showControlHandler,
		gridHandler:        gridHandler,
		mediaStore:         mediaStore,
		mediaCache:         mediaCache,
		storeWarmer:        storeWarmer,
		sessionMgr:         sessionMgr,
		dispatcher:         dispatcher,
	}, nil
}

func loggingInterceptor(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
	resp, err := handler(ctx, req)
	if err != nil {
		log.Printf("[gRPC] %s → ERROR: %v", info.FullMethod, err)
	}
	return resp, err
}

func loggingStreamInterceptor(srv any, ss grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
	log.Printf("[gRPC stream] %s opened", info.FullMethod)
	err := handler(srv, ss)
	if err != nil {
		log.Printf("[gRPC stream] %s → ERROR: %v", info.FullMethod, err)
	}
	return err
}
