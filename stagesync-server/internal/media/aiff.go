package media

import (
	"math"
	"os"

	"github.com/go-audio/aiff"
)

func parseAIFF(path string) *AudioInfo {
	f, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer f.Close()

	dec := aiff.NewDecoder(f)
	if !dec.IsValidFile() {
		return nil
	}

	sampleRate := int32(dec.SampleRate)
	channels := int32(dec.NumChans)
	bitDepth := int32(dec.BitDepth)
	if sampleRate <= 0 || channels <= 0 {
		return nil
	}

	buf, err := dec.FullPCMBuffer()
	if err != nil || buf == nil {
		return nil
	}

	var durationMs int64
	if channels > 0 && sampleRate > 0 {
		frames := int64(len(buf.Data)) / int64(channels)
		durationMs = frames * 1000 / int64(sampleRate)
	}

	ai := &AudioInfo{
		DurationMs: durationMs,
		Channels:   channels,
		SampleRate: sampleRate,
		BitDepth:   bitDepth,
	}

	pcm := aiffPCMToFloat64(buf.Data, bitDepth)
	if len(pcm) >= int(channels) {
		v := integratedLoudness(pcm, int(sampleRate), int(channels))
		if !math.IsInf(v, 0) && !math.IsNaN(v) {
			ai.LoudnessLufs = &v
		}
	}
	return ai
}

func aiffPCMToFloat64(samples []int, bitDepth int32) []float64 {
	out := make([]float64, len(samples))
	switch bitDepth {
	case 16:
		scale := 1.0 / 32768.0
		for i, s := range samples {
			out[i] = float64(s) * scale
		}
	case 24:
		scale := 1.0 / 8388608.0
		for i, s := range samples {
			out[i] = float64(s) * scale
		}
	case 32:
		scale := 1.0 / 2147483648.0
		for i, s := range samples {
			out[i] = float64(s) * scale
		}
	default:
		scale := 1.0 / 32768.0
		for i, s := range samples {
			out[i] = float64(s) * scale
		}
	}
	return out
}
