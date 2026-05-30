// Package audionode provides the server-internal audio output node.
//
// When started with --audio-node, the server registers an internal node that
// processes AudioPreload/AudioPlay/AudioStop/AudioPause/AudioResume commands
// and routes them to the audioengine.Engine (malgo/miniaudio backend).
//
// Designed for professional shared setups (theatre installations) where a
// dedicated audio machine runs the StageSync server directly with an ASIO
// or WASAPI-exclusive interface — no separate Flutter audio client needed.
//
// Remote device management:
//   The master can send NodeConfigCommand.audio_device_index to switch the
//   output device live without restarting the server.
package audionode

import (
	"context"
	"log"
	"math"
	"sync"
	"time"

	"github.com/google/uuid"
	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/audioengine"
	"stagesync-server/internal/media"
	"stagesync-server/internal/node"
	"stagesync-server/internal/session"
)

const internalNodeName = "Server-AudioNode"

// InternalAudioNode is a server-side audio node backed by audioengine.Engine.
type InternalAudioNode struct {
	sessionMgr *session.Manager
	dispatcher *node.Dispatcher
	mediaStore *media.Store
	engine     *audioengine.Engine

	nodeID    string
	sessionID string

	currentDeviceIdx  int32
	currentDeviceName string

	// preloadsMu schützt die Map laufender asynchroner Preloads.
	// cueID → done-Channel: geschlossen wenn Preload abgeschlossen (ok oder fehler).
	preloadsMu sync.Mutex
	preloads   map[string]chan struct{}

	// generation zählt wie oft STOP ALL aufgerufen wurde.
	// Preload-Goroutinen prüfen beim Start ob ihre Generation noch aktuell ist —
	// veraltete Goroutinen (vor einem STOP ALL gestartet) überspringen die Dekodierung.
	genMu      sync.Mutex
	generation uint64
}

// New creates an InternalAudioNode. Call Start to activate it.
// mediaStore may be nil during testing; Preload will then fail gracefully.
func New(mgr *session.Manager, disp *node.Dispatcher, ms *media.Store) *InternalAudioNode {
	return &InternalAudioNode{
		sessionMgr:       mgr,
		dispatcher:       disp,
		mediaStore:       ms,
		currentDeviceIdx: -1,
		preloads:         make(map[string]chan struct{}),
	}
}

// Start initialises the audio engine and begins the command loop.
// Runs in the background until ctx is cancelled.
func (n *InternalAudioNode) Start(ctx context.Context) {
	eng, err := audioengine.New()
	if err != nil {
		log.Printf("[audionode] failed to create audio engine: %v", err)
		return
	}
	n.engine = eng

	// Audio-Gerät sofort initialisieren (nicht lazy beim ersten Preload) —
	// verhindert WASAPI-Init-Latenz beim ersten GO-Befehl.
	if err := eng.EnsureStarted(); err != nil {
		log.Printf("[audionode] Warnung: Audio-Gerät konnte nicht vorab geöffnet werden: %v", err)
	}

	// Log available devices for operator reference.
	if devs, err := eng.EnumerateDevices(); err == nil {
		log.Printf("[audionode] verfügbare Ausgabegeräte (%d):", len(devs))
		for _, d := range devs {
			log.Printf("[audionode]   [%d] %s", d.Index, d.Name)
		}
	} else {
		log.Printf("[audionode] Gerätliste nicht abrufbar: %v", err)
	}

	go n.run(ctx)
}

func (n *InternalAudioNode) run(ctx context.Context) {
	defer func() {
		if n.engine != nil {
			n.engine.Close()
		}
	}()

	sessID := n.waitForSession(ctx)
	if sessID == "" {
		return
	}
	n.sessionID = sessID

	info := &pb.NodeInfo{
		NodeId:   uuid.NewString(),
		Name:     internalNodeName,
		NodeType: pb.NodeType_NODE_TYPE_AUDIO,
		Tasks:    []pb.NodeTask{pb.NodeTask_NODE_TASK_AUDIO_OUTPUT},
		Online:   true,
	}

	nodeID, _, err := n.sessionMgr.AddInternalNode(sessID, info)
	if err != nil {
		log.Printf("[audionode] failed to register in session %s: %v", sessID, err)
		return
	}
	n.nodeID = nodeID

	// Report audio device list as NodeCapabilities so the Flutter UI can show
	// and remotely switch the output device without a WatchNodes subscription.
	n.reportCapabilities(sessID, nodeID, info)

	ch := n.dispatcher.Register(nodeID, info.Tasks)
	defer n.dispatcher.Unregister(nodeID)

	log.Printf("[audionode] started (nodeID=%s, session=%s)", nodeID, sessID)

	for {
		select {
		case <-ctx.Done():
			n.engine.StopAll()
			log.Printf("[audionode] stopping")
			return
		case cmd, ok := <-ch:
			if !ok {
				return
			}
			n.handleCommand(cmd)
		}
	}
}

