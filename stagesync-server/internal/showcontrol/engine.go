package showcontrol

import (
	"context"
	"errors"
	"log"
	"sync"
	"time"

	pb "stagesync-server/gen/go/stagesync/v1"
)

var (
	ErrNoCue          = errors.New("no cue to execute")
	ErrUnknownCueType = errors.New("unknown cue type")
)

// AssetWarmer wärmt den Server-RAM-Cache für bevorstehende Audio-Assets vor.
type AssetWarmer interface {
	WarmAssets(ctx context.Context, assetIDs []string)
	LockForShow()
	UnlockShow()
}

const lookAheadN = 5
const PrewarmN = 3

// NodeDispatcher sendet Befehle an Nodes.
type NodeDispatcher interface {
	Dispatch(ctx context.Context, nodeID string, cmd *pb.NodeCommandRequest) error
	DispatchToTask(ctx context.Context, task pb.NodeTask, cmd *pb.NodeCommandRequest) error
}

// SilenceDetector liefert erkannte Stille-Offsets für Audio-Assets.
type SilenceDetector interface {
	AssetSilenceStartMs(assetID string) (int64, bool)
}

// ── Transport State Machine ───────────────────────────────────────────────────

// transportPhase ist die explizite Phase des Transport-Zustandsautomaten.
// Ungültige Kombinationen (z.B. paused+not-running) sind durch den Typ ausgeschlossen.
type transportPhase int

const (
	phaseIdle    transportPhase = iota // nichts läuft
	phaseRunning                        // Cue spielt
	phasePaused                         // global pausiert
)

// transport bündelt alle veränderlichen Transport-Felder in einem einzigen Struct.
// Zugriff ausschließlich unter Engine.mu.
//
// Invarianten:
//   - phaseIdle:    cue=nil, startedAt=zero, frozenElapsed=0
//   - phaseRunning: cue≠nil, startedAt gesetzt nach Pre-Wait, frozenElapsed=0
//   - phasePaused:  cue≠nil, startedAt gesetzt, frozenElapsed>0 (inkl. Fade-Dauer)
type transport struct {
	phase         transportPhase
	cue           *pb.Cue
	startedAt     time.Time     // effektive Startzeit (wird bei Resume angepasst)
	frozenElapsed time.Duration // bei phasePaused: verstrichene Zeit inkl. Fade-Dauer
}

// ── Engine ────────────────────────────────────────────────────────────────────

// Engine ist das Show-Control-Herzstück einer Session.
type Engine struct {
	mu              sync.Mutex
	store           *Store
	dispatcher      NodeDispatcher
	warmer          AssetWarmer
	silenceDetector SilenceDetector
	sessionID       string
	cueListID       string

	cancelFn context.CancelFunc

	// tp ist die einzige autoritative Quelle des Transport-Zustands.
	// Alle Go/Stop/Pause/Resume-Methoden mutieren ausschließlich tp (unter mu).
	tp transport

	// runningCueIDs: Menge aller gerade ausführenden Cue-IDs.
	runningCueIDs   map[string]struct{}
	perCuePausedIDs map[string]struct{}

	// audioTrackers: pausierbare Countdown-Goroutinen pro laufender Audio-Cue.
	audioTrackers sync.Map // map[cueID string]*audioTrackerEntry
}

type audioTrackerEntry struct {
	cancel   context.CancelFunc
	pauseCh  chan struct{} // gepuffert(1): Engine → Tracker: Timer einfrieren
	resumeCh chan struct{} // gepuffert(1): Engine → Tracker: Timer fortsetzen
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

func (e *Engine) addPerCuePaused(id string) {
	if e.perCuePausedIDs == nil {
		e.perCuePausedIDs = make(map[string]struct{})
	}
	e.perCuePausedIDs[id] = struct{}{}
}

func (e *Engine) removePerCuePaused(id string) {
	delete(e.perCuePausedIDs, id)
}

func (e *Engine) perCuePausedIDsList() []string {
	ids := make([]string, 0, len(e.perCuePausedIDs))
	for id := range e.perCuePausedIDs {
		ids = append(ids, id)
	}
	return ids
}

// PauseCueTracker markiert eine Cue als per-Cue-pausiert, friert ihren Tracker-Timer
// ein und broadcastet CUE_CUE_PAUSED.
func (e *Engine) PauseCueTracker(cueId string, fadeOutMs float64) {
	e.mu.Lock()
	e.addPerCuePaused(cueId)
	pausedIds := e.perCuePausedIDsList()
	runningIds := e.runningCueIDsList()
	e.mu.Unlock()

	// Tracker-Timer einfrieren — sonst läuft der Countdown während die Cue pausiert ist.
	if entry, ok := e.audioTrackers.Load(cueId); ok {
		select {
		case entry.(*audioTrackerEntry).pauseCh <- struct{}{}:
		default:
		}
	}

	effectivePausedMs := time.Now().UnixMilli() + int64(fadeOutMs)
	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:            pb.ShowExecutionEvent_CUE_CUE_PAUSED,
		AffectedCue:     &pb.Cue{CueId: cueId},
		OccurredAt:      &pb.Timestamp{UnixMillis: effectivePausedMs},
		RunningCueIds:   runningIds,
		PerCuePausedIds: pausedIds,
	})
}

