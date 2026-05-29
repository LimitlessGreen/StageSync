package grpc

import (
	"context"
	"sync"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/emptypb"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/node"
	"stagesync-server/internal/session"
	"stagesync-server/internal/showcontrol"
)

// ShowControlHandler verwaltet CueLists und die ShowEngine pro Session.
type ShowControlHandler struct {
	pb.UnimplementedShowControlServiceServer
	sessionMgr  *session.Manager
	dispatcher  *node.Dispatcher
	persistence *showcontrol.Persistence

	mu      sync.RWMutex
	stores  map[string]*showcontrol.Store  // sessionID → Store
	engines map[string]*showcontrol.Engine // sessionID → Engine
}

func NewShowControlHandler(mgr *session.Manager, disp *node.Dispatcher, persist *showcontrol.Persistence) *ShowControlHandler {
	return &ShowControlHandler{
		sessionMgr:  mgr,
		dispatcher:  disp,
		persistence: persist,
		stores:      make(map[string]*showcontrol.Store),
		engines:     make(map[string]*showcontrol.Engine),
	}
}

func (h *ShowControlHandler) getOrCreateStore(sessionID string) *showcontrol.Store {
	h.mu.Lock()
	defer h.mu.Unlock()
	if s, ok := h.stores[sessionID]; ok {
		return s
	}
	store := showcontrol.NewStore()
	h.stores[sessionID] = store
	engine := showcontrol.NewEngine(sessionID, "main", store, h.dispatcher)
	h.engines[sessionID] = engine
	// Gespeicherten Zustand laden (no-op wenn keine Datei existiert)
	h.persistence.Load(sessionID, store)
	return store
}

func (h *ShowControlHandler) getEngine(sessionID string) (*showcontrol.Engine, bool) {
	h.mu.RLock()
	defer h.mu.RUnlock()
	e, ok := h.engines[sessionID]
	return e, ok
}

func (h *ShowControlHandler) auth(sessionID, token string) error {
	_, _, err := h.sessionMgr.ValidateToken(sessionID, token)
	if err != nil {
		return status.Error(codes.Unauthenticated, err.Error())
	}
	return nil
}

func (h *ShowControlHandler) GetCueList(ctx context.Context, req *pb.GetCueListRequest) (*pb.CueListResponse, error) {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store := h.getOrCreateStore(req.SessionId)
	cl, ok := store.GetCueList(req.CueListId)
	if !ok {
		return nil, status.Error(codes.NotFound, "cue list not found")
	}
	return &pb.CueListResponse{CueList: cl}, nil
}

func (h *ShowControlHandler) UpdateCueList(ctx context.Context, req *pb.UpdateCueListRequest) (*pb.CueListResponse, error) {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store := h.getOrCreateStore(req.SessionId)
	updated := store.ReplaceCueList(req.CueList)
	h.persistence.Save(req.SessionId, store)
	return &pb.CueListResponse{CueList: updated}, nil
}

func (h *ShowControlHandler) UpsertCue(ctx context.Context, req *pb.UpsertCueRequest) (*pb.CueResponse, error) {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store := h.getOrCreateStore(req.SessionId)
	cue, ok := store.UpsertCue(req.CueListId, req.Cue)
	if !ok {
		return nil, status.Error(codes.NotFound, "cue list not found")
	}
	h.persistence.Save(req.SessionId, store)
	return &pb.CueResponse{Cue: cue}, nil
}

func (h *ShowControlHandler) DeleteCue(ctx context.Context, req *pb.DeleteCueRequest) (*emptypb.Empty, error) {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store := h.getOrCreateStore(req.SessionId)
	if !store.DeleteCue(req.CueListId, req.CueId) {
		return nil, status.Error(codes.NotFound, "cue not found")
	}
	h.persistence.Save(req.SessionId, store)
	return &emptypb.Empty{}, nil
}

func (h *ShowControlHandler) Go(ctx context.Context, req *pb.GoRequest) (*pb.GoResponse, error) {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	h.getOrCreateStore(req.SessionId)
	engine, ok := h.getEngine(req.SessionId)
	if !ok {
		return nil, status.Error(codes.Internal, "show engine not initialized")
	}

	executing, next, err := engine.Go(ctx, req.CueId)
	if err != nil {
		if err == showcontrol.ErrNoCue {
			return nil, status.Error(codes.NotFound, "no cue to execute")
		}
		return nil, status.Errorf(codes.Internal, "%v", err)
	}
	return &pb.GoResponse{ExecutingCue: executing, NextCue: next}, nil
}

