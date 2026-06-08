package showcontrol

import (
	"context"
	"sync"
	"testing"
	"time"

	pb "stagesync-server/gen/go/stagesync/v1"
)

// ── Test-Dispatcher ───────────────────────────────────────────────────────────

type recordingDispatcher struct {
	mu       sync.Mutex
	commands []*pb.NodeCommandRequest
}

func (d *recordingDispatcher) Dispatch(_ context.Context, _ string, cmd *pb.NodeCommandRequest) error {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.commands = append(d.commands, cmd)
	return nil
}

func (d *recordingDispatcher) DispatchToTask(_ context.Context, _ pb.NodeTask, cmd *pb.NodeCommandRequest) error {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.commands = append(d.commands, cmd)
	return nil
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func makeStore(cues ...*pb.Cue) *Store {
	s := NewStore()
	for _, c := range cues {
		s.UpsertCue("main", c)
	}
	return s
}

func waitCue(id, number string, durationMs float64) *pb.Cue {
	return &pb.Cue{
		CueId:    id,
		Number:   number,
		Label:    id,
		CueType:  pb.CueType_CUE_TYPE_WAIT,
		Params:   &pb.Cue_Wait{Wait: &pb.WaitCueParams{DurationMs: durationMs}},
	}
}

func groupCue(id string, sequential bool, childIDs ...string) *pb.Cue {
	return &pb.Cue{
		CueId:   id,
		Number:  id,
		Label:   id,
		CueType: pb.CueType_CUE_TYPE_GROUP,
		Params: &pb.Cue_Group{Group: &pb.GroupCueParams{
			ChildCueIds: childIDs,
			Sequential:  sequential,
		}},
	}
}

// ── runningCueIDs helper tests ────────────────────────────────────────────────

func TestEngine_RunningCueIDsTracking(t *testing.T) {
	e := &Engine{runningCueIDs: make(map[string]struct{})}
	e.addRunning("a", "b")
	if len(e.runningCueIDs) != 2 {
		t.Fatalf("expected 2 running IDs, got %d", len(e.runningCueIDs))
	}
	e.removeRunning("a")
	if len(e.runningCueIDs) != 1 {
		t.Fatalf("expected 1 running ID after remove, got %d", len(e.runningCueIDs))
	}
	ids := e.runningCueIDsList()
	if ids[0] != "b" {
		t.Errorf("expected 'b', got %q", ids[0])
	}
}

func TestEngine_RunningCueIDsNilSafe(t *testing.T) {
	e := &Engine{} // no map initialised
	e.addRunning("x")
	if len(e.runningCueIDs) != 1 {
		t.Fatal("addRunning should initialise map if nil")
	}
}

// ── Group sequential ──────────────────────────────────────────────────────────

func TestEngine_GroupSequential_RunsInOrder(t *testing.T) {
	child1 := waitCue("c1", "1", 10)
	child2 := waitCue("c2", "2", 10)
	group  := groupCue("g1", true, "c1", "c2")

	store := makeStore(child1, child2, group)
	disp  := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)

	events := store.SubscribeExec()
	defer store.UnsubscribeExec(events)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := engine.dispatchGroupSequential(ctx, []*pb.Cue{child1, child2}); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// Collect: 2×START + 2×DONE
	var collected []*pb.ShowExecutionEvent
	for {
		select {
		case ev := <-events:
			collected = append(collected, ev)
			if len(collected) == 4 {
				goto done
			}
		case <-time.After(time.Second):
			t.Fatalf("timeout collecting events, got %d", len(collected))
		}
	}
done:
	if collected[0].Type != pb.ShowExecutionEvent_CUE_STARTED {
		t.Errorf("expected first event CUE_STARTED, got %v", collected[0].Type)
	}
	if collected[0].AffectedCue.CueId != "c1" {
		t.Errorf("expected c1 first, got %s", collected[0].AffectedCue.CueId)
	}
	if collected[2].AffectedCue.CueId != "c2" {
		t.Errorf("expected c2 second start, got %s", collected[2].AffectedCue.CueId)
	}
}

// ── Group parallel ────────────────────────────────────────────────────────────

