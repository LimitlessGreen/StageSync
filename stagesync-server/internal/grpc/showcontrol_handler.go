package grpc

import (
	"context"
	"log"
	"sync"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/media"
	"stagesync-server/internal/node"
	"stagesync-server/internal/session"
	"stagesync-server/internal/showcontrol"
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

// TalkbackDucker ist ein Interface für den Talkback-Relay — verhindert
// einen zyklischen Import zwischen showcontrol_handler und talkback.
type TalkbackDucker interface {
	DuckOnGo(sessionID string, duckDB float32, durationMs int32)
	HasActiveTalkers() bool
}

// BusRouterUpdater synchronisiert den Bus-Router wenn sich die PatchConfig ändert.
type BusRouterUpdater interface {
	Update(patch *pb.PatchConfig)
}

// ShowControlHandler verwaltet CueLists und die ShowEngine pro Session.
type ShowControlHandler struct {
	pb.UnimplementedShowControlServiceServer
	sessionMgr      *session.Manager
	dispatcher      *node.Dispatcher
	persistence     *showcontrol.Persistence
	mediaStore      *media.Store                  // für WatchMediaSync (nil = kein Media-Store)
	warmer          showcontrol.AssetWarmer        // RAM-Cache-Preloader (nil = deaktiviert)
	silenceDetector showcontrol.SilenceDetector    // Auto-Skip-Silence (nil = deaktiviert)
	busRouter       BusRouterUpdater               // Bus-Routing (nil = deaktiviert)
	talkback        TalkbackDucker                 // Talkback-Ducking bei GO (nil = deaktiviert)
	dedup           *commandDedup

	mu      sync.RWMutex
	stores  map[string]*showcontrol.Store  // sessionID → Store
	engines map[string]*showcontrol.Engine // sessionID → Engine
}

func NewShowControlHandler(mgr *session.Manager, disp *node.Dispatcher, persist *showcontrol.Persistence, ms *media.Store) *ShowControlHandler {
	return &ShowControlHandler{
		sessionMgr:  mgr,
		dispatcher:  disp,
		persistence: persist,
		mediaStore:  ms,
		dedup:       newCommandDedup(),
		stores:      make(map[string]*showcontrol.Store),
		engines:     make(map[string]*showcontrol.Engine),
	}
}

// SetWarmer setzt den Asset-Warmer für alle Engines dieser Handler-Instanz.
func (h *ShowControlHandler) SetWarmer(w showcontrol.AssetWarmer) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.warmer = w
	for _, e := range h.engines {
		e.SetWarmer(w)
	}
}

// SetSilenceDetector verbindet den Stille-Detektor für alle Engines.
// Sobald gesetzt, nutzt jede Engine das erkannte Stille-Offset sofern
// kein manuelles StartTimeMs in der Cue gesetzt ist.
func (h *ShowControlHandler) SetSilenceDetector(d showcontrol.SilenceDetector) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.silenceDetector = d
	for _, e := range h.engines {
		e.SetSilenceDetector(d)
	}
}

// SetBusRouter verbindet den Bus-Router — wird bei PatchConfig-Änderungen informiert.
func (h *ShowControlHandler) SetBusRouter(r BusRouterUpdater) {
	h.mu.Lock()
	h.busRouter = r
	h.mu.Unlock()
}

// SetTalkbackRelay verbindet den Talkback-Relay für GO-Ducking.
func (h *ShowControlHandler) SetTalkbackRelay(t TalkbackDucker) {
	h.mu.Lock()
	h.talkback = t
	h.mu.Unlock()
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
	if h.warmer != nil {
		engine.SetWarmer(h.warmer)
	}
	if h.silenceDetector != nil {
		engine.SetSilenceDetector(h.silenceDetector)
	}
	h.engines[sessionID] = engine
	h.persistence.Load(sessionID, store)

	// RAM-Cache für die ersten Audio-Cues der geladenen Show vorwärmen,
	// damit der erste GO ohne Dekodierungslatenz sofort startet.
	if h.warmer != nil {
		go h.prewarmSession(sessionID, store, engine)
	}
	return store
}

