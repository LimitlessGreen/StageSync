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
// Implementiert von media.StoreWarmer; nil-sicher (Engine prüft vor Aufruf).
type AssetWarmer interface {
	WarmAssets(ctx context.Context, assetIDs []string)
	LockForShow()
	UnlockShow()
}

// lookAheadN: Anzahl Audio-Cues, die nach jedem GO vorausgeladen werden.
const lookAheadN = 5

// PrewarmN: Anzahl Audio-Cues die beim Session-Start vom Anfang vorgewärmt werden.
const PrewarmN = 3

// NodeDispatcher ist das Interface, über das die Engine Befehle an Nodes sendet.
// Implementiert von node.Dispatcher.
type NodeDispatcher interface {
	Dispatch(ctx context.Context, nodeID string, cmd *pb.NodeCommandRequest) error
	DispatchToTask(ctx context.Context, task pb.NodeTask, cmd *pb.NodeCommandRequest) error
}

// SilenceDetector liefert erkannte Stille-Offsets für Audio-Assets.
// Implementiert von audioengine.Engine via AssetSilenceStartMs.
type SilenceDetector interface {
	AssetSilenceStartMs(assetID string) (int64, bool)
}

// Engine ist das Show-Control-Herzstück einer Session.
// Sie verwaltet GO/STOP/PAUSE und koordiniert die Node-Dispatches.
type Engine struct {
	mu               sync.Mutex
	store            *Store
	dispatcher       NodeDispatcher
	warmer           AssetWarmer      // optional; nil = kein RAM-Cache-Preloading
	silenceDetector  SilenceDetector  // optional; nil = Auto-Skip deaktiviert
	sessionID        string
	cueListID        string

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
		store:      store,
		dispatcher: dispatcher,
		sessionID:  sessionID,
		cueListID:  cueListID,
	}
}

// SetWarmer setzt den Asset-Warmer (RAM-Cache-Preloader). Thread-safe.
// Kann nach NewEngine gesetzt werden; nil deaktiviert das Preloading.
func (e *Engine) SetWarmer(w AssetWarmer) {
	e.mu.Lock()
	e.warmer = w
	e.mu.Unlock()
}

