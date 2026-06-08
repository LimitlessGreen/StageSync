package grid

import (
	"context"
	"errors"
	"log"
	"sync"
	"time"

	pb "stagesync-server/gen/go/stagesync/v1"
)

var ErrNoClip = errors.New("no clip at position")

// NodeDispatcher ist das Interface, über das die Engine Befehle an Nodes sendet.
// Implementiert von node.Dispatcher (identisch zu showcontrol.NodeDispatcher).
type NodeDispatcher interface {
	Dispatch(ctx context.Context, nodeID string, cmd *pb.NodeCommandRequest) error
	DispatchToTask(ctx context.Context, task pb.NodeTask, cmd *pb.NodeCommandRequest) error
}

// CueLauncher delegiert cue_ref-Clips an die bestehende ShowControl-Engine.
// Implementiert von showcontrol.Engine.Go (über einen dünnen Adapter).
type CueLauncher interface {
	LaunchCue(ctx context.Context, cueListID, cueID string) error
}

// Engine führt Grid-Clips aus. Additiv neben showcontrol.Engine; nutzt dieselbe
// Audio-Engine, denselben Dispatcher und dieselbe Server-Zeit-Synchronisation.
type Engine struct {
	store       *Store
	dispatcher  NodeDispatcher
	cueLauncher CueLauncher // optional; nil = cue_ref-Clips werden ignoriert
	sessionID   string

	mu sync.Mutex
	// running: clipID → laufender Clip-Zustand.
	running map[string]*clipRun
	// trackActive: trackIndex → clipID des aktuell laufenden exklusiven Clips.
	trackActive map[int32]string
}

type clipRun struct {
	clip    *pb.GridClip
	cancel  context.CancelFunc
	startMs int64
}

func NewEngine(sessionID string, store *Store, dispatcher NodeDispatcher) *Engine {
	return &Engine{
		store:       store,
		dispatcher:  dispatcher,
		sessionID:   sessionID,
		running:     make(map[string]*clipRun),
		trackActive: make(map[int32]string),
	}
}

func (e *Engine) SetCueLauncher(l CueLauncher) {
	e.mu.Lock()
	e.cueLauncher = l
	e.mu.Unlock()
}

// LaunchClip löst die Zelle an (track, scene) aus. released=true behandelt das
// Loslassen eines GATE-Pads (stoppt den Clip).
func (e *Engine) LaunchClip(ctx context.Context, gridID string, track, scene int32, released bool) error {
	clip, ok := e.store.ClipAt(gridID, track, scene)
	if !ok {
		return ErrNoClip
	}

	if released {
		if clip.LaunchMode == pb.LaunchMode_LAUNCH_GATE {
			e.stopClip(clip, audioFadeOutMs(clip))
		}
		return nil
	}

	// TOGGLE: läuft der Clip bereits, stoppen statt neu starten.
	if clip.LaunchMode == pb.LaunchMode_LAUNCH_TOGGLE {
		e.mu.Lock()
		_, isRunning := e.running[clip.ClipId]
		e.mu.Unlock()
		if isRunning {
			e.stopClip(clip, audioFadeOutMs(clip))
			return nil
		}
	}

	// Track-Exklusivität: laufenden Clip derselben Spalte mit Fade stoppen.
	if e.store.TrackExclusive(gridID, track) {
		e.mu.Lock()
		prevID, has := e.trackActive[track]
		e.mu.Unlock()
		if has && prevID != clip.ClipId {
			if prev := e.runningClip(prevID); prev != nil {
				e.stopClip(prev, audioFadeOutMs(prev))
			}
		}
	}

	return e.dispatchClip(ctx, gridID, clip)
}

// LaunchScene startet alle Clips einer Reihe (je Spalte exklusiv).
func (e *Engine) LaunchScene(ctx context.Context, gridID string, scene int32) {
	for _, clip := range e.store.ClipsInScene(gridID, scene) {
		if err := e.LaunchClip(ctx, gridID, clip.TrackIndex, clip.SceneIndex, false); err != nil {
			log.Printf("[grid] LaunchScene clip=%s error: %v", clip.ClipId, err)
		}
	}
}

