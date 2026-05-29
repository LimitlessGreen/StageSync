package showcontrol

import (
	"sync"
	"time"

	"google.golang.org/protobuf/proto"

	pb "stagesync-server/gen/go/stagesync/v1"
)

// Store hält alle CueLists einer Session.
type Store struct {
	mu       sync.RWMutex
	cueLists map[string]*CueList // cueListID → CueList
	activeID string

	// Echter Fan-out: jeder Watcher hat seinen eigenen Channel (sonst würden
	// sich mehrere Geräte die Events teilen → divergierender State).
	subMu       sync.Mutex
	subscribers map[chan *pb.ShowStateEvent]struct{}
	seq         int64 // monoton, pro Store; in jedes Event geschrieben
}

type CueList struct {
	mu          sync.RWMutex
	proto       *pb.CueList
	cueIndex    map[string]int // cueID → Index in proto.Cues
	activeCueID string
	nextCueID   string
}

func NewStore() *Store {
	s := &Store{
		cueLists:    make(map[string]*CueList),
		subscribers: make(map[chan *pb.ShowStateEvent]struct{}),
	}
	// Standard-CueList beim Start erstellen
	defaultList := newCueList("main", "Main")
	s.cueLists["main"] = defaultList
	s.activeID = "main"
	return s
}

func newCueList(id, name string) *CueList {
	return &CueList{
		proto: &pb.CueList{
			CueListId: id,
			Name:      name,
			Cues:      []*pb.Cue{},
			UpdatedAt: nowProto(),
		},
		cueIndex: make(map[string]int),
	}
}

// ── CueList Operations ────────────────────────────────────────────────────────

func (s *Store) GetCueList(id string) (*pb.CueList, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if id == "" {
		id = s.activeID
	}
	cl, ok := s.cueLists[id]
	if !ok {
		return nil, false
	}
	cl.mu.RLock()
	defer cl.mu.RUnlock()
	return cloneProto(cl.proto), true
}

func (s *Store) ReplaceCueList(incoming *pb.CueList) *pb.CueList {
	s.mu.Lock()
	defer s.mu.Unlock()

	incoming.UpdatedAt = nowProto()
	incoming.Version++

	cl := newCueList(incoming.CueListId, incoming.Name)
	cl.proto = incoming
	for i, c := range incoming.Cues {
		cl.cueIndex[c.CueId] = i
	}
	s.cueLists[incoming.CueListId] = cl

	s.broadcast(&pb.ShowStateEvent{
		Type:       pb.ShowStateEvent_TYPE_LIST_UPDATED,
		CueList:    cloneProto(incoming),
		OccurredAt: nowProto(),
	})

	return cloneProto(incoming)
}

// UpsertCue fügt eine Cue ein oder aktualisiert sie (versioniertes Merge).
func (s *Store) UpsertCue(cueListID string, cue *pb.Cue) (*pb.Cue, bool) {
	s.mu.Lock()
	cl, ok := s.cueLists[cueListID]
	s.mu.Unlock()
	if !ok {
		return nil, false
	}

	cl.mu.Lock()
	defer cl.mu.Unlock()

	cue.UpdatedAt = nowProto()
	cue.Version++

	if idx, exists := cl.cueIndex[cue.CueId]; exists {
		// Nur aktualisieren, wenn neue Version höher
		existing := cl.proto.Cues[idx]
		if cue.Version <= existing.Version {
			return cloneCue(existing), true
		}
		cl.proto.Cues[idx] = cue
	} else {
		cl.cueIndex[cue.CueId] = len(cl.proto.Cues)
		cl.proto.Cues = append(cl.proto.Cues, cue)
	}

	cl.proto.UpdatedAt = nowProto()
	cl.proto.Version++

	s.broadcast(&pb.ShowStateEvent{
		Type:        pb.ShowStateEvent_TYPE_LIST_UPDATED,
		CueList:     cloneProto(cl.proto),
		AffectedCue: cloneCue(cue),
		OccurredAt:  nowProto(),
	})

	return cloneCue(cue), true
}

// DeleteCue entfernt eine Cue.
func (s *Store) DeleteCue(cueListID, cueID string) bool {
	s.mu.Lock()
	cl, ok := s.cueLists[cueListID]
	s.mu.Unlock()
	if !ok {
		return false
	}

	cl.mu.Lock()
	defer cl.mu.Unlock()

	idx, exists := cl.cueIndex[cueID]
	if !exists {
		return false
	}

	cl.proto.Cues = append(cl.proto.Cues[:idx], cl.proto.Cues[idx+1:]...)
	delete(cl.cueIndex, cueID)
	// Index neu aufbauen
	for i, c := range cl.proto.Cues {
		cl.cueIndex[c.CueId] = i
	}
	cl.proto.UpdatedAt = nowProto()
	cl.proto.Version++

	s.broadcast(&pb.ShowStateEvent{
		Type:       pb.ShowStateEvent_TYPE_LIST_UPDATED,
		CueList:    cloneProto(cl.proto),
		OccurredAt: nowProto(),
	})
	return true
}