func (h *ShowControlHandler) Stop(ctx context.Context, req *pb.StopRequest) (*emptypb.Empty, error) {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	if engine, ok := h.getEngine(req.SessionId); ok {
		_ = engine.Stop(ctx)
	}
	return &emptypb.Empty{}, nil
}

func (h *ShowControlHandler) Pause(ctx context.Context, req *pb.PauseRequest) (*emptypb.Empty, error) {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	if engine, ok := h.getEngine(req.SessionId); ok {
		_ = engine.Pause(ctx)
	}
	return &emptypb.Empty{}, nil
}

func (h *ShowControlHandler) Resume(ctx context.Context, req *pb.ResumeRequest) (*emptypb.Empty, error) {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	if engine, ok := h.getEngine(req.SessionId); ok {
		_ = engine.Resume(ctx)
	}
	return &emptypb.Empty{}, nil
}

func (h *ShowControlHandler) WatchShowState(req *pb.WatchShowStateRequest, stream pb.ShowControlService_WatchShowStateServer) error {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return err
	}
	store := h.getOrCreateStore(req.SessionId)
	engine, _ := h.getEngine(req.SessionId)

	// Zuerst abonnieren, dann Snapshot senden: Events, die dazwischen passieren,
	// landen im Channel und werden (per seq) korrekt nach dem Snapshot angewandt.
	ch := store.Subscribe()
	defer store.Unsubscribe(ch)

	for _, ev := range h.snapshotEvents(store, engine, req.NodeId) {
		if err := stream.Send(ev); err != nil {
			return err
		}
	}

	for {
		select {
		case <-stream.Context().Done():
			return nil
		case ev, ok := <-ch:
			if !ok {
				return nil
			}
			// Klonen: der Event-Pointer wird an alle Watcher fan-out — NodeId
			// pro Stream zu setzen würde sonst den geteilten Pointer mutieren.
			out := proto.Clone(ev).(*pb.ShowStateEvent)
			out.NodeId = req.NodeId
			if err := stream.Send(out); err != nil {
				return err
			}
		}
	}
}

// snapshotEvents baut den aktuellen Show-Zustand als Event-Folge für einen neu
// verbundenen Watcher (Cue-Liste + ggf. laufender/pausierter Transport).
func (h *ShowControlHandler) snapshotEvents(store *showcontrol.Store, engine *showcontrol.Engine, nodeID string) []*pb.ShowStateEvent {
	seq := store.CurrentSeq()
	out := make([]*pb.ShowStateEvent, 0, 2)

	if cl, ok := store.GetCueList(""); ok {
		out = append(out, &pb.ShowStateEvent{
			Type:       pb.ShowStateEvent_TYPE_LIST_UPDATED,
			CueList:    cl,
			NodeId:     nodeID,
			OccurredAt: &pb.Timestamp{UnixMillis: time.Now().UnixMilli()},
			Seq:        seq,
		})
	}

	if engine != nil {
		ts := engine.TransportSnapshot()
		if ts.Running && ts.ActiveCue != nil {
			out = append(out, &pb.ShowStateEvent{
				Type:        pb.ShowStateEvent_TYPE_CUE_STARTED,
				AffectedCue: ts.ActiveCue,
				NodeId:      nodeID,
				OccurredAt:  &pb.Timestamp{UnixMillis: ts.CueStartedAtMs},
				IsPaused:    ts.Paused,
				Seq:         seq,
			})
			if ts.Paused {
				out = append(out, &pb.ShowStateEvent{
					Type:        pb.ShowStateEvent_TYPE_CUE_PAUSED,
					AffectedCue: ts.ActiveCue,
					NodeId:      nodeID,
					OccurredAt:  &pb.Timestamp{UnixMillis: ts.PausedAtMs},
					IsPaused:    true,
					Seq:         seq,
				})
			}
		}
	}
	return out
}
