package grpc

import (
	"sync"
	"time"
)

// commandDedup verhindert dass dasselbe Command (identische commandId) doppelt
// ausgeführt wird. TTL = 60 s — nach Ablauf ist eine Re-Execution erlaubt.
type commandDedup struct {
	mu   sync.Mutex
	seen map[string]time.Time // commandId → Zeit des ersten Empfangs
}

func newCommandDedup() *commandDedup {
	d := &commandDedup{seen: make(map[string]time.Time)}
	go d.cleanupLoop()
	return d
}

// checkAndMark gibt true zurück wenn das commandId BEREITS gesehen wurde (Duplikat).
func (d *commandDedup) checkAndMark(commandID string) bool {
	if commandID == "" {
		return false
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	if _, exists := d.seen[commandID]; exists {
		return true
	}
	d.seen[commandID] = time.Now()
	return false
}

func (d *commandDedup) cleanupLoop() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	for range ticker.C {
		d.mu.Lock()
		cutoff := time.Now().Add(-60 * time.Second)
		for id, t := range d.seen {
			if t.Before(cutoff) {
				delete(d.seen, id)
			}
		}
		d.mu.Unlock()
	}
}
