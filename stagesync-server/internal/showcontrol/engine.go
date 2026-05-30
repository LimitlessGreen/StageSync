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
	pausedAt      time.Time     // absoluter Pausezeitpunkt (für genauen Snapshot)

	// runningCueIDs: Menge aller gerade ausführenden Cue-IDs.
	// Bei normalen Cues: {activeCueId}; bei Group-Cues: {groupId} ∪ {childIds…}
	runningCueIDs map[string]struct{}
}

func (e *Engine) addRunning(ids ...string) {
	if e.runningCueIDs == nil {
		e.runningCueIDs = make(map[string]struct{})
	}
	for _, id := range ids {
		e.runningCueIDs[id] = struct{}{}
	}
}

func (e *Engine) removeRunning(ids ...string) {
	for _, id := range ids {
		delete(e.runningCueIDs, id)
	}
}

func (e *Engine) runningCueIDsList() []string {
	ids := make([]string, 0, len(e.runningCueIDs))
	for id := range e.runningCueIDs {
		ids = append(ids, id)
	}
	return ids
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
	if e.paused {
		// Effektive Startzeit = Pausezeitpunkt minus bereits vergangene Zeit.
		ts.CueStartedAtMs = e.pausedAt.Add(-e.pausedElapsed).UnixMilli()
		ts.PausedAtMs = e.pausedAt.UnixMilli()
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
	e.cueStartedAt = time.Time{}
	e.pausedElapsed = 0
	e.pausedAt = time.Time{}
	activeCue := e.store.GetActiveCue(e.cueListID)
	// Aktive Cue in Store löschen, damit Reconnect-Snapshots korrekt sind.
	e.store.SetActiveCue(e.cueListID, "")
	e.mu.Unlock()

	// AudioStop an alle Audio-Nodes senden (leere CueId = alle stoppen).
	if e.dispatcher != nil {
		stopCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		_ = e.dispatcher.DispatchToTask(stopCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
			SessionId: e.sessionID,
			Command: &pb.NodeCommandRequest_AudioStop{
				AudioStop: &pb.AudioStopCommand{
					CueId:     "",
					FadeOutMs: 300,
				},
			},
		})
	}

	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:        pb.ShowExecutionEvent_CUE_STOPPED,
		AffectedCue: activeCue,
		OccurredAt:  nowProto(),
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
	e.pausedAt = time.Now()
	// Bereits verstrichene Zeit festhalten, damit Resume korrekt fortsetzt.
	if !e.cueStartedAt.IsZero() {
		e.pausedElapsed = time.Since(e.cueStartedAt)
	}
	activeCue := e.store.GetActiveCue(e.cueListID)
	pausedAt := e.pausedAt
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

	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:        pb.ShowExecutionEvent_CUE_PAUSED,
		AffectedCue: activeCue,
		OccurredAt:  &pb.Timestamp{UnixMillis: pausedAt.UnixMilli()},
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
		e.store.BroadcastExec(&pb.ShowExecutionEvent{
			Type:           pb.ShowExecutionEvent_CUE_STARTED,
			AffectedCue:    activeCue,
			OccurredAt:     &pb.Timestamp{UnixMillis: newStart.UnixMilli()},
			CueStartedAtMs: newStart.UnixMilli(),
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
	e.pausedAt = time.Time{}
	e.mu.Unlock()
	e.mu.Lock()
	runningIDs := e.runningCueIDsList()
	e.mu.Unlock()
	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:           pb.ShowExecutionEvent_CUE_STARTED,
		AffectedCue:    cue,
		OccurredAt:     &pb.Timestamp{UnixMillis: startedAt.UnixMilli()},
		CueStartedAtMs: startedAt.UnixMilli(),
		RunningCueIds:  runningIDs,
	})

	e.mu.Lock()
	e.addRunning(cue.CueId)
	e.mu.Unlock()

	switch cue.CueType {
	case pb.CueType_CUE_TYPE_AUDIO:
		err = e.dispatchAudio(ctx, cue)
	case pb.CueType_CUE_TYPE_MA_OSC:
		err = e.dispatchMaOsc(ctx, cue)
	case pb.CueType_CUE_TYPE_WAIT:
		err = e.dispatchWait(ctx, cue)
	case pb.CueType_CUE_TYPE_GROUP:
		err = e.dispatchGroup(ctx, cue)
	default:
		err = ErrUnknownCueType
	}

	e.mu.Lock()
	e.removeRunning(cue.CueId)
	e.mu.Unlock()

	// Abgebrochen (Stop/Pause hat den Context gecancelt) → KEIN DONE-Event.
	// Sonst würde der Client die aktive Cue fälschlich reaktivieren und der
	// Timer weiterlaufen. Stop/Pause senden bereits ihr eigenes Event.
	if err == context.Canceled || ctx.Err() == context.Canceled {
		return
	}

	execEvType := pb.ShowExecutionEvent_CUE_DONE
	errMsg := ""
	if err != nil {
		execEvType = pb.ShowExecutionEvent_CUE_ERROR
		errMsg = err.Error()
	}
	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:        execEvType,
		AffectedCue: cue,
		OccurredAt:  nowProto(),
		ErrorMsg:    errMsg,
	})

	// Auto-Continue: automatisch nächste Cue nach PostWait (oder Audio-Ende)
	if err == nil && cue.AutoContinue {
		waitMs := cue.PostWaitMs
		// For audio cues: if PostWaitMs==0, wait for the audio to finish
		// using declared_duration_ms (set by the client from asset metadata).
		if waitMs == 0 {
			if ap, ok := cue.Params.(*pb.Cue_Audio); ok && ap != nil {
				dur := ap.Audio.DeclaredDurationMs
				end := ap.Audio.EndTimeMs
				start := ap.Audio.StartTimeMs
				if end > 0 && end > start {
					dur = end - start
				}
				if dur > 0 {
					fade := ap.Audio.FadeOutMs
					if fade > 0 && fade < dur {
						dur -= fade / 2
					}
					waitMs = dur
				}
			}
		}
		if waitMs > 0 {
			select {
			case <-time.After(time.Duration(waitMs) * time.Millisecond):
			case <-ctx.Done():
				return
			}
		}
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

	// 1. Preload senden. asset_id (SHA-256) wird bevorzugt; file_path als Fallback.
	if params.Audio.AssetId != "" || params.Audio.FilePath != "" {
		_ = dispatch(&pb.NodeCommandRequest{
			SessionId:    e.sessionID,
			TargetNodeId: cue.TargetNodeId,
			Command: &pb.NodeCommandRequest_AudioPreload{
				AudioPreload: &pb.AudioPreloadCommand{
					CueId:    cue.CueId,
					AssetId:  params.Audio.AssetId,
					FilePath: params.Audio.FilePath,
				},
			},
		})
	}

	// 2. Play mit Server-Startzeit: Node berechnet via ClockSync ob er leicht
	// überspringen muss (Netzwerklatenz-Kompensation). StartUnixMillis = 0
	// wäre sofort, aber für Mehrfach-Node-Sync brauchen alle denselben Anker.
	e.mu.Lock()
	startMs := e.cueStartedAt.UnixMilli()
	e.mu.Unlock()

	return dispatch(&pb.NodeCommandRequest{
		SessionId:    e.sessionID,
		TargetNodeId: cue.TargetNodeId,
		Command: &pb.NodeCommandRequest_AudioPlay{
			AudioPlay: &pb.AudioPlayCommand{
				CueId:           cue.CueId,
				StartUnixMillis: startMs,
				VolumeDb:        params.Audio.VolumeDb,
				FadeInMs:        params.Audio.FadeInMs,
				FadeOutMs:       params.Audio.FadeOutMs,
				Loop:            params.Audio.Loop,
				StartTimeMs:     params.Audio.StartTimeMs,
				EndTimeMs:       params.Audio.EndTimeMs,
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
	if !ok || params == nil || (params.Audio.AssetId == "" && params.Audio.FilePath == "") {
		return
	}
	cmd := &pb.NodeCommandRequest{
		SessionId:    e.sessionID,
		TargetNodeId: cue.TargetNodeId,
		Command: &pb.NodeCommandRequest_AudioPreload{
			AudioPreload: &pb.AudioPreloadCommand{
				CueId:    cue.CueId,
				AssetId:  params.Audio.AssetId,
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

// dispatchGroup führt eine Group-Cue aus: parallel oder sequentiell.
//
// Parallel: alle Kind-Cues starten gleichzeitig; die Group ist fertig wenn
//
//	die letzte Kind-Cue abgeschlossen ist.
//
// Sequentiell: Kind-Cues laufen der Reihe nach; Abbruch bei erstem Fehler.
func (e *Engine) dispatchGroup(ctx context.Context, group *pb.Cue) error {
	params, ok := group.Params.(*pb.Cue_Group)
	if !ok || params == nil {
		return errors.New("invalid group cue params")
	}

	// Kind-Cues aus der CueList auflösen
	list, found := e.store.GetCueList(e.cueListID)
	if !found {
		return errors.New("cue list not found")
	}
	cueByID := make(map[string]*pb.Cue, len(list.Cues))
	for _, c := range list.Cues {
		cueByID[c.CueId] = c
	}

	children := make([]*pb.Cue, 0, len(params.Group.ChildCueIds))
	for _, id := range params.Group.ChildCueIds {
		if c, ok := cueByID[id]; ok {
			children = append(children, c)
		}
	}
	if len(children) == 0 {
		return nil
	}

	if params.Group.Sequential {
		return e.dispatchGroupSequential(ctx, children)
	}
	return e.dispatchGroupParallel(ctx, children)
}

func (e *Engine) dispatchGroupSequential(ctx context.Context, children []*pb.Cue) error {
	for _, child := range children {
		if ctx.Err() != nil {
			return ctx.Err()
		}
		e.mu.Lock()
		e.addRunning(child.CueId)
		e.mu.Unlock()

		e.store.BroadcastExec(&pb.ShowExecutionEvent{
			Type:          pb.ShowExecutionEvent_CUE_STARTED,
			AffectedCue:   child,
			OccurredAt:    nowProto(),
			RunningCueIds: e.runningCueIDsList(),
		})

		var err error
		switch child.CueType {
		case pb.CueType_CUE_TYPE_AUDIO:
			err = e.dispatchAudio(ctx, child)
		case pb.CueType_CUE_TYPE_MA_OSC:
			err = e.dispatchMaOsc(ctx, child)
		case pb.CueType_CUE_TYPE_WAIT:
			err = e.dispatchWait(ctx, child)
		}

		e.mu.Lock()
		e.removeRunning(child.CueId)
		ids := e.runningCueIDsList()
		e.mu.Unlock()

		execEvType := pb.ShowExecutionEvent_CUE_DONE
		errMsg := ""
		if err != nil && err != context.Canceled {
			execEvType = pb.ShowExecutionEvent_CUE_ERROR
			errMsg = err.Error()
		}
		e.store.BroadcastExec(&pb.ShowExecutionEvent{
			Type:          execEvType,
			AffectedCue:   child,
			OccurredAt:    nowProto(),
			ErrorMsg:      errMsg,
			RunningCueIds: ids,
		})

		if err != nil {
			return err
		}
	}
	return nil
}

func (e *Engine) dispatchGroupParallel(ctx context.Context, children []*pb.Cue) error {
	var wg sync.WaitGroup
	errs := make([]error, len(children))

	for i, child := range children {
		e.mu.Lock()
		e.addRunning(child.CueId)
		ids := e.runningCueIDsList()
		e.mu.Unlock()

		e.store.BroadcastExec(&pb.ShowExecutionEvent{
			Type:          pb.ShowExecutionEvent_CUE_STARTED,
			AffectedCue:   child,
			OccurredAt:    nowProto(),
			RunningCueIds: ids,
		})

		wg.Add(1)
		go func(idx int, c *pb.Cue) {
			defer wg.Done()

			var err error
			switch c.CueType {
			case pb.CueType_CUE_TYPE_AUDIO:
				err = e.dispatchAudio(ctx, c)
			case pb.CueType_CUE_TYPE_MA_OSC:
				err = e.dispatchMaOsc(ctx, c)
			case pb.CueType_CUE_TYPE_WAIT:
				err = e.dispatchWait(ctx, c)
			}
			errs[idx] = err

			e.mu.Lock()
			e.removeRunning(c.CueId)
			remaining := e.runningCueIDsList()
			e.mu.Unlock()

			execEvType := pb.ShowExecutionEvent_CUE_DONE
			errMsg := ""
			if err != nil && err != context.Canceled {
				execEvType = pb.ShowExecutionEvent_CUE_ERROR
				errMsg = err.Error()
			}
			e.store.BroadcastExec(&pb.ShowExecutionEvent{
				Type:          execEvType,
				AffectedCue:   c,
				OccurredAt:    nowProto(),
				ErrorMsg:      errMsg,
				RunningCueIds: remaining,
			})
		}(i, child)
	}

	wg.Wait()

	for _, err := range errs {
		if err != nil && err != context.Canceled {
			return err
		}
	}
	return ctx.Err()
}
