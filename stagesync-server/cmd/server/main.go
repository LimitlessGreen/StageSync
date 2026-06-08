package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"

	"stagesync-server/internal/audioengine"
	"stagesync-server/internal/audionode"
	"stagesync-server/internal/coreserver"
	"stagesync-server/internal/midinode"
)

var (
	port        = flag.Int("port", 50051, "gRPC server port")
	serviceName = flag.String("name", "StageSync", "mDNS service name")
	dataDir     = flag.String("data-dir", "", "state directory (default: ./data)")
	ramCacheMB  = flag.Int64("ram-cache-mb", 2048, "RAM budget for audio cache in MiB")

	enableAudioNode      = flag.Bool("audio-node", false, "Start an internal audio node (malgo/miniaudio).")
	audioBackend         = flag.String("audio-backend", "", "Preferred audio backend (e.g. jack, alsa, pulseaudio, wasapi, asio).")
	audioBackendPriority = flag.String("audio-backend-priority", "", "Comma-separated backend priority list.")
	audioDevice          = flag.Int("audio-device", -1, "Output device index (-1 = system default).")
	audioSampleRate      = flag.Uint("audio-sample-rate", 48000, "Output sample rate in Hz.")
	audioChannels        = flag.Uint("audio-channels", 2, "Output channel count.")

	enableMidiNode = flag.Bool("midi-node", false, "Start an internal MIDI controller node (e.g. Akai APC Mini).")
	midiPort       = flag.String("midi-port", "APC", "Substring to match the MIDI controller port name.")
)

func main() {
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	dir := *dataDir
	if dir == "" {
		dir = filepath.Join(".", "data")
	}

	srv, err := coreserver.Start(ctx, coreserver.Config{
		Port:          *port,
		DataDir:       dir,
		ServiceName:   *serviceName,
		RamCacheBytes: *ramCacheMB * 1024 * 1024,
	})
	if err != nil {
		log.Fatalf("coreserver: %v", err)
	}

	if *enableMidiNode {
		log.Printf("--midi-node: starting internal MIDI node (port match %q)", *midiPort)
		mn := midinode.New(srv.SessionManager(), srv.Dispatcher(), srv.GridHandler(), *midiPort)
		mn.Start(ctx)
	}

	if *enableAudioNode {
		log.Println("--audio-node: starting internal audio node (malgo/miniaudio)")
		backendPriority := parseBackendPriority(*audioBackendPriority)
		if *audioBackend != "" {
			backendPriority = append([]string{*audioBackend}, backendPriority...)
		}
		audioOpts := audioengine.Options{
			SampleRate:      uint32(*audioSampleRate),
			Channels:        uint32(*audioChannels),
			DeviceIndex:     *audioDevice,
			BackendPriority: backendPriority,
		}
		an := audionode.New(srv.SessionManager(), srv.Dispatcher(), srv.MediaStore(), audioOpts)
		an.Start(ctx)
		srv.ShowControlHandler().SetSilenceDetector(an)
	}

	<-ctx.Done()
	log.Println("shutting down...")
	srv.GracefulStop()
	log.Println("shutdown complete.")
}

func parseBackendPriority(raw string) []string {
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
