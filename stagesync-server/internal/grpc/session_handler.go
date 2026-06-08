package grpc

import (
	"context"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/session"
)

func nowTs() *pb.Timestamp { return &pb.Timestamp{UnixMillis: time.Now().UnixMilli()} }

type SessionHandler struct {
	pb.UnimplementedSessionServiceServer
	mgr *session.Manager
}

func NewSessionHandler(mgr *session.Manager) *SessionHandler {
	return &SessionHandler{mgr: mgr}
}

func (h *SessionHandler) CreateSession(ctx context.Context, req *pb.CreateSessionRequest) (*pb.SessionResponse, error) {
	sess, token, err := h.mgr.CreateSession(req)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "create session: %v", err)
	}
	node, _ := sess.GetNode(sess.MasterID)
	return &pb.SessionResponse{
		Session:      sess.ToProto(),
		Token:        token,
		AssignedNode: node.Info,
	}, nil
}

func (h *SessionHandler) JoinSession(ctx context.Context, req *pb.JoinSessionRequest) (*pb.SessionResponse, error) {
	sess, token, err := h.mgr.JoinSession(req)
	if err != nil {
		return nil, mapErr(err)
	}
	node, _ := sess.GetNode(req.MyNode.NodeId)
	return &pb.SessionResponse{
		Session:      sess.ToProto(),
		Token:        token,
		AssignedNode: node.Info,
	}, nil
}

func (h *SessionHandler) LeaveSession(ctx context.Context, req *pb.LeaveSessionRequest) (*emptypb.Empty, error) {
	if err := h.mgr.LeaveSession(req.SessionId, req.NodeId, req.Token); err != nil {
		return nil, status.Errorf(codes.Internal, "%v", err)
	}
	return &emptypb.Empty{}, nil
}

func (h *SessionHandler) Heartbeat(ctx context.Context, req *pb.HeartbeatRequest) (*pb.HeartbeatResponse, error) {
	if err := h.mgr.Heartbeat(req.SessionId, req.NodeId, req.Token); err != nil {
		return nil, status.Errorf(codes.Unauthenticated, "%v", err)
	}
	return &pb.HeartbeatResponse{
		ServerUnixMillis: time.Now().UnixMilli(),
		SessionHealthy:   true,
	}, nil
}

func (h *SessionHandler) WatchSession(req *pb.WatchSessionRequest, stream pb.SessionService_WatchSessionServer) error {
	_, _, err := h.mgr.ValidateToken(req.SessionId, req.Token)
	if err != nil {
		return status.Error(codes.Unauthenticated, err.Error())
	}

	ch, sess, err := h.mgr.WatchSession(stream.Context(), req.SessionId)
	if err != nil {
		return status.Errorf(codes.NotFound, "%v", err)
	}

	// Aktuellen Zustand sofort senden — der Client kann Events verpasst haben
	// die vor seiner Subscription gesendet wurden (z.B. RegisterNode-Broadcasts).
	if err := stream.Send(&pb.SessionEvent{
		Type:       pb.SessionEvent_TYPE_NODE_JOINED,
		Session:    sess.ToProto(),
		OccurredAt: nowTs(),
	}); err != nil {
		return err
	}

	for ev := range ch {
		if err := stream.Send(ev); err != nil {
			return err
		}
	}
	return nil
}

func (h *SessionHandler) ListSessions(ctx context.Context, _ *pb.ListSessionsRequest) (*pb.ListSessionsResponse, error) {
	all := h.mgr.AllSessions()
	protos := make([]*pb.Session, 0, len(all))
	for _, s := range all {
		protos = append(protos, s.ToProto())
	}
	return &pb.ListSessionsResponse{Sessions: protos}, nil
}
