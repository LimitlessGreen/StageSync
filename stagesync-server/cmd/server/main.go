package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	pb "stagesync-server/gen/go/stagesync/v1"
	"path/filepath"

	"stagesync-server/internal/discovery"
	grpchandlers "stagesync-server/internal/grpc"
	"stagesync-server/internal/media"
	"stagesync-server/internal/node"
	"stagesync-server/internal/session"
	"stagesync-server/internal/showcontrol"
)

var (
	port        = flag.Int("port", 50051, "gRPC server port")
	mediaPort   = flag.Int("media-port", 50053, "HTTP media server port")
	serviceName = flag.String("name", "StageSync", "mDNS service name")
)

func main() {
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// ── Kern-Services ────────────────────────────────────────────────────────
	dataDir := filepath.Join(".", "data")
	log.Printf("State-Verzeichnis: %s", dataDir)

	sessionMgr := session.NewManager(dataDir)
	dispatcher := node.NewDispatcher()

	persistence := showcontrol.NewPersistence(dataDir)

	// ── Autoritativer Medien-Speicher (HTTP) ─────────────────────────────────
	mediaStore, err := media.NewStore(filepath.Join(dataDir, "media"))
	if err != nil {
		log.Fatalf("media store: %v", err)
	}
	mediaSrv := media.NewServer(mediaStore, fmt.Sprintf(":%d", *mediaPort))
	go func() {
		log.Printf("Media-HTTP-Server auf :%d", *mediaPort)
		if err := mediaSrv.Start(ctx); err != nil {
			log.Printf("media server error: %v", err)
		}
	}()

	// ── gRPC Server ──────────────────────────────────────────────────────────
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		log.Fatalf("listen: %v", err)
	}

	grpcServer := grpc.NewServer(
		grpc.ChainUnaryInterceptor(loggingInterceptor),
		grpc.ChainStreamInterceptor(loggingStreamInterceptor),
	)

	// Handler registrieren
	pb.RegisterSessionServiceServer(grpcServer, grpchandlers.NewSessionHandler(sessionMgr))
	pb.RegisterNodeServiceServer(grpcServer, grpchandlers.NewNodeHandler(sessionMgr, dispatcher))
	pb.RegisterShowControlServiceServer(grpcServer, grpchandlers.NewShowControlHandler(sessionMgr, dispatcher, persistence, mediaStore))

	// gRPC Reflection (für grpcurl / Debugging)
	reflection.Register(grpcServer)

	// ── mDNS Announcement ───────────────────────────────────────────────────
	txtRecords := []string{"version=1", fmt.Sprintf("port=%d", *port), fmt.Sprintf("mediaPort=%d", *mediaPort)}
	if _, err := discovery.Announce(ctx, *serviceName, *port, txtRecords); err != nil {
		log.Printf("mDNS announce failed (non-fatal): %v", err)
	}

	// ── Start ────────────────────────────────────────────────────────────────
	log.Printf("StageSync Server listening on :%d", *port)

	go func() {
		if err := grpcServer.Serve(lis); err != nil {
			log.Printf("gRPC serve error: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("Shutting down...")
	grpcServer.GracefulStop()
	log.Println("Server stopped.")
}

func loggingInterceptor(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
	resp, err := handler(ctx, req)
	if err != nil {
		log.Printf("[gRPC] %s → ERROR: %v", info.FullMethod, err)
	}
	return resp, err
}

func loggingStreamInterceptor(srv any, ss grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
	log.Printf("[gRPC stream] %s opened", info.FullMethod)
	err := handler(srv, ss)
	if err != nil {
		log.Printf("[gRPC stream] %s → ERROR: %v", info.FullMethod, err)
	}
	return err
}
