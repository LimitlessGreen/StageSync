package showcontrol

import (
	"context"
	"errors"
	"sync"
	"time"

	pb "stagesync-server/gen/go/stagesync/v1"
)

var (
	ErrNoCue          = errors.New("no cue to execute")
	ErrUnknownCueType = errors.New("unknown cue type")
)

// NodeDispatcher ist das Interface, über das die Engine Befehle an Nodes sendet.
// Implementiert von node.Dispatcher.
type NodeDispatcher interface {
	Dispatch(ctx context.Context, nodeID string, cmd *pb.NodeCommandRequest) error
	DispatchToTask(ctx context.Context, task pb.NodeTask, cmd *pb.NodeCommandRequest) error
}

// Engine ist das Show-Control-Herzstück einer Session.
// Sie verwaltet GO/STOP/PAUSE und koordiniert die Node-Dispatches.
type Engine struct {
	mu         sync.Mutex
	store      *Store
	dispatcher NodeDispatcher
	sessionID  string
	cueListID  string

	paused    bool
	running   bool
	cancelFn  context.CancelFunc

	// Transport-Tracking für konsistente verstrichene Zeit über alle Geräte.
	cueStartedAt  time.Time     // Serverzeit, zu der die aktive Cue gestartet ist
	pausedElapsed time.Duration // bei Pause: bereits verstrichene Zeit
}

func NewEngine(sessionID, cueListID string, store *Store, dispatcher NodeDispatcher) *Engine {
	return &Engine{
		store:     store,
		dispatcher: dispatcher,
		sessionID: sessionID,
		cueListID: cueListID,
	}
}

// TransportSnapshot beschreibt den aktuellen Transport-Zustand (für den
// Initial-Sync neuer Watcher).
type TransportSnapshot struct {
	ActiveCue      *pb.Cue
	Running        bool
	Paused         bool
	CueStartedAtMs int64 // effektive Serverzeit-Startzeit (bei Pause: now - elapsed)
	PausedAtMs     int64 // nur bei Pause gesetzt
}

// TransportSnapshot liefert den aktuellen Zustand für einen neu verbundenen Watcher.
func (e *Engine) TransportSnapshot() TransportSnapshot {
	e.mu.Lock()
	defer e.mu.Unlock()
	ts := TransportSnapshot{
		ActiveCue: e.store.GetActiveCue(e.cueListID),
		Running:   e.running,
		Paused:    e.paused,
	}
	now := time.Now()
	if e.paused {
		ts.CueStartedAtMs = now.Add(-e.pausedElapsed).UnixMilli()
		ts.PausedAtMs = now.UnixMilli()
	} else if !e.cueStartedAt.IsZero() {
		ts.CueStartedAtMs = e.cueStartedAt.UnixMilli()
	}
	return ts
}

// Go führt die nächste (oder eine spezifische) Cue aus.
func (e *Engine) Go(ctx context.Context, cueID string) (*pb.Cue, *pb.Cue, error) {
	e.mu.Lock()
	defer e.mu.Unlock()

	var cue *pb.Cue
	var ok bool

	if cueID != "" {
		list, found := e.store.GetCueList(e.cueListID)
		if !found {
			return nil, nil, errors.New("cue list not found")
		}
		for _, c := range list.Cues {
			if c.CueId == cueID {
				cue = c
				ok = true
				break
			}
		}
	} else {
		cue, ok = e.store.NextCue(e.cueListID)
	}

	if !ok || cue == nil {
		return nil, nil, ErrNoCue
	}

	e.store.SetActiveCue(e.cueListID, cue.CueId)

	execCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	if e.cancelFn != nil {
		e.cancelFn()
	}
	e.cancelFn = cancel
	e.running = true
	e.paused = false

	go e.dispatchCue(execCtx, cue)

	// Nächste Cue für Response ermitteln
	list, _ := e.store.GetCueList(e.cueListID)
	var next *pb.Cue
	if list != nil && list.NextCueId != "" {
		for _, c := range list.Cues {
			if c.CueId == list.NextCueId {
				next = c
				break
			}
		}
	}

	// Nächste Cue vorab auf den Nodes laden, damit das folgende GO ohne
	// Lade-Latenz sofort feuern kann.
	if next != nil {
		go e.armCue(context.Background(), next)
	}

	return cue, next, nil
}

