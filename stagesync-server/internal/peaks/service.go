// Package peaks generiert Waveform-Peak-Daten (min/max pro Bucket) für Assets
// und cached sie content-addressiert neben der Audiodatei.
package peaks

import (
	"encoding/binary"
	"fmt"
	"math"
	"os"

	"stagesync-server/internal/decode"
)

// peakRate: Mono-Decode-Rate für die Peak-Berechnung. Ausreichend hoch, damit
// min/max-Buckets die Hüllkurve sauber abbilden, ohne die volle Datei in
// Originalauflösung dekodieren zu müssen.
const peakRate = 22050

// AssetResolver liefert den Dateipfad zu einem Asset (SHA-256).
// Implementiert von media.Store.FilePathBySHA256.
type AssetResolver interface {
	FilePathBySHA256(sha256hex string) (string, error)
}

// Waveform ist das Ergebnis einer Peak-Berechnung.
type Waveform struct {
	Data         []byte // interleaved int16 LE: [min0,max0,min1,max1,...]
	TotalBuckets int
	Channels     uint32
	SampleRate   uint32
	DurationMs   float64
}

// Service berechnet und cached Waveforms.
type Service struct {
	resolver AssetResolver
	cacheDir string
}

func NewService(resolver AssetResolver, cacheDir string) *Service {
	_ = os.MkdirAll(cacheDir, 0o755)
	return &Service{
		resolver: resolver,
		cacheDir: cacheDir,
	}
}

// Generate liefert die Waveform für ein Asset mit der gewünschten Bucket-Zahl.
// Cached das Ergebnis auf Disk (<sha256>.<buckets>.peaks).
func (s *Service) Generate(assetID string, buckets int) (*Waveform, error) {
	if assetID == "" {
		return nil, fmt.Errorf("empty asset id")
	}
	if buckets <= 0 {
		buckets = 2000
	}
	cachePath := fmt.Sprintf("%s/%s.%d.peaks", s.cacheDir, assetID, buckets)

	// Cache-Hit?
	if wf, ok := s.readCache(cachePath); ok {
		return wf, nil
	}

	path, err := s.resolver.FilePathBySHA256(assetID)
	if err != nil {
		return nil, fmt.Errorf("resolve asset: %w", err)
	}

	pcm, _, _, err := decode.PCM(path, peakRate, 1)
	if err != nil {
		return nil, fmt.Errorf("decode: %w", err)
	}

	wf := computePeaks(pcm, peakRate, 1, buckets)
	s.writeCache(cachePath, wf)
	return wf, nil
}

// computePeaks reduziert Mono-PCM zu min/max-Paaren je Bucket.
func computePeaks(pcm []float32, rate, channels uint32, buckets int) *Waveform {
	totalFrames := len(pcm)
	if totalFrames == 0 {
		return &Waveform{Data: nil, TotalBuckets: 0, Channels: channels, SampleRate: rate}
	}
	if buckets > totalFrames {
		buckets = totalFrames
	}
	data := make([]byte, buckets*4) // 2 int16 je Bucket
	per := float64(totalFrames) / float64(buckets)
	for b := 0; b < buckets; b++ {
		start := int(float64(b) * per)
		end := int(float64(b+1) * per)
		if end > totalFrames {
			end = totalFrames
		}
		if start >= end {
			start = end - 1
			if start < 0 {
				start = 0
			}
		}
		mn, mx := float32(0), float32(0)
		first := true
		for i := start; i < end; i++ {
			v := pcm[i]
			if first {
				mn, mx = v, v
				first = false
				continue
			}
			if v < mn {
				mn = v
			}
			if v > mx {
				mx = v
			}
		}
		off := b * 4
		binary.LittleEndian.PutUint16(data[off:], uint16(int16(clampF(mn)*32767)))
		binary.LittleEndian.PutUint16(data[off+2:], uint16(int16(clampF(mx)*32767)))
	}
	durationMs := float64(totalFrames) / float64(rate) * 1000.0
	return &Waveform{
		Data:         data,
		TotalBuckets: buckets,
		Channels:     channels,
		SampleRate:   rate,
		DurationMs:   durationMs,
	}
}

func clampF(v float32) float32 {
	if v > 1 {
		return 1
	}
	if v < -1 {
		return -1
	}
	return v
}

// ── Cache I/O ─────────────────────────────────────────────────────────────────

// Cache-Header: magic(4) + version(1) + channels(1) + sampleRate(4) +
// totalBuckets(4) + durationMs(8 float64 LE), dann die Peak-Bytes.
const cacheMagic = "PEAK"
const cacheVersion byte = 1

func (s *Service) readCache(path string) (*Waveform, bool) {
	b, err := os.ReadFile(path)
	if err != nil || len(b) < 22 {
		return nil, false
	}
	if string(b[:4]) != cacheMagic || b[4] != cacheVersion {
		return nil, false
	}
	channels := uint32(b[5])
	rate := binary.LittleEndian.Uint32(b[6:])
	total := int(binary.LittleEndian.Uint32(b[10:]))
	durBits := binary.LittleEndian.Uint64(b[14:])
	return &Waveform{
		Data:         b[22:],
		TotalBuckets: total,
		Channels:     channels,
		SampleRate:   rate,
		DurationMs:   math.Float64frombits(durBits),
	}, true
}

func (s *Service) writeCache(path string, wf *Waveform) {
	header := make([]byte, 22)
	copy(header[:4], cacheMagic)
	header[4] = cacheVersion
	header[5] = byte(wf.Channels)
	binary.LittleEndian.PutUint32(header[6:], wf.SampleRate)
	binary.LittleEndian.PutUint32(header[10:], uint32(wf.TotalBuckets))
	binary.LittleEndian.PutUint64(header[14:], math.Float64bits(wf.DurationMs))
	out := append(header, wf.Data...)
	if err := os.WriteFile(path, out, 0o644); err != nil {
		// Cache-Fehler sind nicht fatal — Peaks werden bei Bedarf neu berechnet.
		_ = err
	}
}
