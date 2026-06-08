// Package midinode stellt einen server-internen MIDI-Controller-Node bereit.
//
// Mit --midi-node öffnet der Server die MIDI-Ports eines angeschlossenen
// Controllers (z.B. Akai APC Mini), übersetzt Pad-Drücke in Grid-Launches und
// spiegelt den Clip-Status als LED-Feedback zurück. Das LED-Feedback kommt als
// LedFeedbackCommand über den Node-Dispatcher (symmetrisch zum Audio-Node).
package midinode

import (
	"context"
	"log"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"gitlab.com/gomidi/midi/v2"
	"gitlab.com/gomidi/midi/v2/drivers"
	"gitlab.com/gomidi/midi/v2/drivers/rtmididrv"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/node"
	"stagesync-server/internal/session"
)

const internalNodeName = "Server-MidiNode"
const defaultGridID = "main"

// GridLauncher löst Grid-Clips aus Pad-Drücken aus. Implementiert vom GridHandler.
type GridLauncher interface {
	LaunchClipInternal(sessionID, gridID string, track, scene int32, released bool)
}

// MidiNode verbindet einen physischen MIDI-Controller mit dem Grid.
type MidiNode struct {
	sessionMgr *session.Manager
	dispatcher *node.Dispatcher
	launcher   GridLauncher
	portMatch  string // Teilstring zum Finden des Controllers (z.B. "APC")

	nodeID    string
	sessionID string

	drv  drivers.Driver
	out  drivers.Out
	in   drivers.In
	stop func()

	sendMu sync.Mutex
	send   func(midi.Message) error
}

// New erstellt einen MidiNode. portMatch="" → erster verfügbarer Port.
func New(mgr *session.Manager, disp *node.Dispatcher, launcher GridLauncher, portMatch string) *MidiNode {
	if portMatch == "" {
		portMatch = "APC"
	}
	return &MidiNode{
		sessionMgr: mgr,
		dispatcher: disp,
		launcher:   launcher,
		portMatch:  portMatch,
	}
}

// Start öffnet die MIDI-Ports und beginnt die Command-Schleife (im Hintergrund).
func (n *MidiNode) Start(ctx context.Context) {
	go n.run(ctx)
}

func (n *MidiNode) run(ctx context.Context) {
	defer n.closePorts()

	if err := n.openPorts(); err != nil {
		log.Printf("[midinode] MIDI-Ports konnten nicht geöffnet werden: %v", err)
		// Node trotzdem registrieren? Ohne Ports kein Nutzen → abbrechen.
		return
	}

	sessID := n.waitForSession(ctx)
	if sessID == "" {
		return
	}
	n.sessionID = sessID

	info := &pb.NodeInfo{
		NodeId: uuid.NewString(),
		Name:   internalNodeName,
		Tasks:  []pb.NodeTask{pb.NodeTask_NODE_TASK_MIDI_IN, pb.NodeTask_NODE_TASK_MIDI_OUT},
		Online: true,
	}
	nodeID, _, err := n.sessionMgr.AddInternalNode(sessID, info)
	if err != nil {
		log.Printf("[midinode] Registrierung in Session %s fehlgeschlagen: %v", sessID, err)
		return
	}
	n.nodeID = nodeID

	ch := n.dispatcher.Register(nodeID, info.Tasks)
	defer n.dispatcher.Unregister(nodeID)

	if err := n.listenPads(); err != nil {
		log.Printf("[midinode] Pad-Listener fehlgeschlagen: %v", err)
	}
	n.clearAllLeds()

	log.Printf("[midinode] gestartet (nodeID=%s, session=%s, port=%q)", nodeID, sessID, n.portMatch)

	for {
		select {
		case <-ctx.Done():
			log.Printf("[midinode] stoppe")
			return
		case cmd, ok := <-ch:
			if !ok {
				return
			}
			n.handleCommand(cmd)
		}
	}
}

