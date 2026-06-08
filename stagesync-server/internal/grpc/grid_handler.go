package grpc

import (
	"context"
	"log"
	"sync"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/grid"
	"stagesync-server/internal/node"
	"stagesync-server/internal/peaks"
	"stagesync-server/internal/session"
)

// CueLauncherFunc adaptiert eine Funktion an das grid.CueLauncher-Interface,
// damit der Grid-Handler cue_ref-Clips an die ShowControl-Engine delegieren kann.
type CueLauncherFunc func(ctx context.Context, sessionID, cueListID, cueID string) error

// GridHandler implementiert den GridService. Verwaltet Grid-Store + Grid-Engine
// pro Session, analog zum ShowControlHandler.
type GridHandler struct {
	pb.UnimplementedGridServiceServer
	sessionMgr  *session.Manager
	dispatcher  *node.Dispatcher
	persistence *grid.Persistence
	peaks       *peaks.Service // optional; nil = Waveform deaktiviert
	dedup       *commandDedup
	cueLauncher CueLauncherFunc // optional; cue_ref-Delegation an ShowControl

	mu      sync.RWMutex
	stores  map[string]*grid.Store
	engines map[string]*grid.Engine
}

func NewGridHandler(mgr *session.Manager, disp *node.Dispatcher, persist *grid.Persistence, pk *peaks.Service) *GridHandler {
	return &GridHandler{
		sessionMgr:  mgr,
		dispatcher:  disp,
		persistence: persist,
		peaks:       pk,
		dedup:       newCommandDedup(),
		stores:      make(map[string]*grid.Store),
		engines:     make(map[string]*grid.Engine),
	}
}

// SetCueLauncher verbindet die ShowControl-Delegation für cue_ref-Clips.
func (h *GridHandler) SetCueLauncher(f CueLauncherFunc) {
	h.mu.Lock()
	h.cueLauncher = f
	for sid, e := range h.engines {
		e.SetCueLauncher(h.sessionCueLauncher(sid))
	}
	h.mu.Unlock()
}

// sessionCueLauncher bindet die sessionID an den CueLauncherFunc.
func (h *GridHandler) sessionCueLauncher(sessionID string) grid.CueLauncher {
	return cueLauncherAdapter{h: h, sessionID: sessionID}
}

type cueLauncherAdapter struct {
	h         *GridHandler
	sessionID string
}

func (a cueLauncherAdapter) LaunchCue(ctx context.Context, cueListID, cueID string) error {
	a.h.mu.RLock()
	f := a.h.cueLauncher
	a.h.mu.RUnlock()
	if f == nil {
		return status.Error(codes.Unavailable, "cue launcher not configured")
	}
	return f(ctx, a.sessionID, cueListID, cueID)
}

func (h *GridHandler) getOrCreate(sessionID string) (*grid.Store, *grid.Engine) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if s, ok := h.stores[sessionID]; ok {
		return s, h.engines[sessionID]
	}
	store := grid.NewStore()
	engine := grid.NewEngine(sessionID, store, h.dispatcher)
	if h.cueLauncher != nil {
		engine.SetCueLauncher(h.sessionCueLauncher(sessionID))
	}
	h.stores[sessionID] = store
	h.engines[sessionID] = engine
	h.persistence.Load(sessionID, store)
	return store, engine
}

// LaunchClipInternal löst einen Clip ohne Token-Auth aus — für vertrauenswürdige
// In-Process-Aufrufer wie den internen MIDI-Node. Implementiert midinode.GridLauncher.
func (h *GridHandler) LaunchClipInternal(sessionID, gridID string, track, scene int32, released bool) {
	if gridID == "" {
		gridID = grid.DefaultGridID
	}
	_, engine := h.getOrCreate(sessionID)
	_ = engine.LaunchClip(context.Background(), gridID, track, scene, released)
}

// ── Definition RPCs ───────────────────────────────────────────────────────────