func TestEngine_GroupParallel_BroadcastsRunningIDs(t *testing.T) {
	child1 := waitCue("p1", "1", 20)
	child2 := waitCue("p2", "2", 20)

	store  := makeStore(child1, child2)
	disp   := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)
	engine.runningCueIDs = make(map[string]struct{})

	events := store.SubscribeExec()
	defer store.UnsubscribeExec(events)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := engine.dispatchGroupParallel(ctx, []*pb.Cue{child1, child2}); err != nil && err != ctx.Err() {
		t.Fatalf("unexpected error: %v", err)
	}

	// Collect all events (2×START + 2×DONE = 4 minimum)
	var collected []*pb.ShowExecutionEvent
	collecting:
	for {
		select {
		case ev := <-events:
			collected = append(collected, ev)
			if len(collected) >= 4 {
				break collecting
			}
		case <-time.After(2 * time.Second):
			break collecting
		}
	}

	if len(collected) < 4 {
		t.Fatalf("expected at least 4 events, got %d", len(collected))
	}

	var foundRunning bool
	for _, ev := range collected {
		if ev.Type == pb.ShowExecutionEvent_CUE_STARTED && len(ev.RunningCueIds) > 0 {
			foundRunning = true
			break
		}
	}
	if !foundRunning {
		t.Error("no START event had RunningCueIds populated")
	}
}

// ── Group with unknown child IDs ──────────────────────────────────────────────

func TestEngine_GroupSequential_SkipsUnknownChildren(t *testing.T) {
	child := waitCue("known", "1", 5)
	store := makeStore(child)
	disp  := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)

	ctx := context.Background()
	// "unknown" child ID is not in the store → should not panic, just skip
	err := engine.dispatchGroup(ctx, groupCue("g", true, "known", "does-not-exist"))
	if err != nil {
		t.Errorf("unexpected error for unknown child: %v", err)
	}
}

// ── lookAheadAssetIDs ─────────────────────────────────────────────────────────

func audioCue(id, assetID string) *pb.Cue {
	return &pb.Cue{
		CueId:   id,
		Number:  id,
		Label:   id,
		CueType: pb.CueType_CUE_TYPE_AUDIO,
		Params:  &pb.Cue_Audio{Audio: &pb.AudioCueParams{AssetId: assetID}},
	}
}

func TestEngine_LookAheadAssetIDs_Basic(t *testing.T) {
	store := makeStore(
		audioCue("c1", "sha1"),
		audioCue("c2", "sha2"),
		audioCue("c3", "sha3"),
		audioCue("c4", "sha4"),
	)
	engine := NewEngine("sess", "main", store, nil)
	list, _ := store.GetCueList("main")

	ids := engine.lookAheadAssetIDs(list, "c1", 2)
	if len(ids) != 2 {
		t.Fatalf("expected 2 ids, got %d: %v", len(ids), ids)
	}
	if ids[0] != "sha2" || ids[1] != "sha3" {
		t.Errorf("unexpected ids: %v", ids)
	}
}

func TestEngine_LookAheadAssetIDs_SkipsNonAudio(t *testing.T) {
	store := makeStore(
		audioCue("c1", "sha1"),
		waitCue("w1", "1.5", 100),
		audioCue("c2", "sha2"),
	)
	engine := NewEngine("sess", "main", store, nil)
	list, _ := store.GetCueList("main")

	ids := engine.lookAheadAssetIDs(list, "c1", 5)
	if len(ids) != 1 || ids[0] != "sha2" {
		t.Errorf("expected [sha2], got %v", ids)
	}
}

func TestEngine_LookAheadAssetIDs_NilList(t *testing.T) {
	engine := NewEngine("sess", "main", NewStore(), nil)
	ids := engine.lookAheadAssetIDs(nil, "", 5)
	if len(ids) != 0 {
		t.Errorf("expected empty slice for nil list, got %v", ids)
	}
}

func TestEngine_LookAheadAssetIDs_GroupExpanded(t *testing.T) {
	store := makeStore(
		audioCue("c1", "sha1"),
		groupCue("g1", false, "c2", "c3"),
		audioCue("c2", "sha2"),
		audioCue("c3", "sha3"),
	)
	engine := NewEngine("sess", "main", store, nil)
	list, _ := store.GetCueList("main")

	ids := engine.lookAheadAssetIDs(list, "c1", 5)
	if len(ids) != 2 {
		t.Fatalf("expected 2 ids from group, got %d: %v", len(ids), ids)
	}
	if ids[0] != "sha2" || ids[1] != "sha3" {
		t.Errorf("unexpected ids: %v", ids)
	}
}

func TestEngine_LookAheadAssetIDs_RespectsLimit(t *testing.T) {
	store := makeStore(
		audioCue("c1", "sha1"),
		audioCue("c2", "sha2"),
		audioCue("c3", "sha3"),
		audioCue("c4", "sha4"),
		audioCue("c5", "sha5"),
		audioCue("c6", "sha6"),
	)
	engine := NewEngine("sess", "main", store, nil)
	list, _ := store.GetCueList("main")

	ids := engine.lookAheadAssetIDs(list, "c1", 3)
	if len(ids) != 3 {
		t.Fatalf("expected exactly 3 ids, got %d: %v", len(ids), ids)
	}
}

