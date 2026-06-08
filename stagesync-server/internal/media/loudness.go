package media

// EBU R128 integrated loudness measurement (LUFS / LKFS).
//
// Implements ITU-R BS.1770-4 / EBU R128:
//   - K-weighting filter (two biquad stages, coefficients via bilinear transform)
//   - 400 ms gating blocks with 75 % overlap (100 ms hop)
//   - Absolute gate at -70 LKFS
//   - Relative gate at ungated_mean − 10 LU
//
// Supports PCM WAV files with 16-bit, 24-bit, or 32-bit integer samples.
// Supports 1–8 channels; surround weights per ITU-R BS.1770 Table 1.
// Returns nil when the file cannot be analysed.

import (
	"encoding/binary"
	"io"
	"math"
	"os"
)

// measureLoudnessWAV returns the EBU R128 integrated loudness in LUFS, or nil.
func measureLoudnessWAV(path string) *float64 {
	samples, sr, ch, err := readWAVPCMFloat(path)
	if err != nil || len(samples) == 0 || ch == 0 || sr == 0 {
		return nil
	}
	v := integratedLoudness(samples, sr, ch)
	if math.IsInf(v, 0) || math.IsNaN(v) {
		return nil
	}
	return &v
}

// ── K-weighting filter ────────────────────────────────────────────────────────

// kweightCoeffs returns biquad coefficients (b0,b1,b2, a1,a2) for the two
// K-weighting stages at the given sample rate.
// Formulas follow the libebur128 reference implementation.
func kweightCoeffs(fs float64) (b1, a1, b2, a2 [3]float64) {
	// Stage 1: high-shelf pre-filter (accounts for acoustic effect of the head)
	f0 := 1681.974450955533
	G := 3.999843853973347
	Q := 0.7071752369554196

	K := math.Tan(math.Pi * f0 / fs)
	Vh := math.Pow(10, G/20)
	Vb := math.Pow(Vh, 0.4996667741545416)
	a0 := 1 + K/Q + K*K

	b1 = [3]float64{
		(Vh + Vb*K/Q + K*K) / a0,
		2 * (K*K - Vh) / a0,
		(Vh - Vb*K/Q + K*K) / a0,
	}
	a1 = [3]float64{
		1,
		2 * (K*K - 1) / a0,
		(1 - K/Q + K*K) / a0,
	}

	// Stage 2: high-pass (RLB weighting)
	f0 = 38.13547087602444
	Q = 0.5003270373238773

	K = math.Tan(math.Pi * f0 / fs)
	a0 = 1 + K/Q + K*K

	b2 = [3]float64{1 / a0, -2 / a0, 1 / a0}
	a2 = [3]float64{
		1,
		2 * (K*K - 1) / a0,
		(1 - K/Q + K*K) / a0,
	}
	return
}

// applyBiquad filters x in-place using Direct Form II Transposed.
// a[0] is assumed to be 1.0 (normalised). state must be [2]float64{}.
func applyBiquad(x []float64, b, a [3]float64, s *[2]float64) {
	for i, in := range x {
		out := b[0]*in + s[0]
		s[0] = b[1]*in - a[1]*out + s[1]
		s[1] = b[2]*in - a[2]*out
		x[i] = out
	}
}

// ── Gated integrated loudness ─────────────────────────────────────────────────

// channelWeight returns the gain factor per ITU-R BS.1770 Table 1.
// ch is 0-based channel index; nch is total channel count.
func channelWeight(ch, nch int) float64 {
	// For 5.1 (6 ch): L=0, R=1, C=2, LFE=3, Ls=4, Rs=5
	// Ls/Rs get weight 1.41 (~+1.5 dB), LFE is excluded.
	if nch == 6 {
		switch ch {
		case 3:
			return 0 // LFE excluded
		case 4, 5:
			return 1.41
		}
	}
	return 1.0
}

// integratedLoudness computes EBU R128 integrated loudness from interleaved
// float64 PCM (−1…+1). sampleRate is in Hz, channels is the channel count.
func integratedLoudness(pcm []float64, sampleRate, channels int) float64 {
	frames := len(pcm) / channels
	if frames == 0 {
		return math.Inf(-1)
	}

	b1, a1, b2, a2 := kweightCoeffs(float64(sampleRate))

	// Filter each channel independently, collect weighted sum of squares.
	// We compute the mean-square of the K-weighted signal per block.
	chFiltered := make([][]float64, channels)
	for c := 0; c < channels; c++ {
		w := channelWeight(c, channels)
		if w == 0 {
			chFiltered[c] = make([]float64, frames) // zeros = excluded
			continue
		}
		// Extract channel samples.
		ch := make([]float64, frames)
		for i := 0; i < frames; i++ {
			ch[i] = pcm[i*channels+c] * w
		}
		// Apply K-weighting (two stages).
		var s1, s2 [2]float64
		applyBiquad(ch, b1, a1, &s1)
		applyBiquad(ch, b2, a2, &s2)
		chFiltered[c] = ch
	}

	// 400 ms block, 100 ms hop.
	blockFrames := sampleRate * 4 / 10
	hopFrames := sampleRate / 10
	if blockFrames <= 0 || hopFrames <= 0 {
		return math.Inf(-1)
	}

	var blockPowers []float64
	for start := 0; start+blockFrames <= frames; start += hopFrames {
		var power float64
		for c := 0; c < channels; c++ {
			for i := start; i < start+blockFrames; i++ {
				s := chFiltered[c][i]
				power += s * s
			}
		}
		blockPowers = append(blockPowers, power/float64(blockFrames))
	}
	if len(blockPowers) == 0 {
		return math.Inf(-1)
	}

	// Absolute gate: −70 LKFS = 10^(−70/10) = 1e-7
	absThresh := math.Pow(10, -70.0/10.0)
	gated1 := blockPowers[:0:len(blockPowers)]
	for _, p := range blockPowers {
		if p >= absThresh {
			gated1 = append(gated1, p)
		}
	}
	if len(gated1) == 0 {
		return -70
	}

	// Relative gate: ungated_mean − 10 LU
	var sum1 float64
	for _, p := range gated1 {
		sum1 += p
	}
	relThresh := (sum1 / float64(len(gated1))) * math.Pow(10, -10.0/10.0)

	var sum2 float64
	var n2 int
	for _, p := range gated1 {
		if p >= relThresh {
			sum2 += p
			n2++
		}
	}
	if n2 == 0 {
		return -70
	}

	return -0.691 + 10*math.Log10(sum2/float64(n2))
}

