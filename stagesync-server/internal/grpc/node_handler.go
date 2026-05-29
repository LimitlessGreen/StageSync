package grpc

import (
	"context"
	"log"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/node"
	"stagesync-server/internal/session"
)

type NodeHandler struct {
	pb.UnimplementedNodeServiceServer
	sessionMgr *session.Manager
	dispatcher *node.Dispatcher
}

func NewNodeHandler(mgr *session.Manager, disp *node.Dispatcher) *NodeHandler {
	return &NodeHandler{sessionMgr: mgr, dispatcher: disp}
}

func (h *NodeHandler) RegisterNode(ctx context.Context, req *pb.RegisterNodeRequest) (*pb.NodeResponse, error) {
	sess, nodeID, err := h.sessionMgr.ValidateToken(req.SessionId, req.Token)
	if err != nil {
		return nil, status.Error(codes.Unauthenticated, err.Error())
	}

	n, ok := sess.GetNode(nodeID)
	if !ok {
		return nil, status.Error(codes.NotFound, "node not found in session")
	}

	// Debug: exakt loggen was der Client sendet
	nodeUrlFromNode := ""
	nodeUrlFromCaps := ""
	if req.Node != nil {
		nodeUrlFromNode = req.Node.MediaServerUrl
	}
	if req.Capabilities != nil && req.Capabilities.Audio != nil {
		nodeUrlFromCaps = req.Capabilities.Audio.MediaServerUrl
	}
	log.Printf("[RegisterNode] node=%s nodeUrl=%q capsUrl=%q", nodeID, nodeUrlFromNode, nodeUrlFromCaps)

	mediaUrl := nodeUrlFromNode
	if mediaUrl == "" {
		mediaUrl = nodeUrlFromCaps
	}
	if mediaUrl != "" {
		sess.SetNodeMediaServerUrl(nodeID, mediaUrl)
		n, _ = sess.GetNode(nodeID)
		log.Printf("[RegisterNode] URL gesetzt → n.Info.MediaServerUrl=%q", n.Info.MediaServerUrl)
	} else {
		log.Printf("[RegisterNode] WARNUNG: keine MediaServerUrl empfangen!")
	}

	// Capabilities persistieren — werden an WatchNodeHealth-Subscriber weitergegeben.
	if req.Capabilities != nil {
		sess.SetNodeCapabilities(nodeID, req.Capabilities)
		n, _ = sess.GetNode(nodeID)
	}
	h.sessionMgr.NotifyNodeUpdated(req.SessionId, n.Info)

	log.Printf("[node] registered: %s (%s) mediaServer=%s in session %s",
		n.Info.Name, n.Info.NodeType, n.Info.MediaServerUrl, req.SessionId)

	return &pb.NodeResponse{
		Node:  n.Info,
		Token: req.Token,
	}, nil
}

func (h *NodeHandler) UnregisterNode(ctx context.Context, req *pb.UnregisterNodeRequest) (*emptypb.Empty, error) {
	if err := h.sessionMgr.LeaveSession(req.SessionId, req.NodeId, req.Token); err != nil {
		return nil, status.Errorf(codes.Internal, "%v", err)
	}
	h.dispatcher.Unregister(req.NodeId)
	return &emptypb.Empty{}, nil
}

func (h *NodeHandler) ListNodes(ctx context.Context, req *pb.ListNodesRequest) (*pb.ListNodesResponse, error) {
	_, _, err := h.sessionMgr.ValidateToken(req.SessionId, req.Token)
	if err != nil {
		return nil, status.Error(codes.Unauthenticated, err.Error())
	}

	sess, err := h.sessionMgr.GetSession(req.SessionId)
	if err != nil {
		return nil, status.Error(codes.NotFound, err.Error())
	}

	infos := make([]*pb.NodeInfo, 0)
	for _, n := range sess.AllNodes() {
		infos = append(infos, n.Info)
	}
	return &pb.ListNodesResponse{Nodes: infos}, nil
}

