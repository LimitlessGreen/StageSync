package audioengine

import "testing"

func TestNormalizeBackendNameAliases(t *testing.T) {
	tests := map[string]string{
		"jack2":    "jack",
		" JACK2 ":  "jack",
		"pulse":    "pulseaudio",
		"dsound":   "directsound",
		"opensles": "opensl",
		"wasapi":   "wasapi",
	}
	for in, want := range tests {
		if got := normalizeBackendName(in); got != want {
			t.Fatalf("normalizeBackendName(%q)=%q, want %q", in, got, want)
		}
	}
}

func TestParseBackendPriority(t *testing.T) {
	names, backends, err := parseBackendPriority([]string{"jack2", "alsa", "jack", "pulse"})
	if err != nil {
		t.Fatalf("parseBackendPriority returned error: %v", err)
	}
	if len(names) != 3 {
		t.Fatalf("normalized names len=%d, want 3", len(names))
	}
	if names[0] != "jack" || names[1] != "alsa" || names[2] != "pulseaudio" {
		t.Fatalf("unexpected normalized names: %v", names)
	}
	if len(backends) != 3 {
		t.Fatalf("backend list len=%d, want 3", len(backends))
	}
}

func TestParseBackendPriorityRejectsUnknown(t *testing.T) {
	if _, _, err := parseBackendPriority([]string{"unknown-backend"}); err == nil {
		t.Fatal("expected error for unsupported backend, got nil")
	}
}

func TestNormalizeOptionsDefaults(t *testing.T) {
	opts := normalizeOptions(Options{})
	if opts.SampleRate != 48000 {
		t.Fatalf("SampleRate=%d, want 48000", opts.SampleRate)
	}
	if opts.Channels != 2 {
		t.Fatalf("Channels=%d, want 2", opts.Channels)
	}
	if opts.DeviceIndex != -1 {
		t.Fatalf("DeviceIndex=%d, want -1", opts.DeviceIndex)
	}
}

func TestPrependPreferredBackend(t *testing.T) {
	got := prependPreferredBackend("jack2", []string{"alsa", "jack", "pulseaudio"})
	want := []string{"jack", "alsa", "pulseaudio"}
	if len(got) != len(want) {
		t.Fatalf("len=%d, want %d (values=%v)", len(got), len(want), got)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("got[%d]=%q, want %q", i, got[i], want[i])
		}
	}
}