// ── AssetWarmer Integration ───────────────────────────────────────────────────

type recordingWarmer struct {
	mu       sync.Mutex
	locked   bool
	unlocked bool
	warmed   []string
}

func (w *recordingWarmer) WarmAssets(_ context.Context, ids []string) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.warmed = append(w.warmed, ids...)
}
func (w *recordingWarmer) LockForShow() {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.locked = true
}
func (w *recordingWarmer) UnlockShow() {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.unlocked = true
}
func (w *recordingWarmer) isLocked() bool {
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.locked
}
func (w *recordingWarmer) isUnlocked() bool {
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.unlocked
}
func (w *recordingWarmer) warmedCount() int {
	w.mu.Lock()
	defer w.mu.Unlock()
	return len(w.warmed)
}

func TestEngine_Go_WarmerCalled(t *testing.T) {
	store := makeStore(
		audioCue("c1", "sha1"),
		audioCue("c2", "sha2"),
		audioCue("c3", "sha3"),
	)
	disp   := &recordingDispatcher{}
	warmer := &recordingWarmer{}
	engine := NewEngine("sess", "main", store, disp)
	engine.SetWarmer(warmer)

	ctx := context.Background()
	_, _, err := engine.Go(ctx, "c1")
	if err != nil {
		t.Fatalf("Go: %v", err)
	}
	// Kurz warten, damit die WarmAssets-Goroutine starten kann.
	time.Sleep(10 * time.Millisecond)

	if !warmer.isLocked() {
		t.Error("LockForShow sollte beim ersten GO aufgerufen werden")
	}
	if warmer.warmedCount() == 0 {
		t.Error("WarmAssets sollte mit mindestens einer asset_id aufgerufen werden")
	}
}