// ResumeCueTracker hebt per-Cue-Pause auf, setzt den Tracker-Timer fort und
// broadcastet CUE_CUE_RESUMED.
func (e *Engine) ResumeCueTracker(cueId string, fadeInMs float64) {
	e.mu.Lock()
	e.removePerCuePaused(cueId)
	pausedIds := e.perCuePausedIDsList()
	runningIds := e.runningCueIDsList()
	e.mu.Unlock()

	// Tracker-Timer fortsetzen.
	if entry, ok := e.audioTrackers.Load(cueId); ok {
		select {
		case entry.(*audioTrackerEntry).resumeCh <- struct{}{}:
		default:
		}
	}

	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:            pb.ShowExecutionEvent_CUE_CUE_RESUMED,
		AffectedCue:     &pb.Cue{CueId: cueId},
		OccurredAt:      nowProto(),
		RunningCueIds:   runningIds,
		PerCuePausedIds: pausedIds,
	})
}

func NewEngine(sessionID, cueListID string, store *Store, dispatcher NodeDispatcher) *Engine {
	return &Engine{
		store:      store,
		dispatcher: dispatcher,
		sessionID:  sessionID,
		cueListID:  cueListID,
	}
}

func (e *Engine) SetWarmer(w AssetWarmer) {
	e.mu.Lock()
	e.warmer = w
	e.mu.Unlock()
}

func (e *Engine) SetSilenceDetector(d SilenceDetector) {
	e.mu.Lock()
	e.silenceDetector = d
	e.mu.Unlock()
}

// TransportSnapshot liefert den aktuellen Zustand für einen neu verbundenen Watcher.
// Liest ausschließlich aus e.tp — keine doppelten Lock-Regionen.
type TransportSnapshot struct {
	ActiveCue       *pb.Cue
	Running         bool
	Paused          bool
	CueStartedAtMs  int64
	PausedAtMs      int64
	PerCuePausedIDs []string
}

func (e *Engine) TransportSnapshot() TransportSnapshot {
	e.mu.Lock()
	defer e.mu.Unlock()

	tp := e.tp
	ts := TransportSnapshot{
		ActiveCue:       e.store.GetActiveCue(e.cueListID),
		Running:         tp.phase != phaseIdle,
		Paused:          tp.phase == phasePaused,
		PerCuePausedIDs: e.perCuePausedIDsList(),
	}

	switch tp.phase {
	case phaseRunning:
		if !tp.startedAt.IsZero() {
			ts.CueStartedAtMs = tp.startedAt.UnixMilli()
		}
	case phasePaused:
		// CueStartedAtMs = tatsächlicher Startzeit-Anker (unveränderlich).
		ts.CueStartedAtMs = tp.startedAt.UnixMilli()
		// PausedAtMs = startedAt + frozenElapsed = Zeitpunkt des Einfrierens (inkl. Fade).
		ts.PausedAtMs = tp.startedAt.Add(tp.frozenElapsed).UnixMilli()
	}
	return ts
}

// ── Go ────────────────────────────────────────────────────────────────────────

func (e *Engine) Go(ctx context.Context, cueID string) (*pb.Cue, *pb.Cue, error) {
	// 1. Cue ermitteln (Store-Ops sind thread-safe)
	var cue *pb.Cue

	if cueID != "" {
		list, found := e.store.GetCueList(e.cueListID)
		if !found {
			return nil, nil, errors.New("cue list not found")
		}
		for _, c := range list.Cues {
			if c.CueId == cueID {
				cue = c
				break
			}
		}
	} else {
		var ok bool
		cue, ok = e.store.NextCue(e.cueListID)
		if !ok || cue == nil {
			return nil, nil, ErrNoCue
		}
	}
	if cue == nil {
		return nil, nil, ErrNoCue
	}

	e.store.SetActiveCue(e.cueListID, cue.CueId)

	// 2. Transport-State atomisch setzen (eine einzige Lock-Region)
	e.mu.Lock()
	wasRunning := e.tp.phase != phaseIdle
	if e.cancelFn != nil {
		e.cancelFn()
		e.cancelFn = nil
	}
	execCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	e.cancelFn = cancel
	// Startzeit wird erst in dispatchCue() nach Pre-Wait gesetzt.
	e.tp = transport{phase: phaseRunning, cue: cue}
	warmer := e.warmer
	e.mu.Unlock()

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

	if next != nil {
		go e.armCue(context.Background(), next)
	}

	if warmer != nil {
		if !wasRunning {
			warmer.LockForShow()
		}
		assetIDs := e.lookAheadAssetIDs(list, cue.CueId, lookAheadN)
		if len(assetIDs) > 0 {
			go warmer.WarmAssets(context.Background(), assetIDs)
		}
	}

	return cue, next, nil
}

// ── Stop ──────────────────────────────────────────────────────────────────────

