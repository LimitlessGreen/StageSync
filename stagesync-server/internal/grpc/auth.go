package grpc

import (
	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/session"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// authBasic prüft nur Token-Gültigkeit, keine Task-Anforderungen.
func authBasic(mgr *session.Manager, sessionID, token string) error {
	if _, _, err := mgr.ValidateToken(sessionID, token); err != nil {
		return status.Error(codes.Unauthenticated, err.Error())
	}
	return nil
}

// authWrite prüft Token + MASTER- oder EDITOR-Task.
func authWrite(mgr *session.Manager, sessionID, token string) error {
	return authTasks(mgr, sessionID, token,
		pb.NodeTask_NODE_TASK_MASTER, pb.NodeTask_NODE_TASK_EDITOR)
}

// authMaster prüft Token + MASTER-Task.
func authMaster(mgr *session.Manager, sessionID, token string) error {
	return authTasks(mgr, sessionID, token, pb.NodeTask_NODE_TASK_MASTER)
}

// authTasks prüft Token-Gültigkeit und ob die Node mindestens einen der
// geforderten Tasks hat.
func authTasks(mgr *session.Manager, sessionID, token string, required ...pb.NodeTask) error {
	sess, nodeID, err := mgr.ValidateToken(sessionID, token)
	if err != nil {
		return status.Error(codes.Unauthenticated, err.Error())
	}
	n, ok := sess.GetNode(nodeID)
	if !ok {
		return status.Error(codes.Unauthenticated, "node not found in session")
	}
	for _, t := range n.Info.Tasks {
		for _, r := range required {
			if t == r {
				return nil
			}
		}
	}
	return status.Error(codes.PermissionDenied, "insufficient node task for this operation")
}
