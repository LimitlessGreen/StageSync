// Package audioengine provides a low-latency audio playback engine built on
// malgo (miniaudio Go bindings). It supports ASIO (Windows), CoreAudio (macOS)
// and ALSA/PulseAudio (Linux).
//
// Architecture:
//   - One malgo.Device per engine instance (the active output device).
//   - Multiple concurrent PlaybackHandles mixed in the device callback.
//   - Server-timestamp scheduling: PLAY commands carry start_unix_millis;
//     the engine calculates the exact sample offset and starts at the right frame.
//   - Device changes are live: calling SetDevice reinitialises the malgo.Device
//     without dropping handles that have not yet started.
package audioengine

import (
	"fmt"
	"log"
	"math"
	"sync"
	"time"

	"github.com/gen2brain/malgo"
)

// DeviceInfo describes an available output device.
type DeviceInfo struct {
	Index int
	ID    malgo.DeviceID
	Name  string
}

// Engine manages a single audio output device and mixes concurrent handles.
type Engine struct {
	mu      sync.Mutex
	ctx     *malgo.AllocatedContext
	device  *malgo.Device
	handles map[string]*Handle // cueID → handle

	sampleRate uint32
	channels   uint32
	deviceIdx  int // -1 = system default
}

// New allocates the malgo context. Call Close when done.
func New() (*Engine, error) {
	ctx, err := malgo.InitContext(nil, malgo.ContextConfig{}, func(msg string) {
		log.Printf("[audioengine] malgo: %s", msg)
	})
	if err != nil {
		return nil, fmt.Errorf("malgo context init: %w", err)
	}
	e := &Engine{
		ctx:       ctx,
		handles:   make(map[string]*Handle),
		sampleRate: 48000,
		channels:   2,
		deviceIdx: -1,
	}
	return e, nil
}

// Close stops playback and releases resources.
func (e *Engine) Close() {
	e.mu.Lock()
	defer e.mu.Unlock()
	if e.device != nil {
		_ = e.device.Stop()
		e.device.Uninit()
		e.device = nil
	}
	_ = e.ctx.Uninit()
}

// EnumerateDevices returns all available output devices.
func (e *Engine) EnumerateDevices() ([]DeviceInfo, error) {
	infos, err := e.ctx.Devices(malgo.Playback)
	if err != nil {
		return nil, fmt.Errorf("enumerate devices: %w", err)
	}
	out := make([]DeviceInfo, len(infos))
	for i, d := range infos {
		out[i] = DeviceInfo{Index: i, ID: d.ID, Name: d.Name()}
	}
	return out, nil
}

// SetDevice reinitialises the output device. index -1 = system default.
// Handles that are preloaded but not yet started are preserved.
func (e *Engine) SetDevice(index int) error {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.initDeviceLocked(index)
}

// initDeviceLocked (re)creates the malgo.Device. Must be called with e.mu held.
func (e *Engine) initDeviceLocked(index int) error {
	// Stop and release previous device.
	if e.device != nil {
		_ = e.device.Stop()
		e.device.Uninit()
		e.device = nil
	}

	cfg := malgo.DefaultDeviceConfig(malgo.Playback)
	cfg.Playback.Format = malgo.FormatF32
	cfg.Playback.Channels = e.channels
	cfg.SampleRate = e.sampleRate
	cfg.Alsa.NoMMap = 1 // Linux: disable mmap for lower latency

	// Select device by index.
	if index >= 0 {
		devs, err := e.ctx.Devices(malgo.Playback)
		if err == nil && index < len(devs) {
			cfg.Playback.DeviceID = devs[index].ID.Pointer()
		} else {
			log.Printf("[audioengine] device index %d out of range (%d available), using default", index, len(devs))
		}
	}

	// Capture e for the closure without holding the lock during callback.
	eng := e
	deviceCallbacks := malgo.DeviceCallbacks{
		Data: func(outputSamples, _ []byte, frameCount uint32) {
			eng.mix(outputSamples, frameCount)
		},
	}

	dev, err := malgo.InitDevice(e.ctx.Context, cfg, deviceCallbacks)
	if err != nil {
		return fmt.Errorf("init device (index=%d): %w", index, err)
	}
	if err := dev.Start(); err != nil {
		dev.Uninit()
		return fmt.Errorf("start device: %w", err)
	}
	e.device = dev
	e.deviceIdx = index
	log.Printf("[audioengine] device initialised (index=%d, rate=%d, ch=%d)", index, e.sampleRate, e.channels)
	return nil
}

// EnsureStarted lazily initialises the device if not already running.
// Called before the first Preload so we know sample rate / channel count.
func (e *Engine) EnsureStarted() error {
	e.mu.Lock()
	defer e.mu.Unlock()
	if e.device != nil {
		return nil
	}
	return e.initDeviceLocked(e.deviceIdx)
}

// ── Playback API ──────────────────────────────────────────────────────────────