func (h *GridHandler) GetGrid(ctx context.Context, req *pb.GetGridRequest) (*pb.GridResponse, error) {
	if err := authBasic(h.sessionMgr, req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store, _ := h.getOrCreate(req.SessionId)
	g, ok := store.GetGrid(req.GridId)
	if !ok {
		return nil, status.Error(codes.NotFound, "grid not found")
	}
	return &pb.GridResponse{Grid: g}, nil
}

func (h *GridHandler) UpdateGrid(ctx context.Context, req *pb.UpdateGridRequest) (*pb.GridResponse, error) {
	if err := authWrite(h.sessionMgr, req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store, _ := h.getOrCreate(req.SessionId)
	updated := store.ReplaceGrid(req.Grid)
	h.persistence.Save(req.SessionId, store)
	return &pb.GridResponse{Grid: updated}, nil
}

func (h *GridHandler) UpsertClip(ctx context.Context, req *pb.UpsertClipRequest) (*pb.ClipResponse, error) {
	if err := authWrite(h.sessionMgr, req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store, _ := h.getOrCreate(req.SessionId)
	clip, ok := store.UpsertClip(req.GridId, req.Clip)
	if !ok {
		return nil, status.Error(codes.NotFound, "grid not found")
	}
	h.persistence.Save(req.SessionId, store)
	return &pb.ClipResponse{Clip: clip}, nil
}

func (h *GridHandler) DeleteClip(ctx context.Context, req *pb.DeleteClipRequest) (*emptypb.Empty, error) {
	if err := authWrite(h.sessionMgr, req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store, _ := h.getOrCreate(req.SessionId)
	if !store.DeleteClip(req.GridId, req.ClipId) {
		return nil, status.Error(codes.NotFound, "clip not found")
	}
	h.persistence.Save(req.SessionId, store)
	return &emptypb.Empty{}, nil
}

// ── Execution RPCs ────────────────────────────────────────────────────────────

func (h *GridHandler) LaunchClip(ctx context.Context, req *pb.LaunchClipRequest) (*emptypb.Empty, error) {
	if err := authWrite(h.sessionMgr, req.SessionId, req.Token); err != nil {
		return nil, err
	}
	// released-Events nicht deduplizieren (kein eindeutiges command_id pro Release).
	if !req.Released && h.dedup.checkAndMark(req.CommandId) {
		return &emptypb.Empty{}, nil
	}
	_, engine := h.getOrCreate(req.SessionId)
	if err := engine.LaunchClip(ctx, req.GridId, req.TrackIndex, req.SceneIndex, req.Released); err != nil {
		if err == grid.ErrNoClip {
			return &emptypb.Empty{}, nil // leere Zelle: kein Fehler
		}
		return nil, status.Errorf(codes.Internal, "%v", err)
	}
	return &emptypb.Empty{}, nil
}

func (h *GridHandler) LaunchScene(ctx context.Context, req *pb.LaunchSceneRequest) (*emptypb.Empty, error) {
	if err := authWrite(h.sessionMgr, req.SessionId, req.Token); err != nil {
		return nil, err
	}
	if h.dedup.checkAndMark(req.CommandId) {
		return &emptypb.Empty{}, nil
	}
	_, engine := h.getOrCreate(req.SessionId)
	engine.LaunchScene(ctx, req.GridId, req.SceneIndex)
	return &emptypb.Empty{}, nil
}

func (h *GridHandler) StopTrack(ctx context.Context, req *pb.StopTrackRequest) (*emptypb.Empty, error) {
	if err := authWrite(h.sessionMgr, req.SessionId, req.Token); err != nil {
		return nil, err
	}
	if h.dedup.checkAndMark(req.CommandId) {
		return &emptypb.Empty{}, nil
	}
	_, engine := h.getOrCreate(req.SessionId)
	engine.StopTrack(req.GridId, req.TrackIndex)
	return &emptypb.Empty{}, nil
}

func (h *GridHandler) StopAll(ctx context.Context, req *pb.StopAllRequest) (*emptypb.Empty, error) {
	if err := authWrite(h.sessionMgr, req.SessionId, req.Token); err != nil {
		return nil, err
	}
	if h.dedup.checkAndMark(req.CommandId) {
		return &emptypb.Empty{}, nil
	}
	_, engine := h.getOrCreate(req.SessionId)
	engine.StopAll()
	return &emptypb.Empty{}, nil
}

// ── Stream: WatchGridExecution ────────────────────────────────────────────────

func (h *GridHandler) WatchGridExecution(req *pb.WatchGridExecRequest, stream pb.GridService_WatchGridExecutionServer) error {
	if err := authBasic(h.sessionMgr, req.SessionId, req.Token); err != nil {
		return err
	}
	store, engine := h.getOrCreate(req.SessionId)

	ch := store.SubscribeExec()
	defer store.UnsubscribeExec(ch)

	// Snapshot: aktuell laufende Clips.
	if err := stream.Send(&pb.GridExecutionEvent{
		Type:           pb.GridExecutionEvent_GRID_SNAPSHOT,
		OccurredAt:     nowProto(),
		Seq:            store.CurrentExecSeq(),
		RunningClipIds: engine.RunningClipIDs(),
	}); err != nil {
		return err
	}

	for {
		select {
		case <-stream.Context().Done():
			return nil
		case ev, ok := <-ch:
			if !ok {
				return nil
			}
			if err := stream.Send(ev); err != nil {
				return err
			}
		}
	}
}

// ── Stream: GetWaveform ───────────────────────────────────────────────────────

func (h *GridHandler) GetWaveform(req *pb.WaveformRequest, stream pb.GridService_GetWaveformServer) error {
	if err := authBasic(h.sessionMgr, req.SessionId, req.Token); err != nil {
		return err
	}
	if h.peaks == nil {
		return status.Error(codes.Unavailable, "waveform service not available")
	}
	buckets := int(req.Buckets)
	if buckets <= 0 {
		buckets = 2000
	}
	wf, err := h.peaks.Generate(req.AssetId, buckets)
	if err != nil {
		return status.Errorf(codes.Internal, "waveform: %v", err)
	}

	// Peak-Daten in Chunks zu max ~32 KiB streamen.
	const chunkBytes = 32 * 1024
	data := wf.Data
	first := true
	for len(data) > 0 || first {
		n := len(data)
		if n > chunkBytes {
			n = chunkBytes
		}
		chunk := &pb.WaveformChunk{Data: data[:n]}
		if first {
			chunk.TotalBuckets = int32(wf.TotalBuckets)
			chunk.Channels = wf.Channels
			chunk.SampleRate = wf.SampleRate
			chunk.DurationMs = wf.DurationMs
			first = false
		}
		if err := stream.Send(chunk); err != nil {
			return err
		}
		data = data[n:]
	}
	log.Printf("[grid] waveform asset=%s buckets=%d sent", req.AssetId, wf.TotalBuckets)
	return nil
}