// Stop hält alle laufenden Cues an und stoppt Audio auf allen Nodes.
func (e *Engine) Stop(ctx context.Context) error {
	e.mu.Lock()
	if e.cancelFn != nil {
		e.cancelFn()
		e.cancelFn = nil
	}
	e.running = false
	e.paused = false
	activeCue := e.store.GetActiveCue(e.cueListID)
	e.mu.Unlock()

	// AudioStop an alle Audio-Nodes senden
	if activeCue != nil && e.dispatcher != nil {
		stopCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		_ = e.dispatcher.DispatchToTask(stopCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
			SessionId: e.sessionID,
			Command: &pb.NodeCommandRequest_AudioStop{
				AudioStop: &pb.AudioStopCommand{
					CueId:     activeCue.CueId,
					FadeOutMs: 300,
				},
			},
		})
	}

	e.store.broadcast(&pb.ShowStateEvent{
		Type:       pb.ShowStateEvent_TYPE_CUE_STOPPED,
		OccurredAt: nowProto(),
	})
	return nil
}

// pauseFadeMs / resumeFadeMs: kurze Fades gegen Knackser beim Pausieren/Fortsetzen.
const (
	pauseFadeMs  = 120
	resumeFadeMs = 120
)

// Pause hält die aktuelle Cue an: die Voice wird angehalten (Playhead bleibt
// stehen), der Transport-Timer friert ein. Idempotent.
func (e *Engine) Pause(ctx context.Context) error {
	e.mu.Lock()
	if e.paused || !e.running {
		e.mu.Unlock()
		return nil // bereits pausiert / nichts läuft
	}
	if e.cancelFn != nil {
		e.cancelFn()
		e.cancelFn = nil
	}
	e.paused = true
	// Bereits verstrichene Zeit festhalten, damit Resume korrekt fortsetzt.
	if !e.cueStartedAt.IsZero() {
		e.pausedElapsed = time.Since(e.cueStartedAt)
	}
	activeCue := e.store.GetActiveCue(e.cueListID)
	e.mu.Unlock()

	// Audio auf allen Nodes anhalten (nicht stoppen) — mit kurzem Fade.
	if activeCue != nil && e.dispatcher != nil {
		opCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		_ = e.dispatcher.DispatchToTask(opCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
			SessionId: e.sessionID,
			Command: &pb.NodeCommandRequest_AudioPause{
				AudioPause: &pb.AudioPauseCommand{
					CueId:     activeCue.CueId,
					FadeOutMs: pauseFadeMs,
				},
			},
		})
	}

	e.store.broadcast(&pb.ShowStateEvent{
		Type:       pb.ShowStateEvent_TYPE_CUE_PAUSED,
		OccurredAt: nowProto(),
	})
	return nil
}

// Resume setzt eine pausierte Cue fort: Audio läuft an der angehaltenen Stelle
// weiter und der Transport-Timer läuft konsistent über alle Geräte weiter.
// Idempotent.
func (e *Engine) Resume(ctx context.Context) error {
	e.mu.Lock()
	if !e.paused {
		e.mu.Unlock()
		return nil // nicht pausiert → nichts zu tun
	}
	e.paused = false
	e.running = true
	// Startzeit so verschieben, dass die bereits verstrichene Zeit erhalten
	// bleibt → die verstrichene Zeit läuft auf allen Geräten korrekt weiter.
	newStart := time.Now().Add(-e.pausedElapsed)
	e.cueStartedAt = newStart
	e.mu.Unlock()

	activeCue := e.store.GetActiveCue(e.cueListID)
	if activeCue != nil && e.dispatcher != nil {
		opCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		_ = e.dispatcher.DispatchToTask(opCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
			SessionId: e.sessionID,
			Command: &pb.NodeCommandRequest_AudioResume{
				AudioResume: &pb.AudioResumeCommand{
					CueId:    activeCue.CueId,
					FadeInMs: resumeFadeMs,
				},
			},
		})
	}

	if activeCue != nil {
		// Re-broadcast als CUE_STARTED mit angepasster Startzeit → Clients
		// setzen die verstrichene Zeit korrekt fort.
		e.store.broadcast(&pb.ShowStateEvent{
			Type:        pb.ShowStateEvent_TYPE_CUE_STARTED,
			AffectedCue: activeCue,
			OccurredAt:  &pb.Timestamp{UnixMillis: newStart.UnixMilli()},
		})
	}
	return nil
}

