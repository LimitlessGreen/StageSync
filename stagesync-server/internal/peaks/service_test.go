package peaks

import (
	"encoding/binary"
	"testing"
)

func TestComputePeaks_MinMaxPerBucket(t *testing.T) {
	// 4 Samples, 2 Buckets → Bucket 0 = {-1, 0.5}, Bucket 1 = {-0.25, 1.0}
	pcm := []float32{-1.0, 0.5, -0.25, 1.0}
	wf := computePeaks(pcm, 48000, 1, 2)

	if wf.TotalBuckets != 2 {
		t.Fatalf("expected 2 buckets, got %d", wf.TotalBuckets)
	}
	if len(wf.Data) != 8 {
		t.Fatalf("expected 8 bytes, got %d", len(wf.Data))
	}
	min0 := int16(binary.LittleEndian.Uint16(wf.Data[0:]))
	max0 := int16(binary.LittleEndian.Uint16(wf.Data[2:]))
	min1 := int16(binary.LittleEndian.Uint16(wf.Data[4:]))
	max1 := int16(binary.LittleEndian.Uint16(wf.Data[6:]))

	v05, vn025 := float32(0.5), float32(-0.25)
	wantMax0 := int16(v05 * 32767)
	wantMin1 := int16(vn025 * 32767)
	if min0 != -32767 {
		t.Errorf("bucket0 min: want -32767, got %d", min0)
	}
	if max0 != wantMax0 {
		t.Errorf("bucket0 max: want %d, got %d", wantMax0, max0)
	}
	if max1 != 32767 {
		t.Errorf("bucket1 max: want 32767, got %d", max1)
	}
	if min1 != wantMin1 {
		t.Errorf("bucket1 min: want %d, got %d", wantMin1, min1)
	}
}

func TestComputePeaks_Empty(t *testing.T) {
	wf := computePeaks(nil, 48000, 1, 100)
	if wf.TotalBuckets != 0 || len(wf.Data) != 0 {
		t.Fatalf("expected empty waveform, got buckets=%d len=%d", wf.TotalBuckets, len(wf.Data))
	}
}

func TestComputePeaks_DurationMs(t *testing.T) {
	pcm := make([]float32, 48000) // 1 Sekunde @ 48kHz
	wf := computePeaks(pcm, 48000, 1, 10)
	if wf.DurationMs < 999 || wf.DurationMs > 1001 {
		t.Fatalf("expected ~1000ms, got %f", wf.DurationMs)
	}
}