// StopTrack stoppt den laufenden Clip einer Spalte.
func (e *Engine) StopTrack(gridID string, track int32) {
	e.mu.Lock()
	clipID, has := e.trackActive[track]
	e.mu.Unlock()
	if !has {
		return
	}
	if clip := e.runningClip(clipID); clip != nil {
		e.stopClip(clip, 0)
	}
}

// StopAll stoppt alle laufenden Clips.
func (e *Engine) StopAll() {
	e.mu.Lock()
	clips := make([]*pb.GridClip, 0, len(e.running))
	for _, r := range e.running {
		clips = append(clips, r.clip)
	}
	e.mu.Unlock()
	for _, c := range clips {
		e.stopClip(c, 0)
	}
}

// ── Dispatch je Payload-Typ ──────────────────────────────────────────────────

func (e *Engine) dispatchClip(ctx context.Context, gridID string, clip *pb.GridClip) error {
	switch clip.Payload.(type) {
	case *pb.GridClip_Audio:
		return e.dispatchAudio(gridID, clip)
	case *pb.GridClip_Osc:
		return e.dispatchOsc(ctx, clip)
	case *pb.GridClip_Midi:
		return e.dispatchMidi(ctx, clip)
	case *pb.GridClip_CueRef:
		return e.dispatchCueRef(ctx, clip)
	default:
		return errors.New("clip has no payload")
	}
}

func (e *Engine) dispatchAudio(gridID string, clip *pb.GridClip) error {
	a := clip.GetAudio()
	if a == nil {
		return errors.New("invalid audio clip")
	}
	if e.dispatcher == nil {
		return errors.New("no dispatcher")
	}
	sendCtx := context.Background()
	startMs := time.Now().UnixMilli()

	// Preload (SHA-256 Asset bevorzugt).
	if a.AssetId != "" {
		_ = e.dispatcher.DispatchToTask(sendCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
			SessionId: e.sessionID,
			Command: &pb.NodeCommandRequest_AudioPreload{
				AudioPreload: &pb.AudioPreloadCommand{CueId: clip.ClipId, AssetId: a.AssetId},
			},
		})
	}

	// Play mit Server-Startzeit (ClockSync-Anker wie ShowControl).
	if err := e.dispatcher.DispatchToTask(sendCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
		SessionId: e.sessionID,
		Command: &pb.NodeCommandRequest_AudioPlay{
			AudioPlay: &pb.AudioPlayCommand{
				CueId:           clip.ClipId,
				StartUnixMillis: startMs,
				VolumeDb:        a.VolumeDb,
				FadeInMs:        a.FadeInMs,
				FadeOutMs:       a.FadeOutMs,
				Loop:            a.Loop,
				StartTimeMs:     a.StartTimeMs,
				EndTimeMs:       a.EndTimeMs,
			},
		},
	}); err != nil {
		return err
	}

	lengthMs := audioLengthMs(a)
	e.markRunning(clip, startMs, lengthMs)

	// Nicht-loopende Clips: Hintergrund-Tracker für CLIP_DONE + Follow-Action.
	if !a.Loop && lengthMs > 0 {
		e.startAudioTracker(gridID, clip, lengthMs)
	}
	return nil
}

func (e *Engine) dispatchOsc(ctx context.Context, clip *pb.GridClip) error {
	o := clip.GetOsc()
	if o == nil {
		return errors.New("invalid osc clip")
	}
	arg := ""
	if len(o.Args) > 0 {
		arg = o.Args[0]
	}
	cmd := &pb.NodeCommandRequest{
		SessionId: e.sessionID,
		Command:   &pb.NodeCommandRequest_MaOsc{MaOsc: &pb.MaOscCommand{OscAddress: o.Address, OscArgument: arg}},
	}
	var err error
	if o.TargetNodeId != "" {
		cmd.TargetNodeId = o.TargetNodeId
		err = e.dispatcher.Dispatch(ctx, o.TargetNodeId, cmd)
	} else {
		err = e.dispatcher.DispatchToTask(ctx, pb.NodeTask_NODE_TASK_MA_OSC, cmd)
	}
	if err != nil {
		return err
	}
	// OSC ist instantan: launched + sofort done (kein laufender Zustand).
	e.broadcast(pb.GridExecutionEvent_CLIP_LAUNCHED, clip, 0, 0)
	e.broadcast(pb.GridExecutionEvent_CLIP_DONE, clip, 0, 0)
	return nil
}

