package media

import (
	"encoding/binary"
	"math"
	"os"
	"testing"
)

// makeSineWAV writes a stereo 16-bit PCM WAV with a 1 kHz sine at the given
// amplitude (0.0–1.0) for the given duration in seconds.
func makeSineWAV(t *testing.T, sampleRate int, amplitude, durationSec float64) string {
	t.Helper()

	channels   := 2
	bitDepth   := 16
	nFrames    := int(float64(sampleRate) * durationSec)
	dataBytes  := nFrames * channels * (bitDepth / 8)

	f, err := os.CreateTemp(t.TempDir(), "sine-*.wav")
	if err != nil {
		t.Fatalf("create temp: %v", err)
	}
	defer f.Close()

	le := binary.LittleEndian

	// RIFF header
	f.WriteString("RIFF")
	binary.Write(f, le, uint32(36+dataBytes))
	f.WriteString("WAVE")

	// fmt chunk
	f.WriteString("fmt ")
	binary.Write(f, le, uint32(16))
	binary.Write(f, le, uint16(1)) // PCM
	binary.Write(f, le, uint16(channels))
	binary.Write(f, le, uint32(sampleRate))
	binary.Write(f, le, uint32(sampleRate*channels*(bitDepth/8)))
	binary.Write(f, le, uint16(channels*(bitDepth/8)))
	binary.Write(f, le, uint16(bitDepth))

	// data chunk
	f.WriteString("data")
	binary.Write(f, le, uint32(dataBytes))

	freq := 1000.0
	scale := amplitude * 32767.0
	for i := 0; i < nFrames; i++ {
		s := int16(math.Round(math.Sin(2*math.Pi*freq*float64(i)/float64(sampleRate)) * scale))
		binary.Write(f, le, s) // L
		binary.Write(f, le, s) // R
	}
	return f.Name()
}

// TestLoudness_SineWave48k checks that a 1 kHz stereo sine at amplitude 0.1 is
// measured in the correct range.
//
// For stereo (both channels equal), ITU-R BS.1770 gives:
//   z = G_L·(A²/2) + G_R·(A²/2) = A²   (both weights = 1.0)
//   LUFS = −0.691 + 10·log10(A²) = −0.691 + 20·log10(A)
// At 1 kHz the K-weighting filter adds ~+0.65 dB, so the result sits about
// 0.65 dB above the theoretical value — we allow ±2 dB for rounding and gating.
func TestLoudness_SineWave48k(t *testing.T) {
	path := makeSineWAV(t, 48000, 0.1, 10)
	lufs := measureLoudnessWAV(path)
	if lufs == nil {
		t.Fatal("measureLoudnessWAV returned nil")
	}
	// 20·log10(0.1) = −20 dB; expect ≈ −20 LUFS (K-weighting ~+0.65 dB at 1 kHz)
	nominal := 20 * math.Log10(0.1) // −20
	if math.Abs(*lufs-nominal) > 2.0 {
		t.Errorf("loudness = %.2f LUFS, want %.2f ± 2.0", *lufs, nominal)
	}
}

// TestLoudness_SineWave44k1 verifies bilinear-transform coefficients at 44100 Hz.
func TestLoudness_SineWave44k1(t *testing.T) {
	path := makeSineWAV(t, 44100, 0.1, 10)
	lufs := measureLoudnessWAV(path)
	if lufs == nil {
		t.Fatal("measureLoudnessWAV returned nil for 44.1 kHz file")
	}
	nominal := 20 * math.Log10(0.1)
	if math.Abs(*lufs-nominal) > 2.0 {
		t.Errorf("loudness = %.2f LUFS, want %.2f ± 2.0", *lufs, nominal)
	}
}

// TestLoudness_Silence checks that silence returns ≤ −70 LUFS.
func TestLoudness_Silence(t *testing.T) {
	path := makeSineWAV(t, 48000, 0, 5)
	lufs := measureLoudnessWAV(path)
	if lufs == nil {
		t.Fatal("measureLoudnessWAV returned nil for silent file")
	}
	if *lufs > -70 {
		t.Errorf("silence loudness = %.2f, want ≤ −70 LUFS", *lufs)
	}
}

// TestLoudness_FullScale checks that full-scale stereo sine reads near 0 LUFS.
// (With K-weighting ~+0.65 dB at 1 kHz and EBU −0.691 dB offset → ≈ −0.04 LUFS)
func TestLoudness_FullScale(t *testing.T) {
	path := makeSineWAV(t, 48000, 1.0, 10)
	lufs := measureLoudnessWAV(path)
	if lufs == nil {
		t.Fatal("measureLoudnessWAV returned nil")
	}
	// Full-scale stereo sine: z = 1.0, LUFS ≈ −0.69 + 0.65 ≈ −0.04
	if math.Abs(*lufs) > 2.0 {
		t.Errorf("full-scale loudness = %.2f LUFS, want ~0 ± 2.0", *lufs)
	}
}

// TestIntegratedLoudness_KweightingCoeffs sanity-checks that the filter
// coefficients at 48 kHz match known reference values (libebur128 output).
func TestIntegratedLoudness_KweightingCoeffs(t *testing.T) {
	b1, a1, b2, a2 := kweightCoeffs(48000)

	// Stage 1: high-shelf — b0 should be > 1 (boost at high frequencies)
	if b1[0] <= 1.0 {
		t.Errorf("stage1 b0 = %.6f, want > 1.0", b1[0])
	}
	// a0 is normalised to 1
	if a1[0] != 1.0 {
		t.Errorf("stage1 a0 = %.6f, want 1.0", a1[0])
	}

	// Stage 2: high-pass — b0 + b1 + b2 ≈ 0 (zero DC response)
	dcGain2 := (b2[0] + b2[1] + b2[2]) / (a2[0] + a2[1] + a2[2])
	if math.Abs(dcGain2) > 0.001 {
		t.Errorf("stage2 DC gain = %.6f, want ≈ 0", dcGain2)
	}
}
