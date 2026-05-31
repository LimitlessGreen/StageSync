// Package media implementiert den autoritativen Medien-Speicher des
// StageSync-Servers. Alle Audio-Dateien liegen hier; Nodes spiegeln sie.
package media

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

// AudioInfo enthält technische Metadaten einer Audiodatei.
// Wird beim Listing aus dem Datei-Header gelesen (WAV: RIFF-Chunk-Analyse).
type AudioInfo struct {
	DurationMs   int64    `json:"duration_ms"`             // 0 = unbekannt
	Channels     int32    `json:"channels"`                // 0 = unbekannt
	SampleRate   int32    `json:"sample_rate"`             // Hz
	BitDepth     int32    `json:"bit_depth"`               // 0 = unbekannt
	LoudnessLufs *float64 `json:"loudness_lufs,omitempty"` // nil = nicht gemessen (erfordert ffprobe)
}

// FileInfo beschreibt eine gespeicherte Mediendatei. sha256 dient als
// Inhalts-Fingerprint für den Sync (ETag) und als Änderungserkennung.
type FileInfo struct {
	Name       string     `json:"name"`
	SizeBytes  int64      `json:"size_bytes"`
	SHA256     string     `json:"sha256"`
	ModifiedMs int64      `json:"modified_ms"`
	MimeType   string     `json:"mime_type"`
	Audio      *AudioInfo `json:"audio,omitempty"` // nil für nicht unterstützte Formate oder Parse-Fehler
}

// mimeForExt gibt den MIME-Typ für eine Audio-Endung zurück.
func mimeForExt(ext string) string {
	switch ext {
	case ".wav":
		return "audio/wav"
	case ".mp3":
		return "audio/mpeg"
	case ".flac":
		return "audio/flac"
	case ".aac":
		return "audio/aac"
	case ".ogg":
		return "audio/ogg"
	case ".m4a":
		return "audio/mp4"
	case ".aiff", ".aif":
		return "audio/aiff"
	default:
		return "application/octet-stream"
	}
}

var ErrNotFound = errors.New("media file not found")

// audioExts: zugelassene Endungen (Schutz + Filter).
var audioExts = map[string]bool{
	".wav": true, ".mp3": true, ".flac": true, ".aac": true,
	".ogg": true, ".m4a": true, ".aiff": true,
}

// IsAudioName prüft, ob ein Dateiname eine zugelassene Audio-Endung hat.
func IsAudioName(name string) bool {
	return audioExts[strings.ToLower(filepath.Ext(name))]
}

type hashEntry struct {
	modUnixNano int64
	size        int64
	sha         string
}

type audioEntry struct {
	modUnixNano int64
	size        int64
	info        *AudioInfo
}

// Store verwaltet ein Verzeichnis mit Mediendateien thread-safe.
type Store struct {
	dir        string
	mu         sync.Mutex
	hashCache  map[string]hashEntry  // name → gecachter Hash (nach mtime+size)
	audioCache map[string]audioEntry // name → gecachte AudioInfo (nach mtime+size)

	subsMu sync.Mutex
	subs   map[chan struct{}]struct{} // Abonnenten für Änderungs-Notifications
}

func NewStore(dir string) (*Store, error) {
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return nil, err
	}
	return &Store{
		dir:        dir,
		hashCache:  make(map[string]hashEntry),
		audioCache: make(map[string]audioEntry),
		subs:       make(map[chan struct{}]struct{}),
	}, nil
}

// Subscribe liefert einen Kanal, der bei jeder Änderung (Save/Delete) ein
// Signal erhält, plus eine Funktion zum Abbestellen. Gepuffert (Tiefe 1) und
// non-blocking — verpasste Signale sind unkritisch (der Node holt die ganze
// Liste; ein einzelnes „etwas hat sich geändert" genügt).
func (s *Store) Subscribe() (<-chan struct{}, func()) {
	ch := make(chan struct{}, 1)
	s.subsMu.Lock()
	s.subs[ch] = struct{}{}
	s.subsMu.Unlock()
	return ch, func() {
		s.subsMu.Lock()
		delete(s.subs, ch)
		s.subsMu.Unlock()
	}
}

func (s *Store) notifyChange() {
	s.subsMu.Lock()
	defer s.subsMu.Unlock()
	for ch := range s.subs {
		select {
		case ch <- struct{}{}:
		default: // Signal liegt bereits an → nichts zu tun
		}
	}
}

// SafeName entfernt jegliche Pfadanteile → kein Directory-Traversal.
func SafeName(name string) string {
	return filepath.Base(filepath.Clean("/" + name))
}

func (s *Store) path(name string) string {
	return filepath.Join(s.dir, SafeName(name))
}

// FilePath returns the absolute path of the named file in the media store.
// It does not verify that the file exists; use Stat for that.
func (s *Store) FilePath(name string) string {
	return s.path(name)
}