// PreloadPCM stores pre-generated f32 interleaved PCM directly under cueID.
// Useful for synthesised signals (test tones, sweeps) that need no file I/O.
func (e *Engine) PreloadPCM(cueID string, pcm []float32, sampleRate, channels uint32) error {
	if err := e.EnsureStarted(); err != nil {
		return err
	}
	h := &Handle{
		id:         cueID,
		pcm:        pcm,
		sampleRate: sampleRate,
		channels:   channels,
		state:      StatePreloaded,
		volume:     1.0,
	}
	e.mu.Lock()
	e.handles[cueID] = h
	e.mu.Unlock()
	log.Printf("[audioengine] preloaded PCM cueID=%s (%d frames, sr=%d, ch=%d)",
		cueID, len(pcm)/int(channels), sampleRate, channels)
	return nil
}

// Preload decodes the audio file at path and stores it under cueID.
// If a handle for cueID already exists it is replaced.
func (e *Engine) Preload(cueID, path string) error {
	if err := e.EnsureStarted(); err != nil {
		return err
	}

	pcm, sr, ch, err := decodeFile(path, e.sampleRate, e.channels)
	if err != nil {
		return fmt.Errorf("decode %q: %w", path, err)
	}

	h := &Handle{
		id:         cueID,
		pcm:        pcm,
		sampleRate: sr,
		channels:   ch,
		state:      StatePreloaded,
		volume:     1.0,
	}

	e.mu.Lock()
	e.handles[cueID] = h
	e.mu.Unlock()

	log.Printf("[audioengine] preloaded cueID=%s (%d frames, sr=%d, ch=%d)",
		cueID, len(pcm)/int(ch), sr, ch)
	return nil
}

