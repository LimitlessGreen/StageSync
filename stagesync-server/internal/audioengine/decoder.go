package audioengine

import (
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strings"

	goaudioaiff "github.com/go-audio/aiff"
	goaudiowav "github.com/go-audio/wav"
	mp3dec "github.com/hajimehoshi/go-mp3"
	"github.com/jfreymuth/oggvorbis"
	"github.com/mewkiz/flac"
)

// DecodePCM is the exported entry point for other packages (e.g. peaks) that
// need decoded f32 interleaved PCM at a given rate/channel count.
func DecodePCM(path string, targetRate, targetChannels uint32) ([]float32, uint32, uint32, error) {
	return decodeFile(path, targetRate, targetChannels)
}

// decodeFile decodes an audio file to f32 interleaved PCM at the target
// sample rate and channel count.
//
// Supported formats: WAV (PCM/float), MP3.
// Other formats return an error.
func decodeFile(path string, targetRate, targetChannels uint32) ([]float32, uint32, uint32, error) {
	ext := strings.ToLower(filepath.Ext(path))
	switch ext {
	case ".wav":
		return decodeWAV(path, targetRate, targetChannels)
	case ".mp3":
		return decodeMP3(path, targetRate, targetChannels)
	case ".flac":
		return decodeFLAC(path, targetRate, targetChannels)
	case ".ogg":
		return decodeOGG(path, targetRate, targetChannels)
	case ".aiff", ".aif":
		return decodeAIFF(path, targetRate, targetChannels)
	default:
		return nil, 0, 0, fmt.Errorf("unsupported audio format: %q", ext)
	}
}

// ── WAV ───────────────────────────────────────────────────────────────────────

func decodeWAV(path string, targetRate, targetChannels uint32) ([]float32, uint32, uint32, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, 0, 0, err
	}
	defer f.Close()

	dec := goaudiowav.NewDecoder(f)
	if !dec.IsValidFile() {
		return nil, 0, 0, fmt.Errorf("invalid WAV file: %s", path)
	}
	if err := dec.FwdToPCM(); err != nil {
		return nil, 0, 0, fmt.Errorf("WAV seek to PCM: %w", err)
	}

	srcRate := uint32(dec.SampleRate)
	srcChannels := uint32(dec.NumChans)
	bitDepth := dec.BitDepth

	// Decode all PCM frames into an AudioIntBuffer.
	buf, err := dec.FullPCMBuffer()
	if err != nil {
		return nil, 0, 0, fmt.Errorf("WAV decode: %w", err)
	}

	// Convert int samples to f32.
	raw := intSamplesToF32(buf.Data, bitDepth)

	// Resample + remix to target rate and channels.
	out := resample(raw, srcRate, srcChannels, targetRate, targetChannels)
	return out, targetRate, targetChannels, nil
}

// intSamplesToF32 converts integer PCM samples to [-1.0, 1.0] float32.
func intSamplesToF32(samples []int, bitDepth uint16) []float32 {
	out := make([]float32, len(samples))
	switch bitDepth {
	case 8:
		scale := float32(1.0 / 128.0)
		for i, s := range samples {
			out[i] = float32(s-128) * scale
		}
	case 16:
		scale := float32(1.0 / 32768.0)
		for i, s := range samples {
			out[i] = float32(s) * scale
		}
	case 24:
		scale := float32(1.0 / 8388608.0)
		for i, s := range samples {
			out[i] = float32(s) * scale
		}
	case 32:
		scale := float32(1.0 / 2147483648.0)
		for i, s := range samples {
			out[i] = float32(s) * scale
		}
	default:
		scale := float32(1.0 / 32768.0)
		for i, s := range samples {
			out[i] = float32(s) * scale
		}
	}
	return out
}

// ── MP3 ───────────────────────────────────────────────────────────────────────

func decodeMP3(path string, targetRate, targetChannels uint32) ([]float32, uint32, uint32, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, 0, 0, err
	}
	defer f.Close()

	dec, err := mp3dec.NewDecoder(f)
	if err != nil {
		return nil, 0, 0, fmt.Errorf("MP3 init: %w", err)
	}

	srcRate := uint32(dec.SampleRate())
	// go-mp3 always outputs stereo int16 LE.
	const srcChannels = 2

	var raw []float32
	buf := make([]byte, 4096)
	for {
		n, err := dec.Read(buf)
		for i := 0; i+1 < n; i += 2 {
			s16 := int16(buf[i]) | int16(buf[i+1])<<8
			raw = append(raw, float32(s16)/32768.0)
		}
		if err != nil {
			break // io.EOF or real error
		}
	}

	out := resample(raw, srcRate, srcChannels, targetRate, targetChannels)
	return out, targetRate, targetChannels, nil
}

// ── Resample + channel remix ──────────────────────────────────────────────────

