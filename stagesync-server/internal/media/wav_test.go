package media

import (
	"bytes"
	"encoding/binary"
	"os"
	"testing"
)

// makeWAV schreibt eine minimale RIFF/WAV-Datei mit gegebenen Parametern.
func makeWAV(t *testing.T, channels, sampleRate, bitDepth int32, numSamples int64) string {
	t.Helper()

	bytesPerSample := int64(bitDepth / 8)
	blockAlign     := int32(channels) * int32(bitDepth/8)
	byteRate       := int32(sampleRate) * blockAlign
	dataSize        := numSamples * int64(channels) * bytesPerSample

	f, err := os.CreateTemp(t.TempDir(), "test-*.wav")
	if err != nil {
		t.Fatalf("create temp: %v", err)
	}
	defer f.Close()

	le := binary.LittleEndian

	// RIFF header (12 bytes)
	f.WriteString("RIFF")
	binary.Write(f, le, uint32(36+dataSize)) // chunkSize
	f.WriteString("WAVE")

	// fmt chunk (24 bytes)
	f.WriteString("fmt ")
	binary.Write(f, le, uint32(16))          // subchunk1Size
	binary.Write(f, le, uint16(1))           // PCM
	binary.Write(f, le, uint16(channels))
	binary.Write(f, le, uint32(sampleRate))
	binary.Write(f, le, uint32(byteRate))
	binary.Write(f, le, uint16(blockAlign))
	binary.Write(f, le, uint16(bitDepth))

	// data chunk header
	f.WriteString("data")
	binary.Write(f, le, uint32(dataSize))
	// (payload omitted — parser only reads header)

	return f.Name()
}

func TestParseWAV_Stereo48k24bit(t *testing.T) {
	// 2 channels, 48000 Hz, 24 bit, 1 second = 48000 samples
	path := makeWAV(t, 2, 48000, 24, 48000)
	info := parseWAV(path)
	if info == nil {
		t.Fatal("parseWAV returned nil")
	}
	if info.Channels != 2 {
		t.Errorf("channels: want 2, got %d", info.Channels)
	}
	if info.SampleRate != 48000 {
		t.Errorf("sampleRate: want 48000, got %d", info.SampleRate)
	}
	if info.BitDepth != 24 {
		t.Errorf("bitDepth: want 24, got %d", info.BitDepth)
	}
	// 48000 samples × 1s → 1000 ms (allow ±1 ms rounding)
	if info.DurationMs < 999 || info.DurationMs > 1001 {
		t.Errorf("durationMs: want ~1000, got %d", info.DurationMs)
	}
}

func TestParseWAV_Mono44k16bit(t *testing.T) {
	path := makeWAV(t, 1, 44100, 16, 44100)
	info := parseWAV(path)
	if info == nil {
		t.Fatal("parseWAV returned nil")
	}
	if info.Channels != 1 {
		t.Errorf("channels: want 1, got %d", info.Channels)
	}
	if info.SampleRate != 44100 {
		t.Errorf("sampleRate: want 44100, got %d", info.SampleRate)
	}
}

func TestParseWAV_NotWAV(t *testing.T) {
	f, _ := os.CreateTemp(t.TempDir(), "notawav-*.mp3")
	f.WriteString("ID3\x03\x00\x00")
	f.Close()
	if parseWAV(f.Name()) != nil {
		t.Error("expected nil for non-WAV file")
	}
}

func TestParseWAV_Nonexistent(t *testing.T) {
	if parseWAV("/does/not/exist.wav") != nil {
		t.Error("expected nil for nonexistent file")
	}
}

func TestStore_ListIncludesAudioMetadata(t *testing.T) {
	s := tempStore(t)
	// Write a valid WAV into the store directory directly (Save API not needed here)
	wavPath := makeWAV(t, 2, 44100, 16, 44100)
	data, _ := os.ReadFile(wavPath)
	s.Save("test.wav", bytes.NewReader(data))

	files, err := s.List()
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(files) != 1 {
		t.Fatalf("expected 1 file, got %d", len(files))
	}
	if files[0].Audio == nil {
		t.Fatal("expected Audio metadata, got nil")
	}
	if files[0].Audio.Channels != 2 {
		t.Errorf("channels: want 2, got %d", files[0].Audio.Channels)
	}
}