func (n *InternalAudioNode) waitForSession(ctx context.Context) string {
	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return ""
		case <-ticker.C:
			if ss := n.sessionMgr.AllSessions(); len(ss) > 0 {
				return ss[0].ID
			}
		}
	}
}

// ── Command dispatch ──────────────────────────────────────────────────────────

func (n *InternalAudioNode) handleCommand(cmd *pb.NodeCommandRequest) {
	if cmd == nil {
		return
	}
	switch c := cmd.Command.(type) {
	case *pb.NodeCommandRequest_AudioPreload:
		n.handlePreload(c.AudioPreload)
	case *pb.NodeCommandRequest_AudioPlay:
		n.handlePlay(c.AudioPlay)
	case *pb.NodeCommandRequest_AudioStop:
		n.handleStop(c.AudioStop)
	case *pb.NodeCommandRequest_AudioPause:
		n.handlePause(c.AudioPause)
	case *pb.NodeCommandRequest_AudioResume:
		n.handleResume(c.AudioResume)
	case *pb.NodeCommandRequest_NodeConfig:
		n.handleNodeConfig(c.NodeConfig)
	case *pb.NodeCommandRequest_AudioTest:
		n.handleTestSignal(c.AudioTest)
	default:
		log.Printf("[audionode] unhandled command type: %T", cmd.Command)
	}
}

func (n *InternalAudioNode) handlePreload(cmd *pb.AudioPreloadCommand) {
	if n.mediaStore == nil {
		log.Printf("[audionode] PRELOAD skipped: no media store")
		return
	}
	if cmd.GetAssetId() == "" && cmd.GetFilePath() == "" {
		log.Printf("[audionode] PRELOAD: missing assetId/filePath")
		return
	}

	var path string
	assetID := cmd.GetAssetId()
	if assetID != "" {
		if p, err := n.mediaStore.FilePathBySHA256(assetID); err == nil {
			path = p
		}
	}
	if path == "" {
		name := cmd.GetFilePath()
		if name == "" {
			name = assetID
		}
		if _, statErr := n.mediaStore.Stat(name); statErr != nil {
			log.Printf("[audionode] PRELOAD: asset %q nicht im Store gefunden: %v", assetID, statErr)
			return
		}
		path = n.mediaStore.FilePath(name)
	}

	cueID := cmd.GetCueId()
	shortAsset := assetID
	if len(shortAsset) > 12 {
		shortAsset = shortAsset[:12] + "..."
	}
	log.Printf("[audionode] PRELOAD cueId=%s asset=%s path=%s", cueID, shortAsset, path)

	// Aktuelle Generation: wenn STOP ALL feuert, steigt n.generation.
	// Veraltete Goroutinen (vor dem Stop gestartet) überspringen Dekodierung.
	n.genMu.Lock()
	myGen := n.generation
	n.genMu.Unlock()

	// Dekodierung asynchron: blockiert den Command-Channel nicht.
	// PLAY wartet via waitPreload() auf Fertigstellung.
	done := make(chan struct{})
	n.preloadsMu.Lock()
	n.preloads[cueID] = done
	n.preloadsMu.Unlock()

	go func() {
		defer func() {
			close(done)
			n.preloadsMu.Lock()
			delete(n.preloads, cueID)
			n.preloadsMu.Unlock()
		}()
		n.genMu.Lock()
		stale := n.generation != myGen
		n.genMu.Unlock()
		if stale {
			log.Printf("[audionode] PRELOAD veraltet (STOP ALL seit Dispatch): %s", cueID)
			return
		}
		if err := n.engine.PreloadByAsset(cueID, assetID, path); err != nil {
			log.Printf("[audionode] PRELOAD FEHLER cueId=%s: %v", cueID, err)
		} else {
			log.Printf("[audionode] PRELOAD OK cueId=%s", cueID)
		}
	}()
}

