// Package persistence stellt gemeinsame File-I/O-Primitiven für alle
// domänenspezifischen Persistence-Implementierungen bereit.
package persistence

import (
	"log"
	"os"
	"sync"
)

// LockedWriter serialisiert asynchrone Schreiboperationen auf eine Datei.
// Jeder Save-Aufruf läuft in einer Goroutine, aber nie parallel.
type LockedWriter struct {
	mu     sync.Mutex
	logTag string
}

func NewLockedWriter(logTag string) *LockedWriter {
	return &LockedWriter{logTag: logTag}
}

// WriteAsync schreibt data in die Datei path — nicht-blockierend, serialisiert.
func (w *LockedWriter) WriteAsync(path string, data []byte) {
	go func() {
		w.mu.Lock()
		defer w.mu.Unlock()
		if err := os.WriteFile(path, data, 0o644); err != nil {
			log.Printf("[%s] write error: %v", w.logTag, err)
		}
	}()
}

// ReadFile liest path und gibt (data, true) zurück.
// Gibt (nil, false) zurück wenn die Datei nicht existiert (kein Fehler-Log).
// Gibt (nil, false) + Log zurück bei anderen Fehlern.
func ReadFile(path, logTag string) ([]byte, bool) {
	data, err := os.ReadFile(path)
	if err != nil {
		if !os.IsNotExist(err) {
			log.Printf("[%s] read error: %v", logTag, err)
		}
		return nil, false
	}
	return data, true
}