// Stop hält alle laufenden Cues an. Einzelne Lock-Region: runningCueIDs wird
// atomar gecaptured und gecleart, bevor Tracker-Goroutinen gecancelt werden.
func (e *Engine) Stop(ctx context.Context) error {
	e.mu.Lock()
	if e.cancelFn != nil {
		e.cancelFn()
		e.cancelFn = nil
	}
	e.tp = transport{} // → phaseIdle
	activeCue := e.store.GetActiveCue(e.cueListID)
	e.store.SetActiveCue(e.cueListID, "")
	warmer := e.warmer
	// Capture und clear in einer atomischen Operation: kein Race mit Tracker-Goroutinen.
	oldRunning := e.runningCueIDs
	e.runningCueIDs = make(map[string]struct{})
	e.perCuePausedIDs = make(map[string]struct{})
	e.mu.Unlock()

	// Tracker anhand der gecapturten Map canceln — außerhalb des Locks.
	for id := range oldRunning {
		if entry, loaded := e.audioTrackers.LoadAndDelete(id); loaded {
			entry.(*audioTrackerEntry).cancel()
		}
	}
	// Restliche Tracker (z.B. Re-Trigger ohne runningCueID-Eintrag) ebenfalls canceln.
	e.audioTrackers.Range(func(k, v any) bool {
		v.(*audioTrackerEntry).cancel()
		e.audioTrackers.Delete(k)
		return true
	})

	if warmer != nil {
		warmer.UnlockShow()
	}

	if e.dispatcher != nil {
		stopCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		_ = e.dispatcher.DispatchToTask(stopCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
			SessionId: e.sessionID,
			Command: &pb.NodeCommandRequest_AudioStop{
				AudioStop: &pb.AudioStopCommand{CueId: "", FadeOutMs: 300},
			},
		})
	}

	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:        pb.ShowExecutionEvent_CUE_STOPPED,
		AffectedCue: activeCue,
		OccurredAt:  nowProto(),
	})

	go e.reArmNext()
	return nil
}

func (e *Engine) reArmNext() {
	next, ok := e.store.NextCue(e.cueListID)
	if !ok || next == nil {
		return
	}
	e.armCue(context.Background(), next)
}

// StopCueTracker bricht den Audio-Tracker einer einzelnen Cue ab und broadcastet CUE_DONE.
func (e *Engine) StopCueTracker(cueId string) {
	if entry, loaded := e.audioTrackers.LoadAndDelete(cueId); loaded {
		entry.(*audioTrackerEntry).cancel()
	}

	e.mu.Lock()
	e.removeRunning(cueId)
	e.removePerCuePaused(cueId)
	ids := e.runningCueIDsList()
	e.mu.Unlock()

	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:          pb.ShowExecutionEvent_CUE_DONE,
		AffectedCue:   &pb.Cue{CueId: cueId},
		OccurredAt:    nowProto(),
		RunningCueIds: ids,
	})
}

// ── Pause ─────────────────────────────────────────────────────────────────────

const (
	pauseFadeMs  = 120
	resumeFadeMs = 120
)

// Pause hält die aktuelle Cue an. Einzelne Lock-Region: frozenElapsed wird
// atomar mit der phase auf phasePaused gesetzt — kein doppelter Lock-Acquire.
func (e *Engine) Pause(ctx context.Context) error {
	// Fade-Parameter aus aktiver Cue lesen (Store-Op ist thread-safe)
	activeCue := e.store.GetActiveCue(e.cueListID)
	fadeOut := float64(pauseFadeMs)
	if activeCue != nil {
		if ap, ok := activeCue.Params.(*pb.Cue_Audio); ok && ap != nil {
			if ap.Audio.PauseBehavior == pb.AudioCueParams_PAUSE_FADE_OUT && ap.Audio.PauseFadeMs > 0 {
				fadeOut = ap.Audio.PauseFadeMs
			}
		}
	}

	// Einzige Lock-Region: phase + frozenElapsed atomar setzen.
	e.mu.Lock()
	if e.tp.phase != phaseRunning {
		e.mu.Unlock()
		return nil
	}
	if e.cancelFn != nil {
		e.cancelFn()
		e.cancelFn = nil
	}
	now := time.Now()
	var frozenElapsed time.Duration
	if e.tp.startedAt.IsZero() {
		// Cue ist noch im Pre-Wait — kein Audio läuft, nur Fade-Dauer merken.
		frozenElapsed = time.Duration(fadeOut) * time.Millisecond
	} else {
		// Tatsächlich verstrichene Zeit + Fade-Dauer: Audio spielt während Fade weiter.
		frozenElapsed = now.Sub(e.tp.startedAt) + time.Duration(fadeOut)*time.Millisecond
	}
	e.tp.phase = phasePaused
	e.tp.frozenElapsed = frozenElapsed
	e.mu.Unlock()

	// Audio anhalten + Tracker einfrieren + Broadcast — alles außerhalb des Locks.
	if activeCue != nil && e.dispatcher != nil {
		opCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = e.dispatcher.DispatchToTask(opCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
			SessionId: e.sessionID,
			Command: &pb.NodeCommandRequest_AudioPause{
				AudioPause: &pb.AudioPauseCommand{
					CueId:     activeCue.CueId,
					FadeOutMs: fadeOut,
				},
			},
		})
	}

	e.audioTrackers.Range(func(k, v any) bool {
		entry := v.(*audioTrackerEntry)
		select {
		case entry.pauseCh <- struct{}{}:
		default:
		}
		return true
	})

	// OccurredAt = jetzt + Fade-Dauer: Clients frieren den Timer exakt am Stummschalt-Ende ein.
	effectivePausedMs := time.Now().UnixMilli() + int64(fadeOut)
	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:        pb.ShowExecutionEvent_CUE_PAUSED,
		AffectedCue: activeCue,
		OccurredAt:  &pb.Timestamp{UnixMillis: effectivePausedMs},
	})
	return nil
}