func TestEngine_Stop_UnlocksCalled(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	disp   := &recordingDispatcher{}
	warmer := &recordingWarmer{}
	engine := NewEngine("sess", "main", store, disp)
	engine.SetWarmer(warmer)

	ctx := context.Background()
	_, _, _ = engine.Go(ctx, "c1")
	_ = engine.Stop(ctx)

	if !warmer.isUnlocked() {
		t.Error("UnlockShow sollte bei Stop aufgerufen werden")
	}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

type mockSilenceDetector struct{ ms int64 }

func (d *mockSilenceDetector) AssetSilenceStartMs(_ string) (int64, bool) { return d.ms, true }

// collectExecEvents sammelt bis zu count Events aus ch innerhalb von timeout.
func collectExecEvents(ch chan *pb.ShowExecutionEvent, count int, timeout time.Duration) []*pb.ShowExecutionEvent {
	var out []*pb.ShowExecutionEvent
	deadline := time.After(timeout)
	for len(out) < count {
		select {
		case ev := <-ch:
			out = append(out, ev)
		case <-deadline:
			return out
		}
	}
	return out
}

// nextExecEvent blockiert bis zum nächsten Event oder Timeout.
func nextExecEvent(t *testing.T, ch chan *pb.ShowExecutionEvent, timeout time.Duration) *pb.ShowExecutionEvent {
	t.Helper()
	select {
	case ev := <-ch:
		return ev
	case <-time.After(timeout):
		t.Fatal("timeout: kein Event erhalten")
		return nil
	}
}

func audioTrackedCue(id, assetID string, durationMs float64) *pb.Cue {
	return &pb.Cue{
		CueId:   id,
		Number:  id,
		Label:   id,
		CueType: pb.CueType_CUE_TYPE_AUDIO,
		Params: &pb.Cue_Audio{Audio: &pb.AudioCueParams{
			AssetId:             assetID,
			DeclaredDurationMs:  durationMs,
		}},
	}
}

// ── Go ────────────────────────────────────────────────────────────────────────

func TestEngine_Go_ReturnsCueAndSetsRunning(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"), audioCue("c2", "sha2"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	cue, next, err := engine.Go(context.Background(), "c1")
	if err != nil {
		t.Fatalf("Go: %v", err)
	}
	if cue == nil || cue.CueId != "c1" {
		t.Errorf("expected cue c1, got %v", cue)
	}
	if next == nil || next.CueId != "c2" {
		t.Errorf("expected next c2, got %v", next)
	}

	engine.mu.Lock()
	phase := engine.tp.phase
	engine.mu.Unlock()

	if phase != phaseRunning {
		t.Errorf("phase sollte nach Go phaseRunning sein, got %v", phase)
	}
}

func TestEngine_Go_ErrNoCue_EmptyStore(t *testing.T) {
	store := NewStore()
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, err := engine.Go(context.Background(), "")
	if err != ErrNoCue {
		t.Errorf("expected ErrNoCue, got %v", err)
	}
}

func TestEngine_Go_SpecificCueID(t *testing.T) {
	store := makeStore(audioCue("c1", "s1"), audioCue("c2", "s2"), audioCue("c3", "s3"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	cue, _, err := engine.Go(context.Background(), "c3")
	if err != nil {
		t.Fatalf("Go: %v", err)
	}
	if cue.CueId != "c3" {
		t.Errorf("expected c3, got %s", cue.CueId)
	}
}

func TestEngine_Go_ErrNoCue_UnknownID(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, err := engine.Go(context.Background(), "does-not-exist")
	if err != ErrNoCue {
		t.Errorf("expected ErrNoCue, got %v", err)
	}
}

// ── Pause ─────────────────────────────────────────────────────────────────────

func TestEngine_Pause_SetsPausedState(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, _ = engine.Go(context.Background(), "c1")

	if err := engine.Pause(context.Background()); err != nil {
		t.Fatalf("Pause: %v", err)
	}

	engine.mu.Lock()
	phase := engine.tp.phase
	engine.mu.Unlock()

	if phase != phasePaused {
		t.Errorf("phase sollte nach Pause phasePaused sein, got %v", phase)
	}
}

func TestEngine_Pause_Idempotent(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, _ = engine.Go(context.Background(), "c1")
	_ = engine.Pause(context.Background())

	// zweiter Aufruf darf kein Fehler sein und ändert nichts
	if err := engine.Pause(context.Background()); err != nil {
		t.Fatalf("zweites Pause: %v", err)
	}
	engine.mu.Lock()
	phase := engine.tp.phase
	engine.mu.Unlock()
	if phase != phasePaused {
		t.Errorf("phase sollte nach zweitem Pause immer noch phasePaused sein, got %v", phase)
	}
}

func TestEngine_Pause_WhenNotRunning_IsNoOp(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	// Pause ohne vorheriges Go → kein Fehler, kein State-Wechsel
	if err := engine.Pause(context.Background()); err != nil {
		t.Fatalf("Pause auf idle Engine: %v", err)
	}
	engine.mu.Lock()
	phase := engine.tp.phase
	engine.mu.Unlock()
	if phase != phaseIdle {
		t.Errorf("phase sollte auf idle Engine phaseIdle bleiben, got %v", phase)
	}
}

func TestEngine_Pause_BroadcastsCuePaused(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})
	events := store.SubscribeExec()
	defer store.UnsubscribeExec(events)

	_, _, _ = engine.Go(context.Background(), "c1")
	// CUE_STARTED aus Go() konsumieren (async, kurz warten)
	time.Sleep(20 * time.Millisecond)
	for len(events) > 0 {
		<-events
	}

	_ = engine.Pause(context.Background())

	ev := nextExecEvent(t, events, time.Second)
	if ev.Type != pb.ShowExecutionEvent_CUE_PAUSED {
		t.Errorf("expected CUE_PAUSED, got %v", ev.Type)
	}
}

func TestEngine_Pause_RecordsPausedElapsed(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, _ = engine.Go(context.Background(), "c1")
	// cueStartedAt wird in der dispatchCue-Goroutine gesetzt; kurz warten.
	time.Sleep(20 * time.Millisecond)

	_ = engine.Pause(context.Background())

	engine.mu.Lock()
	frozen := engine.tp.frozenElapsed
	phase := engine.tp.phase
	engine.mu.Unlock()

	if phase != phasePaused {
		t.Errorf("phase sollte nach Pause phasePaused sein, got %v", phase)
	}
	// frozenElapsed ≥ pauseFadeMs (120ms wird immer addiert)
	if frozen < time.Duration(pauseFadeMs)*time.Millisecond {
		t.Errorf("frozenElapsed=%v, erwartet ≥ %dms", frozen, pauseFadeMs)
	}
}

// ── Resume ────────────────────────────────────────────────────────────────────

func TestEngine_Resume_ClearsPausedState(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, _ = engine.Go(context.Background(), "c1")
	_ = engine.Pause(context.Background())

	if err := engine.Resume(context.Background()); err != nil {
		t.Fatalf("Resume: %v", err)
	}

	engine.mu.Lock()
	phase := engine.tp.phase
	engine.mu.Unlock()

	if phase != phaseRunning {
		t.Errorf("phase sollte nach Resume phaseRunning sein, got %v", phase)
	}
}

func TestEngine_Resume_WhenNotPaused_IsNoOp(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	if err := engine.Resume(context.Background()); err != nil {
		t.Fatalf("Resume auf idle Engine: %v", err)
	}
}

func TestEngine_Resume_AdjustsCueStartedAt(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, _ = engine.Go(context.Background(), "c1")
	time.Sleep(30 * time.Millisecond) // dispatchCue-Goroutine läuft
	_ = engine.Pause(context.Background())

	engine.mu.Lock()
	frozenBeforeResume := engine.tp.frozenElapsed
	engine.mu.Unlock()

	resumeTime := time.Now()
	_ = engine.Resume(context.Background())

	engine.mu.Lock()
	newStart := engine.tp.startedAt
	engine.mu.Unlock()

	// newStart = now - frozenElapsed → muss vor resumeTime liegen
	expectedStart := resumeTime.Add(-frozenBeforeResume)
	diff := newStart.Sub(expectedStart)
	if diff < -20*time.Millisecond || diff > 20*time.Millisecond {
		t.Errorf("cueStartedAt abweichung: %v (erwartet ~%v)", newStart, expectedStart)
	}
}

func TestEngine_Resume_BroadcastsCueStarted(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})
	events := store.SubscribeExec()
	defer store.UnsubscribeExec(events)

	_, _, _ = engine.Go(context.Background(), "c1")
	time.Sleep(20 * time.Millisecond)
	_ = engine.Pause(context.Background())
	// Alle bisher gesendeten Events konsumieren
	for len(events) > 0 {
		<-events
	}

	_ = engine.Resume(context.Background())

	ev := nextExecEvent(t, events, time.Second)
	if ev.Type != pb.ShowExecutionEvent_CUE_STARTED {
		t.Errorf("Resume sollte CUE_STARTED senden, got %v", ev.Type)
	}
	if ev.CueStartedAtMs == 0 {
		t.Error("CueStartedAtMs sollte gesetzt sein")
	}
}