// List liefert alle Audiodateien inkl. Inhalts-Hash (gecacht nach mtime/size).
func (s *Store) List() ([]FileInfo, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	entries, err := os.ReadDir(s.dir)
	if err != nil {
		return nil, err
	}
	out := make([]FileInfo, 0, len(entries))
	for _, e := range entries {
		if e.IsDir() || !IsAudioName(e.Name()) {
			continue
		}
		fi, err := e.Info()
		if err != nil {
			continue
		}
		sha, err := s.hashLocked(e.Name(), fi)
		if err != nil {
			continue
		}
		info := FileInfo{
			Name:       e.Name(),
			SizeBytes:  fi.Size(),
			SHA256:     sha,
			ModifiedMs: fi.ModTime().UnixMilli(),
			MimeType:   mimeForExt(strings.ToLower(filepath.Ext(e.Name()))),
		}
		info.Audio = s.parseAudioCached(e.Name(), fi)
		out = append(out, info)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })
	return out, nil
}

// Stat liefert FileInfo für eine einzelne Datei.
func (s *Store) Stat(name string) (FileInfo, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	fi, err := os.Stat(s.path(name))
	if err != nil {
		if os.IsNotExist(err) {
			return FileInfo{}, ErrNotFound
		}
		return FileInfo{}, err
	}
	sha, err := s.hashLocked(SafeName(name), fi)
	if err != nil {
		return FileInfo{}, err
	}
	result := FileInfo{
		Name:       SafeName(name),
		SizeBytes:  fi.Size(),
		SHA256:     sha,
		ModifiedMs: fi.ModTime().UnixMilli(),
		MimeType:   mimeForExt(strings.ToLower(filepath.Ext(SafeName(name)))),
	}
	result.Audio = s.parseAudioCached(SafeName(name), fi)
	return result, nil
}

var (
	parseWAVFn  = parseWAV
	parseMP3Fn  = parseMP3
	parseFLACFn = parseFLAC
	parseOGGFn  = parseOGG
	parseAIFFFn = parseAIFF
)

func parseAudioRaw(path string) *AudioInfo {
	switch strings.ToLower(filepath.Ext(path)) {
	case ".wav":
		return parseWAVFn(path)
	case ".mp3":
		return parseMP3Fn(path)
	case ".flac":
		return parseFLACFn(path)
	case ".ogg":
		return parseOGGFn(path)
	case ".aiff", ".aif":
		return parseAIFFFn(path)
	default:
		return nil
	}
}

// parseAudioCached gibt AudioInfo zurück, gecacht nach mtime+size.
// Aufrufer muss s.mu halten.
func (s *Store) parseAudioCached(name string, fi os.FileInfo) *AudioInfo {
	key := SafeName(name)
	if c, ok := s.audioCache[key]; ok &&
		c.modUnixNano == fi.ModTime().UnixNano() && c.size == fi.Size() {
		return c.info
	}
	path := filepath.Join(s.dir, key)
	// Mutex kurz freigeben für die teure I/O-Operation.
	s.mu.Unlock()
	info := parseAudioRaw(path)
	s.mu.Lock()
	s.audioCache[key] = audioEntry{
		modUnixNano: fi.ModTime().UnixNano(),
		size:        fi.Size(),
		info:        info,
	}
	return info
}

// hashLocked berechnet/cached den SHA-256 einer Datei. Aufrufer hält s.mu.
func (s *Store) hashLocked(name string, fi os.FileInfo) (string, error) {
	key := SafeName(name)
	if c, ok := s.hashCache[key]; ok && c.modUnixNano == fi.ModTime().UnixNano() && c.size == fi.Size() {
		return c.sha, nil
	}
	f, err := os.Open(filepath.Join(s.dir, key))
	if err != nil {
		return "", err
	}
	defer f.Close()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	sha := hex.EncodeToString(h.Sum(nil))
	s.hashCache[key] = hashEntry{modUnixNano: fi.ModTime().UnixNano(), size: fi.Size(), sha: sha}
	return sha, nil
}

// Save schreibt Daten atomar (temp + rename) und gibt die FileInfo zurück.
func (s *Store) Save(name string, r io.Reader) (FileInfo, error) {
	safe := SafeName(name)
	if !IsAudioName(safe) {
		return FileInfo{}, errors.New("unsupported audio format")
	}

	tmp, err := os.CreateTemp(s.dir, ".upload-*")
	if err != nil {
		return FileInfo{}, err
	}
	tmpName := tmp.Name()
	defer os.Remove(tmpName) // no-op falls Rename erfolgreich

	if _, err := io.Copy(tmp, r); err != nil {
		tmp.Close()
		return FileInfo{}, err
	}
	if err := tmp.Close(); err != nil {
		return FileInfo{}, err
	}

	dst := s.path(safe)
	if err := os.Rename(tmpName, dst); err != nil {
		return FileInfo{}, err
	}

	s.mu.Lock()
	delete(s.hashCache, safe)
	delete(s.audioCache, safe)
	s.mu.Unlock()

	s.notifyChange()
	return s.Stat(safe)
}

