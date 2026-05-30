package audioengine

import "sync"

// HandleState describes the lifecycle of a PlaybackHandle.
type HandleState int

const (
	StatePreloaded HandleState = iota // decoded, waiting for Play()
	StateScheduled                    // Play() called with future startUnixMs
	StatePlaying                      // actively mixing
	StatePausing                      // fade-out to pause
	StatePaused                       // frozen at pausedAt
	StateStopping                     // fade-out to stop
	StateDone                         // finished or stopped — will be removed
)

// Handle holds decoded PCM data and runtime playback state for one cue.
// All mutable fields below the mu are protected by mu.
type Handle struct {
	id         string
	pcm        []float32 // interleaved f32 at engine sample rate
	sampleRate uint32
	channels   uint32

	mu sync.Mutex

	state    HandleState
	pos      int64   // current frame position
	pausedAt int64   // frame position when paused
	loop     bool
	volume   float32 // linear gain

	// Fade in/out at natural boundaries (end of file or explicit fade params).
	fadeInSamples  int64
	fadeOutSamples int64

	// Stop/pause fade — counts down from stopFadeOutSamples to 0.
	stopFadeOutSamples int64
	stopFadePos        int64

	// Scheduled start: play at this server Unix ms.
	scheduleAt int64
}
