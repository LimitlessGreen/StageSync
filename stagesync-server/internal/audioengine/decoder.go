package audioengine

import (
	"stagesync-server/internal/decode"
)

// DecodePCM is the exported entry point for callers that need decoded f32
// interleaved PCM at a given rate/channel count. Delegates to internal/decode
// which is CGo-free and safe to import from any package.
func DecodePCM(path string, targetRate, targetChannels uint32) ([]float32, uint32, uint32, error) {
	return decode.PCM(path, targetRate, targetChannels)
}

// decodeFile is the package-internal alias used by engine.go (Preload).
func decodeFile(path string, targetRate, targetChannels uint32) ([]float32, uint32, uint32, error) {
	return decode.PCM(path, targetRate, targetChannels)
}
