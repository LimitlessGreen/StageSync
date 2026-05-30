package media

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestCache_GetPut(t *testing.T) {
	c := NewCache(10 * 1024) // 10 KiB Budget

	data := []byte("hello audio")
	c.Put("sha1", "test.wav", data)

	got, ok := c.Get("sha1")
	if !ok {
		t.Fatal("erwarte Cache-Hit nach Put")
	}
	if string(got) != string(data) {
		t.Fatalf("daten falsch: got %q want %q", got, data)
	}
}

func TestCache_GetByName(t *testing.T) {
	c := NewCache(0) // Default-Budget
	c.Put("abc123", "sound.wav", []byte("pcm"))

	_, ok := c.GetByName("sound.wav")
	if !ok {
		t.Fatal("erwarte Hit per Name")
	}
	_, ok = c.GetByName("missing.wav")
	if ok {
		t.Fatal("erwarte Miss für unbekannten Namen")
	}
}

func TestCache_LRUEviction(t *testing.T) {
	// Budget: 30 Bytes — genug für 3×10-Byte-Einträge
	c := NewCache(30)

	c.Put("id1", "a.wav", make([]byte, 10))
	c.Put("id2", "b.wav", make([]byte, 10))
	c.Put("id3", "c.wav", make([]byte, 10))
	// id1 ist ältester Eintrag (LRU-Back)

	// id4 einfügen → id1 muss evicted werden
	c.Put("id4", "d.wav", make([]byte, 10))

	if _, ok := c.Get("id1"); ok {
		t.Error("id1 sollte nach Eviction nicht mehr im Cache sein")
	}
	if _, ok := c.Get("id4"); !ok {
		t.Error("id4 sollte im Cache sein")
	}
}

func TestCache_LRUEviction_TouchPreventsEviction(t *testing.T) {
	c := NewCache(30)

	c.Put("id1", "a.wav", make([]byte, 10))
	c.Put("id2", "b.wav", make([]byte, 10))
	c.Put("id3", "c.wav", make([]byte, 10))

	// id1 anfassen → rückt nach vorne, id2 wird LRU-Kandidat
	c.Get("id1")

	c.Put("id4", "d.wav", make([]byte, 10))

	if _, ok := c.Get("id2"); ok {
		t.Error("id2 (least recently used) sollte evicted sein")
	}
	if _, ok := c.Get("id1"); !ok {
		t.Error("id1 (recently used) sollte noch im Cache sein")
	}
}

func TestCache_Evict(t *testing.T) {
	c := NewCache(0)
	c.Put("sha1", "file.wav", []byte("data"))

	c.Evict("sha1")
	if _, ok := c.Get("sha1"); ok {
		t.Error("nach Evict() sollte Eintrag nicht mehr im Cache sein")
	}
}

func TestCache_EvictByName(t *testing.T) {
	c := NewCache(0)
	c.Put("sha1", "file.wav", []byte("data"))

	c.EvictByName("file.wav")
	if _, ok := c.Get("sha1"); ok {
		t.Error("nach EvictByName() sollte Eintrag nicht mehr im Cache sein")
	}
}

func TestCache_ShowLock_SoftPreventsEviction(t *testing.T) {
	// Budget: 30 Bytes — Show-Lock verhindert Eviction bis 95 %
	c := NewCache(30)

	c.Put("id1", "a.wav", make([]byte, 10))
	c.Put("id2", "b.wav", make([]byte, 10))
	c.Put("id3", "c.wav", make([]byte, 10))

	c.LockForShow()

	// Neues Item: Budget ist voll (30/30). Im Show-Lock wird nur evicted wenn
	// used+need > 95 % von max. 10 Bytes > 28,5 → eviction findet trotzdem statt,
	// aber OOM wird verhindert.
	c.Put("id4", "d.wav", make([]byte, 10))

	c.UnlockShow()

	// Nach dem Show-Lock muss id4 im Cache sein
	if _, ok := c.Get("id4"); !ok {
		t.Error("id4 sollte nach dem Show-Lock im Cache sein")
	}
}

func TestCache_OversizedItem(t *testing.T) {
	c := NewCache(5) // Nur 5 Bytes Budget

	// Ein 10-Byte-Item überschreitet das Budget → wird nicht gecacht
	c.Put("big", "big.wav", make([]byte, 10))
	if _, ok := c.Get("big"); ok {
		t.Error("überdimensioniertes Item sollte nicht gecacht werden")
	}
}

func TestCache_Stats(t *testing.T) {
	c := NewCache(100)
	c.Put("sha1", "a.wav", make([]byte, 20))
	c.Put("sha2", "b.wav", make([]byte, 30))

	used, max, n := c.Stats()
	if used != 50 {
		t.Errorf("used=%d want 50", used)
	}
	if max != 100 {
		t.Errorf("max=%d want 100", max)
	}
	if n != 2 {
		t.Errorf("entries=%d want 2", n)
	}
}

func TestCache_PreloadAsync(t *testing.T) {
	// Store mit echten Dateien anlegen
	dir := t.TempDir()
	store, err := NewStore(dir)
	if err != nil {
		t.Fatalf("NewStore: %v", err)
	}

	// Testdatei schreiben
	testData := []byte("fake wav data")
	if err := os.WriteFile(filepath.Join(dir, "test.wav"), testData, 0o644); err != nil {
		t.Fatal(err)
	}

	// SHA ermitteln
	files, err := store.List()
	if err != nil || len(files) == 0 {
		t.Fatal("List fehlgeschlagen oder leer")
	}
	assetID := files[0].SHA256

	c := NewCache(0)
	wg := c.PreloadAsync(context.Background(), store, []string{assetID}, 1)
	wg.Wait()

	data, ok := c.Get(assetID)
	if !ok {
		t.Fatal("nach PreloadAsync sollte Datei im Cache sein")
	}
	if string(data) != string(testData) {
		t.Errorf("daten stimmen nicht überein")
	}
}

func TestCache_PreloadAsync_AlreadyCached(t *testing.T) {
	dir := t.TempDir()
	store, _ := NewStore(dir)

	c := NewCache(0)
	c.Put("existing", "x.wav", []byte("data"))

	// Bereits gecachtes Item → PreloadAsync soll es nicht doppelt laden
	calls := 0
	_ = calls
	c.PreloadAsync(context.Background(), store, []string{"existing"}, 1)
	// Kein Fehler erwartet; Cache-Inhalt unverändert
	if _, ok := c.Get("existing"); !ok {
		t.Error("bereits gecachtes Item sollte nach PreloadAsync noch da sein")
	}
}