// ── Position Tracking ─────────────────────────────────────────────────────────

// GetActiveCue gibt die aktuell aktive Cue zurück (nil wenn keine).
func (s *Store) GetActiveCue(cueListID string) *pb.Cue {
	s.mu.RLock()
	cl, ok := s.cueLists[cueListID]
	s.mu.RUnlock()
	if !ok {
		return nil
	}
	cl.mu.RLock()
	defer cl.mu.RUnlock()
	if cl.activeCueID == "" {
		return nil
	}
	if idx, ok := cl.cueIndex[cl.activeCueID]; ok {
		return cloneCue(cl.proto.Cues[idx])
	}
	return nil
}

func (s *Store) SetActiveCue(cueListID, cueID string) {
	s.mu.RLock()
	cl, ok := s.cueLists[cueListID]
	s.mu.RUnlock()
	if !ok {
		return
	}

	cl.mu.Lock()
	cl.activeCueID = cueID
	cl.proto.ActiveCueId = cueID

	// Nächste Cue ermitteln
	if idx, exists := cl.cueIndex[cueID]; exists && idx+1 < len(cl.proto.Cues) {
		cl.nextCueID = cl.proto.Cues[idx+1].CueId
		cl.proto.NextCueId = cl.nextCueID
	} else {
		cl.nextCueID = ""
		cl.proto.NextCueId = ""
	}
	cl.mu.Unlock()
}

// NextCue gibt die nächste auszuführende Cue zurück.
func (s *Store) NextCue(cueListID string) (*pb.Cue, bool) {
	s.mu.RLock()
	cl, ok := s.cueLists[cueListID]
	s.mu.RUnlock()
	if !ok {
		return nil, false
	}

	cl.mu.RLock()
	defer cl.mu.RUnlock()

	if cl.nextCueID != "" {
		if idx, ok := cl.cueIndex[cl.nextCueID]; ok {
			return cloneCue(cl.proto.Cues[idx]), true
		}
	}
	// Noch keine aktive Cue: erste Cue
	if len(cl.proto.Cues) > 0 {
		return cloneCue(cl.proto.Cues[0]), true
	}
	return nil, false
}

// Subscribe registriert einen neuen Watcher und gibt seinen Channel zurück.
func (s *Store) Subscribe() chan *pb.ShowStateEvent {
	ch := make(chan *pb.ShowStateEvent, 64)
	s.subMu.Lock()
	s.subscribers[ch] = struct{}{}
	s.subMu.Unlock()
	return ch
}

// Unsubscribe entfernt einen Watcher und schließt seinen Channel.
func (s *Store) Unsubscribe(ch chan *pb.ShowStateEvent) {
	s.subMu.Lock()
	if _, ok := s.subscribers[ch]; ok {
		delete(s.subscribers, ch)
		close(ch)
	}
	s.subMu.Unlock()
}

// CurrentSeq gibt die zuletzt vergebene Sequenznummer zurück.
func (s *Store) CurrentSeq() int64 {
	s.subMu.Lock()
	defer s.subMu.Unlock()
	return s.seq
}

// broadcast vergibt eine Sequenznummer und sendet das Event an ALLE Watcher
// (Fan-out, non-blocking).
func (s *Store) broadcast(ev *pb.ShowStateEvent) {
	s.subMu.Lock()
	s.seq++
	ev.Seq = s.seq
	for ch := range s.subscribers {
		select {
		case ch <- ev:
		default: // Watcher zu langsam — Event verwerfen statt blockieren
		}
	}
	s.subMu.Unlock()
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// Deep-Clone für gRPC-Responses und Broadcasts: proto.Clone kopiert auch
// verschachtelte Felder (Params, Timestamps) und vermeidet das Kopieren des
// internen Mutex/MessageState — verhindert geteilte Pointer & Data-Races.
func cloneProto(cl *pb.CueList) *pb.CueList {
	return proto.Clone(cl).(*pb.CueList)
}

func cloneCue(c *pb.Cue) *pb.Cue {
	return proto.Clone(c).(*pb.Cue)
}

func nowProto() *pb.Timestamp {
	return &pb.Timestamp{UnixMillis: time.Now().UnixMilli()}
}
