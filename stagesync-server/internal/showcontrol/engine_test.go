package showcontrol

import (
	"context"
	"testing"
	"time"

	pb "stagesync-server/gen/go/stagesync/v1"
)

// ── Test-Dispatcher ───────────────────────────────────────────────────────────

type recordingDispatcher struct {
	commands []*pb.NodeCommandRequest
}

func (d *recordingDispatcher) Dispatch(_ context.Context, _ string, cmd *pb.NodeCommandRequest) error {
	d.commands = append(d.commands, cmd)
	return nil
}

func (d *recordingDispatcher) DispatchToTask(_ context.Context, _ pb.NodeTask, cmd *pb.NodeCommandRequest) error {
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
	locked   bool
	unlocked bool
	warmed   []string
}

func (w *recordingWarmer) WarmAssets(_ context.Context, ids []string) { w.warmed = append(w.warmed, ids...) }
func (w *recordingWarmer) LockForShow()                               { w.locked = true }
func (w *recordingWarmer) UnlockShow()                                { w.unlocked = true }

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

	if !warmer.locked {
		t.Error("LockForShow sollte beim ersten GO aufgerufen werden")
	}
	if len(warmer.warmed) == 0 {
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

	if !warmer.unlocked {
		t.Error("UnlockShow sollte bei Stop aufgerufen werden")
	}
}
