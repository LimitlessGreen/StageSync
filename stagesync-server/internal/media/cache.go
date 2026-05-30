package media

import (
	"container/list"
	"context"
	"log"
	"sync"
)

const defaultCacheMaxBytes = 2 * 1024 * 1024 * 1024 // 2 GiB

// cacheEntry ist ein Eintrag im RAM-Cache.
type cacheEntry struct {
	assetID string // SHA-256
	name    string
	data    []byte
	elem    *list.Element // Zeiger auf den LRU-Listen-Knoten
}

// Cache hält Audiodateien im RAM (LRU-Eviction). Thread-safe.
//
// Preload-Strategie: Die Show-Engine ruft PreloadAsync mit den asset_ids der
// nächsten N Cues auf, sobald ein Go-Befehl dispatcht wird. Der Cache füllt
// sich im Hintergrund, sodass bei StreamFile fast immer ein Cache-Hit vorliegt.
//
// Show-Lock: Während einer laufenden Show wird die Eviction gesperrt. Nur wenn
// der RAM unter den konfigurierten Schwellwert fällt, wird trotzdem evicted.
type Cache struct {
	mu       sync.RWMutex
	maxBytes int64
	used     int64
	byID     map[string]*cacheEntry // assetID → entry
	byName   map[string]*cacheEntry // name → entry (Lookup-Hilfe)
	lru      list.List              // Front = zuletzt genutzt

	// locked = true während aktiver Show: verhindert Eviction von Items,
	// die im letzten syncPoint-Zeitraum genutzt wurden.
	showMu sync.Mutex
	locked bool
}

// NewCache erzeugt einen neuen Cache mit maxBytes RAM-Budget.
// maxBytes <= 0 ⇒ Default (2 GiB).
func NewCache(maxBytes int64) *Cache {
	if maxBytes <= 0 {
		maxBytes = defaultCacheMaxBytes
	}
	return &Cache{
		maxBytes: maxBytes,
		byID:     make(map[string]*cacheEntry),
		byName:   make(map[string]*cacheEntry),
	}
}

// Get gibt die gecachten Bytes für asset_id zurück (nil, false = Cache-Miss).
func (c *Cache) Get(assetID string) ([]byte, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	e, ok := c.byID[assetID]
	if !ok {
		return nil, false
	}
	c.lru.MoveToFront(e.elem)
	return e.data, true
}

// GetByName gibt die gecachten Bytes für den Dateinamen zurück.
func (c *Cache) GetByName(name string) ([]byte, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	e, ok := c.byName[SafeName(name)]
	if !ok {
		return nil, false
	}
	c.lru.MoveToFront(e.elem)
	return e.data, true
}

// Put speichert Daten im Cache. Ist der Cache zu voll, wird LRU evicted
// (außer bei aktivem Show-Lock — dann wird trotzdem evicted wenn nötig,
// um OOM zu verhindern).
func (c *Cache) Put(assetID, name string, data []byte) {
	if int64(len(data)) > c.maxBytes {
		return // einzelne Datei größer als Budget → nicht cachen
	}
	c.mu.Lock()
	defer c.mu.Unlock()

	safe := SafeName(name)

	// Bestehendem Eintrag ersetzen
	if old, ok := c.byID[assetID]; ok {
		c.used -= int64(len(old.data))
		c.lru.Remove(old.elem)
		delete(c.byID, assetID)
		delete(c.byName, old.name)
	}

	c.evictLocked(int64(len(data)))

	e := &cacheEntry{assetID: assetID, name: safe, data: data}
	e.elem = c.lru.PushFront(e)
	c.byID[assetID] = e
	c.byName[safe] = e
	c.used += int64(len(data))
}

// Evict entfernt einen Eintrag explizit (z.B. nach Delete oder Upload).
func (c *Cache) Evict(assetID string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.evictOneByID(assetID)
}

// EvictByName entfernt einen Eintrag anhand des Dateinamens.
func (c *Cache) EvictByName(name string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	safe := SafeName(name)
	if e, ok := c.byName[safe]; ok {
		c.evictOneByID(e.assetID)
	}
}