// waitPreload wartet bis das Preload für cueID abgeschlossen ist.
// Gibt sofort zurück wenn kein laufendes Preload bekannt ist.
// Timeout: 30 s (gibt bei Dekodierungshänger nach).
func (n *InternalAudioNode) waitPreload(cueID string) {
	n.preloadsMu.Lock()
	done, loading := n.preloads[cueID]
	n.preloadsMu.Unlock()
	if !loading {
		return
	}
	log.Printf("[audionode] PLAY wartet auf Preload-Abschluss: %s", cueID)
	select {
	case <-done:
	case <-time.After(30 * time.Second):
		log.Printf("[audionode] PLAY Timeout beim Warten auf Preload: %s", cueID)
	}
}

func (n *InternalAudioNode) handlePlay(cmd *pb.AudioPlayCommand) {
	cueID := cmd.GetCueId()

	// PLAY wartet auf sein PRELOAD — wenn kein Preload läuft, sofort weiter.
	n.waitPreload(cueID)

	log.Printf("[audionode] PLAY cueId=%s startMs=%d vol=%.1fdB loop=%v",
		cueID, cmd.GetStartUnixMillis(), cmd.GetVolumeDb(), cmd.GetLoop())

	if err := n.engine.Play(
		cueID,
		cmd.GetStartUnixMillis(),
		cmd.GetVolumeDb(),
		cmd.GetFadeInMs(),
		cmd.GetFadeOutMs(),
		cmd.GetLoop(),
	); err != nil {
		log.Printf("[audionode] PLAY FEHLER cueId=%s: %v", cueID, err)
	} else {
		log.Printf("[audionode] PLAY OK cueId=%s", cueID)
	}
}

func (n *InternalAudioNode) handleStop(cmd *pb.AudioStopCommand) {
	cueID := cmd.GetCueId()
	log.Printf("[audionode] STOP cueId=%s fadeOut=%.0fms", cueID, cmd.GetFadeOutMs())

	if cueID == "" {
		// Leere CueId = alle Cues stoppen (Notfall-Stop vom Server).
		// Generation erhöhen → laufende und wartende Preload-Goroutinen werden verworfen.
		n.genMu.Lock()
		n.generation++
		log.Printf("[audionode] STOP ALL (gen=%d)", n.generation)
		n.genMu.Unlock()
		n.engine.StopAll()
		return
	}
	if err := n.engine.Stop(cueID, cmd.GetFadeOutMs()); err != nil {
		log.Printf("[audionode] STOP FEHLER cueId=%s: %v", cueID, err)
	}
}

func (n *InternalAudioNode) handlePause(cmd *pb.AudioPauseCommand) {
	cueID := cmd.GetCueId()
	log.Printf("[audionode] PAUSE cueId=%s fadeOut=%.0fms", cueID, cmd.GetFadeOutMs())
	if err := n.engine.Pause(cueID, cmd.GetFadeOutMs()); err != nil {
		log.Printf("[audionode] PAUSE error cueId=%s: %v", cueID, err)
	}
}

func (n *InternalAudioNode) handleResume(cmd *pb.AudioResumeCommand) {
	cueID := cmd.GetCueId()
	log.Printf("[audionode] RESUME cueId=%s fadeIn=%.0fms", cueID, cmd.GetFadeInMs())
	if err := n.engine.Resume(cueID, cmd.GetFadeInMs()); err != nil {
		log.Printf("[audionode] RESUME error cueId=%s: %v", cueID, err)
	}
}

// reportCapabilities enumerates local audio devices and publishes them via
// NodeCapabilities so the Flutter health stream delivers the device list to the UI.
// It also reports the currently selected device so Flutter can pre-select it.
func (n *InternalAudioNode) reportCapabilities(sessID, nodeID string, info *pb.NodeInfo) {
	caps := &pb.NodeCapabilities{}
	if devs, err := n.engine.EnumerateDevices(); err == nil {
		devices := make([]*pb.AudioDeviceInfo, len(devs))
		for i, d := range devs {
			devices[i] = &pb.AudioDeviceInfo{
				Index: int32(d.Index),
				Name:  d.Name,
			}
		}
		// selectedIdx is 0 for the system default (-1) so Flutter always gets a
		// valid index; the name distinguishes "default" from an explicit selection.
		selectedIdx := n.currentDeviceIdx
		if selectedIdx < 0 {
			selectedIdx = 0
		}
		caps.Audio = &pb.AudioCapabilities{
			AvailableDevices: devices,
			SelectedDevice:   selectedIdx,
		}
	}
	caps.AuditionDevice = n.currentDeviceName
	sess, err := n.sessionMgr.GetSession(sessID)
	if err != nil {
		return
	}
	sess.SetNodeCapabilities(nodeID, caps)
	n.sessionMgr.NotifyNodeUpdated(sessID, info)
}

