package media

import (
	"math"
	"os"

	"github.com/jfreymuth/oggvorbis"
)

func parseOGG(path string) *AudioInfo {
	f, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer f.Close()

	r, err := oggvorbis.NewReader(f)
	if err != nil {
		return nil
	}

	sampleRate := r.SampleRate()
	channels := r.Channels()
	if sampleRate <= 0 || channels <= 0 {
		return nil
	}

	var durationMs int64
	if total := r.Length(); total > 0 {
		durationMs = int64(total) * 1000 / int64(sampleRate)
	}

	maxFrames := sampleRate * 300
	pcm := make([]float64, 0, maxFrames*channels)
	buf := make([]float32, 4096)
	for len(pcm)/channels < maxFrames {
		n, err := r.Read(buf)
		for i := 0; i < n; i++ {
			pcm = append(pcm, float64(buf[i]))
		}
		if err != nil {
			break
		}
	}

	ai := &AudioInfo{
		DurationMs: durationMs,
		Channels:   int32(channels),
		SampleRate: int32(sampleRate),
		BitDepth:   0, // OGG Vorbis ist float-basiert, kein fester Bit-Depth
	}
	if len(pcm) >= channels {
		v := integratedLoudness(pcm, sampleRate, channels)
		if !math.IsInf(v, 0) && !math.IsNaN(v) {
			ai.LoudnessLufs = &v
		}
	}
	return ai
}