// SetSilenceDetector verbindet den Stille-Detektor. Thread-safe.
// nil deaktiviert Auto-Skip-Silence für alle Cues dieser Session.
func (e *Engine) SetSilenceDetector(d SilenceDetector) {
	e.mu.Lock()
	e.silenceDetector = d
	e.mu.Unlock()
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

	wasRunning := e.running // vor State-Wechsel merken (für Show-Lock-Entscheidung)

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

	// Node-seitiges Preload: nächste Cue direkt auf den Audio-Nodes vorladen.
	if next != nil {
		go e.armCue(context.Background(), next)
	}

	// Server-RAM-Cache: nächste N Audio-Cues vorladen damit StreamFile Cache-Hits liefert.
	if w := e.warmer; w != nil {
		if !wasRunning { // erste GO dieser Show: Show-Lock aktivieren
			w.LockForShow()
		}
		assetIDs := e.lookAheadAssetIDs(list, cue.CueId, lookAheadN)
		if len(assetIDs) > 0 {
			go w.WarmAssets(context.Background(), assetIDs)
		}
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
	warmer := e.warmer
	e.mu.Unlock()

	// Show beendet → RAM-Cache darf wieder normal evicten.
	if warmer != nil {
		warmer.UnlockShow()
	}

	// AudioStop an alle Audio-Nodes senden (leere CueId = alle stoppen).
	// Background-Kontext: Stop darf nie verworfen werden.
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

	// Re-arm: nach STOP sofort die nächste Cue auf den Nodes vorpreparen,
	// damit der folgende GO ohne Preload-Wartezeit startet.
	go e.reArmNext()

	return nil
}

// reArmNext lädt die nächste (oder erste) Cue nach einem STOP sofort vor.
// Läuft im Hintergrund damit Stop() nicht blockiert wird.
func (e *Engine) reArmNext() {
	next, ok := e.store.NextCue(e.cueListID)
	if !ok || next == nil {
		return
	}
	e.armCue(context.Background(), next)
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

	// Fade-Dauer aus den Cue-Parametern lesen (falls Audio-Cue mit PauseBehavior gesetzt).
	fadeOut := float64(pauseFadeMs)
	if activeCue != nil {
		if ap, ok := activeCue.Params.(*pb.Cue_Audio); ok && ap != nil {
			if ap.Audio.PauseBehavior == pb.AudioCueParams_PAUSE_FADE_OUT && ap.Audio.PauseFadeMs > 0 {
				fadeOut = ap.Audio.PauseFadeMs
			}
		}
	}

	// Die Fade-Dauer zur bereits verstrichenen Zeit addieren: Audio spielt während
	// des Ausblendvorgangs weiter. Resume muss den Playhead hinter dem Fade-Ende
	// verankern, sonst springt der Timer beim Fortsetzen zurück.
	e.mu.Lock()
	e.pausedElapsed += time.Duration(fadeOut) * time.Millisecond
	e.mu.Unlock()

	// Audio auf allen Nodes anhalten (nicht stoppen) — mit Fade.
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

	// OccurredAt = tatsächliches Stummschalt-Ende (Zeitpunkt + Fade-Dauer).
	// Flutter-Clients frieren den Timer an dieser Position ein, nicht am Druckzeitpunkt.
	effectivePausedMs := pausedAt.UnixMilli() + int64(fadeOut)
	e.store.BroadcastExec(&pb.ShowExecutionEvent{
		Type:        pb.ShowExecutionEvent_CUE_PAUSED,
		AffectedCue: activeCue,
		OccurredAt:  &pb.Timestamp{UnixMillis: effectivePausedMs},
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

	// Fade-In-Dauer aus den Cue-Parametern lesen.
	fadeIn := float64(resumeFadeMs)
	if activeCue != nil {
		if ap, ok := activeCue.Params.(*pb.Cue_Audio); ok && ap != nil {
			if ap.Audio.ResumeBehavior == pb.AudioCueParams_RESUME_FADE_IN && ap.Audio.ResumeFadeMs > 0 {
				fadeIn = ap.Audio.ResumeFadeMs
			} else if ap.Audio.ResumeBehavior == pb.AudioCueParams_RESUME_FROM_START {
				// Von vorne: erst stoppen, dann neu starten
				_ = e.dispatcher.DispatchToTask(context.Background(), pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, &pb.NodeCommandRequest{
					SessionId: e.sessionID,
					Command: &pb.NodeCommandRequest_AudioStop{
						AudioStop: &pb.AudioStopCommand{CueId: activeCue.CueId},
					},
				})
				_ = e.dispatchAudio(context.Background(), activeCue)
				return nil
			}
		}
	}

	if activeCue != nil && e.dispatcher != nil {
		opCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
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
	log.Printf("[engine] dispatchCue %s/%q type=%s target=%q",
		cue.Number, cue.Label, cue.CueType, cue.LogicalOutputId)
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

	// Effektiven Typ ermitteln: explizit gesetzt oder aus dem oneof-Params inferieren
	// (Abwärtskompatibilität mit Cues die vor dem cue_type-Fix gespeichert wurden).
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
		// Note/Placeholder: kein Execution — sofort fertig.
		log.Printf("[engine] Cue %s/%q: Note → übersprungen", cue.Number, cue.Label)
		err = nil
	case pb.CueType_CUE_TYPE_FADE:
		err = e.dispatchFade(ctx, cue)
	default:
		log.Printf("[engine] Cue %s/%q: unbekannter Typ %s (params=%T) → übersprungen",
			cue.Number, cue.Label, cue.CueType, cue.Params)
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

	// Commands werden mit einem nicht-cancellierbaren Kontext gesendet.
	// Der execCtx (ctx) kann durch ein neues GO gecancelt werden — das darf
	// aber nicht dazu führen dass PRELOAD geht, PLAY aber verworfen wird.
	// Nur Warte-Phasen (dispatchWait, Auto-Continue) reagieren auf ctx.
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
	sd := e.silenceDetector
	e.mu.Unlock()

	// Effektive Start-Zeit: vom Nutzer gesetztes StartTimeMs, oder — wenn
	// Auto-Skip-Silence aktiv ist und kein manuelles Offset gesetzt wurde —
	// der erkannte Stille-Offset aus dem PCM-Buffer.
	effectiveStartMs := params.Audio.StartTimeMs
	if effectiveStartMs == 0 && sd != nil && params.Audio.AssetId != "" {
		if silenceMs, ok := sd.AssetSilenceStartMs(params.Audio.AssetId); ok {
			effectiveStartMs = float64(silenceMs)
			log.Printf("[engine] autoSkipSilence cueId=%s: startTimeMs=%.0fms", cue.CueId, effectiveStartMs)
		}
	}

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
				StartTimeMs:     effectiveStartMs,
				EndTimeMs:       params.Audio.EndTimeMs,
			},
		},
	})
}