// prewarmSession wärmt den Server-RAM-Cache für alle Audio-Assets vor
// UND sendet PRELOAD-Commands an alle Audio-Nodes (PCM-Dekodierung vorab).
func (h *ShowControlHandler) prewarmSession(sessionID string, store *showcontrol.Store, engine *showcontrol.Engine) {
	list, ok := store.GetCueList("main")
	if !ok || list == nil || len(list.Cues) == 0 {
		return
	}

	// Server-RAM-Cache: alle Asset-IDs vorladen
	if h.warmer != nil {
		ids := engine.LookAheadFromStart(list, len(list.Cues))
		if len(ids) > 0 {
			log.Printf("[showcontrol] prewarm RAM-Cache session=%s: %d assets", sessionID, len(ids))
			go h.warmer.WarmAssets(context.Background(), ids)
		}
	}

	// PRELOAD an alle Audio-Nodes: PCM vorab dekodieren
	log.Printf("[showcontrol] prewarm ArmAll session=%s", sessionID)
	go engine.ArmAll(context.Background())
}

func (h *ShowControlHandler) getEngine(sessionID string) (*showcontrol.Engine, bool) {
	h.mu.RLock()
	defer h.mu.RUnlock()
	e, ok := h.engines[sessionID]
	return e, ok
}

// StopCueTracker implementiert CueTrackStopper: bricht den Audio-Tracker einer
// einzelnen Cue ab und broadcastet CUE_DONE. Wird vom NodeHandler bei AudioStop
// mit expliziter cue_id aufgerufen.
func (h *ShowControlHandler) StopCueTracker(sessionID, cueId string) {
	if engine, ok := h.getEngine(sessionID); ok {
		engine.StopCueTracker(cueId)
	}
}

// PauseCueTracker implementiert CueTrackStopper: markiert eine Cue als per-Cue-pausiert
// und broadcastet CUE_CUE_PAUSED. Wird vom NodeHandler bei AudioPause mit cue_id aufgerufen.
func (h *ShowControlHandler) PauseCueTracker(sessionID, cueId string, fadeOutMs float64) {
	if engine, ok := h.getEngine(sessionID); ok {
		engine.PauseCueTracker(cueId, fadeOutMs)
	}
}

func (h *ShowControlHandler) ResumeCueTracker(sessionID, cueId string, fadeInMs float64) {
	if engine, ok := h.getEngine(sessionID); ok {
		engine.ResumeCueTracker(cueId, fadeInMs)
	}
}

func (h *ShowControlHandler) auth(sessionID, token string) error {
	_, _, err := h.sessionMgr.ValidateToken(sessionID, token)
	if err != nil {
		return status.Error(codes.Unauthenticated, err.Error())
	}
	return nil
}

// authWrite prüft Authentifizierung UND dass die Node MASTER- oder EDITOR-Rechte hat.
func (h *ShowControlHandler) authWrite(sessionID, token string) error {
	sess, nodeID, err := h.sessionMgr.ValidateToken(sessionID, token)
	if err != nil {
		return status.Error(codes.Unauthenticated, err.Error())
	}
	node, ok := sess.GetNode(nodeID)
	if !ok {
		return status.Error(codes.Unauthenticated, "node not found in session")
	}
	for _, t := range node.Info.Tasks {
		if t == pb.NodeTask_NODE_TASK_MASTER || t == pb.NodeTask_NODE_TASK_EDITOR {
			return nil
		}
	}
	return status.Error(codes.PermissionDenied, "only MASTER or EDITOR nodes may send transport commands")
}

// ── CueList RPCs ──────────────────────────────────────────────────────────────

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
	if err := h.authWrite(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store := h.getOrCreateStore(req.SessionId)
	updated := store.ReplaceCueList(req.CueList)
	h.persistence.Save(req.SessionId, store)
	return &pb.CueListResponse{CueList: updated}, nil
}

