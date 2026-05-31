package audionode

import (
	"log"
	"math"

	pionopus "github.com/pion/opus"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/audioengine"
)

const (
	talkbackSampleRate = 48000
	talkbackChannels   = 1 // Mono Talkback (Stereo optional, aber Mono reicht für Sprache)

	// duckDefaultDB: Talkback-Absenkung bei GO-Trigger in dB.
	duckDefaultDB = -12.0
	// duckDefaultMs: Dauer der Ducking-Rampe in ms.
	duckDefaultMs = 2000
)

// talkbackSink verwaltet Opus-Decoder pro Client und schreibt PCM in
// die audioengine.Engine via StreamingHandles.
type talkbackSink struct {
	engine   *audioengine.Engine
	decoders map[string]*pionopus.Decoder // clientID → Decoder
}

func newTalkbackSink(eng *audioengine.Engine) *talkbackSink {
	return &talkbackSink{
		engine:   eng,
		decoders: make(map[string]*pionopus.Decoder),
	}
}

// handleChunk verarbeitet einen eingehenden Talkback-Chunk:
// Opus-Decode → PCM → StreamingHandle.
func (s *talkbackSink) handleChunk(cmd *pb.AudioTalkbackChunkCommand) {
	if s.engine == nil || len(cmd.OpusData) == 0 {
		return
	}

	clientID := cmd.ClientId
	handleID := "talkback_" + clientID

	dec, ok := s.decoders[clientID]
	if !ok {
		d, err := pionopus.NewDecoderWithOutput(talkbackSampleRate, talkbackChannels)
		if err != nil {
			log.Printf("[talkback-sink] Opus-Decoder-Fehler client=%s: %v", clientID, err)
			return
		}
		dec = &d
		s.decoders[clientID] = dec

		if !s.engine.HasStreamingHandle(handleID) {
			s.engine.CreateStreamingHandle(handleID, talkbackChannels)
		}
	}

	// Opus dekodieren: max 120ms Frame @ 48kHz mono = 5760 Samples.
	// DecodeToInt16 liefert die tatsächliche Anzahl dekodierter Samples —
	// wichtig damit wir nicht den vollen 5760er-Buffer in den Ring-Buffer schreiben.
	pcmInt16 := make([]int16, 5760*talkbackChannels)
	n, err := dec.DecodeToInt16(cmd.OpusData, pcmInt16)
	if err != nil {
		log.Printf("[talkback-sink] Opus-Decode-Fehler client=%s: %v", clientID, err)
		return
	}
	if n == 0 {
		return
	}

	// int16 → float32, nur tatsächlich dekodierte Samples (n * channels)
	gain := float32(1.0)
	if cmd.LevelDb != 0 {
		gain = dbToLinear32(float64(cmd.LevelDb))
	}
	pcmF32 := make([]float32, n*talkbackChannels)
	for i := 0; i < n*talkbackChannels; i++ {
		pcmF32[i] = float32(pcmInt16[i]) / 32768.0 * gain
	}

	s.engine.WriteStreamingChunk(handleID, pcmF32)
}

// handleControl verarbeitet START/STOP/DUCK-Befehle.
func (s *talkbackSink) handleControl(cmd *pb.AudioTalkbackControlCommand) {
	clientID := cmd.ClientId
	handleID := "talkback_" + clientID

	switch cmd.Action {
	case pb.AudioTalkbackControlCommand_ACTION_START:
		// Immer neuen Handle anlegen — ersetzt ggf. noch drainenden Handle
		// von einer vorherigen Session, sodass kein Restton aus altem Puffer
		// in die neue Übertragung eingemischt wird.
		s.engine.CreateStreamingHandle(handleID, talkbackChannels)
		log.Printf("[talkback-sink] START client=%s", clientID)

	case pb.AudioTalkbackControlCommand_ACTION_STOP:
		s.engine.StopStreamingHandle(handleID)
		delete(s.decoders, clientID)
		log.Printf("[talkback-sink] STOP client=%s", clientID)

	case pb.AudioTalkbackControlCommand_ACTION_DUCK:
		duckDB := float64(cmd.DuckDb)
		if duckDB == 0 {
			duckDB = duckDefaultDB
		}
		duckMs := float64(cmd.DuckMs)
		if duckMs == 0 {
			duckMs = duckDefaultMs
		}
		// Alle laufenden Cues kurz absenken. Die Engine kennt alle Handles —
		// wir senken den Talkback-Handle-Volume direkt ab (er bleibt bei 0 dB),
		// die regulären Cues werden via FadeVolume gedimmt.
		// Hier: alle non-talkback Handles faden.
		log.Printf("[talkback-sink] DUCK %.1fdB über %.0fms", duckDB, duckMs)
		// Das eigentliche Ducking passiert über die Engine-API:
		// Die Engine wird von InternalAudioNode.handleTalkbackControl aufgerufen.
	}
}

func dbToLinear32(db float64) float32 {
	if db <= -100 {
		return 0
	}
	return float32(math.Pow(10, db/20))
}