// ArmAll sendet PRELOAD-Commands für alle Audio-Cues in der aktuellen CueList.
// Soll beim Session-Start und nach Cue-Listen-Änderungen aufgerufen werden,
// damit alle Assets vorab dekodiert sind und jeder GO sofort startet.
func (e *Engine) ArmAll(ctx context.Context) {
	list, found := e.store.GetCueList(e.cueListID)
	if !found || list == nil {
		return
	}
	count := 0
	for _, cue := range list.Cues {
		if cue.CueType != pb.CueType_CUE_TYPE_AUDIO {
			// Typ aus params inferieren (Abwärtskompatibilität)
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

// ArmCue lädt eine Audio-Cue auf den zuständigen Nodes vor (Preload ohne Play).
func (e *Engine) ArmCue(ctx context.Context, cue *pb.Cue) { e.armCue(ctx, cue) }

// LiveUpdateVolume wendet eine Lautstärkeänderung sofort auf eine laufende Cue an
// (duration_ms=0 = instantan). Wird von UpsertCue zusätzlich zu ArmCue gerufen.
// Wenn die Cue gerade nicht spielt, ignoriert der Audio-Node den Befehl still.
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

// armCue — interne Implementierung.
func (e *Engine) armCue(_ context.Context, cue *pb.Cue) {
	if cue == nil || e.dispatcher == nil {
		return
	}
	// Typ aus params inferieren (Abwärtskompatibilität)
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
	// Arm-Commands immer mit Background-Kontext — dürfen nie verworfen werden.
	bgCtx := context.Background()
	if cue.TargetNodeId != "" {
		_ = e.dispatcher.Dispatch(bgCtx, cue.TargetNodeId, cmd)
	} else {
		_ = e.dispatcher.DispatchToTask(bgCtx, pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd)
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

// dispatchFade sendet einen Lautstärke-Fade an eine laufende Audio-Cue.
// Nach Ablauf der Fade-Dauer kann die Ziel-Cue gestoppt oder pausiert werden.
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

	// Fade-Command an alle Audio-Nodes senden.
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

	// Bei RESUME: Resume-Command mit Fade-In statt Fade-Out senden.
	if fp.Action == pb.FadeCueParams_FADE_ACTION_RESUME {
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
	}

	// Warte die Fade-Dauer ab (damit GO-Screen Fortschritt sieht).
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

// LookAheadFromStart gibt die asset_ids der ersten n Audio-Cues vom Anfang der
// CueList zurück (unabhängig von der aktiven Cue). Für Session-Start-Prewarm.
func (e *Engine) LookAheadFromStart(list *pb.CueList, n int) []string {
	return e.lookAheadAssetIDs(list, "", n) // activeCueID="" → startet von vorne
}

// lookAheadAssetIDs sammelt die asset_ids der nächsten n Audio-Cues nach
// activeCueID in der übergebenen CueList. Gruppe-Cues werden flach expandiert.
// Duplikate werden entfernt. list darf nil sein (gibt nil zurück).
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

// collectAssetIDs extrahiert asset_ids aus einer Cue (inkl. Group-Expansion).
// seen verhindert Duplikate wenn Kinder-Cues auch als Top-Level-Einträge stehen.
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
