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
}

// New creates an InternalAudioNode. Call Start to activate it.
// mediaStore may be nil during testing; Preload will then fail gracefully.
func New(mgr *session.Manager, disp *node.Dispatcher, ms *media.Store) *InternalAudioNode {
	return &InternalAudioNode{
		sessionMgr: mgr,
		dispatcher: disp,
		mediaStore: ms,
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

	// Log available devices for operator reference.
	if devs, err := eng.EnumerateDevices(); err == nil {
		log.Printf("[audionode] available output devices (%d):", len(devs))
		for _, d := range devs {
			log.Printf("[audionode]   [%d] %s", d.Index, d.Name)
		}
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
	default:
		log.Printf("[audionode] unhandled command type: %T", cmd.Command)
	}
}

func (n *InternalAudioNode) handlePreload(cmd *pb.AudioPreloadCommand) {
	if n.mediaStore == nil {
		log.Printf("[audionode] PRELOAD skipped: no media store")
		return
	}
	assetID := cmd.GetAssetId()
	if assetID == "" {
		assetID = cmd.GetFilePath()
	}
	if assetID == "" {
		log.Printf("[audionode] PRELOAD: missing assetId/filePath")
		return
	}

	// Resolve file path: first try assetID as name, then as SHA-256 key.
	path := n.mediaStore.FilePath(assetID)
	_, statErr := n.mediaStore.Stat(assetID)
	if statErr != nil {
		log.Printf("[audionode] PRELOAD: asset %q not found in store: %v", assetID, statErr)
		return
	}

	cueID := cmd.GetCueId()
	log.Printf("[audionode] PRELOAD cueId=%s asset=%s", cueID, assetID)

	if err := n.engine.Preload(cueID, path); err != nil {
		log.Printf("[audionode] PRELOAD error cueId=%s: %v", cueID, err)
	}
}

func (n *InternalAudioNode) handlePlay(cmd *pb.AudioPlayCommand) {
	cueID := cmd.GetCueId()
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
		log.Printf("[audionode] PLAY error cueId=%s: %v", cueID, err)
	}
}

func (n *InternalAudioNode) handleStop(cmd *pb.AudioStopCommand) {
	cueID := cmd.GetCueId()
	log.Printf("[audionode] STOP cueId=%s fadeOut=%.0fms", cueID, cmd.GetFadeOutMs())
	if err := n.engine.Stop(cueID, cmd.GetFadeOutMs()); err != nil {
		log.Printf("[audionode] STOP error cueId=%s: %v", cueID, err)
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
		caps.Audio = &pb.AudioCapabilities{AvailableDevices: devices}
	}
	sess, err := n.sessionMgr.GetSession(sessID)
	if err != nil {
		return
	}
	sess.SetNodeCapabilities(nodeID, caps)
	n.sessionMgr.NotifyNodeUpdated(sessID, info)
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
	} else {
		log.Printf("[audionode] audio device changed to index=%d", idx)
	}
}