func (e *Engine) dispatchMidi(ctx context.Context, clip *pb.GridClip) error {
	m := clip.GetMidi()
	if m == nil {
		return errors.New("invalid midi clip")
	}
	err := e.dispatcher.DispatchToTask(ctx, pb.NodeTask_NODE_TASK_MIDI_OUT, &pb.NodeCommandRequest{
		SessionId: e.sessionID,
		Command: &pb.NodeCommandRequest_MidiSend{
			MidiSend: &pb.MidiSendCommand{Channel: m.Channel, Command: m.Command, Data1: m.Data1, Data2: m.Data2},
		},
	})
	if err != nil {
		return err
	}
	e.broadcast(pb.GridExecutionEvent_CLIP_LAUNCHED, clip, 0, 0)
	e.broadcast(pb.GridExecutionEvent_CLIP_DONE, clip, 0, 0)
	return nil
}

func (e *Engine) dispatchCueRef(ctx context.Context, clip *pb.GridClip) error {
	ref := clip.GetCueRef()
	if ref == nil {
		return errors.New("invalid cue_ref clip")
	}
	e.mu.Lock()
	l := e.cueLauncher
	e.mu.Unlock()
	if l == nil {
		return errors.New("no cue launcher configured")
	}
	if err := l.LaunchCue(ctx, ref.CueListId, ref.CueId); err != nil {
		return err
	}
	// Der eigentliche Transport-State lebt im ShowControl-Stream; hier nur ein
	// kurzes Launched/Done-Signal für LED + UI-Feedback der Zelle.
	e.broadcast(pb.GridExecutionEvent_CLIP_LAUNCHED, clip, 0, 0)
	e.broadcast(pb.GridExecutionEvent_CLIP_DONE, clip, 0, 0)
	return nil
}

// ── Running-State + Tracker ──────────────────────────────────────────────────

func (e *Engine) markRunning(clip *pb.GridClip, startMs int64, lengthMs float64) {
	e.mu.Lock()
	// Alten Tracker derselben Zelle abbrechen (Re-Trigger).
	if old, ok := e.running[clip.ClipId]; ok && old.cancel != nil {
		old.cancel()
	}
	// cancel wird (für Audio) vom Tracker gesetzt; non-audio bleibt nil.
	e.running[clip.ClipId] = &clipRun{clip: clip, startMs: startMs}
	// trackActive immer setzen — ermöglicht StopTrack/Exklusivität unabhängig
	// vom exclusive-Flag (das Flag steuert nur das automatische Stoppen).
	e.trackActive[clip.TrackIndex] = clip.ClipId
	e.mu.Unlock()
	e.broadcast(pb.GridExecutionEvent_CLIP_PLAYING, clip, startMs, lengthMs)
}

func (e *Engine) startAudioTracker(gridID string, clip *pb.GridClip, lengthMs float64) {
	trackCtx, trackCancel := context.WithCancel(context.Background())
	e.mu.Lock()
	if r, ok := e.running[clip.ClipId]; ok {
		r.cancel = trackCancel
	}
	e.mu.Unlock()

	go func() {
		defer trackCancel() // gibt den Context auf allen Pfaden frei
		timer := time.NewTimer(time.Duration(lengthMs) * time.Millisecond)
		defer timer.Stop()
		select {
		case <-timer.C:
		case <-trackCtx.Done():
			return // durch stopClip/Exklusivität abgebrochen — Cleanup dort erledigt
		}
		e.clearRunning(clip.ClipId, clip.TrackIndex)
		e.broadcast(pb.GridExecutionEvent_CLIP_DONE, clip, 0, lengthMs)
		e.runFollowAction(gridID, clip)
	}()
}

func (e *Engine) runFollowAction(gridID string, clip *pb.GridClip) {
	switch clip.Follow {
	case pb.FollowAction_FOLLOW_NEXT_CLIP:
		_ = e.LaunchClip(context.Background(), gridID, clip.TrackIndex, clip.SceneIndex+1, false)
	case pb.FollowAction_FOLLOW_NEXT_SCENE:
		e.LaunchScene(context.Background(), gridID, clip.SceneIndex+1)
	case pb.FollowAction_FOLLOW_STOP:
		e.StopTrack(gridID, clip.TrackIndex)
	}
}