// dispatchCue sendet die Cue-Ausführung an den zuständigen Node.
func (e *Engine) dispatchCue(ctx context.Context, cue *pb.Cue) {
	var err error

	// Pre-Wait
	if cue.PreWaitMs > 0 {
		select {
		case <-time.After(time.Duration(cue.PreWaitMs) * time.Millisecond):
		case <-ctx.Done():
			return
		}
	}

	// Startzeit merken (für Pause/Resume-Re-Anchoring) und autoritatives
	// Start-Signal mit Server-Zeitstempel senden. Alle Clients leiten daraus
	// (via Clock-Sync) dieselbe verstrichene Zeit ab.
	startedAt := time.Now()
	e.mu.Lock()
	e.cueStartedAt = startedAt
	e.pausedElapsed = 0
	e.mu.Unlock()
	e.store.broadcast(&pb.ShowStateEvent{
		Type:        pb.ShowStateEvent_TYPE_CUE_STARTED,
		AffectedCue: cue,
		OccurredAt:  &pb.Timestamp{UnixMillis: startedAt.UnixMilli()},
	})

	switch cue.CueType {
	case pb.CueType_CUE_TYPE_AUDIO:
		err = e.dispatchAudio(ctx, cue)
	case pb.CueType_CUE_TYPE_MA_OSC:
		err = e.dispatchMaOsc(ctx, cue)
	case pb.CueType_CUE_TYPE_WAIT:
		err = e.dispatchWait(ctx, cue)
	default:
		err = ErrUnknownCueType
	}

	// Abgebrochen (Stop/Pause hat den Context gecancelt) → KEIN DONE-Event.
	// Sonst würde der Client die aktive Cue fälschlich reaktivieren und der
	// Timer weiterlaufen. Stop/Pause senden bereits ihr eigenes Event.
	if err == context.Canceled || ctx.Err() == context.Canceled {
		return
	}

	evType := pb.ShowStateEvent_TYPE_CUE_DONE
	errMsg := ""
	if err != nil {
		evType = pb.ShowStateEvent_TYPE_CUE_ERROR
		errMsg = err.Error()
	}

	e.store.broadcast(&pb.ShowStateEvent{
		Type:        evType,
		AffectedCue: cue,
		OccurredAt:  nowProto(),
		ErrorMsg:    errMsg,
	})

	// Auto-Continue: automatisch nächste Cue nach PostWait
	if err == nil && cue.AutoContinue {
		if cue.PostWaitMs > 0 {
			select {
			case <-time.After(time.Duration(cue.PostWaitMs) * time.Millisecond):
			case <-ctx.Done():
				return
			}
		}
		e.mu.Lock()
		e.mu.Unlock()
		_, _, _ = e.Go(ctx, "")
	}
}

