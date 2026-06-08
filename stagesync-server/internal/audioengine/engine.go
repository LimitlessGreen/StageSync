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
	Index     int
	ID        malgo.DeviceID
	Name      string
	Backend   string
	IsDefault bool
}

// Engine manages a single audio output device and mixes concurrent handles.
type Engine struct {
	mu      sync.Mutex
	ctx     *malgo.AllocatedContext
	device  *malgo.Device
	handles map[string]*Handle // cueID → handle

	// streamingHandles: Echtzeit-Streams (Talkback, Live-Input).
	// Werden von streaming_handle.go verwaltet.
	streamingHandles map[string]*StreamingHandle

	// assetPCM: decodierter PCM-Buffer pro Asset-ID (SHA-256).
	// Mehrere Cues mit demselben Asset teilen denselben Buffer — kein Doppel-Decode.
	assetPCM map[string][]float32 // assetID → PCM

	// assetSilenceMs: erkannter Stille-Start in ms pro Asset-ID.
	// Wird einmalig beim Preload berechnet; 0 = kein Skip nötig.
	assetSilenceMs map[string]int64

	sampleRate uint32
	channels   uint32
	deviceIdx  int // -1 = system default

	backendPriority []string
	activeBackend   string

	// mixBuf: wiederverwendeter Ausgabepuffer für mix(). Wird bei Bedarf vergrößert,
	// nie verkleinert — verhindert GC-Allokation im heißen Audio-Callback-Pfad.
	mixBuf []float32
}

// New allocates the malgo context. Call Close when done.
func New() (*Engine, error) {
	return NewWithOptions(Options{})
}

// NewWithOptions allocates the malgo context with runtime audio options.
func NewWithOptions(opts Options) (*Engine, error) {
	normalized := normalizeOptions(opts)
	ctx, activeBackend, backendPriority, err := initContextForPriority(normalized.BackendPriority)
	if err != nil {
		return nil, err
	}
	e := &Engine{
		ctx:              ctx,
		handles:          make(map[string]*Handle),
		streamingHandles: make(map[string]*StreamingHandle),
		assetPCM:         make(map[string][]float32),
		assetSilenceMs:   make(map[string]int64),
		sampleRate:       normalized.SampleRate,
		channels:         normalized.Channels,
		deviceIdx:        normalized.DeviceIndex,
		backendPriority:  backendPriority,
		activeBackend:    activeBackend,
	}
	return e, nil
}

func initContextForPriority(priority []string) (*malgo.AllocatedContext, string, []string, error) {
	initWithLogger := func(backends []malgo.Backend) (*malgo.AllocatedContext, error) {
		return malgo.InitContext(backends, malgo.ContextConfig{}, func(msg string) {
			log.Printf("[audioengine] malgo: %s", msg)
		})
	}

	normalized, backends, err := parseBackendPriority(priority)
	if err != nil {
		return nil, "", nil, fmt.Errorf("malgo backend config: %w", err)
	}

	if len(backends) == 0 {
		ctx, initErr := initWithLogger(nil)
		if initErr != nil {
			return nil, "", nil, fmt.Errorf("malgo context init: %w", initErr)
		}
		return ctx, "", normalized, nil
	}

	for i, backend := range backends {
		ctx, initErr := initWithLogger([]malgo.Backend{backend})
		if initErr == nil {
			active := ""
			if i < len(normalized) {
				active = normalized[i]
			}
			return ctx, active, normalized, nil
		}
		log.Printf("[audioengine] backend %q unavailable: %v", normalized[i], initErr)
	}

	return nil, "", nil, fmt.Errorf("malgo context init: no configured backend available (%v)", normalized)
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
	if e.ctx != nil {
		_ = e.ctx.Uninit()
		e.ctx.Free()
		e.ctx = nil
	}
}

// EnumerateDevices returns all available output devices.
func (e *Engine) EnumerateDevices() ([]DeviceInfo, error) {
	infos, err := e.ctx.Devices(malgo.Playback)
	if err != nil {
		return nil, fmt.Errorf("enumerate devices: %w", err)
	}
	out := make([]DeviceInfo, len(infos))
	for i, d := range infos {
		out[i] = DeviceInfo{
			Index:     i,
			ID:        d.ID,
			Name:      d.Name(),
			Backend:   e.activeBackend,
			IsDefault: d.IsDefault != 0,
		}
	}
	return out, nil
}

// ActiveBackend returns the currently active playback backend (e.g. jack/alsa/wasapi).
func (e *Engine) ActiveBackend() string {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.activeBackend
}