func (c *Cache) evictOneByID(assetID string) {
	e, ok := c.byID[assetID]
	if !ok {
		return
	}
	c.used -= int64(len(e.data))
	c.lru.Remove(e.elem)
	delete(c.byID, assetID)
	delete(c.byName, e.name)
}

// evictLocked räumt Platz für needBytes. Aufrufer hält c.mu.
func (c *Cache) evictLocked(needBytes int64) {
	c.showMu.Lock()
	locked := c.locked
	c.showMu.Unlock()

	for c.used+needBytes > c.maxBytes {
		back := c.lru.Back()
		if back == nil {
			break
		}
		e := back.Value.(*cacheEntry)
		// Im Show-Lock nur evicten wenn absolut nötig (> 95 % voll),
		// damit laufende Cues nicht aus dem Cache fallen.
		if locked && c.used+needBytes <= int64(float64(c.maxBytes)*0.95) {
			break
		}
		c.used -= int64(len(e.data))
		c.lru.Remove(back)
		delete(c.byID, e.assetID)
		delete(c.byName, e.name)
	}
}

// LockForShow verhindert reguläre Eviction während einer laufenden Show.
func (c *Cache) LockForShow() {
	c.showMu.Lock()
	c.locked = true
	c.showMu.Unlock()
}

// UnlockShow gibt die Eviction wieder frei.
func (c *Cache) UnlockShow() {
	c.showMu.Lock()
	c.locked = false
	c.showMu.Unlock()
}

// Stats gibt aktuelle Nutzung zurück (für Monitoring/Logging).
func (c *Cache) Stats() (usedBytes, maxBytes int64, entries int) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.used, c.maxBytes, len(c.byID)
}

// StoreWarmer verbindet Cache und Store und implementiert showcontrol.AssetWarmer.
// So bleibt engine.go frei von einem direkten media-Import.
type StoreWarmer struct {
	cache *Cache
	store *Store
}

// NewStoreWarmer erzeugt einen StoreWarmer. Kann direkt an engine.SetWarmer übergeben werden.
func NewStoreWarmer(cache *Cache, store *Store) *StoreWarmer {
	return &StoreWarmer{cache: cache, store: store}
}

// WarmAssets lädt die übergebenen asset_ids asynchron in den RAM-Cache.
func (w *StoreWarmer) WarmAssets(ctx context.Context, assetIDs []string) {
	w.cache.PreloadAsync(ctx, w.store, assetIDs, 4)
}

// LockForShow verhindert reguläre Cache-Eviction während der Show.
func (w *StoreWarmer) LockForShow() { w.cache.LockForShow() }

// UnlockShow gibt die Eviction nach Show-Ende wieder frei.
func (w *StoreWarmer) UnlockShow() { w.cache.UnlockShow() }

// PreloadAsync lädt asset_ids im Hintergrund in den Cache und kehrt sofort
// zurück. Bereits gecachte Einträge werden übersprungen.
// maxConcurrent begrenzt gleichzeitige Disk-Reads (0 → 4).
// Die zurückgegebene WaitGroup kann gewartet werden; in der Produktion
// typischerweise ignoriert (fire-and-forget).
func (c *Cache) PreloadAsync(ctx context.Context, store *Store, assetIDs []string, maxConcurrent int) *sync.WaitGroup {
	if maxConcurrent <= 0 {
		maxConcurrent = 4
	}
	sem := make(chan struct{}, maxConcurrent)
	var wg sync.WaitGroup

	for _, id := range assetIDs {
		if _, ok := c.Get(id); ok {
			continue // bereits im Cache
		}
		id := id // loop-var capture
		sem <- struct{}{}
		wg.Add(1)
		go func() {
			defer wg.Done()
			defer func() { <-sem }()
			if ctx.Err() != nil {
				return
			}
			path, err := store.FilePathBySHA256(id)
			if err != nil {
				return // Datei nicht gefunden → still überspringen
			}
			data, err := store.ReadAll(path)
			if err != nil {
				log.Printf("[cache] preload %s: %v", id[:8], err)
				return
			}
			name := SafeName(path)
			c.Put(id, name, data)
			used, max, n := c.Stats()
			log.Printf("[cache] preloaded %s (%d MB, cache %d/%d MB, %d entries)",
				name, len(data)>>20, used>>20, max>>20, n)
		}()
	}
	return &wg
}
