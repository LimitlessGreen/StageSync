package grid

import (
	"context"
	"sync"
	"testing"
	"time"

	pb "stagesync-server/gen/go/stagesync/v1"
)

// fakeDispatcher zeichnet alle gesendeten Node-Commands auf.
type fakeDispatcher struct {
	mu   sync.Mutex
	cmds []*pb.NodeCommandRequest
}

func (f *fakeDispatcher) Dispatch(_ context.Context, _ string, cmd *pb.NodeCommandRequest) error {
	f.record(cmd)
	return nil
}
func (f *fakeDispatcher) DispatchToTask(_ context.Context, _ pb.NodeTask, cmd *pb.NodeCommandRequest) error {
	f.record(cmd)
	return nil
}
func (f *fakeDispatcher) record(cmd *pb.NodeCommandRequest) {
	f.mu.Lock()
	f.cmds = append(f.cmds, cmd)
	f.mu.Unlock()
}
func (f *fakeDispatcher) count() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return len(f.cmds)
}
func (f *fakeDispatcher) typesOf() []string {
	f.mu.Lock()
	defer f.mu.Unlock()
	var out []string
	for _, c := range f.cmds {
		switch c.Command.(type) {
		case *pb.NodeCommandRequest_AudioPreload:
			out = append(out, "preload")
		case *pb.NodeCommandRequest_AudioPlay:
			out = append(out, "play")
		case *pb.NodeCommandRequest_AudioStop:
			out = append(out, "stop")
		case *pb.NodeCommandRequest_MaOsc:
			out = append(out, "osc")
		case *pb.NodeCommandRequest_MidiSend:
			out = append(out, "midi")
		}
	}
	return out
}

func audioClip(id string, track, scene int32, durationMs float64) *pb.GridClip {
	return &pb.GridClip{
		ClipId:     id,
		TrackIndex: track,
		SceneIndex: scene,
		Payload: &pb.GridClip_Audio{Audio: &pb.AudioClipPayload{
			AssetId:            "asset-" + id,
			DeclaredDurationMs: durationMs,
		}},
	}
}

func newTestEngine(t *testing.T) (*Engine, *Store, *fakeDispatcher) {
	t.Helper()
	store := NewStore()
	disp := &fakeDispatcher{}
	eng := NewEngine("sess", store, disp)
	return eng, store, disp
}

func TestLaunchAudioClip_SendsPreloadAndPlay(t *testing.T) {
	eng, store, disp := newTestEngine(t)
	store.UpsertClip(DefaultGridID, audioClip("c1", 0, 0, 0)) // keine Dauer → kein Tracker

	if err := eng.LaunchClip(context.Background(), DefaultGridID, 0, 0, false); err != nil {
		t.Fatalf("LaunchClip: %v", err)
	}
	types := disp.typesOf()
	if len(types) != 2 || types[0] != "preload" || types[1] != "play" {
		t.Fatalf("expected [preload play], got %v", types)
	}
	if ids := eng.RunningClipIDs(); len(ids) != 1 || ids[0] != "c1" {
		t.Fatalf("expected c1 running, got %v", ids)
	}
}

func TestLaunchEmptyCell_NoError(t *testing.T) {
	eng, _, disp := newTestEngine(t)
	err := eng.LaunchClip(context.Background(), DefaultGridID, 3, 3, false)
	if err != ErrNoClip {
		t.Fatalf("expected ErrNoClip, got %v", err)
	}
	if disp.count() != 0 {
		t.Fatalf("expected no commands, got %d", disp.count())
	}
}

func TestTrackExclusivity_StopsPreviousClip(t *testing.T) {
	eng, store, disp := newTestEngine(t)
	store.UpsertClip(DefaultGridID, audioClip("a", 0, 0, 0))
	store.UpsertClip(DefaultGridID, audioClip("b", 0, 1, 0)) // selbe Spalte 0

	_ = eng.LaunchClip(context.Background(), DefaultGridID, 0, 0, false)
	_ = eng.LaunchClip(context.Background(), DefaultGridID, 0, 1, false)

	// Erwartung: a(preload,play) → b stoppt a (stop) → b(preload,play)
	types := disp.typesOf()
	wantStop := false
	for _, ty := range types {
		if ty == "stop" {
			wantStop = true
		}
	}
	if !wantStop {
		t.Fatalf("expected a stop command from exclusivity, got %v", types)
	}
	ids := eng.RunningClipIDs()
	if len(ids) != 1 || ids[0] != "b" {
		t.Fatalf("expected only b running, got %v", ids)
	}
}

