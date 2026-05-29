package session

import (
	"encoding/json"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// Persistence speichert die Identität persistenter Sessions auf Disk, damit sie
// einen Server-Neustart überleben. Nodes/Tokens sind transient und werden NICHT
// gespeichert — Clients treten nach einem Neustart neu bei (Re-Join).
// Die CueLists werden separat von showcontrol.Persistence gesichert.
type Persistence struct {
	mu   sync.Mutex
	path string
}

type sessionRecord struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	ShowName    string `json:"show_name"`
	PassHash    string `json:"pass_hash"`
	MasterID    string `json:"master_id"`
	CreatedAtMs int64  `json:"created_at_ms"`
}

func NewPersistence(dataDir string) *Persistence {
	_ = os.MkdirAll(dataDir, 0o755)
	return &Persistence{path: filepath.Join(dataDir, "sessions.json")}
}

// Load liest alle persistenten Sessions (ohne Nodes/Tokens).
func (p *Persistence) Load() []*Session {
	p.mu.Lock()
	defer p.mu.Unlock()

	data, err := os.ReadFile(p.path)
	if err != nil {
		if !os.IsNotExist(err) {
			log.Printf("[session-persist] read error: %v", err)
		}
		return nil
	}
	var recs []sessionRecord
	if err := json.Unmarshal(data, &recs); err != nil {
		log.Printf("[session-persist] unmarshal error: %v", err)
		return nil
	}
	out := make([]*Session, 0, len(recs))
	for _, r := range recs {
		s := NewSession(r.ID, r.Name, r.ShowName, r.PassHash, r.MasterID)
		if r.CreatedAtMs > 0 {
			s.CreatedAt = time.UnixMilli(r.CreatedAtMs)
		}
		s.Persistent = true
		out = append(out, s)
	}
	return out
}

// Save schreibt alle persistenten Sessions (transiente werden ignoriert).
func (p *Persistence) Save(sessions []*Session) {
	p.mu.Lock()
	defer p.mu.Unlock()

	recs := make([]sessionRecord, 0)
	for _, s := range sessions {
		if !s.Persistent {
			continue
		}
		recs = append(recs, sessionRecord{
			ID:          s.ID,
			Name:        s.Name,
			ShowName:    s.ShowName,
			PassHash:    s.PassHash,
			MasterID:    s.MasterID,
			CreatedAtMs: s.CreatedAt.UnixMilli(),
		})
	}
	data, err := json.MarshalIndent(recs, "", "  ")
	if err != nil {
		log.Printf("[session-persist] marshal error: %v", err)
		return
	}
	if err := os.WriteFile(p.path, data, 0o644); err != nil {
		log.Printf("[session-persist] write error: %v", err)
	}
}
