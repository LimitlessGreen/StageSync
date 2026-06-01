package audioengine

import (
	"fmt"
	"runtime"
	"strings"

	"github.com/gen2brain/malgo"
)

// Options configures the audio engine at startup.
type Options struct {
	SampleRate      uint32
	Channels        uint32
	DeviceIndex     int
	BackendPriority []string
}

// RuntimeConfig applies runtime changes without restarting the server process.
type RuntimeConfig struct {
	Backend         string
	BackendPriority []string
	SampleRate      uint32
	Channels        uint32
	DeviceIndex     *int
}

func defaultBackendPriority() []string {
	switch runtime.GOOS {
	case "linux":
		return []string{"jack", "alsa", "pulseaudio"}
	case "windows":
		return []string{"asio", "wasapi", "directsound"}
	case "darwin":
		return []string{"coreaudio"}
	case "android":
		return []string{"aaudio", "opensl"}
	default:
		return nil
	}
}

func normalizeBackendName(name string) string {
	n := strings.TrimSpace(strings.ToLower(name))
	switch n {
	case "jack2":
		return "jack"
	case "pulse":
		return "pulseaudio"
	case "dsound":
		return "directsound"
	case "opensles":
		return "opensl"
	default:
		return n
	}
}

func backendFromName(name string) (malgo.Backend, bool) {
	switch normalizeBackendName(name) {
	case "wasapi":
		return malgo.BackendWasapi, true
	case "asio":
		return malgo.BackendAudio4, true
	case "directsound":
		return malgo.BackendDsound, true
	case "coreaudio":
		return malgo.BackendCoreaudio, true
	case "alsa":
		return malgo.BackendAlsa, true
	case "pulseaudio":
		return malgo.BackendPulseaudio, true
	case "jack":
		return malgo.BackendJack, true
	case "aaudio":
		return malgo.BackendAaudio, true
	case "opensl":
		return malgo.BackendOpensl, true
	default:
		return malgo.BackendNull, false
	}
}

func dedupeBackendPriority(names []string) []string {
	seen := make(map[string]struct{}, len(names))
	out := make([]string, 0, len(names))
	for _, raw := range names {
		n := normalizeBackendName(raw)
		if n == "" {
			continue
		}
		if _, ok := seen[n]; ok {
			continue
		}
		seen[n] = struct{}{}
		out = append(out, n)
	}
	return out
}

func parseBackendPriority(names []string) ([]string, []malgo.Backend, error) {
	normalized := dedupeBackendPriority(names)
	if len(normalized) == 0 {
		return nil, nil, nil
	}
	backends := make([]malgo.Backend, 0, len(normalized))
	for _, n := range normalized {
		b, ok := backendFromName(n)
		if !ok {
			return nil, nil, fmt.Errorf("unsupported backend %q", n)
		}
		backends = append(backends, b)
	}
	return normalized, backends, nil
}

func defaultOptions() Options {
	return Options{
		SampleRate:      48000,
		Channels:        2,
		DeviceIndex:     -1,
		BackendPriority: defaultBackendPriority(),
	}
}

func normalizeOptions(opts Options) Options {
	base := defaultOptions()
	if opts.SampleRate == 0 && opts.Channels == 0 && opts.DeviceIndex == 0 && len(opts.BackendPriority) == 0 {
		return base
	}
	if opts.SampleRate > 0 {
		base.SampleRate = opts.SampleRate
	}
	if opts.Channels > 0 {
		base.Channels = opts.Channels
	}
	base.DeviceIndex = opts.DeviceIndex
	if opts.BackendPriority != nil {
		base.BackendPriority = dedupeBackendPriority(opts.BackendPriority)
	}
	return base
}

func prependPreferredBackend(preferred string, existing []string) []string {
	p := normalizeBackendName(preferred)
	if p == "" {
		return dedupeBackendPriority(existing)
	}
	merged := append([]string{p}, existing...)
	return dedupeBackendPriority(merged)
}