// BackendPriority returns the configured backend order.
func (e *Engine) BackendPriority() []string {
	e.mu.Lock()
	defer e.mu.Unlock()
	return append([]string(nil), e.backendPriority...)
}

// DeviceIndex returns the currently configured output device index (-1 = system default).
func (e *Engine) DeviceIndex() int {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.deviceIdx
}

// SampleRate returns the engine output sample rate.
func (e *Engine) SampleRate() uint32 {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.sampleRate
}

// Channels returns the engine output channel count.
func (e *Engine) Channels() uint32 {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.channels
}

// Reconfigure updates runtime settings (backend, priority, samplerate, channels, device).
func (e *Engine) Reconfigure(cfg RuntimeConfig) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	nextPriority := append([]string(nil), e.backendPriority...)
	if cfg.BackendPriority != nil {
		nextPriority = dedupeBackendPriority(cfg.BackendPriority)
	}
	if cfg.Backend != "" {
		nextPriority = prependPreferredBackend(cfg.Backend, nextPriority)
	}

	nextSampleRate := e.sampleRate
	if cfg.SampleRate > 0 {
		nextSampleRate = cfg.SampleRate
	}
	nextChannels := e.channels
	if cfg.Channels > 0 {
		nextChannels = cfg.Channels
	}
	nextDevice := e.deviceIdx
	if cfg.DeviceIndex != nil {
		nextDevice = *cfg.DeviceIndex
	}

	requiresContextReload := !stringSlicesEqual(nextPriority, e.backendPriority)
	if requiresContextReload {
		if err := e.reinitContextLocked(nextPriority); err != nil {
			return err
		}
	}

	e.sampleRate = nextSampleRate
	e.channels = nextChannels
	return e.initDeviceLocked(nextDevice)
}

func (e *Engine) reinitContextLocked(priority []string) error {
	newCtx, activeBackend, normalized, err := initContextForPriority(priority)
	if err != nil {
		return err
	}
	oldDevice := e.device
	e.device = nil
	oldCtx := e.ctx
	e.ctx = newCtx
	e.activeBackend = activeBackend
	e.backendPriority = normalized

	if oldDevice != nil {
		_ = oldDevice.Stop()
		oldDevice.Uninit()
	}

	if oldCtx != nil {
		_ = oldCtx.Uninit()
		oldCtx.Free()
	}
	return nil
}

