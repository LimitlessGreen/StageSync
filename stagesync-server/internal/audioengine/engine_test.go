package audioengine

import (
	"math"
	"testing"
)

// newTestEngine creates an Engine without a real audio device, suitable for
// unit-testing mix logic, state transitions, and handle management.
func newTestEngine() *Engine {
	return &Engine{
		handles:          make(map[string]*Handle),
		streamingHandles: make(map[string]*StreamingHandle),
		assetPCM:         make(map[string][]float32),
		assetSilenceMs:   make(map[string]int64),
		sampleRate:       48000,
		channels:         2,
	}
}

// sineHandle adds a Handle with n frames of sine PCM at the engine sample rate.
func sineHandle(e *Engine, id string, frames int) *Handle {
	ch := int(e.channels)
	pcm := make([]float32, frames*ch)
	for i := 0; i < frames; i++ {
		v := float32(math.Sin(2 * math.Pi * 440 * float64(i) / float64(e.sampleRate)))
		for c := 0; c < ch; c++ {
			pcm[i*ch+c] = v
		}
	}
	h := &Handle{
		id:         id,
		pcm:        pcm,
		sampleRate: e.sampleRate,
		channels:   e.channels,
		state:      StatePlaying,
		volume:     1.0,
	}
	e.mu.Lock()
	e.handles[id] = h
	e.mu.Unlock()
	return h
}

// mixFrames calls e.mix() for n frames and returns the f32 output.
func mixFrames(e *Engine, frames int) []float32 {
	ch := int(e.channels)
	buf := make([]byte, frames*ch*4)
	e.mix(buf, uint32(frames))
	out := make([]float32, frames*ch)
	for i, v := range out {
		_ = v
		bits := uint32(buf[i*4]) | uint32(buf[i*4+1])<<8 | uint32(buf[i*4+2])<<16 | uint32(buf[i*4+3])<<24
		out[i] = math.Float32frombits(bits)
	}
	return out
}

// peak returns the maximum absolute sample value in samples.
func peak(samples []float32) float32 {
	var p float32
	for _, v := range samples {
		if v < 0 {
			v = -v
		}
		if v > p {
			p = v
		}
	}
	return p
}

// ── State-transition tests ────────────────────────────────────────────────────

func TestStopPausedHandleIsImmediate(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)
	e.handles["c1"].state = StatePaused

	if err := e.Stop("c1", 500); err != nil {
		t.Fatalf("Stop returned error: %v", err)
	}
	if e.handles["c1"].state != StateDone {
		t.Fatalf("state=%v, want StateDone", e.handles["c1"].state)
	}
}

func TestStopPausedHandleProducesNoAudio(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)
	e.handles["c1"].state = StatePaused

	_ = e.Stop("c1", 500)

	// mix() should output silence — handle is done, nothing to play.
	out := mixFrames(e, 512)
	if p := peak(out); p > 1e-6 {
		t.Fatalf("expected silence after Stop(paused), got peak=%f", p)
	}
}

func TestStopPausingHandleKeepsFadeProgress(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)
	h := e.handles["c1"]
	h.state = StatePausing
	h.stopFadeOutSamples = 2400 // 50 ms at 48 kHz
	h.stopFadePos = 1200        // halfway through

	if err := e.Stop("c1", 999); err != nil {
		t.Fatalf("Stop returned error: %v", err)
	}
	if h.state != StateStopping {
		t.Fatalf("state=%v, want StateStopping", h.state)
	}
	// Fade position must not be reset.
	if h.stopFadePos != 1200 {
		t.Fatalf("stopFadePos=%d, want 1200 (fade must not reset)", h.stopFadePos)
	}
}

func TestStopPlayingWithFadeStartsFreshFade(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)

	if err := e.Stop("c1", 100); err != nil {
		t.Fatalf("Stop returned error: %v", err)
	}
	h := e.handles["c1"]
	if h.state != StateStopping {
		t.Fatalf("state=%v, want StateStopping", h.state)
	}
	want := msToSamples(100, e.sampleRate)
	if h.stopFadeOutSamples != want {
		t.Fatalf("stopFadeOutSamples=%d, want %d", h.stopFadeOutSamples, want)
	}
	if h.stopFadePos != 0 {
		t.Fatalf("stopFadePos=%d, want 0", h.stopFadePos)
	}
}

func TestStopPlayingNoFadeIsImmediate(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)

	if err := e.Stop("c1", 0); err != nil {
		t.Fatalf("Stop returned error: %v", err)
	}
	if e.handles["c1"].state != StateDone {
		t.Fatalf("state=%v, want StateDone", e.handles["c1"].state)
	}
}

func TestStopMissingHandleIsNoop(t *testing.T) {
	e := newTestEngine()
	if err := e.Stop("nonexistent", 100); err != nil {
		t.Fatalf("Stop on missing handle returned error: %v", err)
	}
}

