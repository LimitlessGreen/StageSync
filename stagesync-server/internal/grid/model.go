package grid

import (
	"sync"
	"time"

	"google.golang.org/protobuf/proto"

	pb "stagesync-server/gen/go/stagesync/v1"
)

// Store hält alle Grids einer Session und den Execution-Broadcast-Kanal.
// Spiegelt das Subscribe/Broadcast-Muster von showcontrol.Store.
type Store struct {
	mu    sync.RWMutex
	grids map[string]*pb.Grid // gridID → Grid

	// Definition-Stream (Grid-Änderungen).
	defMu   sync.Mutex
	defSubs map[chan *pb.Grid]struct{}

	// Execution-Stream (Clip-Transport).
	execMu   sync.Mutex
	execSubs map[chan *pb.GridExecutionEvent]struct{}
	execSeq  int64
}

const DefaultGridID = "main"

func NewStore() *Store {
	s := &Store{
		grids:    make(map[string]*pb.Grid),
		defSubs:  make(map[chan *pb.Grid]struct{}),
		execSubs: make(map[chan *pb.GridExecutionEvent]struct{}),
	}
	s.grids[DefaultGridID] = newDefaultGrid()
	return s
}

// newDefaultGrid liefert ein leeres 8×8-Grid (passend zum APC Mini Pad-Layout).
func newDefaultGrid() *pb.Grid {
	tracks := make([]*pb.GridTrack, 0, 8)
	for i := 0; i < 8; i++ {
		tracks = append(tracks, &pb.GridTrack{
			TrackId:   trackID(i),
			Name:      "",
			Exclusive: true,
		})
	}
	scenes := make([]*pb.GridScene, 0, 8)
	for i := 0; i < 8; i++ {
		scenes = append(scenes, &pb.GridScene{SceneId: sceneID(i)})
	}
	return &pb.Grid{
		GridId: DefaultGridID,
		Name:   "Main",
		Tracks: tracks,
		Scenes: scenes,
		Clips:  []*pb.GridClip{},
	}
}

// ── Grid Operations ─────────────────────────────────────────────────────────

func (s *Store) GetGrid(id string) (*pb.Grid, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if id == "" {
		id = DefaultGridID
	}
	g, ok := s.grids[id]
	if !ok {
		return nil, false
	}
	return proto.Clone(g).(*pb.Grid), true
}

func (s *Store) ReplaceGrid(incoming *pb.Grid) *pb.Grid {
	s.mu.Lock()
	if incoming.GridId == "" {
		incoming.GridId = DefaultGridID
	}
	incoming.Version++
	s.grids[incoming.GridId] = incoming
	out := proto.Clone(incoming).(*pb.Grid)
	s.mu.Unlock()

	s.broadcastDef(out)
	return proto.Clone(out).(*pb.Grid)
}

// UpsertClip setzt eine Zelle (track_index, scene_index). Vorhandene Zelle an
// derselben Position wird ersetzt (Position ist der logische Schlüssel).
func (s *Store) UpsertClip(gridID string, clip *pb.GridClip) (*pb.GridClip, bool) {
	s.mu.Lock()
	g, ok := s.grids[gridID]
	if !ok {
		s.mu.Unlock()
		return nil, false
	}
	replaced := false
	for i, c := range g.Clips {
		if c.TrackIndex == clip.TrackIndex && c.SceneIndex == clip.SceneIndex {
			g.Clips[i] = clip
			replaced = true
			break
		}
	}
	if !replaced {
		g.Clips = append(g.Clips, clip)
	}
	g.Version++
	out := proto.Clone(g).(*pb.Grid)
	clipOut := proto.Clone(clip).(*pb.GridClip)
	s.mu.Unlock()

	s.broadcastDef(out)
	return clipOut, true
}

func (s *Store) DeleteClip(gridID, clipID string) bool {
	s.mu.Lock()
	g, ok := s.grids[gridID]
	if !ok {
		s.mu.Unlock()
		return false
	}
	idx := -1
	for i, c := range g.Clips {
		if c.ClipId == clipID {
			idx = i
			break
		}
	}
	if idx < 0 {
		s.mu.Unlock()
		return false
	}
	g.Clips = append(g.Clips[:idx], g.Clips[idx+1:]...)
	g.Version++
	out := proto.Clone(g).(*pb.Grid)
	s.mu.Unlock()

	s.broadcastDef(out)
	return true
}