// FilePathBySHA256 returns the absolute path of the file whose SHA-256 hash
// matches the given hex string. Returns ErrNotFound if no match exists.
// List() is used internally and handles caching.
func (s *Store) FilePathBySHA256(sha256hex string) (string, error) {
	files, err := s.List()
	if err != nil {
		return "", err
	}
	for _, f := range files {
		if f.SHA256 == sha256hex {
			return s.path(f.Name), nil
		}
	}
	return "", ErrNotFound
}

// Open öffnet eine Datei zum Lesen.
func (s *Store) Open(name string) (*os.File, error) {
	f, err := os.Open(s.path(name))
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return f, nil
}

// Delete entfernt eine Datei.
func (s *Store) Delete(name string) error {
	safe := SafeName(name)
	err := os.Remove(s.path(safe))
	s.mu.Lock()
	delete(s.hashCache, safe)
	delete(s.audioCache, safe)
	s.mu.Unlock()
	if err != nil {
		if os.IsNotExist(err) {
			return ErrNotFound
		}
		return err
	}
	s.notifyChange()
	return nil
}

// ReadAll liest den gesamten Inhalt einer Datei in den Speicher.
// path muss ein absoluter Pfad sein (z.B. aus FilePath oder FilePathBySHA256).
func (s *Store) ReadAll(path string) ([]byte, error) {
	return os.ReadFile(path)
}

// touch (Test-Hilfe / Reserve): aktualisiert mtime.
func (s *Store) touch(name string) error {
	now := time.Now()
	return os.Chtimes(s.path(name), now, now)
}

// parseWAV liest den RIFF/WAV-Header und gibt AudioInfo zurück.
// Gibt nil zurück wenn die Datei kein WAV ist oder der Header nicht lesbar ist.
// Unterstützt: PCM (fmt-Chunk mit wFormatTag=1 oder 3).
func parseWAV(path string) *AudioInfo {
	f, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer f.Close()

	// RIFF-Header: "RIFF" (4) + chunkSize (4) + "WAVE" (4) = 12 Bytes
	var riff [12]byte
	if _, err := io.ReadFull(f, riff[:]); err != nil {
		return nil
	}
	if string(riff[0:4]) != "RIFF" || string(riff[8:12]) != "WAVE" {
		return nil
	}

	// Chunks suchen: fmt und data
	var channels, sampleRate, bitDepth int32
	var dataSize int64
	foundFmt := false

	buf4 := make([]byte, 4)
	for {
		if _, err := io.ReadFull(f, buf4); err != nil {
			break
		}
		id := string(buf4)
		if _, err := io.ReadFull(f, buf4); err != nil {
			break
		}
		size := int64(buf4[0]) | int64(buf4[1])<<8 | int64(buf4[2])<<16 | int64(buf4[3])<<24

		switch id {
		case "fmt ":
			if size < 16 {
				return nil
			}
			fmtData := make([]byte, size)
			if _, err := io.ReadFull(f, fmtData); err != nil {
				return nil
			}
			// wFormatTag: 1=PCM, 3=IEEE float — beide haben Standard-Felder
			channels = int32(fmtData[2]) | int32(fmtData[3])<<8
			sampleRate = int32(fmtData[4]) | int32(fmtData[5])<<8 |
				int32(fmtData[6])<<16 | int32(fmtData[7])<<24
			bitDepth = int32(fmtData[14]) | int32(fmtData[15])<<8
			foundFmt = true
		case "data":
			dataSize = size
			if _, err := f.Seek(size, io.SeekCurrent); err != nil {
				break
			}
		default:
			// Unbekannter Chunk überspringen (WORD-aligned)
			skip := size
			if skip%2 != 0 {
				skip++
			}
			if _, err := f.Seek(skip, io.SeekCurrent); err != nil {
				break
			}
		}
	}

	if !foundFmt || channels == 0 || sampleRate == 0 || bitDepth == 0 {
		return nil
	}

	var durationMs int64
	if dataSize > 0 {
		bytesPerSec := int64(sampleRate) * int64(channels) * int64(bitDepth/8)
		if bytesPerSec > 0 {
			durationMs = (dataSize * 1000) / bytesPerSec
		}
	}

	info := &AudioInfo{
		DurationMs: durationMs,
		Channels:   channels,
		SampleRate: sampleRate,
		BitDepth:   bitDepth,
	}
	info.LoudnessLufs = measureLoudnessWAV(path)
	return info
}
