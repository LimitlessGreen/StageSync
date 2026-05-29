package media

import (
	"os"
	"strings"
	"testing"
)

func tempStore(t *testing.T) *Store {
	t.Helper()
	dir := t.TempDir()
	s, err := NewStore(dir)
	if err != nil {
		t.Fatalf("NewStore: %v", err)
	}
	return s
}

func TestStore_SaveAndList(t *testing.T) {
	s := tempStore(t)
	_, err := s.Save("test.wav", strings.NewReader("RIFF fake wav data"))
	if err != nil {
		t.Fatalf("Save: %v", err)
	}
	files, err := s.List()
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(files) != 1 {
		t.Fatalf("expected 1 file, got %d", len(files))
	}
	if files[0].Name != "test.wav" {
		t.Errorf("expected test.wav, got %s", files[0].Name)
	}
}

func TestStore_SHA256ContentAddressable(t *testing.T) {
	s := tempStore(t)
	content := "same content for both saves"
	fi1, err := s.Save("a.wav", strings.NewReader(content))
	if err != nil {
		t.Fatalf("Save a: %v", err)
	}
	fi2, err := s.Save("b.wav", strings.NewReader(content))
	if err != nil {
		t.Fatalf("Save b: %v", err)
	}
	if fi1.SHA256 != fi2.SHA256 {
		t.Errorf("same content must produce same SHA256: %s != %s", fi1.SHA256, fi2.SHA256)
	}
}

func TestStore_MimeType(t *testing.T) {
	s := tempStore(t)
	cases := []struct {
		name     string
		wantMime string
	}{
		{"song.wav", "audio/wav"},
		{"song.mp3", "audio/mpeg"},
		{"song.flac", "audio/flac"},
		{"song.ogg", "audio/ogg"},
		{"song.m4a", "audio/mp4"},
	}
	for _, tc := range cases {
		fi, err := s.Save(tc.name, strings.NewReader("data"))
		if err != nil {
			t.Fatalf("Save %s: %v", tc.name, err)
		}
		if fi.MimeType != tc.wantMime {
			t.Errorf("%s: want %s, got %s", tc.name, tc.wantMime, fi.MimeType)
		}
	}
}

func TestStore_DeleteRemovesFile(t *testing.T) {
	s := tempStore(t)
	s.Save("del.wav", strings.NewReader("data"))
	if err := s.Delete("del.wav"); err != nil {
		t.Fatalf("Delete: %v", err)
	}
	files, _ := s.List()
	if len(files) != 0 {
		t.Errorf("expected 0 files after delete, got %d", len(files))
	}
}

func TestStore_ManifestDiff(t *testing.T) {
	s := tempStore(t)
	s.Save("a.wav", strings.NewReader("content-a"))
	s.Save("b.mp3", strings.NewReader("content-b"))

	files, err := s.List()
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(files) != 2 {
		t.Fatalf("expected 2, got %d", len(files))
	}

	// Simulate manifest-based diff: client knows "a.wav" by sha256
	serverSHA := map[string]string{}
	for _, f := range files {
		serverSHA[f.Name] = f.SHA256
	}

	// Client already has a.wav with correct SHA → only b.mp3 needs download
	clientHas := map[string]string{
		"a.wav": serverSHA["a.wav"],
	}
	var toDownload []string
	for _, f := range files {
		if clientSHA, ok := clientHas[f.Name]; !ok || clientSHA != f.SHA256 {
			toDownload = append(toDownload, f.Name)
		}
	}
	if len(toDownload) != 1 || toDownload[0] != "b.mp3" {
		t.Errorf("expected [b.mp3] to download, got %v", toDownload)
	}
}

func TestStore_SafeName_PreventDirectoryTraversal(t *testing.T) {
	s := tempStore(t)
	// Attempt directory traversal
	_, err := s.Save("../../etc/passwd", strings.NewReader("malicious"))
	if err == nil {
		// Save may succeed but must land in temp dir, not traverse
		path := s.path("../../etc/passwd")
		if !strings.HasPrefix(path, s.dir) {
			t.Error("path traversal detected!")
		}
	}
	// SafeName must strip traversal
	safe := SafeName("../../etc/passwd")
	if strings.Contains(safe, "..") || strings.Contains(safe, "/") {
		t.Errorf("SafeName should strip traversal, got %q", safe)
	}
}

func TestStore_HashCaching(t *testing.T) {
	s := tempStore(t)
	s.Save("cached.wav", strings.NewReader("hash-me"))

	fi1, _ := s.Stat("cached.wav")
	fi2, _ := s.Stat("cached.wav")
	if fi1.SHA256 != fi2.SHA256 {
		t.Error("cached hash should be identical on repeated Stat calls")
	}
	if len(s.hashCache) != 1 {
		t.Errorf("expected 1 cache entry, got %d", len(s.hashCache))
	}
}

func TestStore_NonAudioRejected(t *testing.T) {
	s := tempStore(t)
	_, err := s.Save("script.sh", strings.NewReader("#!/bin/bash"))
	if err == nil {
		t.Error("non-audio file should be rejected")
	}
}

func TestStore_DeleteNotFound(t *testing.T) {
	s := tempStore(t)
	err := s.Delete("nonexistent.wav")
	if err != ErrNotFound {
		t.Errorf("expected ErrNotFound, got %v", err)
	}
}

func TestMimeForExt(t *testing.T) {
	if mimeForExt(".wav") != "audio/wav" {
		t.Error("wav mime wrong")
	}
	if mimeForExt(".unknown") != "application/octet-stream" {
		t.Error("unknown ext should return octet-stream")
	}
}

func init() {
	// Ensure test dir is writable
	_ = os.MkdirAll(os.TempDir(), 0o755)
}
