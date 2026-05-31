package media

import (
	"encoding/binary"
	"io"
	"math"
	"os"

	mp3dec "github.com/hajimehoshi/go-mp3"
)

func parseMP3(path string) *AudioInfo {
	f, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer f.Close()

	dec, err := mp3dec.NewDecoder(f)
	if err != nil {
		return nil
	}

	sampleRate := int32(dec.SampleRate())
	if sampleRate <= 0 {
		return nil
	}

	const channels = int32(2) // go-mp3 decodes to stereo PCM16LE
	const bitDepth = int32(16)
	const bytesPerFrame = int64(channels * (bitDepth / 8))

	var durationMs int64
	if decodedBytes := dec.Length(); decodedBytes > 0 {
		frames := int64(decodedBytes) / bytesPerFrame
		durationMs = (frames * 1000) / int64(sampleRate)
	}

	return &AudioInfo{
		DurationMs:   durationMs,
		Channels:     channels,
		SampleRate:   sampleRate,
		BitDepth:     bitDepth,
		LoudnessLufs: measureLoudnessMP3(dec, int(sampleRate), int(channels)),
	}
}

func measureLoudnessMP3(dec *mp3dec.Decoder, sampleRate, channels int) *float64 {
	if sampleRate <= 0 || channels <= 0 {
		return nil
	}

	maxFrames := sampleRate * 300 // 5 minutes
	maxSamples := maxFrames * channels
	pcm := make([]float64, 0, maxSamples)
	buf := make([]byte, 32*1024)

	var hasPendingByte bool
	var pendingByte byte

	for len(pcm) < maxSamples {
		n, err := dec.Read(buf)
		if n > 0 {
			data := buf[:n]
			i := 0
			if hasPendingByte && len(data) > 0 {
				v := int16(uint16(pendingByte) | uint16(data[0])<<8)
				pcm = append(pcm, float64(v)/32768.0)
				hasPendingByte = false
				i = 1
			}
			for ; i+1 < len(data) && len(pcm) < maxSamples; i += 2 {
				v := int16(binary.LittleEndian.Uint16(data[i : i+2]))
				pcm = append(pcm, float64(v)/32768.0)
			}
			if i < len(data) {
				hasPendingByte = true
				pendingByte = data[i]
			}
		}
		if err != nil {
			if err == io.EOF {
				break
			}
			return nil
		}
	}

	if len(pcm) < channels {
		return nil
	}
	v := integratedLoudness(pcm, sampleRate, channels)
	if math.IsInf(v, 0) || math.IsNaN(v) {
		return nil
	}
	return &v
}
