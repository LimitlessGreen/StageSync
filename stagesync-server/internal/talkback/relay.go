// Package talkback implements the server-side relay for the Talkback feature.
//
// Flow:
//   Flutter Client ──Opus──► TalkbackService.StreamTalkback
//                                  │ (per client session)
//                                  ▼
//                             Relay.Route
//                                  │ (resolves bus → nodes via busengine.Router)
//                                  ▼ (one goroutine per node)
//                             NodeDispatcher.Dispatch
//                                  │ NodeCommandRequest_AudioTalkbackChunk
//                                  ▼
//                             InternalAudioNode (or remote Flutter audio node)
//                                  │
//                                  ▼ Opus-Decode → StreamingHandle
//                             audioengine.Engine.mix()
package talkback

import (
	"context"
	"log"
	"sync"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/busengine"
)

// NodeDispatcher matches the node.Dispatcher interface needed here.
type NodeDispatcher interface {
	Dispatch(ctx context.Context, nodeID string, cmd *pb.NodeCommandRequest) error
	DispatchToTask(ctx context.Context, task pb.NodeTask, cmd *pb.NodeCommandRequest) error
}

// ActiveSession beschreibt einen aktiven Talkback-Stream.
type ActiveSession struct {
	ClientID    string
	DisplayName string
	SessionID   string
	BusIDs      []string // explizit angefordert oder aus TALKBACK-Buses
	Targets     []busengine.NodeTarget
}

// Relay verwaltet aktive Talkback-Sessions und routet Chunks an Nodes.
type Relay struct {
	mu       sync.RWMutex
	sessions map[string]*ActiveSession // clientID → session
	router   *busengine.Router
	disp     NodeDispatcher

	// duckLevel: aktueller Ducking-Pegel (0.0 = kein Ducking).
	// Wird beim GO-Trigger gesetzt.
	duckLevel float32
}

// NewRelay erstellt einen neuen Relay.
func NewRelay(router *busengine.Router, disp NodeDispatcher) *Relay {
	return &Relay{
		sessions: make(map[string]*ActiveSession),
		router:   router,
		disp:     disp,
	}
}

// Open registriert eine neue Talkback-Session und sendet START-Control an Nodes.
func (r *Relay) Open(sess *ActiveSession) {
	if len(sess.Targets) == 0 {
		sess.Targets = r.router.ResolveTalkbackBuses(sess.BusIDs)
	}

	r.mu.Lock()
	r.sessions[sess.ClientID] = sess
	r.mu.Unlock()

	log.Printf("[talkback] session geöffnet: client=%s name=%q targets=%d",
		sess.ClientID, sess.DisplayName, len(sess.Targets))

	// START-Control an alle Ziel-Nodes
	ctrl := &pb.AudioTalkbackControlCommand{
		Action:   pb.AudioTalkbackControlCommand_ACTION_START,
		ClientId: sess.ClientID,
	}
	r.sendControl(sess.SessionID, sess.Targets, ctrl)
}

// Close beendet eine Talkback-Session und sendet STOP-Control an Nodes.
func (r *Relay) Close(clientID string) {
	r.mu.Lock()
	sess, ok := r.sessions[clientID]
	if ok {
		delete(r.sessions, clientID)
	}
	r.mu.Unlock()

	if !ok {
		return
	}

	log.Printf("[talkback] session geschlossen: client=%s", clientID)
	ctrl := &pb.AudioTalkbackControlCommand{
		Action:   pb.AudioTalkbackControlCommand_ACTION_STOP,
		ClientId: clientID,
	}
	r.sendControl(sess.SessionID, sess.Targets, ctrl)
}