// handleTestSignal synthesises a tone or sweep and plays it immediately.
func (n *InternalAudioNode) handleTestSignal(cmd *pb.AudioTestSignalCommand) {
	const sr = uint32(48000)
	const ch = uint32(2)

	durationMs := cmd.GetDurationMs()
	if durationMs <= 0 {
		durationMs = 1000
	}
	amplitude := cmd.GetAmplitude()
	if amplitude <= 0 {
		amplitude = 0.5
	}
	frames := int(float64(sr) * float64(durationMs) / 1000)
	pcm := make([]float32, frames*int(ch))

	switch cmd.GetKind() {
	case pb.AudioTestSignalCommand_KIND_SWEEP:
		startHz := cmd.GetStartHz()
		endHz := cmd.GetEndHz()
		if startHz <= 0 {
			startHz = 20
		}
		if endHz <= 0 {
			endHz = 20000
		}
		T := float64(frames) / float64(sr)
		for i := 0; i < frames; i++ {
			t := float64(i) / float64(sr)
			// Exponential sweep: instantaneous frequency grows from startHz to endHz.
			phase := 2 * math.Pi * startHz * T / math.Log(endHz/startHz) *
				(math.Pow(endHz/startHz, t/T) - 1)
			s := float32(amplitude * math.Sin(phase))
			pcm[i*int(ch)] = s
			pcm[i*int(ch)+1] = s
		}
	default: // KIND_TONE — simple sine
		freq := cmd.GetFrequencyHz()
		if freq <= 0 {
			freq = 1000
		}
		for i := 0; i < frames; i++ {
			t := float64(i) / float64(sr)
			s := float32(amplitude * math.Sin(2*math.Pi*float64(freq)*t))
			pcm[i*int(ch)] = s
			pcm[i*int(ch)+1] = s
		}
	}

	cueID := cmd.GetCueId()
	if cueID == "" {
		cueID = "test_signal"
	}
	if err := n.engine.PreloadPCM(cueID, pcm, sr, ch); err != nil {
		log.Printf("[audionode] test signal preload error: %v", err)
		return
	}
	if err := n.engine.Play(cueID, 0, 0, 100, 100, false); err != nil {
		log.Printf("[audionode] test signal play error: %v", err)
		return
	}
	log.Printf("[audionode] test signal: kind=%s cueId=%s dur=%.0fms freq=%.0fHz",
		cmd.GetKind(), cueID, durationMs, cmd.GetFrequencyHz())
}

// handleNodeConfig handles remote device configuration sent by the master.
// audio_device_index = -1 → system default.
func (n *InternalAudioNode) handleNodeConfig(cmd *pb.NodeConfigCommand) {
	idx := int(cmd.GetAudioDeviceIndex())
	name := cmd.GetAudioDeviceName()
	if name == "" {
		name = "(index)"
	}
	log.Printf("[audionode] NodeConfig: set audio device index=%d name=%q", idx, name)

	if err := n.engine.SetDevice(idx); err != nil {
		log.Printf("[audionode] SetDevice(%d) failed: %v", idx, err)
		return
	}
	log.Printf("[audionode] audio device changed to index=%d", idx)

	// Track the newly active device so reportCapabilities can advertise it.
	n.currentDeviceIdx = int32(idx)
	if cmd.GetAudioDeviceName() != "" {
		n.currentDeviceName = cmd.GetAudioDeviceName()
	} else {
		n.currentDeviceName = ""
	}

	// Push updated capabilities immediately so Flutter clients learn about
	// the new active device without waiting for the next WatchNodes event.
	n.reportCapabilities(n.sessionID, n.nodeID, &pb.NodeInfo{
		NodeId:   n.nodeID,
		Name:     internalNodeName,
		NodeType: pb.NodeType_NODE_TYPE_AUDIO,
		Tasks:    []pb.NodeTask{pb.NodeTask_NODE_TASK_AUDIO_OUTPUT},
		Online:   true,
	})
}