func (h *ShowControlHandler) UpsertCue(ctx context.Context, req *pb.UpsertCueRequest) (*pb.CueResponse, error) {
	if err := h.authWrite(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store := h.getOrCreateStore(req.SessionId)
	cue, ok := store.UpsertCue(req.CueListId, req.Cue)
	if !ok {
		return nil, status.Error(codes.NotFound, "cue list not found")
	}
	h.persistence.Save(req.SessionId, store)
	if engine, ok := h.getEngine(req.SessionId); ok {
		go engine.ArmCue(ctx, cue)
		// Lautstärke sofort auf laufende Cue anwenden (kein Preload-Interrupt).
		// Wenn die Cue nicht spielt, ignoriert der Node den Befehl still.
		if audio, ok2 := cue.Params.(*pb.Cue_Audio); ok2 {
			go engine.LiveUpdateVolume(cue.CueId, cue.TargetNodeId, float64(audio.Audio.VolumeDb))
		}
	}
	return &pb.CueResponse{Cue: cue}, nil
}

func (h *ShowControlHandler) DeleteCue(ctx context.Context, req *pb.DeleteCueRequest) (*emptypb.Empty, error) {
	if err := h.authWrite(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store := h.getOrCreateStore(req.SessionId)
	if !store.DeleteCue(req.CueListId, req.CueId) {
		return nil, status.Error(codes.NotFound, "cue not found")
	}
	h.persistence.Save(req.SessionId, store)
	return &emptypb.Empty{}, nil
}

// ── Transport RPCs ────────────────────────────────────────────────────────────

func (h *ShowControlHandler) Go(ctx context.Context, req *pb.GoRequest) (*pb.GoResponse, error) {
	if err := h.authWrite(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	if h.dedup.checkAndMark(req.CommandId) {
		return &pb.GoResponse{}, nil
	}
	h.getOrCreateStore(req.SessionId)
	engine, ok := h.getEngine(req.SessionId)
	if !ok {
		return nil, status.Error(codes.Internal, "show engine not initialized")
	}

	cueDesc := req.CueId
	if cueDesc == "" {
		cueDesc = "(next)"
	}
	log.Printf("[showcontrol] GO session=%s cue=%s cmd=%s", req.SessionId, cueDesc, req.CommandId)

	// Talkback-Ducking beim GO-Trigger (falls aktive Talker vorhanden)
	h.mu.RLock()
	tb := h.talkback
	h.mu.RUnlock()
	if tb != nil && tb.HasActiveTalkers() {
		tb.DuckOnGo(req.SessionId, -12.0, 2000)
	}

	executing, next, err := engine.Go(ctx, req.CueId)
	if err != nil {
		if err == showcontrol.ErrNoCue {
			log.Printf("[showcontrol] GO → keine Cue vorhanden (session=%s)", req.SessionId)
			return nil, status.Error(codes.NotFound, "no cue to execute")
		}
		return nil, status.Errorf(codes.Internal, "%v", err)
	}

	nextDesc := "(Ende)"
	if next != nil {
		nextDesc = next.Number + " \"" + next.Label + "\""
	}
	log.Printf("[showcontrol] GO OK → exec=%s/%q next=%s",
		executing.Number, executing.Label, nextDesc)
	return &pb.GoResponse{ExecutingCue: executing, NextCue: next}, nil
}

func (h *ShowControlHandler) Stop(ctx context.Context, req *pb.StopRequest) (*emptypb.Empty, error) {
	if err := h.authWrite(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	if h.dedup.checkAndMark(req.CommandId) {
		return &emptypb.Empty{}, nil
	}
	log.Printf("[showcontrol] STOP session=%s", req.SessionId)
	if engine, ok := h.getEngine(req.SessionId); ok {
		_ = engine.Stop(ctx)
	}
	return &emptypb.Empty{}, nil
}

func (h *ShowControlHandler) Pause(ctx context.Context, req *pb.PauseRequest) (*emptypb.Empty, error) {
	if err := h.authWrite(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	if h.dedup.checkAndMark(req.CommandId) {
		return &emptypb.Empty{}, nil
	}
	log.Printf("[showcontrol] PAUSE session=%s", req.SessionId)
	if engine, ok := h.getEngine(req.SessionId); ok {
		_ = engine.Pause(ctx)
	}
	return &emptypb.Empty{}, nil
}

func (h *ShowControlHandler) Resume(ctx context.Context, req *pb.ResumeRequest) (*emptypb.Empty, error) {
	if err := h.authWrite(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	if h.dedup.checkAndMark(req.CommandId) {
		return &emptypb.Empty{}, nil
	}
	log.Printf("[showcontrol] RESUME session=%s", req.SessionId)
	if engine, ok := h.getEngine(req.SessionId); ok {
		_ = engine.Resume(ctx)
	}
	return &emptypb.Empty{}, nil
}

// ── PatchConfig RPC ───────────────────────────────────────────────────────────

func (h *ShowControlHandler) UpdatePatchConfig(ctx context.Context, req *pb.UpdatePatchConfigRequest) (*pb.PatchConfigResponse, error) {
	if err := h.authWrite(req.SessionId, req.Token); err != nil {
		return nil, err
	}
	store := h.getOrCreateStore(req.SessionId)
	store.SetPatchConfig(req.PatchConfig)
	h.persistence.Save(req.SessionId, store)

	// BusRouter über neue PatchConfig informieren
	h.mu.RLock()
	busRouter := h.busRouter
	h.mu.RUnlock()
	if busRouter != nil {
		busRouter.Update(req.PatchConfig)
	}

	return &pb.PatchConfigResponse{PatchConfig: store.GetPatchConfig()}, nil
}

// ── Stream 1: WatchShowDefinition ─────────────────────────────────────────────

func (h *ShowControlHandler) WatchShowDefinition(req *pb.WatchShowDefinitionRequest, stream pb.ShowControlService_WatchShowDefinitionServer) error {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return err
	}
	store := h.getOrCreateStore(req.SessionId)

	// Erst abonnieren, dann Snapshot senden → kein Event geht verloren.
	ch := store.SubscribeDef()
	defer store.UnsubscribeDef(ch)

	// Snapshot: CueList + PatchConfig senden.
	snap := &pb.ShowDefinitionEvent{
		Type:        pb.ShowDefinitionEvent_DEFINITION_SNAPSHOT,
		PatchConfig: store.GetPatchConfig(),
		OccurredAt:  nowProto(),
		Seq:         store.CurrentDefSeq(),
	}
	if cl, ok := store.GetCueList(""); ok {
		snap.CueList = cl
	}
	if err := stream.Send(snap); err != nil {
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

// ── Stream 2: WatchShowExecution ──────────────────────────────────────────────

func (h *ShowControlHandler) WatchShowExecution(req *pb.WatchShowExecutionRequest, stream pb.ShowControlService_WatchShowExecutionServer) error {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return err
	}
	store := h.getOrCreateStore(req.SessionId)
	engine, _ := h.getEngine(req.SessionId)

	ch := store.SubscribeExec()
	defer store.UnsubscribeExec(ch)

	// Snapshot: aktuelle Transport-State senden.
	for _, ev := range h.executionSnapshot(store, engine, req.NodeId) {
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
			ev.NodeId = req.NodeId
			if err := stream.Send(ev); err != nil {
				return err
			}
		}
	}
}

// executionSnapshot erstellt den Transport-Snapshot für neu verbundene Watcher.
func (h *ShowControlHandler) executionSnapshot(store *showcontrol.Store, engine *showcontrol.Engine, nodeID string) []*pb.ShowExecutionEvent {
	seq := store.CurrentExecSeq()
	out := make([]*pb.ShowExecutionEvent, 0, 2)

	if engine == nil {
		out = append(out, &pb.ShowExecutionEvent{
			Type:       pb.ShowExecutionEvent_EXECUTION_SNAPSHOT,
			NodeId:     nodeID,
			OccurredAt: nowProto(),
			Seq:        seq,
		})
		return out
	}

	ts := engine.TransportSnapshot()
	if ts.Running && ts.ActiveCue != nil {
		out = append(out, &pb.ShowExecutionEvent{
			Type:           pb.ShowExecutionEvent_EXECUTION_SNAPSHOT,
			AffectedCue:    ts.ActiveCue,
			NodeId:         nodeID,
			OccurredAt:     &pb.Timestamp{UnixMillis: ts.CueStartedAtMs},
			CueStartedAtMs: ts.CueStartedAtMs,
			IsPaused:       ts.Paused,
			Seq:            seq,
		})
		if ts.Paused {
			out = append(out, &pb.ShowExecutionEvent{
				Type:        pb.ShowExecutionEvent_CUE_PAUSED,
				AffectedCue: ts.ActiveCue,
				NodeId:      nodeID,
				OccurredAt:  &pb.Timestamp{UnixMillis: ts.PausedAtMs},
				IsPaused:    true,
				Seq:         seq,
			})
		}
	} else {
		out = append(out, &pb.ShowExecutionEvent{
			Type:       pb.ShowExecutionEvent_EXECUTION_SNAPSHOT,
			NodeId:     nodeID,
			OccurredAt: nowProto(),
			Seq:        seq,
		})
	}
	return out
}

// ── Stream 3: WatchNodeHealth ─────────────────────────────────────────────────

func (h *ShowControlHandler) WatchNodeHealth(req *pb.WatchNodeHealthRequest, stream pb.ShowControlService_WatchNodeHealthServer) error {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return err
	}

	// Erst abonnieren, dann Snapshot → kein Event geht verloren.
	eventCh, sess, err := h.sessionMgr.WatchSession(stream.Context(), req.SessionId)
	if err != nil {
		return status.Errorf(codes.NotFound, "%v", err)
	}

	// Snapshot: einen Event pro bekanntem Node senden (inkl. Capabilities).
	nodes := sess.AllNodes()
	for _, n := range nodes {
		if err := stream.Send(&pb.NodeHealthEvent{
			Type:         pb.NodeHealthEvent_HEALTH_SNAPSHOT,
			Node:         n.Info,
			Capabilities: n.Capabilities,
			OccurredAt:   nowProto(),
		}); err != nil {
			return err
		}
	}
	// Leerer Snapshot wenn keine Nodes → Client weiß dass Stream läuft.
	if len(nodes) == 0 {
		if err := stream.Send(&pb.NodeHealthEvent{
			Type:       pb.NodeHealthEvent_HEALTH_SNAPSHOT,
			OccurredAt: nowProto(),
		}); err != nil {
			return err
		}
	}

	for ev := range eventCh {
		var evType pb.NodeHealthEvent_HealthEventType
		switch ev.Type {
		case pb.SessionEvent_TYPE_NODE_JOINED:
			evType = pb.NodeHealthEvent_NODE_ONLINE
		case pb.SessionEvent_TYPE_NODE_LEFT, pb.SessionEvent_TYPE_NODE_OFFLINE:
			evType = pb.NodeHealthEvent_NODE_OFFLINE
		default:
			continue
		}
		// Capabilities beim NODE_ONLINE-Event aus dem Session-Store holen.
		var caps *pb.NodeCapabilities
		if ev.AffectedNode != nil {
			if n, ok := sess.GetNode(ev.AffectedNode.NodeId); ok {
				caps = n.Capabilities
			}
		}
		if err := stream.Send(&pb.NodeHealthEvent{
			Type:         evType,
			Node:         ev.AffectedNode,
			Capabilities: caps,
			OccurredAt:   ev.OccurredAt,
		}); err != nil {
			return err
		}
	}
	return nil
}

// ── Stream 4: WatchMediaSync ──────────────────────────────────────────────────

func (h *ShowControlHandler) WatchMediaSync(req *pb.WatchMediaSyncRequest, stream pb.ShowControlService_WatchMediaSyncServer) error {
	if err := h.auth(req.SessionId, req.Token); err != nil {
		return err
	}

	// Ohne Media-Store: leerer Snapshot, Stream bleibt offen.
	if h.mediaStore == nil {
		if err := stream.Send(&pb.MediaSyncEvent{
			Type:       pb.MediaSyncEvent_MEDIA_SNAPSHOT,
			OccurredAt: nowProto(),
		}); err != nil {
			return err
		}
		<-stream.Context().Done()
		return nil
	}

	// Erst abonnieren, dann Snapshot → kein Upload geht verloren.
	changeCh, unsub := h.mediaStore.Subscribe()
	defer unsub()

	if err := h.sendMediaSnapshot(stream); err != nil {
		return err
	}

	for {
		select {
		case <-stream.Context().Done():
			return nil
		case _, ok := <-changeCh:
			if !ok {
				return nil
			}
			// Neu-Snapshot bei jeder Änderung: diff-freies, einfaches Protokoll.
			// Clients übernehmen das Manifest komplett (kein partieller Merge nötig).
			if err := h.sendMediaSnapshot(stream); err != nil {
				return err
			}
		}
	}
}

func (h *ShowControlHandler) sendMediaSnapshot(stream pb.ShowControlService_WatchMediaSyncServer) error {
	files, err := h.mediaStore.List()
	if err != nil {
		return status.Errorf(codes.Internal, "media list: %v", err)
	}
	for _, f := range files {
		if err := stream.Send(&pb.MediaSyncEvent{
			Type:      pb.MediaSyncEvent_MEDIA_SNAPSHOT,
			AssetId:   f.SHA256,
			AssetName: f.Name,
			Sha256:    f.SHA256,
			SizeBytes: f.SizeBytes,
			OccurredAt: nowProto(),
		}); err != nil {
			return err
		}
	}
	// Leerer SNAPSHOT wenn keine Dateien → Client weiß dass Stream läuft.
	if len(files) == 0 {
		if err := stream.Send(&pb.MediaSyncEvent{
			Type:       pb.MediaSyncEvent_MEDIA_SNAPSHOT,
			OccurredAt: nowProto(),
		}); err != nil {
			return err
		}
	}
	return nil
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func nowProto() *pb.Timestamp {
	return &pb.Timestamp{UnixMillis: time.Now().UnixMilli()}
}
