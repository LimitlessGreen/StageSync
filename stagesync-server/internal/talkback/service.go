package talkback

import (
	"context"
	"io"
	"log"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/busengine"
	"stagesync-server/internal/session"
)

// Handler implements TalkbackServiceServer.
type Handler struct {
	pb.UnimplementedTalkbackServiceServer
	sessionMgr *session.Manager
	relay      *Relay
	router     *busengine.Router
}

// NewHandler erstellt einen TalkbackService Handler.
func NewHandler(mgr *session.Manager, relay *Relay, router *busengine.Router) *Handler {
	return &Handler{
		sessionMgr: mgr,
		relay:      relay,
		router:     router,
	}
}

// StreamTalkback ist der bidirektionale Hauptstream.
// Erstes Frame muss TalkbackInitFrame sein; danach AudioChunks.
func (h *Handler) StreamTalkback(stream pb.TalkbackService_StreamTalkbackServer) error { //nolint:gocritic
	// Erstes Frame empfangen — muss Init sein
	firstFrame, err := stream.Recv()
	if err != nil {
		return err
	}
	init := firstFrame.GetInit()
	if init == nil {
		return status.Error(codes.InvalidArgument, "erstes Frame muss TalkbackInitFrame sein")
	}

	// Session validieren
	_, _, err = h.sessionMgr.ValidateToken(init.SessionId, init.Token)
	if err != nil {
		return status.Errorf(codes.Unauthenticated, "ungültiges Token: %v", err)
	}

	// Bus-Targets auflösen
	targets := h.router.ResolveTalkbackBuses(init.TargetBusIds)
	if len(targets) == 0 {
		log.Printf("[talkback] kein Bus-Patch → Fallback auf alle AUDIO_OUTPUT-Nodes (session=%s)", init.SessionId)
	}

	// Session registrieren
	activeSess := &ActiveSession{
		ClientID:    init.ClientId,
		DisplayName: init.DisplayName,
		SessionID:   init.SessionId,
		BusIDs:      init.TargetBusIds,
		Targets:     targets,
	}
	h.relay.Open(activeSess)
	defer h.relay.Close(init.ClientId)

	// Status-Update-Ticker (alle 2 s aktive Talker broadcasten)
	statusTicker := time.NewTicker(2 * time.Second)
	defer statusTicker.Stop()

	// Goroutine für Status-Sends
	go func() {
		for {
			select {
			case <-stream.Context().Done():
				return
			case <-statusTicker.C:
				if err := stream.Send(h.buildStatus()); err != nil {
					return
				}
			}
		}
	}()

	// Initiales Status-Update
	if err := stream.Send(h.buildStatus()); err != nil {
		return err
	}

	// Audio-Chunk-Loop
	for {
		frame, err := stream.Recv()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}

		chunk := frame.GetAudio()
		if chunk == nil {
			continue
		}

		// Lautstärke aus dem ersten Talkback-Bus ableiten (für level_db im Command)
		levelDB := float32(0.0)
		if len(targets) > 0 {
			levelDB = targets[0].LevelDB
		}

		h.relay.Route(init.SessionId, init.ClientId, chunk, levelDB)
	}
}

// ListActiveTalkers gibt alle aktiven Talkback-Sessions zurück.
func (h *Handler) ListActiveTalkers(
	_ context.Context,
	req *pb.ListActiveTalkersRequest,
) (*pb.ListActiveTalkersResponse, error) {
	if _, _, err := h.sessionMgr.ValidateToken(req.SessionId, req.Token); err != nil {
		return nil, status.Errorf(codes.Unauthenticated, "ungültiges Token: %v", err)
	}
	talkers := h.relay.ActiveTalkers()
	resp := &pb.ListActiveTalkersResponse{
		Talkers: make([]*pb.ActiveTalker, len(talkers)),
	}
	for i, t := range talkers {
		resp.Talkers[i] = &pb.ActiveTalker{
			ClientId:    t.ClientID,
			DisplayName: t.DisplayName,
			BusIds:      t.BusIDs,
		}
	}
	return resp, nil
}

func (h *Handler) buildStatus() *pb.TalkbackStatus {
	talkers := h.relay.ActiveTalkers()
	protoTalkers := make([]*pb.ActiveTalker, len(talkers))
	for i, t := range talkers {
		protoTalkers[i] = &pb.ActiveTalker{
			ClientId:    t.ClientID,
			DisplayName: t.DisplayName,
			BusIds:      t.BusIDs,
		}
	}
	return &pb.TalkbackStatus{
		Active:         len(talkers) > 0,
		ActiveTalkers:  protoTalkers,
	}
}