// ── Resume ────────────────────────────────────────────────────────────────────

// Resume setzt eine pausierte Cue fort. Einzelne Lock-Region: newStart wird
// atomar aus frozenElapsed berechnet und der Phase auf phaseRunning gewechselt.
func (e *Engine) Resume(ctx context.Context) error {
	activeCue := e.store.GetActiveCue(e.cueListID)

	fadeIn := float64(resumeFadeMs)
	if activeCue != nil {
		if ap, ok := activeCue.Params.(*pb.Cue_Audio); ok && ap != nil {
			switch ap.Audio.ResumeBehavior {
			case pb.AudioCueParams_RESUME_FADE_IN:
				if ap.Audio.ResumeFadeMs > 0 {
					fadeIn = ap.Audio.ResumeFadeMs
				}
			case pb.AudioCueParams_RESUME_FROM_START:
				return e.resumeFromStart(ctx, activeCue)
			}
		}
	}

	now := time.Now()
	var newStart time.Time
	var execCtx context.Context

	e.mu.Lock()
	if e.tp.phase != phasePaused {
		e.mu.Unlock()
		return nil
	}
	var cancel context.CancelFunc
	execCtx, cancel = context.WithTimeout(ctx, 30*time.Second)
	e.cancelFn = cancel
	// newStart so rekonstruieren dass die verstrichene Zeit konsistent weiterläuft.
	newStart = now.Add(-e.tp.frozenElapsed)
	e.tp.phase = phaseRunning
	e.tp.startedAt = newStart
	e.tp.frozenElapsed = 0
	e.mu.Unlock()

	_ = execCtx // wird nur von dispatchCue-Goroutinen benötigt; hier kein neuer Dispatch

	if activeCue != nil && e.dispatcher != nil {
		opCtx, cancel2 := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel2()
		_ = e.dispatcher.DispatchToTask(opCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
			SessionId: e.sessionID,
			Command: &pb.NodeCommandRequest_AudioResume{
				AudioResume: &pb.AudioResumeCommand{
					CueId:    activeCue.CueId,
					FadeInMs: fadeIn,
				},
			},
		})
	}

	e.audioTrackers.Range(func(k, v any) bool {
		entry := v.(*audioTrackerEntry)
		select {
		case entry.resumeCh <- struct{}{}:
		default:
		}
		return true
	})

	if activeCue != nil {
		e.store.BroadcastExec(&pb.ShowExecutionEvent{
			Type:           pb.ShowExecutionEvent_CUE_STARTED,
			AffectedCue:    activeCue,
			OccurredAt:     &pb.Timestamp{UnixMillis: newStart.UnixMilli()},
			CueStartedAtMs: newStart.UnixMilli(),
		})
	}
	return nil
}

// resumeFromStart stoppt die aktuelle Audio und startet sie von vorne.
// Broadcastet CUE_STARTED mit neuem Zeitstempel — vorher fehlender Broadcast behoben.
func (e *Engine) resumeFromStart(ctx context.Context, activeCue *pb.Cue) error {
	newStart := time.Now()

	e.mu.Lock()
	if e.cancelFn != nil {
		e.cancelFn()
		e.cancelFn = nil
	}
	execCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	e.cancelFn = cancel
	e.tp.phase = phaseRunning
	e.tp.startedAt = newStart
	e.tp.frozenElapsed = 0
	e.mu.Unlock()

	if e.dispatcher != nil {
		_ = e.dispatcher.DispatchToTask(context.Background(), pb.NodeTask_NODE_TASK_AUDIO_OUTPUT,
			&pb.NodeCommandRequest{
				SessionId: e.sessionID,
				Command: &pb.NodeCommandRequest_AudioStop{
					AudioStop: &pb.AudioStopCommand{CueId: activeCue.CueId},
				},
			})
		_ = e.dispatchAudio(execCtx, activeCue)
	}

	// CUE_STARTED mit neuem Zeitstempel: alle Clients setzen Fortschrittsbalken zurück.
	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:           pb.ShowExecutionEvent_CUE_STARTED,
		AffectedCue:    activeCue,
		OccurredAt:     &pb.Timestamp{UnixMillis: newStart.UnixMilli()},
		CueStartedAtMs: newStart.UnixMilli(),
	})
	return nil
}

// ── dispatchCue ───────────────────────────────────────────────────────────────

