package media

import (
	"math"
	"os"

	"github.com/mewkiz/flac"
)

func parseFLAC(path string) *AudioInfo {
	f, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer f.Close()
	stream, err := flac.New(f)
	if err != nil {
		return nil
	}

	info := stream.Info
	if info.SampleRate == 0 || info.NChannels == 0 {
		return nil
	}

	sampleRate := int(info.SampleRate)
	channels := int(info.NChannels)
	scale := 1.0 / math.Pow(2, float64(info.BitsPerSample-1))
	maxFrames := sampleRate * 300

	pcm := make([]float64, 0, min(int(info.NSamples)*channels, maxFrames*channels))
	for len(pcm)/channels < maxFrames {
		frame, err := stream.ParseNext()
		if err != nil {
			break
		}
		nSamples := len(frame.Subframes[0].Samples)
		for i := 0; i < nSamples && len(pcm)/channels < maxFrames; i++ {
			for ch := 0; ch < channels; ch++ {
				pcm = append(pcm, float64(frame.Subframes[ch].Samples[i])*scale)
			}
		}
	}

	var durationMs int64
	if info.NSamples > 0 {
		durationMs = int64(info.NSamples) * 1000 / int64(sampleRate)
	}

	ai := &AudioInfo{
		DurationMs: durationMs,
		Channels:   int32(channels),
		SampleRate: int32(sampleRate),
		BitDepth:   int32(info.BitsPerSample),
	}
	if len(pcm) >= channels {
		v := integratedLoudness(pcm, sampleRate, channels)
		if !math.IsInf(v, 0) && !math.IsNaN(v) {
			ai.LoudnessLufs = &v
		}
	}
	return ai
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