func (e *Engine) stopClip(clip *pb.GridClip, fadeOutMs float64) {
	e.mu.Lock()
	r, ok := e.running[clip.ClipId]
	if ok && r.cancel != nil {
		r.cancel()
	}
	e.mu.Unlock()
	if !ok {
		return
	}

	// Audio-Voice auf dem Node stoppen.
	if _, isAudio := clip.Payload.(*pb.GridClip_Audio); isAudio && e.dispatcher != nil {
		_ = e.dispatcher.DispatchToTask(context.Background(), pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
			SessionId: e.sessionID,
			Command:   &pb.NodeCommandRequest_AudioStop{AudioStop: &pb.AudioStopCommand{CueId: clip.ClipId, FadeOutMs: fadeOutMs}},
		})
	}

	e.clearRunning(clip.ClipId, clip.TrackIndex)
	e.broadcast(pb.GridExecutionEvent_CLIP_STOPPED, clip, 0, 0)
}

func (e *Engine) clearRunning(clipID string, track int32) {
	e.mu.Lock()
	delete(e.running, clipID)
	if e.trackActive[track] == clipID {
		delete(e.trackActive, track)
	}
	e.mu.Unlock()
}

func (e *Engine) runningClip(clipID string) *pb.GridClip {
	e.mu.Lock()
	defer e.mu.Unlock()
	if r, ok := e.running[clipID]; ok {
		return r.clip
	}
	return nil
}

// RunningClipIDs liefert die IDs aller laufenden Clips (für Snapshot).
func (e *Engine) RunningClipIDs() []string {
	e.mu.Lock()
	defer e.mu.Unlock()
	ids := make([]string, 0, len(e.running))
	for id := range e.running {
		ids = append(ids, id)
	}
	return ids
}

func (e *Engine) broadcast(t pb.GridExecutionEvent_Type, clip *pb.GridClip, startMs int64, lengthMs float64) {
	e.store.BroadcastExec(&pb.GridExecutionEvent{
		Type:         t,
		OccurredAt:   nowProto(),
		ClipId:       clip.ClipId,
		TrackIndex:   clip.TrackIndex,
		SceneIndex:   clip.SceneIndex,
		StartedAtMs:  startMs,
		ClipLengthMs: lengthMs,
	})
	e.dispatchLed(t, clip)
}

// dispatchLed spiegelt den Clip-Status als LED-Feedback an MIDI-Out-Nodes
// (z.B. APC Mini). Symmetrisch zum Audio-Pfad: der Node empfängt das Command
// über den Dispatcher und setzt die Pad-LED.
func (e *Engine) dispatchLed(t pb.GridExecutionEvent_Type, clip *pb.GridClip) {
	if e.dispatcher == nil {
		return
	}
	var color pb.LedFeedbackCommand_Color
	switch t {
	case pb.GridExecutionEvent_CLIP_PLAYING, pb.GridExecutionEvent_CLIP_LAUNCHED:
		color = pb.LedFeedbackCommand_LED_GREEN
	case pb.GridExecutionEvent_CLIP_ERROR:
		color = pb.LedFeedbackCommand_LED_RED
	default: // CLIP_STOPPED, CLIP_DONE
		color = pb.LedFeedbackCommand_LED_OFF
	}
	_ = e.dispatcher.DispatchToTask(context.Background(), pb.NodeTask_NODE_TASK_MIDI_OUT, &pb.NodeCommandRequest{
		SessionId: e.sessionID,
		Command: &pb.NodeCommandRequest_LedFeedback{
			LedFeedback: &pb.LedFeedbackCommand{
				TrackIndex: clip.TrackIndex,
				SceneIndex: clip.SceneIndex,
				Color:      color,
			},
		},
	})
}

// ── Helpers ──────────────────────────────────────────────────────────────────

func audioLengthMs(a *pb.AudioClipPayload) float64 {
	if a.EndTimeMs > 0 && a.EndTimeMs > a.StartTimeMs {
		return a.EndTimeMs - a.StartTimeMs
	}
	if a.DeclaredDurationMs > 0 {
		if rem := a.DeclaredDurationMs - a.StartTimeMs; rem > 0 {
			return rem
		}
	}
	return 0
}

func audioFadeOutMs(clip *pb.GridClip) float64 {
	if a := clip.GetAudio(); a != nil {
		return a.FadeOutMs
	}
	return 0
}