// Route leitet einen Opus-Chunk an die Ziel-Nodes weiter.
// Fallback: wenn die Session keine expliziten Targets hat (Bus ohne Node-Patch),
// wird an alle AUDIO_OUTPUT-Nodes der Session gesendet.
func (r *Relay) Route(sessionID, clientID string, chunk *pb.AudioChunk, levelDB float32) {
	r.mu.RLock()
	sess, ok := r.sessions[clientID]
	r.mu.RUnlock()
	if !ok {
		return
	}

	cmd := &pb.NodeCommandRequest{
		SessionId: sessionID,
		Command: &pb.NodeCommandRequest_AudioTalkback{
			AudioTalkback: &pb.AudioTalkbackChunkCommand{
				ClientId:    clientID,
				OpusData:    chunk.OpusData,
				TimestampMs: chunk.TimestampMs,
				Sequence:    chunk.Sequence,
				LevelDb:     levelDB,
			},
		},
	}

	if len(sess.Targets) > 0 {
		for _, target := range sess.Targets {
			if err := r.disp.Dispatch(context.Background(), target.NodeID, cmd); err != nil {
				log.Printf("[talkback] dispatch Fehler node=%s: %v", target.NodeID, err)
			}
		}
	} else {
		// Kein Node im Bus-Patch → an alle AUDIO_OUTPUT-Nodes senden
		if err := r.disp.DispatchToTask(context.Background(), pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd); err != nil {
			log.Printf("[talkback] fallback dispatch Fehler: %v", err)
		}
	}
}

// DuckOnGo sendet DUCK-Control an alle Nodes mit aktiven Talkback-Sessions.
// Wird vom ShowControl-Engine beim GO-Trigger aufgerufen.
func (r *Relay) DuckOnGo(sessionID string, duckDB float32, durationMs int32) {
	r.mu.RLock()
	if len(r.sessions) == 0 {
		r.mu.RUnlock()
		return
	}
	// Alle einzigartigen Node-Targets sammeln
	seen := make(map[string]struct{})
	var targets []busengine.NodeTarget
	for _, sess := range r.sessions {
		for _, t := range sess.Targets {
			if _, dup := seen[t.NodeID]; !dup {
				seen[t.NodeID] = struct{}{}
				targets = append(targets, t)
			}
		}
	}
	r.mu.RUnlock()

	ctrl := &pb.AudioTalkbackControlCommand{
		Action:  pb.AudioTalkbackControlCommand_ACTION_DUCK,
		DuckDb:  duckDB,
		DuckMs:  durationMs,
	}
	r.sendControl(sessionID, targets, ctrl)
	log.Printf("[talkback] DuckOnGo: %.1fdB über %dms an %d Nodes", duckDB, durationMs, len(targets))
}

// HasActiveTalkers gibt true zurück wenn mindestens eine Session aktiv ist.
func (r *Relay) HasActiveTalkers() bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.sessions) > 0
}

// ActiveTalkers gibt eine Momentaufnahme aller aktiven Sessions zurück.
func (r *Relay) ActiveTalkers() []*ActiveSession {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]*ActiveSession, 0, len(r.sessions))
	for _, s := range r.sessions {
		out = append(out, s)
	}
	return out
}

func (r *Relay) sendControl(sessionID string, targets []busengine.NodeTarget, ctrl *pb.AudioTalkbackControlCommand) {
	cmd := &pb.NodeCommandRequest{
		SessionId: sessionID,
		Command: &pb.NodeCommandRequest_AudioTalkbackCtrl{
			AudioTalkbackCtrl: ctrl,
		},
	}
	if len(targets) > 0 {
		for _, target := range targets {
			if err := r.disp.Dispatch(context.Background(), target.NodeID, cmd); err != nil {
				log.Printf("[talkback] control dispatch Fehler node=%s action=%s: %v",
					target.NodeID, ctrl.Action, err)
			}
		}
	} else {
		// Fallback: an alle AUDIO_OUTPUT-Nodes
		if err := r.disp.DispatchToTask(context.Background(), pb.NodeTask_NODE_TASK_AUDIO_OUTPUT, cmd); err != nil {
			log.Printf("[talkback] control fallback Fehler action=%s: %v", ctrl.Action, err)
		}
	}
}