func (h *NodeHandler) WatchNodes(req *pb.WatchNodesRequest, stream pb.NodeService_WatchNodesServer) error {
	_, _, err := h.sessionMgr.ValidateToken(req.SessionId, req.Token)
	if err != nil {
		return status.Error(codes.Unauthenticated, err.Error())
	}

	// Session-Events filtern und als NodeEvents re-publishen
	eventCh, _, err := h.sessionMgr.WatchSession(stream.Context(), req.SessionId)
	if err != nil {
		return status.Errorf(codes.NotFound, "%v", err)
	}

	for ev := range eventCh {
		var evType pb.NodeEvent_Type
		switch ev.Type {
		case pb.SessionEvent_TYPE_NODE_JOINED:
			evType = pb.NodeEvent_TYPE_REGISTERED
		case pb.SessionEvent_TYPE_NODE_LEFT:
			evType = pb.NodeEvent_TYPE_UNREGISTERED
		case pb.SessionEvent_TYPE_NODE_OFFLINE:
			evType = pb.NodeEvent_TYPE_OFFLINE
		default:
			continue
		}
		if err := stream.Send(&pb.NodeEvent{
			Type:        evType,
			Node:        ev.AffectedNode,
			OccurredAt:  ev.OccurredAt,
		}); err != nil {
			return err
		}
	}
	return nil
}

func (h *NodeHandler) UpdateCapabilities(ctx context.Context, req *pb.UpdateCapabilitiesRequest) (*emptypb.Empty, error) {
	_, _, err := h.sessionMgr.ValidateToken(req.SessionId, req.Token)
	if err != nil {
		return nil, status.Error(codes.Unauthenticated, err.Error())
	}
	// Capabilities werden in Phase 3 persistiert
	return &emptypb.Empty{}, nil
}

// StreamNodeCommands — Node öffnet diesen Stream, Server pusht Commands rein.
// Der Node hält den Stream offen solange er läuft.
func (h *NodeHandler) StreamNodeCommands(req *pb.StreamNodeCommandsRequest, stream pb.NodeService_StreamNodeCommandsServer) error {
	_, _, err := h.sessionMgr.ValidateToken(req.SessionId, req.Token)
	if err != nil {
		return status.Error(codes.Unauthenticated, err.Error())
	}

	log.Printf("[node] %s connected command stream (session %s)", req.NodeId, req.SessionId)

	// Tasks aus dem gespeicherten NodeInfo lesen (wurden beim JoinSession gesetzt)
	var tasks []pb.NodeTask
	if sess, err2 := h.sessionMgr.GetSession(req.SessionId); err2 == nil {
		if n, ok2 := sess.GetNode(req.NodeId); ok2 {
			tasks = n.Info.Tasks
		}
	}

	ch := h.dispatcher.Register(req.NodeId, tasks)
	defer func() {
		h.dispatcher.Unregister(req.NodeId)
		log.Printf("[node] %s disconnected command stream", req.NodeId)
	}()

	for {
		select {
		case <-stream.Context().Done():
			return nil
		case cmd, ok := <-ch:
			if !ok {
				return nil
			}
			if err := stream.Send(cmd); err != nil {
				return err
			}
		}
	}
}

// authMaster prüft, dass der Token zu einem Node mit MASTER-Task gehört.
func (h *NodeHandler) authMaster(sessionID, token string) error {
	sess, nodeID, err := h.sessionMgr.ValidateToken(sessionID, token)
	if err != nil {
		return status.Error(codes.Unauthenticated, err.Error())
	}
	n, ok := sess.GetNode(nodeID)
	if !ok {
		return status.Error(codes.Unauthenticated, "node not found")
	}
	for _, t := range n.Info.Tasks {
		if t == pb.NodeTask_NODE_TASK_MASTER {
			return nil
		}
	}
	return status.Error(codes.PermissionDenied, "only MASTER nodes may send node commands")
}

// SendNodeCommand — Master schickt Command an einen Node über den Dispatcher.
func (h *NodeHandler) SendNodeCommand(ctx context.Context, req *pb.SendNodeCommandRequest) (*pb.NodeCommandResponse, error) {
	if err := h.authMaster(req.SessionId, req.Token); err != nil {
		return nil, err
	}

	if req.Command == nil {
		return nil, status.Error(codes.InvalidArgument, "command is required")
	}

	if err := h.dispatcher.Dispatch(ctx, req.TargetNodeId, req.Command); err != nil {
		if err == node.ErrNodeNotConnected {
			return nil, status.Errorf(codes.Unavailable, "node %q not connected", req.TargetNodeId)
		}
		return nil, status.Errorf(codes.Internal, "%v", err)
	}

	return &pb.NodeCommandResponse{Success: true}, nil
}