func (e *Engine) dispatchCue(ctx context.Context, cue *pb.Cue) {
	log.Printf("[engine] dispatchCue %s/%q type=%s target=%q",
		cue.Number, cue.Label, cue.CueType, cue.LogicalOutputId)

	if cue.PreWaitMs > 0 {
		select {
		case <-time.After(time.Duration(cue.PreWaitMs) * time.Millisecond):
		case <-ctx.Done():
			return
		}
	}

	// Startzeit nach Pre-Wait setzen (autoritativer Zeitpunkt für alle Clients).
	startedAt := time.Now()
	e.mu.Lock()
	// Nur updaten wenn wir noch die aktive Cue sind (nicht durch ein neues GO überschrieben).
	if e.tp.phase == phaseRunning && e.tp.cue != nil && e.tp.cue.CueId == cue.CueId {
		e.tp.startedAt = startedAt
		e.tp.frozenElapsed = 0
	}
	e.addRunning(cue.CueId)
	runningIDs := e.runningCueIDsList()
	e.mu.Unlock()

	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:           pb.ShowExecutionEvent_CUE_STARTED,
		AffectedCue:    cue,
		OccurredAt:     &pb.Timestamp{UnixMillis: startedAt.UnixMilli()},
		CueStartedAtMs: startedAt.UnixMilli(),
		RunningCueIds:  runningIDs,
	})

	effectiveType := cue.CueType
	if effectiveType == pb.CueType_CUE_TYPE_UNSPECIFIED {
		switch cue.Params.(type) {
		case *pb.Cue_Audio:
			effectiveType = pb.CueType_CUE_TYPE_AUDIO
		case *pb.Cue_MaOsc:
			effectiveType = pb.CueType_CUE_TYPE_MA_OSC
		case *pb.Cue_Wait:
			effectiveType = pb.CueType_CUE_TYPE_WAIT
		case *pb.Cue_Group:
			effectiveType = pb.CueType_CUE_TYPE_GROUP
		case *pb.Cue_GotoP:
			effectiveType = pb.CueType_CUE_TYPE_GOTO
		}
		if effectiveType != pb.CueType_CUE_TYPE_UNSPECIFIED {
			log.Printf("[engine] Cue %s/%q: cue_type=UNSPECIFIED, aus params inferiert: %s",
				cue.Number, cue.Label, effectiveType)
		}
	}

	var err error
	skipNote := false // übersprungene Note → wie AutoContinue
	switch effectiveType {
	case pb.CueType_CUE_TYPE_AUDIO:
		err = e.dispatchAudio(ctx, cue)
	case pb.CueType_CUE_TYPE_MA_OSC:
		err = e.dispatchMaOsc(ctx, cue)
	case pb.CueType_CUE_TYPE_WAIT:
		err = e.dispatchWait(ctx, cue)
	case pb.CueType_CUE_TYPE_GROUP:
		err = e.dispatchGroup(ctx, cue)
	case pb.CueType_CUE_TYPE_NOTE:
		if np, ok := cue.Params.(*pb.Cue_Note); ok && np.Note != nil && np.Note.Landable {
			log.Printf("[engine] Cue %s/%q: Note landable → wartet auf nächstes GO", cue.Number, cue.Label)
			<-ctx.Done()
			err = ctx.Err()
		} else {
			log.Printf("[engine] Cue %s/%q: Note → übersprungen, starte nächste Cue", cue.Number, cue.Label)
			skipNote = true
			err = nil
		}
	case pb.CueType_CUE_TYPE_FADE:
		err = e.dispatchFade(ctx, cue)
	default:
		log.Printf("[engine] Cue %s/%q: unbekannter Typ %s (params=%T) → übersprungen",
			cue.Number, cue.Label, cue.CueType, cue.Params)
		err = ErrUnknownCueType
	}

	e.mu.Lock()
	_, isAudioTracked := e.audioTrackers.Load(cue.CueId)
	if !isAudioTracked {
		e.removeRunning(cue.CueId)
	}
	remainingIDs := e.runningCueIDsList()
	e.mu.Unlock()

	if isAudioTracked {
		return
	}

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
		Type:          execEvType,
		AffectedCue:   cue,
		OccurredAt:    nowProto(),
		ErrorMsg:      errMsg,
		RunningCueIds: remainingIDs,
	})

	if err == nil && (cue.AutoContinue || skipNote) {
		if cue.PostWaitMs > 0 {
			select {
			case <-time.After(time.Duration(cue.PostWaitMs) * time.Millisecond):
			case <-ctx.Done():
				return
			}
		}
		_, _, _ = e.Go(ctx, "")
	}
}

// ── dispatchAudio ─────────────────────────────────────────────────────────────