// resample converts interleaved PCM (srcRate, srcCh) to (dstRate, dstCh)
// using linear interpolation between frames.
func resample(src []float32, srcRate, srcCh, dstRate, dstCh uint32) []float32 {
	if len(src) == 0 {
		return nil
	}

	srcFrames := len(src) / int(srcCh)
	ratio := float64(srcRate) / float64(dstRate)
	dstFrames := int(math.Ceil(float64(srcFrames) / ratio))
	out := make([]float32, dstFrames*int(dstCh))

	for dstF := 0; dstF < dstFrames; dstF++ {
		srcFrac := float64(dstF) * ratio
		srcF0 := int(srcFrac)
		srcF1 := srcF0 + 1
		t := float32(srcFrac - float64(srcF0))

		if srcF1 >= srcFrames {
			srcF1 = srcFrames - 1
		}

		// Remix channels: src → dst channel count.
		// src mono → dst stereo: duplicate
		// src stereo → dst mono: average
		// same: copy
		for dstC := 0; dstC < int(dstCh); dstC++ {
			srcC := dstC
			if int(srcCh) == 1 {
				srcC = 0
			} else if int(srcCh) > int(dstCh) {
				// Downmix: average all src channels.
				var sum float32
				for sc := 0; sc < int(srcCh); sc++ {
					s0 := getSample(src, srcF0, sc, int(srcCh), srcFrames)
					s1 := getSample(src, srcF1, sc, int(srcCh), srcFrames)
					sum += s0*(1-t) + s1*t
				}
				out[dstF*int(dstCh)+dstC] = sum / float32(srcCh)
				continue
			}

			s0 := getSample(src, srcF0, srcC, int(srcCh), srcFrames)
			s1 := getSample(src, srcF1, srcC, int(srcCh), srcFrames)
			out[dstF*int(dstCh)+dstC] = s0*(1-t) + s1*t
		}
	}
	return out
}

func getSample(pcm []float32, frame, ch, channels, totalFrames int) float32 {
	if frame < 0 || frame >= totalFrames {
		return 0
	}
	idx := frame*channels + ch
	if idx >= len(pcm) {
		return 0
	}
	return pcm[idx]
}

// ── FLAC ──────────────────────────────────────────────────────────────────────

func decodeFLAC(path string, targetRate, targetChannels uint32) ([]float32, uint32, uint32, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, 0, 0, err
	}
	defer f.Close()
	stream, err := flac.New(f)
	if err != nil {
		return nil, 0, 0, fmt.Errorf("FLAC open: %w", err)
	}

	srcRate := uint32(stream.Info.SampleRate)
	srcChannels := uint32(stream.Info.NChannels)
	scale := float32(1.0 / math.Pow(2, float64(stream.Info.BitsPerSample-1)))

	var raw []float32
	for {
		frame, err := stream.ParseNext()
		if err != nil {
			break
		}
		nSamples := len(frame.Subframes[0].Samples)
		for i := 0; i < nSamples; i++ {
			for ch := 0; ch < int(srcChannels); ch++ {
				raw = append(raw, float32(frame.Subframes[ch].Samples[i])*scale)
			}
		}
	}

	out := resample(raw, srcRate, srcChannels, targetRate, targetChannels)
	return out, targetRate, targetChannels, nil
}

// ── OGG Vorbis ────────────────────────────────────────────────────────────────

func decodeOGG(path string, targetRate, targetChannels uint32) ([]float32, uint32, uint32, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, 0, 0, err
	}
	defer f.Close()

	r, err := oggvorbis.NewReader(f)
	if err != nil {
		return nil, 0, 0, fmt.Errorf("OGG open: %w", err)
	}

	srcRate := uint32(r.SampleRate())
	srcChannels := uint32(r.Channels())

	var raw []float32
	buf := make([]float32, 4096)
	for {
		n, err := r.Read(buf)
		raw = append(raw, buf[:n]...)
		if err != nil {
			break
		}
	}

	out := resample(raw, srcRate, srcChannels, targetRate, targetChannels)
	return out, targetRate, targetChannels, nil
}

// ── AIFF ──────────────────────────────────────────────────────────────────────

func decodeAIFF(path string, targetRate, targetChannels uint32) ([]float32, uint32, uint32, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, 0, 0, err
	}
	defer f.Close()

	dec := goaudioaiff.NewDecoder(f)
	if !dec.IsValidFile() {
		return nil, 0, 0, fmt.Errorf("invalid AIFF file: %s", path)
	}

	srcRate := uint32(dec.SampleRate)
	srcChannels := uint32(dec.NumChans)
	bitDepth := dec.BitDepth

	buf, err := dec.FullPCMBuffer()
	if err != nil {
		return nil, 0, 0, fmt.Errorf("AIFF decode: %w", err)
	}

	raw := intSamplesToF32(buf.Data, bitDepth)
	out := resample(raw, srcRate, srcChannels, targetRate, targetChannels)
	return out, targetRate, targetChannels, nil
}
