package showcontrol

import (
	"sync"
	"time"

	"google.golang.org/protobuf/proto"

	pb "stagesync-server/gen/go/stagesync/v1"
)

// Store hält alle CueLists einer Session und die 4 Event-Broadcast-Kanäle.
type Store struct {
	mu       sync.RWMutex
	cueLists map[string]*CueList // cueListID → CueList
	activeID string

	// Stream 1: Show-Definition (CueList-Änderungen)
	defMu   sync.Mutex
	defSubs map[chan *pb.ShowDefinitionEvent]struct{}
	defSeq  int64

	// Stream 2: Show-Execution (Transport-Events)
	execMu   sync.Mutex
	execSubs map[chan *pb.ShowExecutionEvent]struct{}
	execSeq  int64
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
		cueLists: make(map[string]*CueList),
		defSubs:  make(map[chan *pb.ShowDefinitionEvent]struct{}),
		execSubs: make(map[chan *pb.ShowExecutionEvent]struct{}),
	}
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

	s.broadcastDef(&pb.ShowDefinitionEvent{
		Type:    pb.ShowDefinitionEvent_CUE_LIST_CHANGED,
		CueList: cloneProto(incoming),
		OccurredAt: nowProto(),
	})

	return cloneProto(incoming)
}

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

	s.broadcastDef(&pb.ShowDefinitionEvent{
		Type:    pb.ShowDefinitionEvent_CUE_LIST_CHANGED,
		CueList: cloneProto(cl.proto),
		OccurredAt: nowProto(),
	})

	return cloneCue(cue), true
}

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
	for i, c := range cl.proto.Cues {
		cl.cueIndex[c.CueId] = i
	}
	cl.proto.UpdatedAt = nowProto()
	cl.proto.Version++

	s.broadcastDef(&pb.ShowDefinitionEvent{
		Type:    pb.ShowDefinitionEvent_CUE_LIST_CHANGED,
		CueList: cloneProto(cl.proto),
		OccurredAt: nowProto(),
	})
	return true
}

// ── Position Tracking ─────────────────────────────────────────────────────────

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

	if idx, exists := cl.cueIndex[cueID]; exists && idx+1 < len(cl.proto.Cues) {
		cl.nextCueID = cl.proto.Cues[idx+1].CueId
		cl.proto.NextCueId = cl.nextCueID
	} else {
		cl.nextCueID = ""
		cl.proto.NextCueId = ""
	}
	cl.mu.Unlock()
}

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
	if len(cl.proto.Cues) > 0 {
		return cloneCue(cl.proto.Cues[0]), true
	}
	return nil, false
}

// ── Stream 1: Definition Subscribe/Broadcast ──────────────────────────────────

func (s *Store) SubscribeDef() chan *pb.ShowDefinitionEvent {
	ch := make(chan *pb.ShowDefinitionEvent, 64)
	s.defMu.Lock()
	s.defSubs[ch] = struct{}{}
	s.defMu.Unlock()
	return ch
}

func (s *Store) UnsubscribeDef(ch chan *pb.ShowDefinitionEvent) {
	s.defMu.Lock()
	if _, ok := s.defSubs[ch]; ok {
		delete(s.defSubs, ch)
		close(ch)
	}
	s.defMu.Unlock()
}

func (s *Store) broadcastDef(ev *pb.ShowDefinitionEvent) {
	s.defMu.Lock()
	s.defSeq++
	ev.Seq = s.defSeq
	for ch := range s.defSubs {
		select {
		case ch <- ev:
		default:
		}
	}
	s.defMu.Unlock()
}

func (s *Store) CurrentDefSeq() int64 {
	s.defMu.Lock()
	defer s.defMu.Unlock()
	return s.defSeq
}

// ── Stream 2: Execution Subscribe/Broadcast ───────────────────────────────────

func (s *Store) SubscribeExec() chan *pb.ShowExecutionEvent {
	ch := make(chan *pb.ShowExecutionEvent, 64)
	s.execMu.Lock()
	s.execSubs[ch] = struct{}{}
	s.execMu.Unlock()
	return ch
}

func (s *Store) UnsubscribeExec(ch chan *pb.ShowExecutionEvent) {
	s.execMu.Lock()
	if _, ok := s.execSubs[ch]; ok {
		delete(s.execSubs, ch)
		close(ch)
	}
	s.execMu.Unlock()
}

func (s *Store) BroadcastExec(ev *pb.ShowExecutionEvent) {
	s.execMu.Lock()
	s.execSeq++
	ev.Seq = s.execSeq
	for ch := range s.execSubs {
		select {
		case ch <- ev:
		default:
		}
	}
	s.execMu.Unlock()
}

func (s *Store) CurrentExecSeq() int64 {
	s.execMu.Lock()
	defer s.execMu.Unlock()
	return s.execSeq
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func cloneProto(cl *pb.CueList) *pb.CueList {
	return proto.Clone(cl).(*pb.CueList)
}

func cloneCue(c *pb.Cue) *pb.Cue {
	return proto.Clone(c).(*pb.Cue)
}

func nowProto() *pb.Timestamp {
	return &pb.Timestamp{UnixMillis: time.Now().UnixMilli()}
}