func (e *Engine) dispatchAudio(ctx context.Context, cue *pb.Cue) error {
	params, ok := cue.Params.(*pb.Cue_Audio)
	if !ok || params == nil {
		return errors.New("invalid audio cue params")
	}
	if e.dispatcher == nil {
		return errors.New("no dispatcher")
	}

	sendCtx := context.Background()

	dispatch := func(cmd *pb.NodeCommandRequest) error {
		if cue.TargetNodeId != "" {
			return e.dispatcher.Dispatch(sendCtx, cue.TargetNodeId, cmd)
		}
		return e.dispatcher.DispatchToTask(sendCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd)
	}

	assetDesc := params.Audio.AssetId
	if len(assetDesc) > 8 {
		assetDesc = assetDesc[:8] + "..."
	}
	if assetDesc == "" {
		assetDesc = params.Audio.FilePath
	}
	routeDesc := "task:AUDIO_OUTPUT"
	if cue.TargetNodeId != "" {
		routeDesc = "node:" + cue.TargetNodeId
	}
	log.Printf("[engine] dispatchAudio cueId=%s asset=%s route=%s vol=%.1fdB loop=%v",
		cue.CueId, assetDesc, routeDesc, params.Audio.VolumeDb, params.Audio.Loop)

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

	e.mu.Lock()
	startMs := e.tp.startedAt.UnixMilli()
	sd := e.silenceDetector
	e.mu.Unlock()

	effectiveStartMs := params.Audio.StartTimeMs
	if effectiveStartMs == 0 && sd != nil && params.Audio.AssetId != "" {
		if silenceMs, ok := sd.AssetSilenceStartMs(params.Audio.AssetId); ok {
			effectiveStartMs = float64(silenceMs)
			log.Printf("[engine] autoSkipSilence cueId=%s: startTimeMs=%.0fms", cue.CueId, effectiveStartMs)
		}
	}

	if err := dispatch(&pb.NodeCommandRequest{
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
				StartTimeMs:     effectiveStartMs,
				EndTimeMs:       params.Audio.EndTimeMs,
			},
		},
	}); err != nil {
		return err
	}

	if !params.Audio.Loop {
		waitMs := params.Audio.DeclaredDurationMs
		end := params.Audio.EndTimeMs
		start := params.Audio.StartTimeMs
		if end > 0 && end > start {
			waitMs = end - start
		} else if waitMs > 0 && effectiveStartMs > 0 {
			if rem := waitMs - effectiveStartMs; rem > 0 {
				waitMs = rem
			}
		}
		if waitMs > 0 {
			if old, loaded := e.audioTrackers.LoadAndDelete(cue.CueId); loaded {
				old.(*audioTrackerEntry).cancel()
			}
			trackCtx, trackCancel := context.WithCancel(context.Background())
			entry := &audioTrackerEntry{
				cancel:   trackCancel,
				pauseCh:  make(chan struct{}, 1),
				resumeCh: make(chan struct{}, 1),
			}
			e.audioTrackers.Store(cue.CueId, entry)

			autoContinue := cue.AutoContinue
			postWaitMs := cue.PostWaitMs
			cueSnapshot := cue

			go func() {
				defer e.audioTrackers.CompareAndDelete(cueSnapshot.CueId, entry)

				remaining := time.Duration(waitMs) * time.Millisecond
				for {
					timer := time.NewTimer(remaining)
					timerStarted := time.Now()

					select {
					case <-timer.C:

					case <-entry.pauseCh:
						timer.Stop()
						select {
						case <-timer.C:
						default:
						}
						elapsed := time.Since(timerStarted)
						remaining -= elapsed
						if remaining < 0 {
							remaining = 0
						}
						select {
						case <-entry.resumeCh:
							continue
						case <-trackCtx.Done():
							return
						}

					case <-trackCtx.Done():
						timer.Stop()
						return
					}

					e.mu.Lock()
					e.removeRunning(cueSnapshot.CueId)
					ids := e.runningCueIDsList()
					e.mu.Unlock()

					e.store.BroadcastExec(&pb.ShowExecutionEvent{
						Type:          pb.ShowExecutionEvent_CUE_DONE,
						AffectedCue:   cueSnapshot,
						OccurredAt:    nowProto(),
						RunningCueIds: ids,
					})

					if autoContinue {
						if postWaitMs > 0 {
							postTimer := time.NewTimer(time.Duration(postWaitMs) * time.Millisecond)
							select {
							case <-postTimer.C:
								postTimer.Stop()
							case <-trackCtx.Done():
								postTimer.Stop()
								return
							}
						}
						_, _, _ = e.Go(context.Background(), "")
					}
					return
				}
			}()
		}
	}
	return nil
}

// ── ArmCue / ArmAll ───────────────────────────────────────────────────────────

func (e *Engine) ArmAll(ctx context.Context) {
	list, found := e.store.GetCueList(e.cueListID)
	if !found || list == nil {
		return
	}
	count := 0
	for _, cue := range list.Cues {
		if cue.CueType != pb.CueType_CUE_TYPE_AUDIO {
			if _, ok := cue.Params.(*pb.Cue_Audio); !ok {
				continue
			}
		}
		e.armCue(ctx, cue)
		count++
	}
	if count > 0 {
		log.Printf("[engine] armAll: %d Audio-Cues an Nodes gesendet", count)
	}
}

func (e *Engine) ArmCue(ctx context.Context, cue *pb.Cue) { e.armCue(ctx, cue) }

func (e *Engine) LiveUpdateVolume(cueID, targetNodeID string, volumeDb float64) {
	if e.dispatcher == nil {
		return
	}
	cmd := &pb.NodeCommandRequest{
		SessionId:    e.sessionID,
		TargetNodeId: targetNodeID,
		Command: &pb.NodeCommandRequest_AudioFade{
			AudioFade: &pb.AudioFadeCommand{
				CueId:          cueID,
				TargetVolumeDb: volumeDb,
				DurationMs:     0,
			},
		},
	}
	ctx := context.Background()
	if targetNodeID != "" {
		_ = e.dispatcher.Dispatch(ctx, targetNodeID, cmd)
	} else {
		_ = e.dispatcher.DispatchToTask(ctx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd)
	}
}

func (e *Engine) armCue(_ context.Context, cue *pb.Cue) {
	if cue == nil || e.dispatcher == nil {
		return
	}
	isAudio := cue.CueType == pb.CueType_CUE_TYPE_AUDIO
	if !isAudio {
		_, isAudio = cue.Params.(*pb.Cue_Audio)
	}
	if !isAudio {
		return
	}
	params, ok := cue.Params.(*pb.Cue_Audio)
	if !ok || params == nil || (params.Audio.AssetId == "" && params.Audio.FilePath == "") {
		return
	}
	log.Printf("[engine] armCue %s/%q", cue.Number, cue.Label)
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
	bgCtx := context.Background()
	if cue.TargetNodeId != "" {
		_ = e.dispatcher.Dispatch(bgCtx, cue.TargetNodeId, cmd)
	} else {
		_ = e.dispatcher.DispatchToTask(bgCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd)
	}
}