func TestPauseTransitionAndPositionPreserved(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)
	h := e.handles["c1"]
	h.pos = 1000

	if err := e.Pause("c1", 0); err != nil {
		t.Fatalf("Pause returned error: %v", err)
	}
	if h.state != StatePaused {
		t.Fatalf("state=%v, want StatePaused", h.state)
	}
	if h.pausedAt != 1000 {
		t.Fatalf("pausedAt=%d, want 1000", h.pausedAt)
	}
}

func TestResumeRestoresPosition(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)
	h := e.handles["c1"]
	h.state = StatePaused
	h.pausedAt = 5000

	if err := e.Resume("c1", 0); err != nil {
		t.Fatalf("Resume returned error: %v", err)
	}
	if h.state != StatePlaying {
		t.Fatalf("state=%v, want StatePlaying", h.state)
	}
	if h.pos != 5000 {
		t.Fatalf("pos=%d, want 5000", h.pos)
	}
}

// ── mix() output tests ────────────────────────────────────────────────────────

func TestMixPlayingHandleProducesAudio(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)

	out := mixFrames(e, 512)
	if p := peak(out); p < 0.01 {
		t.Fatalf("expected audio from playing handle, got peak=%f", p)
	}
}

func TestMixStopFadeSilencesOverTime(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)
	_ = e.Stop("c1", 100) // 100 ms fade

	// Collect two windows: beginning and end of the fade.
	const window = 512
	early := mixFrames(e, window)

	// Advance through the fade.
	fadeFrames := int(msToSamples(100, e.sampleRate))
	for remaining := fadeFrames - window; remaining > window; remaining -= window {
		mixFrames(e, window)
	}
	late := mixFrames(e, window)

	if peak(early) <= peak(late) {
		t.Fatalf("fade should reduce level over time: early peak=%f late peak=%f",
			peak(early), peak(late))
	}
}

func TestMixPausedHandleProducesNoAudio(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)
	e.handles["c1"].state = StatePaused

	out := mixFrames(e, 512)
	if p := peak(out); p > 1e-6 {
		t.Fatalf("paused handle must produce silence, got peak=%f", p)
	}
}

func TestMixHandleRemovedAfterDone(t *testing.T) {
	e := newTestEngine()
	sineHandle(e, "c1", 48000)
	_ = e.Stop("c1", 0) // immediate stop → StateDone

	mixFrames(e, 512) // mix() should clean up the handle

	e.mu.Lock()
	_, exists := e.handles["c1"]
	e.mu.Unlock()
	if exists {
		t.Fatal("handle should have been removed after StateDone")
	}
}

// ── Helper function tests ─────────────────────────────────────────────────────

func TestDbToLinear(t *testing.T) {
	cases := []struct {
		db   float64
		want float32
	}{
		{0, 1.0},
		{-20, 0.1},
		{-100, 0.0},  // mute threshold
		{-200, 0.0},  // well below mute threshold
	}
	for _, tc := range cases {
		got := dbToLinear(tc.db)
		if math.Abs(float64(got-tc.want)) > 0.002 {
			t.Errorf("dbToLinear(%g)=%f, want %f", tc.db, got, tc.want)
		}
	}
}

func TestMsToSamples(t *testing.T) {
	if got := msToSamples(1000, 48000); got != 48000 {
		t.Fatalf("msToSamples(1000, 48000)=%d, want 48000", got)
	}
	if got := msToSamples(0, 48000); got != 0 {
		t.Fatalf("msToSamples(0, 48000)=%d, want 0", got)
	}
	if got := msToSamples(500, 44100); got != 22050 {
		t.Fatalf("msToSamples(500, 44100)=%d, want 22050", got)
	}
}

func TestDetectSilenceStartAllSilent(t *testing.T) {
	pcm := make([]float32, 48000*2) // 1 s stereo silence
	if ms := detectSilenceStart(pcm, 2, 48000); ms != 0 {
		t.Fatalf("all-silent file: expected 0, got %d ms", ms)
	}
}

func TestDetectSilenceStartImmediateContent(t *testing.T) {
	pcm := make([]float32, 48000*2)
	pcm[0] = 0.5 // non-silent from the first sample
	if ms := detectSilenceStart(pcm, 2, 48000); ms != 0 {
		t.Fatalf("immediate content: expected 0, got %d ms", ms)
	}
}

func TestDetectSilenceStartOffset(t *testing.T) {
	// 100 ms silence, then audio.
	silenceFrames := 48000 / 10 // 100 ms
	ch := uint32(2)
	pcm := make([]float32, (silenceFrames+48000)*int(ch))
	// Write signal starting at silenceFrames.
	for i := silenceFrames; i < silenceFrames+48000; i++ {
		pcm[i*int(ch)] = 0.5
	}
	ms := detectSilenceStart(pcm, ch, 48000)
	// Allowed tolerance: one window (20 ms).
	if ms < 80 || ms > 120 {
		t.Fatalf("expected ~100 ms silence, got %d ms", ms)
	}
}