// ── Stop ──────────────────────────────────────────────────────────────────────

func TestEngine_Stop_ResetsTransportState(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, _ = engine.Go(context.Background(), "c1")
	_ = engine.Stop(context.Background())

	engine.mu.Lock()
	phase := engine.tp.phase
	engine.mu.Unlock()

	if phase != phaseIdle {
		t.Errorf("phase sollte nach Stop phaseIdle sein, got %v", phase)
	}
	if store.GetActiveCue("main") != nil {
		t.Error("activeCue sollte nach Stop nil sein")
	}
}

func TestEngine_Stop_BroadcastsCueStopped(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})
	events := store.SubscribeExec()
	defer store.UnsubscribeExec(events)

	_, _, _ = engine.Go(context.Background(), "c1")
	time.Sleep(20 * time.Millisecond)
	for len(events) > 0 {
		<-events
	}

	_ = engine.Stop(context.Background())

	ev := nextExecEvent(t, events, time.Second)
	if ev.Type != pb.ShowExecutionEvent_CUE_STOPPED {
		t.Errorf("expected CUE_STOPPED, got %v", ev.Type)
	}
}

func TestEngine_Stop_CancelsAudioTrackers(t *testing.T) {
	store := makeStore(audioTrackedCue("c1", "sha1", 5000))
	disp := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)
	engine.runningCueIDs = make(map[string]struct{})

	ctx := context.Background()

	// Tracker manuell registrieren wie dispatchAudio es tun würde
	trackCtx, trackCancel := context.WithCancel(ctx)
	entry := &audioTrackerEntry{cancel: trackCancel}
	engine.audioTrackers.Store("c1", entry)

	_, _, _ = engine.Go(ctx, "c1")
	_ = engine.Stop(ctx)

	// trackCtx muss durch Stop gecancelt worden sein
	select {
	case <-trackCtx.Done():
		// korrekt
	case <-time.After(200 * time.Millisecond):
		t.Error("Stop sollte audioTrackers canceln")
	}
	_ = trackCancel // cleanup
}

func TestEngine_Stop_SendsAudioStopCommand(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	disp := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)

	_, _, _ = engine.Go(context.Background(), "c1")
	_ = engine.Stop(context.Background())

	var found bool
	for _, cmd := range disp.commands {
		if cmd.GetAudioStop() != nil {
			found = true
			break
		}
	}
	if !found {
		t.Error("Stop sollte AudioStop-Command an Dispatcher senden")
	}
}

// ── TransportSnapshot ─────────────────────────────────────────────────────────