// ── Per-Cue Audio Dispatch (server-seitig) ────────────────────────────────────

// DispatchPauseCueAudio pausiert eine einzelne Cue direkt vom Server aus.
// Setzt Engine-State atomar VOR dem Node-Dispatch → Echo-Back ist idempotent.
func (e *Engine) DispatchPauseCueAudio(ctx context.Context, cueID string, fadeOutMs float64) error {
	if e.dispatcher == nil {
		return errors.New("no dispatcher")
	}
	cue := e.resolveCue(cueID)

	// State atomar setzen bevor der Befehl den Node erreicht.
	e.mu.Lock()
	e.addPerCuePaused(cueID)
	pausedIds := e.perCuePausedIDsList()
	runningIds := e.runningCueIDsList()
	e.mu.Unlock()

	// Tracker-Timer einfrieren bevor der Node-Befehl abgesendet wird.
	if entry, ok := e.audioTrackers.Load(cueID); ok {
		select {
		case entry.(*audioTrackerEntry).pauseCh <- struct{}{}:
		default:
		}
	}

	sendCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	cmd := &pb.NodeCommandRequest{
		SessionId: e.sessionID,
		Command: &pb.NodeCommandRequest_AudioPause{
			AudioPause: &pb.AudioPauseCommand{CueId: cueID, FadeOutMs: fadeOutMs},
		},
	}
	var err error
	if cue != nil && cue.TargetNodeId != "" {
		err = e.dispatcher.Dispatch(sendCtx, cue.TargetNodeId, cmd)
	} else {
		err = e.dispatcher.DispatchToTask(sendCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd)
	}

	effectivePausedMs := time.Now().UnixMilli() + int64(fadeOutMs)
	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:            pb.ShowExecutionEvent_CUE_CUE_PAUSED,
		AffectedCue:     &pb.Cue{CueId: cueID},
		OccurredAt:      &pb.Timestamp{UnixMillis: effectivePausedMs},
		RunningCueIds:   runningIds,
		PerCuePausedIds: pausedIds,
	})
	return err
}

// DispatchResumeCueAudio setzt eine per-Cue-pausierte Cue fort.
func (e *Engine) DispatchResumeCueAudio(ctx context.Context, cueID string, fadeInMs float64) error {
	if e.dispatcher == nil {
		return errors.New("no dispatcher")
	}
	cue := e.resolveCue(cueID)

	e.mu.Lock()
	e.removePerCuePaused(cueID)
	pausedIds := e.perCuePausedIDsList()
	runningIds := e.runningCueIDsList()
	e.mu.Unlock()

	// Tracker-Timer fortsetzen.
	if entry, ok := e.audioTrackers.Load(cueID); ok {
		select {
		case entry.(*audioTrackerEntry).resumeCh <- struct{}{}:
		default:
		}
	}

	sendCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	cmd := &pb.NodeCommandRequest{
		SessionId: e.sessionID,
		Command: &pb.NodeCommandRequest_AudioResume{
			AudioResume: &pb.AudioResumeCommand{CueId: cueID, FadeInMs: fadeInMs},
		},
	}
	var err error
	if cue != nil && cue.TargetNodeId != "" {
		err = e.dispatcher.Dispatch(sendCtx, cue.TargetNodeId, cmd)
	} else {
		err = e.dispatcher.DispatchToTask(sendCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd)
	}

	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:            pb.ShowExecutionEvent_CUE_CUE_RESUMED,
		AffectedCue:     &pb.Cue{CueId: cueID},
		OccurredAt:      nowProto(),
		RunningCueIds:   runningIds,
		PerCuePausedIds: pausedIds,
	})
	return err
}

// DispatchStopCueAudio stoppt eine einzelne Cue und broadcastet CUE_DONE.
func (e *Engine) DispatchStopCueAudio(ctx context.Context, cueID string, fadeOutMs float64) error {
	if e.dispatcher == nil {
		return errors.New("no dispatcher")
	}
	cue := e.resolveCue(cueID)

	// Tracker abbrechen
	if entry, loaded := e.audioTrackers.LoadAndDelete(cueID); loaded {
		entry.(*audioTrackerEntry).cancel()
	}

	e.mu.Lock()
	e.removeRunning(cueID)
	e.removePerCuePaused(cueID)
	ids := e.runningCueIDsList()
	e.mu.Unlock()

	sendCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	cmd := &pb.NodeCommandRequest{
		SessionId: e.sessionID,
		Command: &pb.NodeCommandRequest_AudioStop{
			AudioStop: &pb.AudioStopCommand{CueId: cueID, FadeOutMs: fadeOutMs},
		},
	}
	var err error
	if cue != nil && cue.TargetNodeId != "" {
		err = e.dispatcher.Dispatch(sendCtx, cue.TargetNodeId, cmd)
	} else {
		err = e.dispatcher.DispatchToTask(sendCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd)
	}

	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:          pb.ShowExecutionEvent_CUE_DONE,
		AffectedCue:   &pb.Cue{CueId: cueID},
		OccurredAt:    nowProto(),
		RunningCueIds: ids,
	})
	return err
}