func (n *MidiNode) waitForSession(ctx context.Context) string {
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

// ── MIDI Ports ────────────────────────────────────────────────────────────────

func (n *MidiNode) openPorts() error {
	drv, err := rtmididrv.New()
	if err != nil {
		return err
	}
	n.drv = drv

	ins, err := drv.Ins()
	if err != nil {
		return err
	}
	outs, err := drv.Outs()
	if err != nil {
		return err
	}
	in, err := findPort(ins, n.portMatch)
	if err != nil {
		return err
	}
	out, err := findPort(outs, n.portMatch)
	if err != nil {
		return err
	}
	if err := in.Open(); err != nil {
		return err
	}
	if err := out.Open(); err != nil {
		return err
	}
	n.in = in
	n.out = out

	send, err := midi.SendTo(out)
	if err != nil {
		return err
	}
	n.send = send
	return nil
}

// findPort liefert den ersten Port, dessen Name den Match-Teilstring enthält
// (case-insensitive); fällt sonst auf den ersten verfügbaren Port zurück.
func findPort[T interface {
	String() string
}](ports []T, match string) (T, error) {
	var zero T
	if len(ports) == 0 {
		return zero, errNoPorts
	}
	lower := strings.ToLower(match)
	for _, p := range ports {
		if strings.Contains(strings.ToLower(p.String()), lower) {
			return p, nil
		}
	}
	return ports[0], nil
}

func (n *MidiNode) listenPads() error {
	stop, err := midi.ListenTo(n.in, n.onMidiIn, midi.UseSysEx())
	if err != nil {
		return err
	}
	n.stop = stop
	return nil
}

func (n *MidiNode) onMidiIn(msg midi.Message, _ int32) {
	var ch, key, vel uint8
	if msg.GetNoteOn(&ch, &key, &vel) {
		track, scene, ok := noteToCell(key)
		if !ok {
			return
		}
		// Velocity 0 = Release (manche Controller senden NoteOn statt NoteOff).
		released := vel == 0
		n.launcher.LaunchClipInternal(n.sessionID, defaultGridID, track, scene, released)
		return
	}
	if msg.GetNoteOff(&ch, &key, &vel) {
		track, scene, ok := noteToCell(key)
		if !ok {
			return
		}
		n.launcher.LaunchClipInternal(n.sessionID, defaultGridID, track, scene, true)
	}
}

func (n *MidiNode) closePorts() {
	if n.stop != nil {
		n.stop()
	}
	if n.in != nil {
		_ = n.in.Close()
	}
	if n.out != nil {
		_ = n.out.Close()
	}
	if n.drv != nil {
		_ = n.drv.Close()
	}
}

// ── Command-Dispatch (Server → Node) ──────────────────────────────────────────

func (n *MidiNode) handleCommand(cmd *pb.NodeCommandRequest) {
	if cmd == nil {
		return
	}
	switch c := cmd.Command.(type) {
	case *pb.NodeCommandRequest_LedFeedback:
		n.setLed(c.LedFeedback)
	case *pb.NodeCommandRequest_MidiSend:
		n.sendRaw(c.MidiSend)
	}
}

func (n *MidiNode) setLed(cmd *pb.LedFeedbackCommand) {
	note, ok := cellToNote(cmd.TrackIndex, cmd.SceneIndex)
	if !ok {
		return
	}
	n.writeMessage(midi.NoteOn(0, note, ledVelocity(cmd.Color)))
}

func (n *MidiNode) sendRaw(cmd *pb.MidiSendCommand) {
	// command ist das volle Status-Byte (z.B. 0x90 NoteOn). gomidi erwartet
	// Kanal separat; das untere Nibble von command kodiert hier den Kanal nicht,
	// daher Kanal explizit aus cmd.Channel.
	ch := uint8(cmd.Channel & 0x0F)
	status := uint8(cmd.Command) & 0xF0
	switch status {
	case 0x90:
		n.writeMessage(midi.NoteOn(ch, uint8(cmd.Data1), uint8(cmd.Data2)))
	case 0x80:
		n.writeMessage(midi.NoteOff(ch, uint8(cmd.Data1)))
	case 0xB0:
		n.writeMessage(midi.ControlChange(ch, uint8(cmd.Data1), uint8(cmd.Data2)))
	}
}

func (n *MidiNode) clearAllLeds() {
	for note := uint8(0); note < apcGridSize*apcGridSize; note++ {
		n.writeMessage(midi.NoteOn(0, note, 0))
	}
}

func (n *MidiNode) writeMessage(msg midi.Message) {
	n.sendMu.Lock()
	defer n.sendMu.Unlock()
	if n.send == nil {
		return
	}
	if err := n.send(msg); err != nil {
		log.Printf("[midinode] MIDI-Send-Fehler: %v", err)
	}
}