func TestEngine_TransportSnapshot_InitialState(t *testing.T) {
	engine := NewEngine("sess", "main", NewStore(), nil)
	snap := engine.TransportSnapshot()
	if snap.Running || snap.Paused {
		t.Errorf("frische Engine sollte running=false paused=false haben, got %+v", snap)
	}
}

func TestEngine_TransportSnapshot_AfterGo(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, _ = engine.Go(context.Background(), "c1")

	snap := engine.TransportSnapshot()
	if !snap.Running {
		t.Error("Running sollte nach Go true sein")
	}
	if snap.Paused {
		t.Error("Paused sollte nach Go false sein")
	}
}

func TestEngine_TransportSnapshot_AfterPause(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, _ = engine.Go(context.Background(), "c1")
	time.Sleep(20 * time.Millisecond)
	_ = engine.Pause(context.Background())

	snap := engine.TransportSnapshot()
	if !snap.Paused {
		t.Error("Paused sollte nach Pause true sein")
	}
	if snap.PausedAtMs == 0 {
		t.Error("PausedAtMs sollte gesetzt sein")
	}
	if snap.CueStartedAtMs == 0 {
		t.Error("CueStartedAtMs sollte bei Pause gesetzt sein")
	}
}

func TestEngine_TransportSnapshot_AfterResume(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})

	_, _, _ = engine.Go(context.Background(), "c1")
	time.Sleep(20 * time.Millisecond)
	_ = engine.Pause(context.Background())
	_ = engine.Resume(context.Background())

	snap := engine.TransportSnapshot()
	if snap.Paused {
		t.Error("Paused sollte nach Resume false sein")
	}
	if !snap.Running {
		t.Error("Running sollte nach Resume true sein")
	}
	if snap.PausedAtMs != 0 {
		t.Error("PausedAtMs sollte nach Resume 0 sein")
	}
}

// ── Per-Cue Pause Tracker ─────────────────────────────────────────────────────

func TestEngine_PauseCueTracker_AddsToPerCuePaused(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})
	events := store.SubscribeExec()
	defer store.UnsubscribeExec(events)

	engine.PauseCueTracker("c1", 0)

	engine.mu.Lock()
	_, found := engine.perCuePausedIDs["c1"]
	engine.mu.Unlock()
	if !found {
		t.Error("c1 sollte in perCuePausedIDs sein")
	}

	ev := nextExecEvent(t, events, time.Second)
	if ev.Type != pb.ShowExecutionEvent_CUE_CUE_PAUSED {
		t.Errorf("expected CUE_CUE_PAUSED, got %v", ev.Type)
	}
	if ev.AffectedCue.CueId != "c1" {
		t.Errorf("expected affected cue c1, got %s", ev.AffectedCue.CueId)
	}
}

func TestEngine_ResumeCueTracker_RemovesFromPerCuePaused(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})
	events := store.SubscribeExec()
	defer store.UnsubscribeExec(events)

	engine.PauseCueTracker("c1", 0)
	<-events // CUE_CUE_PAUSED konsumieren

	engine.ResumeCueTracker("c1", 0)

	engine.mu.Lock()
	_, found := engine.perCuePausedIDs["c1"]
	engine.mu.Unlock()
	if found {
		t.Error("c1 sollte nach ResumeCueTracker nicht mehr in perCuePausedIDs sein")
	}

	ev := nextExecEvent(t, events, time.Second)
	if ev.Type != pb.ShowExecutionEvent_CUE_CUE_RESUMED {
		t.Errorf("expected CUE_CUE_RESUMED, got %v", ev.Type)
	}
}

func TestEngine_StopCueTracker_RemovesRunningAndBroadcastsDone(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})
	events := store.SubscribeExec()
	defer store.UnsubscribeExec(events)

	engine.runningCueIDs = make(map[string]struct{})
	engine.addRunning("c1")

	engine.StopCueTracker("c1")

	engine.mu.Lock()
	_, found := engine.runningCueIDs["c1"]
	engine.mu.Unlock()
	if found {
		t.Error("c1 sollte nach StopCueTracker nicht mehr in runningCueIDs sein")
	}

	ev := nextExecEvent(t, events, time.Second)
	if ev.Type != pb.ShowExecutionEvent_CUE_DONE {
		t.Errorf("expected CUE_DONE, got %v", ev.Type)
	}
}

