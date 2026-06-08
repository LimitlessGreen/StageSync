package grpc

import (
	"stagesync-server/internal/session"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

var sessionErrCodes = map[error]codes.Code{
	session.ErrSessionNotFound:  codes.NotFound,
	session.ErrSessionExists:    codes.AlreadyExists,
	session.ErrInvalidToken:     codes.Unauthenticated,
	session.ErrInvalidPassword:  codes.Unauthenticated,
	session.ErrNodeNotFound:     codes.NotFound,
	session.ErrPermissionDenied: codes.PermissionDenied,
}

// mapErr wandelt bekannte Domain-Fehler in gRPC-Status-Codes um.
// Zusätzliche Mappings können per extra übergeben werden.
func mapErr(err error, extra ...map[error]codes.Code) error {
	if err == nil {
		return nil
	}
	for _, m := range append([]map[error]codes.Code{sessionErrCodes}, extra...) {
		if c, ok := m[err]; ok {
			return status.Error(c, err.Error())
		}
	}
	return status.Errorf(codes.Internal, "%v", err)
}
