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

// FileInfo beschreibt eine gespeicherte Mediendatei. sha256 dient als
// Inhalts-Fingerprint für den Sync (ETag) und als Änderungserkennung.
type FileInfo struct {
	Name       string `json:"name"`
	SizeBytes  int64  `json:"size_bytes"`
	SHA256     string `json:"sha256"`
	ModifiedMs int64  `json:"modified_ms"`
	MimeType   string `json:"mime_type"`
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

// Store verwaltet ein Verzeichnis mit Mediendateien thread-safe.
type Store struct {
	dir       string
	mu        sync.Mutex
	hashCache map[string]hashEntry // name → gecachter Hash (nach mtime+size)

	subsMu sync.Mutex
	subs   map[chan struct{}]struct{} // Abonnenten für Änderungs-Notifications
}

func NewStore(dir string) (*Store, error) {
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return nil, err
	}
	return &Store{
		dir:       dir,
		hashCache: make(map[string]hashEntry),
		subs:      make(map[chan struct{}]struct{}),
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
		out = append(out, FileInfo{
			Name:       e.Name(),
			SizeBytes:  fi.Size(),
			SHA256:     sha,
			ModifiedMs: fi.ModTime().UnixMilli(),
			MimeType:   mimeForExt(strings.ToLower(filepath.Ext(e.Name()))),
		})
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
	return FileInfo{
		Name:       SafeName(name),
		SizeBytes:  fi.Size(),
		SHA256:     sha,
		ModifiedMs: fi.ModTime().UnixMilli(),
		MimeType:   mimeForExt(strings.ToLower(filepath.Ext(SafeName(name)))),
	}, nil
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
	delete(s.hashCache, safe) // Cache invalidieren
	s.mu.Unlock()

	s.notifyChange()
	return s.Stat(safe)
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

// touch (Test-Hilfe / Reserve): aktualisiert mtime.
func (s *Store) touch(name string) error {
	now := time.Now()
	return os.Chtimes(s.path(name), now, now)
}
