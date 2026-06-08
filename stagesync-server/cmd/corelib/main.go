// cmd/corelib is the embeddable StageSync core library.
//
// It exports a minimal C API so Flutter can start and stop the StageSync
// gRPC server in-process via dart:ffi. Unlike cmd/server it intentionally
// does NOT import audioengine, audionode or midinode — all of which require
// CGo. This keeps the library compilable with gomobile (Android/iOS) and as
// a plain c-shared library (desktop).
//
// Build as a desktop shared library:
//
//	go build -buildmode=c-shared -o stagesync_core.dll ./cmd/corelib   (Windows)
//	go build -buildmode=c-shared -o libstagesync_core.so ./cmd/corelib (Linux)
//	go build -buildmode=c-shared -o libstagesync_core.dylib ./cmd/corelib (macOS)
//
// Build for Android/iOS via gomobile:
//
//	gomobile bind -target=android,ios -o StagesyncCore ./cmd/corelib
package main

// #include <stdlib.h>
import "C"

import (
	"context"
	"log"
	"sync"

	"stagesync-server/internal/coreserver"
)

var (
	mu     sync.Mutex
	srv    *coreserver.Server
	cancel context.CancelFunc
)

// stagesync_start starts the StageSync core gRPC server.
//
//	port    — TCP port to listen on (0 → default 50051)
//	dataDir — path to the persistent state directory (empty → "./data")
//
// Returns 0 on success, -1 if the server is already running or fails to start.
//
//export stagesync_start
func stagesync_start(port C.int, dataDir *C.char) C.int {
	mu.Lock()
	defer mu.Unlock()

	if srv != nil {
		log.Println("[corelib] already running")
		return -1
	}

	ctx, cancelFn := context.WithCancel(context.Background())

	s, err := coreserver.Start(ctx, coreserver.Config{
		Port:    int(port),
		DataDir: C.GoString(dataDir),
	})
	if err != nil {
		log.Printf("[corelib] start failed: %v", err)
		cancelFn()
		return -1
	}

	srv = s
	cancel = cancelFn
	return 0
}

// stagesync_stop shuts down the running StageSync core server gracefully.
//
//export stagesync_stop
func stagesync_stop() {
	mu.Lock()
	defer mu.Unlock()

	if srv == nil {
		return
	}
	cancel()
	srv.GracefulStop()
	srv = nil
	cancel = nil
}

// stagesync_version returns the library version string. The caller must NOT
// free the returned pointer — it points to a Go-managed string.
//
//export stagesync_version
func stagesync_version() *C.char {
	return C.CString("1.0.0")
}

func main() {}