func TestAudioTracker_BroadcastsDone(t *testing.T) {
	eng, store, _ := newTestEngine(t)
	ch := store.SubscribeExec()
	defer store.UnsubscribeExec(ch)

	store.UpsertClip(DefaultGridID, audioClip("c", 0, 0, 30)) // 30ms → Tracker feuert schnell
	_ = eng.LaunchClip(context.Background(), DefaultGridID, 0, 0, false)

	// Auf CLIP_DONE warten.
	deadline := time.After(2 * time.Second)
	gotDone := false
	for !gotDone {
		select {
		case ev := <-ch:
			if ev.Type == pb.GridExecutionEvent_CLIP_DONE && ev.ClipId == "c" {
				gotDone = true
			}
		case <-deadline:
			t.Fatal("timed out waiting for CLIP_DONE")
		}
	}
	if ids := eng.RunningClipIDs(); len(ids) != 0 {
		t.Fatalf("expected no running clips after done, got %v", ids)
	}
}

func TestCueRefClip_DelegatesToCueLauncher(t *testing.T) {
	eng, store, _ := newTestEngine(t)
	var launched string
	eng.SetCueLauncher(cueLauncherStub(func(_ context.Context, _, cueID string) error {
		launched = cueID
		return nil
	}))
	store.UpsertClip(DefaultGridID, &pb.GridClip{
		ClipId: "ref", TrackIndex: 1, SceneIndex: 0,
		Payload: &pb.GridClip_CueRef{CueRef: &pb.CueRefPayload{CueId: "cue-42"}},
	})
	if err := eng.LaunchClip(context.Background(), DefaultGridID, 1, 0, false); err != nil {
		t.Fatalf("LaunchClip: %v", err)
	}
	if launched != "cue-42" {
		t.Fatalf("expected cue-42 launched, got %q", launched)
	}
}

func TestOscClip_DispatchesOsc(t *testing.T) {
	eng, store, disp := newTestEngine(t)
	store.UpsertClip(DefaultGridID, &pb.GridClip{
		ClipId: "o", TrackIndex: 2, SceneIndex: 0,
		Payload: &pb.GridClip_Osc{Osc: &pb.OscClipPayload{Address: "/go", Args: []string{"1"}}},
	})
	if err := eng.LaunchClip(context.Background(), DefaultGridID, 2, 0, false); err != nil {
		t.Fatalf("LaunchClip: %v", err)
	}
	types := disp.typesOf()
	if len(types) != 1 || types[0] != "osc" {
		t.Fatalf("expected [osc], got %v", types)
	}
}

func TestLaunchScene_StartsAllClipsInRow(t *testing.T) {
	eng, store, _ := newTestEngine(t)
	store.UpsertClip(DefaultGridID, audioClip("a", 0, 2, 0))
	store.UpsertClip(DefaultGridID, audioClip("b", 1, 2, 0))
	store.UpsertClip(DefaultGridID, audioClip("c", 2, 5, 0)) // andere Scene

	eng.LaunchScene(context.Background(), DefaultGridID, 2)

	ids := eng.RunningClipIDs()
	if len(ids) != 2 {
		t.Fatalf("expected 2 clips running, got %v", ids)
	}
	got := map[string]bool{}
	for _, id := range ids {
		got[id] = true
	}
	if !got["a"] || !got["b"] || got["c"] {
		t.Fatalf("expected a+b running (not c), got %v", ids)
	}
}

func TestFollowNextClip_LaunchesNextScene(t *testing.T) {
	eng, store, _ := newTestEngine(t)
	first := audioClip("f0", 0, 0, 25)
	first.Follow = pb.FollowAction_FOLLOW_NEXT_CLIP
	store.UpsertClip(DefaultGridID, first)
	store.UpsertClip(DefaultGridID, audioClip("f1", 0, 1, 0)) // nächste Scene, selbe Spalte

	_ = eng.LaunchClip(context.Background(), DefaultGridID, 0, 0, false)

	// Nach ~25ms feuert der Tracker CLIP_DONE und startet f1.
	deadline := time.After(2 * time.Second)
	for {
		ids := eng.RunningClipIDs()
		if len(ids) == 1 && ids[0] == "f1" {
			return // Follow-Action hat f1 gestartet
		}
		select {
		case <-deadline:
			t.Fatalf("follow action did not launch f1; running=%v", ids)
		case <-time.After(10 * time.Millisecond):
		}
	}
}

// cueLauncherStub adaptiert eine Funktion an das CueLauncher-Interface.
type cueLauncherStub func(ctx context.Context, cueListID, cueID string) error

func (f cueLauncherStub) LaunchCue(ctx context.Context, cueListID, cueID string) error {
	return f(ctx, cueListID, cueID)
}
