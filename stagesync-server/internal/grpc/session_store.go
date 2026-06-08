package grpc

import "sync"

// SessionStore verwaltet Store/Engine-Paare pro Session mit Lazy-Init.
// Typsicherer Ersatz für die manuellen mu/stores/engines-Felder in jedem Handler.
type SessionStore[S any, E any] struct {
	mu      sync.RWMutex
	stores  map[string]S
	engines map[string]E
}

func NewSessionStore[S any, E any]() *SessionStore[S, E] {
	return &SessionStore[S, E]{
		stores:  make(map[string]S),
		engines: make(map[string]E),
	}
}

// GetOrCreate gibt das bestehende Paar zurück oder erstellt es via factory.
func (ss *SessionStore[S, E]) GetOrCreate(sessionID string, factory func() (S, E)) (S, E) {
	ss.mu.Lock()
	defer ss.mu.Unlock()
	if s, ok := ss.stores[sessionID]; ok {
		return s, ss.engines[sessionID]
	}
	s, e := factory()
	ss.stores[sessionID] = s
	ss.engines[sessionID] = e
	return s, e
}

// GetEngine gibt die Engine für eine Session zurück (read-only).
func (ss *SessionStore[S, E]) GetEngine(sessionID string) (E, bool) {
	ss.mu.RLock()
	defer ss.mu.RUnlock()
	e, ok := ss.engines[sessionID]
	return e, ok
}

// GetStore gibt den Store für eine Session zurück (read-only).
func (ss *SessionStore[S, E]) GetStore(sessionID string) (S, bool) {
	ss.mu.RLock()
	defer ss.mu.RUnlock()
	s, ok := ss.stores[sessionID]
	return s, ok
}

// ForEachEngine iteriert über alle Engines (unter Write-Lock des Callers).
func (ss *SessionStore[S, E]) ForEachEngine(fn func(sessionID string, e E)) {
	ss.mu.RLock()
	defer ss.mu.RUnlock()
	for id, e := range ss.engines {
		fn(id, e)
	}
}