// Play starts (or schedules) playback of cueID.
//   - startUnixMs == 0  → start immediately.
//   - startUnixMs > 0   → start at that server time; if already past, start from the
//     corresponding sample offset so the timeline stays correct (late-join sync).
func (e *Engine) Play(cueID string, startUnixMs int64, volumeDb float64,
	fadeInMs, fadeOutMs float64, loop bool) error {

	e.mu.Lock()
	h, ok := e.handles[cueID]
	e.mu.Unlock()
	if !ok {
		return fmt.Errorf("handle not found: %q (call Preload first)", cueID)
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	h.volume = dbToLinear(volumeDb)
	h.loop = loop
	h.fadeInSamples = msToSamples(fadeInMs, h.sampleRate)
	h.fadeOutSamples = msToSamples(fadeOutMs, h.sampleRate)

	totalFrames := int64(len(h.pcm)) / int64(h.channels)

	if startUnixMs > 0 {
		nowMs := time.Now().UnixMilli()
		elapsedMs := nowMs - startUnixMs
		if elapsedMs > 0 {
			// Already past start time — jump to correct position.
			offsetFrames := msToSamples(float64(elapsedMs), h.sampleRate)
			if offsetFrames >= totalFrames && !loop {
				log.Printf("[audioengine] cue %s already finished (elapsed=%dms)", cueID, elapsedMs)
				h.state = StateDone
				return nil
			}
			if loop {
				offsetFrames = offsetFrames % totalFrames
			}
			h.pos = offsetFrames
		} else {
			// Future start — schedule it.
			h.scheduleAt = startUnixMs
			h.state = StateScheduled
			log.Printf("[audioengine] cue %s scheduled in %dms", cueID, -elapsedMs)
			return nil
		}
	}

	h.state = StatePlaying
	log.Printf("[audioengine] play cueID=%s vol=%.1fdB loop=%v", cueID, volumeDb, loop)
	return nil
}

// Stop fades out and removes the handle.
func (e *Engine) Stop(cueID string, fadeOutMs float64) error {
	e.mu.Lock()
	h, ok := e.handles[cueID]
	if !ok {
		e.mu.Unlock()
		return nil
	}
	e.mu.Unlock()

	h.mu.Lock()
	defer h.mu.Unlock()
	if fadeOutMs > 0 {
		h.stopFadeOutSamples = msToSamples(fadeOutMs, h.sampleRate)
		h.stopFadePos = 0
		h.state = StateStopping
	} else {
		h.state = StateDone
	}
	return nil
}

// Pause freezes playback at the current position.
func (e *Engine) Pause(cueID string, fadeOutMs float64) error {
	e.mu.Lock()
	h, ok := e.handles[cueID]
	e.mu.Unlock()
	if !ok {
		return nil
	}

	h.mu.Lock()
	defer h.mu.Unlock()
	if h.state == StatePlaying {
		if fadeOutMs > 0 {
			h.stopFadeOutSamples = msToSamples(fadeOutMs, h.sampleRate)
			h.stopFadePos = 0
			h.state = StatePausing
		} else {
			h.state = StatePaused
		}
	}
	return nil
}

// Resume continues a paused handle.
func (e *Engine) Resume(cueID string, fadeInMs float64) error {
	e.mu.Lock()
	h, ok := e.handles[cueID]
	e.mu.Unlock()
	if !ok {
		return nil
	}

	h.mu.Lock()
	defer h.mu.Unlock()
	if h.state == StatePaused {
		h.fadeInSamples = msToSamples(fadeInMs, h.sampleRate)
		h.pos = h.pausedAt
		h.state = StatePlaying
	}
	return nil
}

// StopAll immediately silences everything (PANIC).
func (e *Engine) StopAll() {
	e.mu.Lock()
	defer e.mu.Unlock()
	for _, h := range e.handles {
		h.mu.Lock()
		h.state = StateDone
		h.mu.Unlock()
	}
}

// ── Mixer callback ────────────────────────────────────────────────────────────

// mix is called by the malgo device callback to fill outputSamples (f32LE).
func (e *Engine) mix(outputSamples []byte, frameCount uint32) {
	out := make([]float32, int(frameCount)*int(e.channels))

	nowMs := time.Now().UnixMilli()

	e.mu.Lock()
	handles := make([]*Handle, 0, len(e.handles))
	for _, h := range e.handles {
		handles = append(handles, h)
	}
	e.mu.Unlock()

	var done []string
	for _, h := range handles {
		h.mu.Lock()

		switch h.state {
		case StateScheduled:
			if nowMs >= h.scheduleAt {
				h.state = StatePlaying
				elapsedMs := nowMs - h.scheduleAt
				if elapsedMs > 0 {
					h.pos = msToSamples(float64(elapsedMs), h.sampleRate)
				}
			} else {
				h.mu.Unlock()
				continue
			}
		case StatePlaying, StateStopping, StatePausing:
			// handled below
		default:
			h.mu.Unlock()
			continue
		}

		totalFrames := int64(len(h.pcm)) / int64(h.channels)
		ch := int(h.channels)

		for frame := uint32(0); frame < frameCount; frame++ {
			if h.pos >= totalFrames {
				if h.loop {
					h.pos = 0
				} else {
					h.state = StateDone
					break
				}
			}

			// Per-sample gain with fade in/out and stop/pause fade.
			gain := h.volume
			framePos := h.pos

			// Fade in
			if h.fadeInSamples > 0 && framePos < h.fadeInSamples {
				gain *= float32(framePos) / float32(h.fadeInSamples)
			}
			// Fade out (near end)
			if h.fadeOutSamples > 0 {
				remaining := totalFrames - framePos
				if remaining < h.fadeOutSamples {
					gain *= float32(remaining) / float32(h.fadeOutSamples)
				}
			}
			// Stop/pause fade
			if h.state == StateStopping || h.state == StatePausing {
				if h.stopFadeOutSamples > 0 && h.stopFadePos < h.stopFadeOutSamples {
					gain *= 1 - float32(h.stopFadePos)/float32(h.stopFadeOutSamples)
					h.stopFadePos++
				} else {
					if h.state == StatePausing {
						h.pausedAt = h.pos
						h.state = StatePaused
					} else {
						h.state = StateDone
					}
					break
				}
			}

			// Mix into output buffer.
			srcBase := int(h.pos) * ch
			dstBase := int(frame) * int(e.channels)
			for c := 0; c < ch && c < int(e.channels); c++ {
				out[dstBase+c] += h.pcm[srcBase+c] * gain
			}
			h.pos++
		}

		if h.state == StateDone {
			done = append(done, h.id)
		}
		h.mu.Unlock()
	}

	// Clip output to [-1, 1] and write back to malgo buffer.
	for i := range out {
		if out[i] > 1.0 {
			out[i] = 1.0
		} else if out[i] < -1.0 {
			out[i] = -1.0
		}
	}
	f32ToBytes(out, outputSamples)

	// Remove finished handles.
	if len(done) > 0 {
		e.mu.Lock()
		for _, id := range done {
			delete(e.handles, id)
			log.Printf("[audioengine] handle done: %s", id)
		}
		e.mu.Unlock()
	}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func dbToLinear(db float64) float32 {
	if db <= -100 {
		return 0
	}
	return float32(math.Pow(10, db/20))
}

func msToSamples(ms float64, sampleRate uint32) int64 {
	return int64(ms * float64(sampleRate) / 1000)
}

// bytesToF32 interprets the malgo output buffer as f32 samples (read/write view).
// The returned slice shares the backing array with b.
func bytesToF32(b []byte) []float32 {
	n := len(b) / 4
	if n == 0 {
		return nil
	}
	out := make([]float32, n)
	for i := range out {
		bits := uint32(b[i*4]) | uint32(b[i*4+1])<<8 | uint32(b[i*4+2])<<16 | uint32(b[i*4+3])<<24
		out[i] = math.Float32frombits(bits)
	}
	return out
}

// f32ToBytes writes f32 samples back into the malgo output buffer.
func f32ToBytes(f []float32, b []byte) {
	for i, v := range f {
		bits := math.Float32bits(v)
		b[i*4] = byte(bits)
		b[i*4+1] = byte(bits >> 8)
		b[i*4+2] = byte(bits >> 16)
		b[i*4+3] = byte(bits >> 24)
	}
}