// ClipAt liefert den Clip an einer Gitterposition (geklont).
func (s *Store) ClipAt(gridID string, track, scene int32) (*pb.GridClip, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	g, ok := s.grids[gridID]
	if !ok {
		return nil, false
	}
	for _, c := range g.Clips {
		if c.TrackIndex == track && c.SceneIndex == scene {
			return proto.Clone(c).(*pb.GridClip), true
		}
	}
	return nil, false
}

// ClipsInScene liefert alle Clips einer Reihe (geklont).
func (s *Store) ClipsInScene(gridID string, scene int32) []*pb.GridClip {
	s.mu.RLock()
	defer s.mu.RUnlock()
	g, ok := s.grids[gridID]
	if !ok {
		return nil
	}
	var out []*pb.GridClip
	for _, c := range g.Clips {
		if c.SceneIndex == scene {
			out = append(out, proto.Clone(c).(*pb.GridClip))
		}
	}
	return out
}

// TrackExclusive prüft, ob die Spalte exklusiv ist (default true, wenn unbekannt).
func (s *Store) TrackExclusive(gridID string, track int32) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	g, ok := s.grids[gridID]
	if !ok {
		return true
	}
	if int(track) < len(g.Tracks) {
		return g.Tracks[track].Exclusive
	}
	return true
}

// TrackBusSends liefert die Bus-Routing-Sends einer Spalte.
func (s *Store) TrackBusSends(gridID string, track int32) []*pb.BusSend {
	s.mu.RLock()
	defer s.mu.RUnlock()
	g, ok := s.grids[gridID]
	if !ok {
		return nil
	}
	if int(track) < len(g.Tracks) {
		return g.Tracks[track].BusSends
	}
	return nil
}

// ── Definition Subscribe/Broadcast ──────────────────────────────────────────

func (s *Store) SubscribeDef() chan *pb.Grid {
	ch := make(chan *pb.Grid, 16)
	s.defMu.Lock()
	s.defSubs[ch] = struct{}{}
	s.defMu.Unlock()
	return ch
}

func (s *Store) UnsubscribeDef(ch chan *pb.Grid) {
	s.defMu.Lock()
	if _, ok := s.defSubs[ch]; ok {
		delete(s.defSubs, ch)
		close(ch)
	}
	s.defMu.Unlock()
}

func (s *Store) broadcastDef(g *pb.Grid) {
	s.defMu.Lock()
	for ch := range s.defSubs {
		select {
		case ch <- proto.Clone(g).(*pb.Grid):
		default:
		}
	}
	s.defMu.Unlock()
}

// ── Execution Subscribe/Broadcast ───────────────────────────────────────────

func (s *Store) SubscribeExec() chan *pb.GridExecutionEvent {
	ch := make(chan *pb.GridExecutionEvent, 64)
	s.execMu.Lock()
	s.execSubs[ch] = struct{}{}
	s.execMu.Unlock()
	return ch
}

func (s *Store) UnsubscribeExec(ch chan *pb.GridExecutionEvent) {
	s.execMu.Lock()
	if _, ok := s.execSubs[ch]; ok {
		delete(s.execSubs, ch)
		close(ch)
	}
	s.execMu.Unlock()
}

func (s *Store) BroadcastExec(ev *pb.GridExecutionEvent) {
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

// ── Helpers ─────────────────────────────────────────────────────────────────

func trackID(i int) string { return "track-" + itoa(i) }
func sceneID(i int) string { return "scene-" + itoa(i) }

func itoa(i int) string {
	// kleine, allokationsarme Variante für 0..99
	if i < 10 {
		return string(rune('0' + i))
	}
	return string(rune('0'+i/10)) + string(rune('0'+i%10))
}

func nowProto() *pb.Timestamp {
	return &pb.Timestamp{UnixMillis: time.Now().UnixMilli()}
}
