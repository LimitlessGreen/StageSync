package grpc

import (
	"testing"
	"time"
)

// ── commandDedup unit tests ───────────────────────────────────────────────────

func TestCommandDedup_FirstCallNotDuplicate(t *testing.T) {
	d := &commandDedup{seen: make(map[string]time.Time)}
	if d.checkAndMark("cmd-1") {
		t.Fatal("first call should not be a duplicate")
	}
}

func TestCommandDedup_SecondCallIsDuplicate(t *testing.T) {
	d := &commandDedup{seen: make(map[string]time.Time)}
	d.checkAndMark("cmd-1")
	if !d.checkAndMark("cmd-1") {
		t.Fatal("second call with same id should be a duplicate")
	}
}

func TestCommandDedup_DifferentIDsAreIndependent(t *testing.T) {
	d := &commandDedup{seen: make(map[string]time.Time)}
	d.checkAndMark("cmd-a")
	if d.checkAndMark("cmd-b") {
		t.Fatal("different commandIds must not interfere")
	}
}

func TestCommandDedup_EmptyIDAlwaysAllowed(t *testing.T) {
	d := &commandDedup{seen: make(map[string]time.Time)}
	if d.checkAndMark("") {
		t.Fatal("empty commandId should never be treated as duplicate")
	}
	// second call with empty id also allowed
	if d.checkAndMark("") {
		t.Fatal("empty commandId should never be treated as duplicate on repeat")
	}
}

func TestCommandDedup_CleanupRemovesExpiredEntries(t *testing.T) {
	d := &commandDedup{seen: make(map[string]time.Time)}

	// Inject an already-expired entry manually
	d.seen["old-cmd"] = time.Now().Add(-90 * time.Second)
	d.seen["fresh-cmd"] = time.Now()

	cutoff := time.Now().Add(-60 * time.Second)
	d.mu.Lock()
	for id, ts := range d.seen {
		if ts.Before(cutoff) {
			delete(d.seen, id)
		}
	}
	d.mu.Unlock()

	d.mu.Lock()
	_, hasOld := d.seen["old-cmd"]
	_, hasFresh := d.seen["fresh-cmd"]
	d.mu.Unlock()

	if hasOld {
		t.Error("expired entry should have been cleaned up")
	}
	if !hasFresh {
		t.Error("fresh entry should still be present")
	}
}

func TestCommandDedup_AfterCleanupSameIDCanBeReused(t *testing.T) {
	d := &commandDedup{seen: make(map[string]time.Time)}

	// Inject expired entry
	d.mu.Lock()
	d.seen["reused-cmd"] = time.Now().Add(-90 * time.Second)
	d.mu.Unlock()

	// Run cleanup manually
	cutoff := time.Now().Add(-60 * time.Second)
	d.mu.Lock()
	for id, ts := range d.seen {
		if ts.Before(cutoff) {
			delete(d.seen, id)
		}
	}
	d.mu.Unlock()

	// Now the same ID should be accepted again (not a duplicate)
	if d.checkAndMark("reused-cmd") {
		t.Error("after cleanup, the same commandId should be re-accepted")
	}
}