// ── WAV PCM reader ────────────────────────────────────────────────────────────

// readWAVPCMFloat reads a WAV file and returns interleaved f64 PCM in [−1,+1].
// Supports PCM 16/24/32-bit integer formats.
func readWAVPCMFloat(path string) (samples []float64, sampleRate, channels int, err error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, 0, 0, err
	}
	defer f.Close()

	// RIFF header
	var riff [12]byte
	if _, err = io.ReadFull(f, riff[:]); err != nil {
		return
	}
	if string(riff[0:4]) != "RIFF" || string(riff[8:12]) != "WAVE" {
		return nil, 0, 0, nil
	}

	var nChannels, sRate, bitsPerSample int
	var dataOffset int64
	var dataSize int64
	var formatTag uint16

	buf4 := make([]byte, 4)
	for {
		if _, err = io.ReadFull(f, buf4); err != nil {
			err = nil
			break
		}
		id := string(buf4)
		if _, err = io.ReadFull(f, buf4); err != nil {
			err = nil
			break
		}
		chunkSize := int64(binary.LittleEndian.Uint32(buf4))

		switch id {
		case "fmt ":
			if chunkSize < 16 {
				return nil, 0, 0, nil
			}
			fmtData := make([]byte, chunkSize)
			if _, err = io.ReadFull(f, fmtData); err != nil {
				return
			}
			formatTag = binary.LittleEndian.Uint16(fmtData[0:2])
			nChannels = int(binary.LittleEndian.Uint16(fmtData[2:4]))
			sRate = int(binary.LittleEndian.Uint32(fmtData[4:8]))
			bitsPerSample = int(binary.LittleEndian.Uint16(fmtData[14:16]))
		case "data":
			cur, _ := f.Seek(0, io.SeekCurrent)
			dataOffset = cur
			dataSize = chunkSize
			if _, err = f.Seek(chunkSize, io.SeekCurrent); err != nil {
				err = nil
			}
		default:
			skip := chunkSize
			if skip%2 != 0 {
				skip++
			}
			if _, err = f.Seek(skip, io.SeekCurrent); err != nil {
				err = nil
			}
		}
	}

	// Only PCM (1) and IEEE-float (3) are supported; skip everything else.
	if formatTag != 1 && formatTag != 3 {
		return nil, 0, 0, nil
	}
	if nChannels == 0 || sRate == 0 || bitsPerSample == 0 || dataOffset == 0 {
		return nil, 0, 0, nil
	}
	if formatTag == 3 && bitsPerSample == 32 {
		// f32 WAV — skip loudness (uncommon in theatre; add when needed)
		return nil, 0, 0, nil
	}

	bytesPerSample := bitsPerSample / 8
	nFrames := int(dataSize) / (nChannels * bytesPerSample)

	// Limit analysis to 5 minutes to keep memory / time bounded.
	maxFrames := sRate * 300
	if nFrames > maxFrames {
		nFrames = maxFrames
	}

	raw := make([]byte, nFrames*nChannels*bytesPerSample)
	if _, err = f.ReadAt(raw, dataOffset); err != nil && err != io.EOF {
		return nil, 0, 0, err
	}
	err = nil

	out := make([]float64, nFrames*nChannels)
	switch bitsPerSample {
	case 16:
		scale := 1.0 / 32768.0
		for i := range out {
			v := int16(binary.LittleEndian.Uint16(raw[i*2:]))
			out[i] = float64(v) * scale
		}
	case 24:
		scale := 1.0 / 8388608.0
		for i := range out {
			b := raw[i*3 : i*3+3]
			v := int32(b[0]) | int32(b[1])<<8 | int32(b[2])<<16
			if v&0x800000 != 0 {
				v |= ^int32(0xFFFFFF) // sign-extend
			}
			out[i] = float64(v) * scale
		}
	case 32:
		scale := 1.0 / 2147483648.0
		for i := range out {
			v := int32(binary.LittleEndian.Uint32(raw[i*4:]))
			out[i] = float64(v) * scale
		}
	default:
		return nil, 0, 0, nil
	}

	return out, sRate, nChannels, nil
}
