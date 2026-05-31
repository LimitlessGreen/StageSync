package media

import (
	"strings"
	"testing"
)

func TestParseAudio_UsesMP3Parser(t *testing.T) {
	oldWAV := parseWAVFn
	oldMP3 := parseMP3Fn
	defer func() {
		parseWAVFn = oldWAV
		parseMP3Fn = oldMP3
	}()

	var wavCalled bool
	var mp3Called bool
	want := &AudioInfo{
		DurationMs: 1234,
		Channels:   2,
		SampleRate: 48000,
		BitDepth:   16,
	}

	parseWAVFn = func(string) *AudioInfo {
		wavCalled = true
		return nil
	}
	parseMP3Fn = func(string) *AudioInfo {
		mp3Called = true
		return want
	}

	got := parseAudioRaw("C:\\tmp\\test.mp3")
	if !mp3Called {
		t.Fatal("expected MP3 parser to be called")
	}
	if wavCalled {
		t.Fatal("did not expect WAV parser for .mp3")
	}
	if got != want {
		t.Fatal("expected parseAudio to return MP3 parser result")
	}
}

func TestStore_ListIncludesMP3AudioMetadata(t *testing.T) {
	s := tempStore(t)

	oldMP3 := parseMP3Fn
	defer func() { parseMP3Fn = oldMP3 }()

	parseMP3Fn = func(path string) *AudioInfo {
		return &AudioInfo{
			DurationMs: 42000,
			Channels:   2,
			SampleRate: 44100,
			BitDepth:   16,
		}
	}

	if _, err := s.Save("test.mp3", strings.NewReader("fake-mp3-payload")); err != nil {
		t.Fatalf("Save: %v", err)
	}

	files, err := s.List()
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(files) != 1 {
		t.Fatalf("expected 1 file, got %d", len(files))
	}
	if files[0].Audio == nil {
		t.Fatal("expected Audio metadata for MP3, got nil")
	}
	if files[0].Audio.SampleRate != 44100 {
		t.Fatalf("sampleRate: want 44100, got %d", files[0].Audio.SampleRate)
	}
}