func TestEngine_StopCueTracker_CancelsTracker(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	engine := NewEngine("sess", "main", store, &recordingDispatcher{})
	engine.runningCueIDs = make(map[string]struct{})

	ctx, cancel := context.WithCancel(context.Background())
	entry := &audioTrackerEntry{cancel: cancel}
	engine.audioTrackers.Store("c1", entry)

	engine.StopCueTracker("c1")

	select {
	case <-ctx.Done():
		// korrekt gecancelt
	case <-time.After(100 * time.Millisecond):
		t.Error("StopCueTracker sollte den Audio-Tracker canceln")
	}
}

// ── dispatchAudio ─────────────────────────────────────────────────────────────

func TestEngine_DispatchAudio_SendsPreloadAndPlay(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"))
	disp := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)
	engine.runningCueIDs = make(map[string]struct{})
	engine.mu.Lock()
	engine.tp.startedAt = time.Now()
	engine.mu.Unlock()

	cue := audioCue("c1", "sha1")
	err := engine.dispatchAudio(context.Background(), cue)
	if err != nil {
		t.Fatalf("dispatchAudio: %v", err)
	}

	var hasPreload, hasPlay bool
	for _, cmd := range disp.commands {
		if cmd.GetAudioPreload() != nil {
			hasPreload = true
		}
		if cmd.GetAudioPlay() != nil {
			hasPlay = true
		}
	}
	if !hasPreload {
		t.Error("dispatchAudio sollte AudioPreload senden")
	}
	if !hasPlay {
		t.Error("dispatchAudio sollte AudioPlay senden")
	}
}

func TestEngine_DispatchAudio_PlayContainsCueID(t *testing.T) {
	store := makeStore()
	disp := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)
	engine.runningCueIDs = make(map[string]struct{})
	engine.mu.Lock()
	engine.tp.startedAt = time.Now()
	engine.mu.Unlock()

	cue := audioCue("cue-42", "sha1")
	_ = engine.dispatchAudio(context.Background(), cue)

	for _, cmd := range disp.commands {
		if p := cmd.GetAudioPlay(); p != nil {
			if p.CueId != "cue-42" {
				t.Errorf("AudioPlay.CueId = %q, erwartet cue-42", p.CueId)
			}
			return
		}
	}
	t.Error("kein AudioPlay-Command gefunden")
}

func TestEngine_DispatchAudio_TrackerFiresCueDone(t *testing.T) {
	store := makeStore()
	disp := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)
	engine.runningCueIDs = make(map[string]struct{})
	engine.mu.Lock()
	engine.tp.startedAt = time.Now()
	engine.mu.Unlock()

	events := store.SubscribeExec()
	defer store.UnsubscribeExec(events)

	cue := audioTrackedCue("c1", "sha1", 30) // 30ms Dauer
	err := engine.dispatchAudio(context.Background(), cue)
	if err != nil {
		t.Fatalf("dispatchAudio: %v", err)
	}

	// CUE_DONE sollte nach ~30ms kommen
	evs := collectExecEvents(events, 1, 500*time.Millisecond)
	if len(evs) == 0 {
		t.Fatal("kein CUE_DONE Event erhalten")
	}
	if evs[0].Type != pb.ShowExecutionEvent_CUE_DONE {
		t.Errorf("expected CUE_DONE, got %v", evs[0].Type)
	}
	if evs[0].AffectedCue.CueId != "c1" {
		t.Errorf("expected cue c1, got %s", evs[0].AffectedCue.CueId)
	}
}

func TestEngine_DispatchAudio_SilenceDetectorApplied(t *testing.T) {
	store := makeStore()
	disp := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)
	engine.runningCueIDs = make(map[string]struct{})
	engine.mu.Lock()
	engine.tp.startedAt = time.Now()
	engine.mu.Unlock()
	engine.silenceDetector = &mockSilenceDetector{ms: 250}

	cue := audioCue("c1", "sha1")
	_ = engine.dispatchAudio(context.Background(), cue)

	for _, cmd := range disp.commands {
		if p := cmd.GetAudioPlay(); p != nil {
			if p.StartTimeMs != 250 {
				t.Errorf("StartTimeMs = %.0f, erwartet 250 (von SilenceDetector)", p.StartTimeMs)
			}
			return
		}
	}
	t.Error("kein AudioPlay-Command gefunden")
}

