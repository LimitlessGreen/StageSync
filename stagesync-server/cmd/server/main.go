package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	pb "stagesync-server/gen/go/stagesync/v1"

	"stagesync-server/internal/audioengine"
	"stagesync-server/internal/audionode"
	"stagesync-server/internal/busengine"
	"stagesync-server/internal/discovery"
	grpchandlers "stagesync-server/internal/grpc"
	"stagesync-server/internal/media"
	"stagesync-server/internal/node"
	"stagesync-server/internal/session"
	"stagesync-server/internal/showcontrol"
	"stagesync-server/internal/talkback"
)

var (
	port            = flag.Int("port", 50051, "gRPC server port")
	serviceName     = flag.String("name", "StageSync", "mDNS service name")
	enableAudioNode = flag.Bool("audio-node", false,
		"Start an internal audio node (malgo/miniaudio).")
	audioBackend = flag.String("audio-backend", "",
		"Preferred audio backend (e.g. jack, alsa, pulseaudio, wasapi, asio).")
	audioBackendPriority = flag.String("audio-backend-priority", "",
		"Comma-separated backend priority list, e.g. jack,alsa,pulseaudio.")
	audioDevice = flag.Int("audio-device", -1,
		"Output device index (-1 = system default).")
	audioSampleRate = flag.Uint("audio-sample-rate", 48000,
		"Output sample rate in Hz.")
	audioChannels = flag.Uint("audio-channels", 2,
		"Output channel count.")
	ramCacheMB = flag.Int64("ram-cache-mb", 2048,
		"RAM-Budget für den Audio-Cache in MiB (0 = 2 GiB Default).")
)

func parseBackendPriorityFlag(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

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

	// ── Media: Store + RAM-Cache + gRPC-Handler ───────────────────────────────
	mediaStore, err := media.NewStore(filepath.Join(dataDir, "media"))
	if err != nil {
		log.Fatalf("media store: %v", err)
	}

	cacheMaxBytes := *ramCacheMB * 1024 * 1024
	mediaCache := media.NewCache(cacheMaxBytes)
	mediaGRPC := media.NewGRPCHandler(mediaStore, mediaCache)
	storeWarmer := media.NewStoreWarmer(mediaCache, mediaStore)

	used, max, _ := mediaCache.Stats()
	log.Printf("Audio-Cache: %d MiB Budget (aktuell %d MiB genutzt)", max>>20, used>>20)

	// ── gRPC Server ──────────────────────────────────────────────────────────
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		log.Fatalf("listen: %v", err)
	}

	grpcServer := grpc.NewServer(
		grpc.ChainUnaryInterceptor(loggingInterceptor),
		grpc.ChainStreamInterceptor(loggingStreamInterceptor),
		// Größere Message-Limits für Audio-Uploads (default 4 MiB)
		grpc.MaxRecvMsgSize(512*1024*1024), // 512 MiB
		grpc.MaxSendMsgSize(512*1024*1024),
	)

	// ── Bus-Router + Talkback-Relay ─────────────────────────────────────────────
	busRouter := busengine.NewRouter()
	talkbackRelay := talkback.NewRelay(busRouter, dispatcher)
	talkbackHandler := talkback.NewHandler(sessionMgr, talkbackRelay, busRouter)

	pb.RegisterSessionServiceServer(grpcServer, grpchandlers.NewSessionHandler(sessionMgr))
	pb.RegisterNodeServiceServer(grpcServer, grpchandlers.NewNodeHandler(sessionMgr, dispatcher))
	showControlHandler := grpchandlers.NewShowControlHandler(sessionMgr, dispatcher, persistence, mediaStore)
	showControlHandler.SetWarmer(storeWarmer)
	showControlHandler.SetBusRouter(busRouter)
	showControlHandler.SetTalkbackRelay(talkbackRelay)
	pb.RegisterShowControlServiceServer(grpcServer, showControlHandler)
	pb.RegisterMediaServiceServer(grpcServer, mediaGRPC)
	pb.RegisterTalkbackServiceServer(grpcServer, talkbackHandler)

	reflection.Register(grpcServer)

	// ── Optional internal audio node ─────────────────────────────────────────
	if *enableAudioNode {
		log.Println("--audio-node: starting internal audio node (malgo/miniaudio)")
		backendPriority := parseBackendPriorityFlag(*audioBackendPriority)
		if *audioBackend != "" {
			backendPriority = append([]string{*audioBackend}, backendPriority...)
		}
		audioOpts := audioengine.Options{
			SampleRate:      uint32(*audioSampleRate),
			Channels:        uint32(*audioChannels),
			DeviceIndex:     *audioDevice,
			BackendPriority: backendPriority,
		}
		an := audionode.New(sessionMgr, dispatcher, mediaStore, audioOpts)
		an.Start(ctx)
		// Stille-Detektor: interne Audio-Engine hat das dekodierte PCM und kann
		// den erkannten Stille-Offset für alle Show-Engines bereitstellen.
		showControlHandler.SetSilenceDetector(an)
	}

	// ── mDNS Announcement ────────────────────────────────────────────────────
	txtRecords := []string{"version=1", fmt.Sprintf("port=%d", *port)}
	if _, err := discovery.Announce(ctx, *serviceName, *port, txtRecords); err != nil {
		log.Printf("mDNS announce failed (non-fatal): %v", err)
	}

	// ── Start ─────────────────────────────────────────────────────────────────
	log.Printf("StageSync Server listening on :%d (gRPC + MediaService)", *port)

	go func() {
		if err := grpcServer.Serve(lis); err != nil {
			log.Printf("gRPC serve error: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("Shutting down...")

	stopDone := make(chan struct{})
	go func() {
		grpcServer.GracefulStop()
		close(stopDone)
	}()
	select {
	case <-stopDone:
		log.Println("Graceful shutdown complete.")
	case <-time.After(5 * time.Second):
		log.Println("Graceful shutdown timed out, forcing stop.")
		grpcServer.Stop()
	}
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
