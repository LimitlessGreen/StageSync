package media

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"
)

// Server ist der autoritative HTTP-Medienserver des Sync-Servers.
//
// Endpunkte:
//
//	GET    /media                  → JSON-Liste aller Dateien (mit sha256)
//	POST   /media/upload           → multipart/form-data („file") hochladen
//	GET    /media/download/{name}  → Datei herunterladen (ETag = sha256, 304-fähig)
//	DELETE /media/{name}           → Datei löschen
//	GET    /media/events           → Server-Sent-Events: Signal bei Änderung
//	GET    /health                 → Health-Check
type Server struct {
	store *Store
	http  *http.Server
}

func NewServer(store *Store, addr string) *Server {
	s := &Server{store: store}
	mux := http.NewServeMux()
	mux.HandleFunc("/media", s.withCORS(s.handleMediaRoot))
	mux.HandleFunc("/media/manifest", s.withCORS(s.handleManifest))
	mux.HandleFunc("/media/upload", s.withCORS(s.handleUpload))
	mux.HandleFunc("/media/download/", s.withCORS(s.handleDownload))
	mux.HandleFunc("/media/events", s.withCORS(s.handleEvents))
	mux.HandleFunc("/media/", s.withCORS(s.handleByName)) // DELETE /media/{name}
	mux.HandleFunc("/health", s.withCORS(s.handleHealth))
	s.http = &http.Server{Addr: addr, Handler: mux}
	return s
}

// Start startet den Server (blockierend) bis ctx abgebrochen wird.
func (s *Server) Start(ctx context.Context) error {
	go func() {
		<-ctx.Done()
		shutCtx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()
		_ = s.http.Shutdown(shutCtx)
	}()
	if err := s.http.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		return err
	}
	return nil
}

// ── Handler ─────────────────────────────────────────────────────────────────

func (s *Server) handleMediaRoot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	files, err := s.store.List()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	writeJSON(w, files)
}

// handleManifest: GET /media/manifest — liefert alle Dateien mit SHA256 + MIME.
// Clients (Flutter-Nodes) nutzen diesen Endpoint für Manifest-basierten Sync:
// nur Dateien mit abweichendem SHA256 werden heruntergeladen.
func (s *Server) handleManifest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	files, err := s.store.List()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	writeJSON(w, files)
}

func (s *Server) handleUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	// Bis 1 GiB im RAM/temp puffern lassen; größere Teile gehen auf Disk.
	if err := r.ParseMultipartForm(64 << 20); err != nil {
		http.Error(w, "invalid multipart: "+err.Error(), http.StatusBadRequest)
		return
	}
	file, header, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "missing 'file' field", http.StatusBadRequest)
		return
	}
	defer file.Close()

	if !IsAudioName(header.Filename) {
		http.Error(w, "unsupported audio format", http.StatusBadRequest)
		return
	}

	info, err := s.store.Save(header.Filename, file)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	log.Printf("[media] upload: %s (%d bytes, %s)", info.Name, info.SizeBytes, info.SHA256[:8])
	writeJSON(w, info)
}

func (s *Server) handleDownload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	name := strings.TrimPrefix(r.URL.Path, "/media/download/")
	if name == "" {
		http.Error(w, "missing filename", http.StatusBadRequest)
		return
	}
	info, err := s.store.Stat(name)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	// ETag = sha256 → Node spart Download wenn unverändert (If-None-Match).
	etag := `"` + info.SHA256 + `"`
	w.Header().Set("ETag", etag)
	if match := r.Header.Get("If-None-Match"); match == etag {
		w.WriteHeader(http.StatusNotModified)
		return
	}
	f, err := s.store.Open(name)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	defer f.Close()
	w.Header().Set("Content-Type", "application/octet-stream")
	http.ServeContent(w, r, info.Name, time.UnixMilli(info.ModifiedMs), f)
}

func (s *Server) handleByName(w http.ResponseWriter, r *http.Request) {
	name := strings.TrimPrefix(r.URL.Path, "/media/")
	switch r.Method {
	case http.MethodDelete:
		if name == "" {
			http.Error(w, "missing filename", http.StatusBadRequest)
			return
		}
		if err := s.store.Delete(name); err != nil {
			if err == ErrNotFound {
				http.NotFound(w, r)
				return
			}
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		log.Printf("[media] delete: %s", SafeName(name))
		writeJSON(w, map[string]string{"status": "deleted"})
	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

// handleEvents: Server-Sent-Events. Sendet bei jeder Medienänderung eine Zeile,
// damit Nodes sofort re-syncen können (statt zu pollen).
func (s *Server) handleEvents(w http.ResponseWriter, r *http.Request) {
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming unsupported", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")

	ch, unsub := s.store.Subscribe()
	defer unsub()

	// Initiales Signal → Node synct sofort beim Verbinden.
	fmt.Fprint(w, "data: changed\n\n")
	flusher.Flush()

	keepalive := time.NewTicker(20 * time.Second)
	defer keepalive.Stop()

	for {
		select {
		case <-r.Context().Done():
			return
		case <-ch:
			fmt.Fprint(w, "data: changed\n\n")
			flusher.Flush()
		case <-keepalive.C:
			fmt.Fprint(w, ": keepalive\n\n") // Kommentar-Zeile hält die Verbindung offen
			flusher.Flush()
		}
	}
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, map[string]string{"status": "ok"})
}

// ── Helpers ──────────────────────────────────────────────────────────────────

func (s *Server) withCORS(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, If-None-Match")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next(w, r)
	}
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