func TestEngine_DispatchAudio_ManualStartTimeTakesPrecedence(t *testing.T) {
	store := makeStore()
	disp := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)
	engine.runningCueIDs = make(map[string]struct{})
	engine.mu.Lock()
	engine.tp.startedAt = time.Now()
	engine.mu.Unlock()
	engine.silenceDetector = &mockSilenceDetector{ms: 250}

	cue := &pb.Cue{
		CueId:   "c1",
		CueType: pb.CueType_CUE_TYPE_AUDIO,
		Params: &pb.Cue_Audio{Audio: &pb.AudioCueParams{
			AssetId:     "sha1",
			StartTimeMs: 500, // manuell gesetzt → überschreibt SilenceDetector
		}},
	}
	_ = engine.dispatchAudio(context.Background(), cue)

	for _, cmd := range disp.commands {
		if p := cmd.GetAudioPlay(); p != nil {
			if p.StartTimeMs != 500 {
				t.Errorf("StartTimeMs = %.0f, erwartet 500 (manuell)", p.StartTimeMs)
			}
			return
		}
	}
	t.Error("kein AudioPlay-Command gefunden")
}

func TestEngine_DispatchAudio_EndTimeTruncatesDuration(t *testing.T) {
	store := makeStore()
	disp := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)
	engine.runningCueIDs = make(map[string]struct{})
	engine.mu.Lock()
	engine.tp.startedAt = time.Now()
	engine.mu.Unlock()

	events := store.SubscribeExec()
	defer store.UnsubscribeExec(events)

	// EndTimeMs=30, StartTimeMs=0 → waitMs=30ms
	cue := &pb.Cue{
		CueId:   "c1",
		CueType: pb.CueType_CUE_TYPE_AUDIO,
		Params: &pb.Cue_Audio{Audio: &pb.AudioCueParams{
			AssetId:             "sha1",
			DeclaredDurationMs:  10000,
			EndTimeMs:           30,
		}},
	}
	_ = engine.dispatchAudio(context.Background(), cue)

	evs := collectExecEvents(events, 1, 500*time.Millisecond)
	if len(evs) == 0 {
		t.Fatal("kein CUE_DONE erhalten (EndTimeMs-Truncation)")
	}
	if evs[0].Type != pb.ShowExecutionEvent_CUE_DONE {
		t.Errorf("expected CUE_DONE, got %v", evs[0].Type)
	}
}

func TestEngine_DispatchAudio_LoopCue_NoTracker(t *testing.T) {
	store := makeStore()
	disp := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)
	engine.runningCueIDs = make(map[string]struct{})
	engine.mu.Lock()
	engine.tp.startedAt = time.Now()
	engine.mu.Unlock()

	cue := &pb.Cue{
		CueId:   "loop1",
		CueType: pb.CueType_CUE_TYPE_AUDIO,
		Params: &pb.Cue_Audio{Audio: &pb.AudioCueParams{
			AssetId:            "sha1",
			DeclaredDurationMs: 50,
			Loop:               true,
		}},
	}
	_ = engine.dispatchAudio(context.Background(), cue)

	// Loop-Cues legen keinen audioTracker an
	_, loaded := engine.audioTrackers.Load("loop1")
	if loaded {
		t.Error("Loop-Cues sollten keinen audioTracker erhalten")
	}
}

// ── Go/Pause/Resume/Stop Sequenz (Integrations-Smoke-Test) ───────────────────

func TestEngine_FullTransportCycle(t *testing.T) {
	store := makeStore(audioCue("c1", "sha1"), audioCue("c2", "sha2"))
	disp := &recordingDispatcher{}
	engine := NewEngine("sess", "main", store, disp)
	ctx := context.Background()

	// Go
	cue, _, err := engine.Go(ctx, "c1")
	if err != nil || cue.CueId != "c1" {
		t.Fatalf("Go: err=%v cue=%v", err, cue)
	}
	time.Sleep(20 * time.Millisecond)

	// Pause
	if err := engine.Pause(ctx); err != nil {
		t.Fatalf("Pause: %v", err)
	}
	snap := engine.TransportSnapshot()
	if !snap.Paused {
		t.Error("Snapshot: Paused sollte true sein")
	}

	// Resume
	if err := engine.Resume(ctx); err != nil {
		t.Fatalf("Resume: %v", err)
	}
	snap = engine.TransportSnapshot()
	if snap.Paused {
		t.Error("Snapshot: Paused sollte nach Resume false sein")
	}

	// Stop
	if err := engine.Stop(ctx); err != nil {
		t.Fatalf("Stop: %v", err)
	}
	snap = engine.TransportSnapshot()
	if snap.Running || snap.Paused {
		t.Errorf("Snapshot nach Stop: Running=%v Paused=%v (beide sollen false sein)", snap.Running, snap.Paused)
	}

	// Erneutes Go nach Stop (nächste Cue)
	cue2, _, err2 := engine.Go(ctx, "c2")
	if err2 != nil || cue2.CueId != "c2" {
		t.Fatalf("Go nach Stop: err=%v cue=%v", err2, cue2)
	}
	engine.Stop(ctx) //nolint
}