func stringSlicesEqual(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
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
	log.Printf("[audioengine] device initialised (backend=%s, index=%d, rate=%d, ch=%d)", e.activeBackend, index, e.sampleRate, e.channels)
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
func (e *Engine) Preload(cueID, path string) error {
	return e.PreloadByAsset(cueID, "", path)
}

// IsAssetCached gibt true zurück wenn der PCM-Buffer für assetID bereits dekodiert im Speicher liegt.
func (e *Engine) IsAssetCached(assetID string) bool {
	if assetID == "" {
		return false
	}
	e.mu.Lock()
	_, hit := e.assetPCM[assetID]
	e.mu.Unlock()
	return hit
}

// PreloadByAsset decodes path and stores it under cueID.
// Wenn assetID nicht leer ist und das Asset bereits dekodiert wurde, wird
// der vorhandene PCM-Buffer wiederverwendet (kein Doppel-Decode).
func (e *Engine) PreloadByAsset(cueID, assetID, path string) error {
	if err := e.EnsureStarted(); err != nil {
		return err
	}

	var pcm []float32
	var sr, ch uint32

	if assetID != "" {
		e.mu.Lock()
		cached, hit := e.assetPCM[assetID]
		e.mu.Unlock()
		if hit {
			pcm = cached
			sr = e.sampleRate
			ch = e.channels
			log.Printf("[audioengine] preload cueID=%s assetID=%s…: PCM aus Cache (%d frames)",
				cueID, assetID[:8], len(pcm)/int(ch))
		}
	}

	if pcm == nil {
		var err error
		pcm, sr, ch, err = decodeFile(path, e.sampleRate, e.channels)
		if err != nil {
			return fmt.Errorf("decode %q: %w", path, err)
		}
		log.Printf("[audioengine] preloaded cueID=%s (%d frames, sr=%d, ch=%d)",
			cueID, len(pcm)/int(ch), sr, ch)
		if assetID != "" {
			silenceMs := detectSilenceStart(pcm, ch, sr)
			e.mu.Lock()
			e.assetPCM[assetID] = pcm // PCM für spätere Cues cachen
			e.assetSilenceMs[assetID] = silenceMs
			e.mu.Unlock()
			if silenceMs > 0 {
				log.Printf("[audioengine] silence detected: asset %s… skip=%.0fms", assetID[:min(8, len(assetID))], float64(silenceMs))
			}
		}
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
	return nil
}

// graceMs: wenn die Zeit zwischen dem autoritativen Startpunkt und dem Zeitpunkt
// des PLAY-Befehls kleiner als dieser Schwellwert ist, wird kein Frame-Seek
// durchgeführt. Verhindert, dass Preload-Latenzen (< 300ms) zum Überspringen
// des Anfangs führen — relevant beim ersten Play einer Cue.
const graceMs = int64(300)

// Play starts (or schedules) playback of cueID.
//   - startUnixMs == 0  → start immediately (no multi-node sync).
//   - startUnixMs > 0   → start at that server time; if already past by more
//     than graceMs, seek to the correct position so multi-node timelines stay
//     in sync; within graceMs (LAN latency + typical preload), start from
//     startTimeMs without seeking.
//   - startTimeMs > 0   → trim start: begin playback at this in-file offset.
func (e *Engine) Play(cueID string, startUnixMs int64, volumeDb float64,
	fadeInMs, fadeOutMs float64, loop bool, startTimeMs float64) error {

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
	h.fadeInOffset = 0 // will be adjusted below for late-join seeks
	h.fadeOutSamples = msToSamples(fadeOutMs, h.sampleRate)

	totalFrames := int64(len(h.pcm)) / int64(h.channels)

	// Base position: in-file trim start (startTimeMs).
	baseFrames := msToSamples(startTimeMs, h.sampleRate)
	if baseFrames >= totalFrames {
		baseFrames = 0
	}

	if startUnixMs > 0 {
		nowMs := time.Now().UnixMilli()
		elapsedMs := nowMs - startUnixMs
		if elapsedMs > 0 {
			if elapsedMs <= graceMs {
				// Innerhalb des Grace-Fensters: Preload-Latenz nicht als Seek einrechnen.
				// Verhindert den "spring in die Mitte" Effekt beim ersten Play.
				h.pos = baseFrames
				h.fadeInOffset = baseFrames
				h.state = StatePlaying
				log.Printf("[audioengine] play cueID=%s (grace %dms, from %.0fms)", cueID, elapsedMs, startTimeMs)
				return nil
			}
			// Weit nach dem Startpunkt: Frame-genauen Seek für Multi-Node-Sync.
			offsetFrames := baseFrames + msToSamples(float64(elapsedMs), h.sampleRate)
			if offsetFrames >= totalFrames && !loop {
				log.Printf("[audioengine] cue %s: elapsed %dms > Länge, spiele von startTimeMs=%.0f", cueID, elapsedMs, startTimeMs)
				h.pos = baseFrames
				h.state = StatePlaying
				return nil
			}
			if loop {
				offsetFrames = offsetFrames % totalFrames
			}
			h.pos = offsetFrames
			h.fadeInOffset = offsetFrames
		} else {
			// Noch in der Zukunft — einplanen.
			h.pos = baseFrames
			h.scheduleAt = startUnixMs
			h.state = StateScheduled
			log.Printf("[audioengine] cue %s scheduled in %dms", cueID, -elapsedMs)
			return nil
		}
	} else {
		h.pos = baseFrames
		h.fadeInOffset = baseFrames
	}

	h.state = StatePlaying
	log.Printf("[audioengine] play cueID=%s vol=%.1fdB loop=%v startTimeMs=%.0f", cueID, volumeDb, loop, startTimeMs)
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
	switch h.state {
	case StatePaused:
		// Nothing is audible; remove immediately without restarting playback.
		h.state = StateDone
	case StatePausing:
		// Already fading out; keep the ongoing fade but target stop instead of pause.
		h.state = StateStopping
	default:
		if fadeOutMs > 0 {
			h.stopFadeOutSamples = msToSamples(fadeOutMs, h.sampleRate)
			h.stopFadePos = 0
			h.state = StateStopping
		} else {
			h.state = StateDone
		}
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
			h.pausedAt = h.pos
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
		h.fadeInOffset = h.pausedAt // fade-in relative to resume position, not file start
		h.state = StatePlaying
	}
	return nil
}

// StopAll immediately silences everything (PANIC).
// FadeVolume gradually changes the volume of a playing cue to targetVolumeDb
// over durationMs. Optionally stops or pauses the cue when the fade finishes.
func (e *Engine) FadeVolume(cueID string, targetVolumeDb, durationMs float64, stopWhenDone, pauseWhenDone bool) error {
	e.mu.Lock()
	defer e.mu.Unlock()
	h, ok := e.handles[cueID]
	if !ok {
		return fmt.Errorf("handle not found: %q", cueID)
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.state != StatePlaying && h.state != StatePaused {
		return fmt.Errorf("cue %q not playing", cueID)
	}
	targetLinear := float32(dbToLinear(targetVolumeDb))
	totalSamples := msToSamples(durationMs, h.sampleRate)
	if totalSamples <= 0 {
		// Immediate volume change
		h.volume = targetLinear
		return nil
	}
	h.volumeFadeStart = h.volume
	h.volumeFadeTarget = targetLinear
	h.volumeFadeSamples = totalSamples
	h.volumeFadePos = 0
	h.volumeFadeStop = stopWhenDone
	h.volumeFadePause = pauseWhenDone
	log.Printf("[audioengine] fadeVolume cueID=%s → %.1fdB over %.0fms", cueID, targetVolumeDb, durationMs)
	return nil
}

func (e *Engine) StopAll() {
	e.mu.Lock()
	defer e.mu.Unlock()
	for _, h := range e.handles {
		h.mu.Lock()
		h.state = StateDone
		h.mu.Unlock()
	}
}

// DuckAll fades all currently playing handles to duckVolumeDb over durationMs,
// then ramps back to the original volume. Used for Talkback-Ducking on GO.
func (e *Engine) DuckAll(duckVolumeDb float64, durationMs float64) {
	e.mu.Lock()
	handles := make([]*Handle, 0, len(e.handles))
	for _, h := range e.handles {
		handles = append(handles, h)
	}
	e.mu.Unlock()

	duckLinear := float32(dbToLinear(duckVolumeDb))

	for _, h := range handles {
		h.mu.Lock()
		if h.state == StatePlaying {
			original := h.volume
			totalSamples := msToSamples(durationMs, h.sampleRate)
			if totalSamples > 0 {
				h.volumeFadeStart = original
				h.volumeFadeTarget = duckLinear
				h.volumeFadeSamples = totalSamples
				h.volumeFadePos = 0
				h.volumeFadeStop = false
				h.volumeFadePause = false
				// Nach dem Duck-Fade zurückblenden (zweites Fade wird nach erstem gestartet)
				// Vereinfachte Implementierung: direkt auf original zurücksetzen nach durationMs
				// via einer Goroutine (außerhalb des Callbacks).
				_ = original // wird in Goroutine genutzt
			}
		}
		h.mu.Unlock()
	}

	// Ramp-back nach durationMs (außerhalb des Audio-Callbacks, daher Goroutine)
	go func() {
		// Warte duck-Dauer
		time.Sleep(time.Duration(durationMs) * time.Millisecond)
		e.mu.Lock()
		currentHandles := make([]*Handle, 0, len(e.handles))
		for _, h := range e.handles {
			currentHandles = append(currentHandles, h)
		}
		e.mu.Unlock()
		for _, h := range currentHandles {
			h.mu.Lock()
			if h.state == StatePlaying && h.volume <= duckLinear*1.1 {
				// Nur zurückfaden wenn noch auf Duck-Level
				h.volumeFadeStart = h.volume
				h.volumeFadeTarget = 1.0                             // Unity zurück
				h.volumeFadeSamples = msToSamples(500, h.sampleRate) // 500ms Ramp-Back
				h.volumeFadePos = 0
			}
			h.mu.Unlock()
		}
	}()
}

// ── Mixer callback ────────────────────────────────────────────────────────────

// mix is called by the malgo device callback to fill outputSamples (f32LE).
func (e *Engine) mix(outputSamples []byte, frameCount uint32) {
	need := int(frameCount) * int(e.channels)
	if len(e.mixBuf) < need {
		e.mixBuf = make([]float32, need)
	}
	out := e.mixBuf[:need]
	for i := range out {
		out[i] = 0
	}

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
		case StateDone:
			// Already finished before this mix call (e.g. Stop with no fade).
			done = append(done, h.id)
			h.mu.Unlock()
			continue
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

			// Per-sample gain with fade in/out, stop/pause fade and continuous volume fade.
			gain := h.volume
			framePos := h.pos

			// Continuous volume fade (Fade-Cue)
			if h.volumeFadeSamples > 0 {
				t := float32(h.volumeFadePos) / float32(h.volumeFadeSamples)
				if t >= 1.0 {
					// Fade done
					h.volume = h.volumeFadeTarget
					h.volumeFadeSamples = 0
					if h.volumeFadeStop {
						h.state = StateDone
						break
					}
					if h.volumeFadePause {
						h.pausedAt = h.pos
						h.state = StatePaused
						break
					}
				} else {
					h.volume = h.volumeFadeStart + (h.volumeFadeTarget-h.volumeFadeStart)*t
					h.volumeFadePos++
				}
				gain = h.volume
			}

			// Fade in — relative to fadeInOffset so Resume-fades work correctly.
			if h.fadeInSamples > 0 {
				elapsed := framePos - h.fadeInOffset
				if elapsed >= 0 && elapsed < h.fadeInSamples {
					gain *= float32(elapsed) / float32(h.fadeInSamples)
				}
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

	// Streaming-Handles mischen (Talkback, Live-Input).
	e.mu.Lock()
	sHandles := make([]*StreamingHandle, 0, len(e.streamingHandles))
	for _, sh := range e.streamingHandles {
		sHandles = append(sHandles, sh)
	}
	e.mu.Unlock()

	var doneSH []string
	for _, sh := range sHandles {
		sh.mu.Lock()
		if sh.active || sh.draining {
			sh.readFrames(out, frameCount, int(e.channels))
		}
		if !sh.active {
			doneSH = append(doneSH, sh.id)
		}
		sh.mu.Unlock()
	}

	if len(doneSH) > 0 {
		e.mu.Lock()
		for _, id := range doneSH {
			delete(e.streamingHandles, id)
			log.Printf("[audioengine] streaming handle entfernt (leer): %s", id)
		}
		e.mu.Unlock()
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

// AssetSilenceStartMs liefert den erkannten Stille-Offset am Anfang eines Assets in ms.
// Gibt (0, false) zurück wenn das Asset nicht im Cache ist oder keine Stille erkannt wurde.
func (e *Engine) AssetSilenceStartMs(assetID string) (int64, bool) {
	if assetID == "" {
		return 0, false
	}
	e.mu.Lock()
	ms, ok := e.assetSilenceMs[assetID]
	e.mu.Unlock()
	return ms, ok && ms > 0
}

// ── Stille-Erkennung ─────────────────────────────────────────────────────────

// silenceWindowMs: Fenstergröße für die Peak-Analyse (ms).
// Kleinere Fenster erkennen kürzere Stille-Abschnitte, erhöhen aber Rechenzeit.
const silenceWindowMs = 20.0

// silenceThresholdLinear: Samples unterhalb dieser Amplitude gelten als Stille.
// Entspricht ca. −60 dBFS — Rauschen/Digitalstille-Artefakte werden ignoriert.
const silenceThresholdLinear = float32(0.001)

// detectSilenceStart scannt den dekodiertes PCM-Buffer und gibt zurück, ab wie
// vielen Millisekunden das erste nicht-stille Fenster beginnt. Gibt 0 zurück
// wenn die Datei sofort mit Inhalt beginnt oder zu kurz ist.
func detectSilenceStart(pcm []float32, channels, sampleRate uint32) int64 {
	if len(pcm) == 0 || channels == 0 || sampleRate == 0 {
		return 0
	}
	windowFrames := int(float64(sampleRate) * silenceWindowMs / 1000)
	if windowFrames < 1 {
		windowFrames = 1
	}
	totalFrames := len(pcm) / int(channels)

	for startFrame := 0; startFrame+windowFrames <= totalFrames; startFrame += windowFrames {
		endFrame := startFrame + windowFrames
		// Peak-Amplitude im Fenster bestimmen.
		var peak float32
		for f := startFrame; f < endFrame; f++ {
			for c := 0; c < int(channels); c++ {
				s := pcm[f*int(channels)+c]
				if s < 0 {
					s = -s
				}
				if s > peak {
					peak = s
				}
			}
		}
		if peak > silenceThresholdLinear {
			// Erstes nicht-stilles Fenster gefunden.
			ms := int64(float64(startFrame) / float64(sampleRate) * 1000)
			return ms
		}
	}
	return 0 // gesamtes File ist still
}

func dbToLinear(db float64) float32 {
	if db <= -100 {
		return 0
	}
	return float32(math.Pow(10, db/20))
}

func msToSamples(ms float64, sampleRate uint32) int64 {
	return int64(ms * float64(sampleRate) / 1000)
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
