package audioengine

import (
	"log"
	"sync"
)

// streamingRingCap: initiale Kapazität des Ring-Buffers in Frames (Samples pro Kanal).
// 24000 Samples @ 48 kHz = 500 ms für Live-Streams.
// Der Buffer wächst dynamisch wenn nötig (z.B. Delayed-Modus).
const streamingRingCap = 24000

// StreamingHandle ist ein Audio-Handle für kontinuierliche Echtzeit-Streams
// (Talkback Live und Delayed). PCM-Daten werden via WriteChunk() eingespeist und
// im Device-Callback von mix() gelesen.
type StreamingHandle struct {
	id       string
	channels uint32
	volume   float32

	mu        sync.Mutex
	ring      []float32 // interleaved PCM (cap = capacity * channels)
	writePos  int       // nächste Schreibposition (in Frames)
	readPos   int       // nächste Leseposition (in Frames)
	available int       // verfügbare Frames zum Lesen
	capacity  int       // Ring-Buffer-Kapazität in Frames

	active   bool // false = fertig, wird von mix() aus der Map entfernt
	draining bool // true = Stop() wurde gerufen; nach Leerung → active=false
}

func newStreamingHandle(id string, channels uint32) *StreamingHandle {
	cap := streamingRingCap
	return &StreamingHandle{
		id:       id,
		channels: channels,
		volume:   1.0,
		ring:     make([]float32, cap*int(channels)),
		capacity: cap,
		active:   true,
	}
}

// WriteChunk schreibt interleaved PCM-Frames in den Ring-Buffer.
// Der Buffer wächst automatisch wenn nötig (kein Datenverlust).
func (h *StreamingHandle) WriteChunk(pcm []float32) {
	if len(pcm) == 0 {
		return
	}
	frames := len(pcm) / int(h.channels)
	if frames == 0 {
		return
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	if !h.active && !h.draining {
		return
	}

	// Buffer wächst wenn der eingehende Burst nicht passt.
	if h.available+frames > h.capacity {
		h.grow(h.available + frames)
	}

	ch := int(h.channels)
	for i := 0; i < frames; i++ {
		dst := h.writePos * ch
		src := i * ch
		copy(h.ring[dst:dst+ch], pcm[src:src+ch])
		h.writePos = (h.writePos + 1) % h.capacity
	}
	h.available += frames
}

// grow vergrößert den Ring-Buffer auf mindestens needed Frames.
// Muss mit h.mu gehalten aufgerufen werden.
func (h *StreamingHandle) grow(needed int) {
	newCap := h.capacity
	for newCap < needed {
		newCap *= 2
	}
	ch := int(h.channels)
	newRing := make([]float32, newCap*ch)
	// Bestehende Daten in linearen Buffer umkopieren (Circular → Linear)
	for i := 0; i < h.available; i++ {
		srcPos := (h.readPos + i) % h.capacity
		copy(newRing[i*ch:(i+1)*ch], h.ring[srcPos*ch:(srcPos+1)*ch])
	}
	h.ring = newRing
	h.readPos = 0
	h.writePos = h.available
	h.capacity = newCap
	log.Printf("[audioengine] streaming handle %q: Buffer auf %d Frames gewachsen", h.id, newCap)
}

// readFrames liest bis zu frameCount Frames aus dem Ring-Buffer in out (addierend).
// outChannels ist die Kanalzahl des Ausgabegeräts (z.B. 2 für Stereo).
// Mono-Handles werden auf alle Ausgangskanäle upmixed.
// Muss mit h.mu gehalten aufgerufen werden.
func (h *StreamingHandle) readFrames(out []float32, frameCount uint32, outChannels int) uint32 {
	if h.available == 0 {
		if h.draining {
			// Alle Daten abgespielt → Handle deaktivieren; mix() entfernt ihn.
			h.active = false
		}
		return 0
	}
	toRead := int(frameCount)
	if toRead > h.available {
		toRead = h.available
	}

	srcCh := int(h.channels)
	for i := 0; i < toRead; i++ {
		srcBase := h.readPos * srcCh
		dstBase := i * outChannels
		for outC := 0; outC < outChannels; outC++ {
			srcC := min(outC, srcCh-1)
			out[dstBase+outC] += h.ring[srcBase+srcC] * h.volume
		}
		h.readPos = (h.readPos + 1) % h.capacity
	}
	h.available -= toRead

	if h.draining && h.available == 0 {
		h.active = false
	}
	return uint32(toRead)
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// SetVolume setzt den Mix-Pegel thread-safe.
func (h *StreamingHandle) SetVolume(linear float32) {
	h.mu.Lock()
	h.volume = linear
	h.mu.Unlock()
}

// Stop leitet das Draining ein: bestehende Puffer-Inhalte werden noch abgespielt,
// dann wird der Handle von mix() aus der Map entfernt.
func (h *StreamingHandle) Stop() {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.available > 0 {
		h.draining = true // Buffer läuft aus, dann active=false
	} else {
		h.active = false // Buffer leer → sofort deaktivieren
	}
}

// ── Engine-Integration ────────────────────────────────────────────────────────

// CreateStreamingHandle legt einen neuen Streaming-Handle an (ersetzt ggf. vorhandenen).
func (e *Engine) CreateStreamingHandle(id string, channels uint32) {
	h := newStreamingHandle(id, channels)
	e.mu.Lock()
	e.streamingHandles[id] = h
	e.mu.Unlock()
	log.Printf("[audioengine] streaming handle angelegt: %s", id)
}

// WriteStreamingChunk speist interleaved f32 PCM in den Handle mit id.
func (e *Engine) WriteStreamingChunk(id string, pcm []float32) {
	e.mu.Lock()
	h, ok := e.streamingHandles[id]
	e.mu.Unlock()
	if !ok {
		return
	}
	h.WriteChunk(pcm)
}

// SetStreamingVolume setzt den Pegel eines Streaming-Handles.
func (e *Engine) SetStreamingVolume(id string, linearGain float32) {
	e.mu.Lock()
	h, ok := e.streamingHandles[id]
	e.mu.Unlock()
	if !ok {
		return
	}
	h.SetVolume(linearGain)
}

// StopStreamingHandle leitet Draining ein: verbleibende Puffer-Daten werden
// noch abgespielt; mix() entfernt den Handle wenn der Buffer leer ist.
func (e *Engine) StopStreamingHandle(id string) {
	e.mu.Lock()
	h, ok := e.streamingHandles[id]
	e.mu.Unlock()
	if !ok {
		return
	}
	h.Stop()
	log.Printf("[audioengine] streaming handle draining: %s", id)
}

// HasStreamingHandle prüft ob ein Handle existiert und aktiv (nicht draining) ist.
func (e *Engine) HasStreamingHandle(id string) bool {
	e.mu.Lock()
	h, ok := e.streamingHandles[id]
	e.mu.Unlock()
	return ok && h.active && !h.draining
}

// IsPlaying gibt true zurück wenn eine Cue aktiv abgespielt wird (nicht paused/preloaded).
func (e *Engine) IsPlaying(cueID string) bool {
	e.mu.Lock()
	h, ok := e.handles[cueID]
	e.mu.Unlock()
	if !ok {
		return false
	}
	h.mu.Lock()
	active := h.state == StatePlaying || h.state == StateStopping || h.state == StatePausing
	h.mu.Unlock()
	return active
}