// resolveCue schlägt eine Cue aus der CueList auf (nil wenn nicht gefunden).
func (e *Engine) resolveCue(cueID string) *pb.Cue {
	list, found := e.store.GetCueList(e.cueListID)
	if !found {
		return nil
	}
	for _, c := range list.Cues {
		if c.CueId == cueID {
			return c
		}
	}
	return nil
}

// ── dispatchMaOsc / dispatchWait ──────────────────────────────────────────────

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

// ── dispatchFade ──────────────────────────────────────────────────────────────

// dispatchFade sendet einen Lautstärke-Fade an eine laufende Audio-Cue.
// Bug-Fix: FADE_ACTION_RESUME sendet nur AudioResume (kein zusätzliches AudioFade).
func (e *Engine) dispatchFade(ctx context.Context, cue *pb.Cue) error {
	params, ok := cue.Params.(*pb.Cue_Fade)
	if !ok || params == nil {
		return errors.New("invalid fade cue params")
	}
	if e.dispatcher == nil {
		return errors.New("no dispatcher")
	}

	fp := params.Fade
	log.Printf("[engine] dispatchFade cueId=%s → target=%s action=%s vol=%.1fdB dur=%.0fms",
		cue.CueId, fp.TargetCueId, fp.Action, fp.TargetVolumeDb, fp.DurationMs)

	sendCtx := context.Background()

	if fp.Action == pb.FadeCueParams_FADE_ACTION_RESUME {
		// Resume: nur AudioResume mit Fade-In senden — kein paralleles AudioFade.
		_ = e.dispatcher.DispatchToTask(sendCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT,
			&pb.NodeCommandRequest{
				SessionId: e.sessionID,
				Command: &pb.NodeCommandRequest_AudioResume{
					AudioResume: &pb.AudioResumeCommand{
						CueId:    fp.TargetCueId,
						FadeInMs: fp.DurationMs,
					},
				},
			})
	} else {
		// Volume/Stop/Pause: AudioFade senden.
		_ = e.dispatcher.DispatchToTask(sendCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT,
			&pb.NodeCommandRequest{
				SessionId: e.sessionID,
				Command: &pb.NodeCommandRequest_AudioFade{
					AudioFade: &pb.AudioFadeCommand{
						CueId:          fp.TargetCueId,
						TargetVolumeDb: fp.TargetVolumeDb,
						DurationMs:     fp.DurationMs,
						StopWhenDone:   fp.StopWhenDone || fp.Action == pb.FadeCueParams_FADE_ACTION_STOP,
						PauseWhenDone:  fp.Action == pb.FadeCueParams_FADE_ACTION_PAUSE,
					},
				},
			})
	}

	fadeDur := time.Duration(fp.DurationMs) * time.Millisecond
	if fadeDur <= 0 {
		return nil
	}
	select {
	case <-time.After(fadeDur):
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// ── dispatchGroup ─────────────────────────────────────────────────────────────

func (e *Engine) dispatchGroup(ctx context.Context, group *pb.Cue) error {
	params, ok := group.Params.(*pb.Cue_Group)
	if !ok || params == nil {
		return errors.New("invalid group cue params")
	}

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

		// Lock: addRunning + runningCueIDsList in einer atomischen Region.
		e.mu.Lock()
		e.addRunning(child.CueId)
		runningIDs := e.runningCueIDsList()
		e.mu.Unlock()

		e.store.BroadcastExec(&pb.ShowExecutionEvent{
			Type:          pb.ShowExecutionEvent_CUE_STARTED,
			AffectedCue:   child,
			OccurredAt:    nowProto(),
			RunningCueIds: runningIDs, // konsistente Kopie
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
	return nil
}

// ── LookAhead ─────────────────────────────────────────────────────────────────

func (e *Engine) LookAheadFromStart(list *pb.CueList, n int) []string {
	return e.lookAheadAssetIDs(list, "", n)
}

func (e *Engine) lookAheadAssetIDs(list *pb.CueList, activeCueID string, n int) []string {
	if list == nil || n <= 0 {
		return nil
	}

	cueByID := make(map[string]*pb.Cue, len(list.Cues))
	for _, c := range list.Cues {
		cueByID[c.CueId] = c
	}

	seen := make(map[string]struct{}, n)
	ids := make([]string, 0, n)
	past := activeCueID == ""

	for _, c := range list.Cues {
		if len(ids) >= n {
			break
		}
		if c.CueId == activeCueID {
			past = true
			continue
		}
		if !past {
			continue
		}
		ids = collectAssetIDs(c, cueByID, ids, seen, n)
	}
	return ids
}

func collectAssetIDs(c *pb.Cue, byID map[string]*pb.Cue, out []string, seen map[string]struct{}, max int) []string {
	switch c.CueType {
	case pb.CueType_CUE_TYPE_AUDIO:
		if ap, ok := c.Params.(*pb.Cue_Audio); ok && ap.Audio.AssetId != "" {
			id := ap.Audio.AssetId
			if _, dup := seen[id]; !dup {
				seen[id] = struct{}{}
				out = append(out, id)
			}
		}
	case pb.CueType_CUE_TYPE_GROUP:
		gp, ok := c.Params.(*pb.Cue_Group)
		if !ok || gp == nil {
			break
		}
		for _, childID := range gp.Group.ChildCueIds {
			if len(out) >= max {
				break
			}
			if child, ok := byID[childID]; ok {
				out = collectAssetIDs(child, byID, out, seen, max)
			}
		}
	}
	return out
}