func (e *Engine) dispatchAudio(ctx context.Context, cue *pb.Cue) error {
	params, ok := cue.Params.(*pb.Cue_Audio)
	if !ok || params == nil {
		return errors.New("invalid audio cue params")
	}
	if e.dispatcher == nil {
		return errors.New("no dispatcher")
	}

	dispatch := func(cmd *pb.NodeCommandRequest) error {
		if cue.TargetNodeId != "" {
			return e.dispatcher.Dispatch(ctx, cue.TargetNodeId, cmd)
		}
		return e.dispatcher.DispatchToTask(ctx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd)
	}

	// 1. Preload senden (Sicherheitsnetz). Wurde die Cue bereits via armCue
	// vorgeladen, ist das auf dem Node ein No-Op (Pfad-Tracking) — die Datei
	// liegt dann schon dekodiert im Speicher und der Trigger feuert sofort.
	if params.Audio.FilePath != "" {
		_ = dispatch(&pb.NodeCommandRequest{
			SessionId:    e.sessionID,
			TargetNodeId: cue.TargetNodeId,
			Command: &pb.NodeCommandRequest_AudioPreload{
				AudioPreload: &pb.AudioPreloadCommand{
					CueId:    cue.CueId,
					FilePath: params.Audio.FilePath,
				},
			},
		})
	}

	// 2. Sofort feuern: StartUnixMillis = 0 → der Node spielt unmittelbar bei
	// Empfang ab (kein Zeitstempel-Warten). Niedrigste Latenz, QLab-artig.
	// Mehrere Nodes erhalten das Signal quasi gleichzeitig (LAN-Zustellung).
	return dispatch(&pb.NodeCommandRequest{
		SessionId:    e.sessionID,
		TargetNodeId: cue.TargetNodeId,
		Command: &pb.NodeCommandRequest_AudioPlay{
			AudioPlay: &pb.AudioPlayCommand{
				CueId:           cue.CueId,
				StartUnixMillis: 0,
				VolumeDb:        params.Audio.VolumeDb,
				FadeInMs:        params.Audio.FadeInMs,
			},
		},
	})
}

// armCue lädt eine Audio-Cue auf den zuständigen Nodes vor (Preload ohne Play),
// damit ein späteres GO ohne Lade-Latenz sofort feuern kann (QLab "loaded").
func (e *Engine) armCue(ctx context.Context, cue *pb.Cue) {
	if cue == nil || cue.CueType != pb.CueType_CUE_TYPE_AUDIO || e.dispatcher == nil {
		return
	}
	params, ok := cue.Params.(*pb.Cue_Audio)
	if !ok || params == nil || params.Audio.FilePath == "" {
		return
	}
	cmd := &pb.NodeCommandRequest{
		SessionId:    e.sessionID,
		TargetNodeId: cue.TargetNodeId,
		Command: &pb.NodeCommandRequest_AudioPreload{
			AudioPreload: &pb.AudioPreloadCommand{
				CueId:    cue.CueId,
				FilePath: params.Audio.FilePath,
			},
		},
	}
	if cue.TargetNodeId != "" {
		_ = e.dispatcher.Dispatch(ctx, cue.TargetNodeId, cmd)
	} else {
		_ = e.dispatcher.DispatchToTask(ctx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd)
	}
}

func (e *Engine) dispatchMaOsc(ctx context.Context, cue *pb.Cue) error {
	params, ok := cue.Params.(*pb.Cue_MaOsc)
	if !ok || params == nil {
		return errors.New("invalid MA OSC cue params")
	}
	if e.dispatcher == nil {
		return errors.New("no dispatcher")
	}

	cmd := &pb.NodeCommandRequest{
		SessionId:    e.sessionID,
		TargetNodeId: cue.TargetNodeId,
		Command: &pb.NodeCommandRequest_MaOsc{
			MaOsc: &pb.MaOscCommand{
				OscAddress:  params.MaOsc.OscAddress,
				OscArgument: params.MaOsc.OscArgument,
			},
		},
	}

	if cue.TargetNodeId != "" {
		return e.dispatcher.Dispatch(ctx, cue.TargetNodeId, cmd)
	}
	return e.dispatcher.DispatchToTask(ctx, pb.NodeTask_NODE_TASK_MA_OSC, cmd)
}

func (e *Engine) dispatchWait(ctx context.Context, cue *pb.Cue) error {
	params, ok := cue.Params.(*pb.Cue_Wait)
	if !ok || params == nil {
		return errors.New("invalid wait cue params")
	}
	select {
	case <-time.After(time.Duration(params.Wait.DurationMs) * time.Millisecond):
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
