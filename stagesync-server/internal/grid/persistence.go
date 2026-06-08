package grid

import (
	"encoding/json"
	"os"
	"path/filepath"

	"google.golang.org/protobuf/encoding/protojson"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/persistence"
)

// Persistence speichert/lädt Grids pro Session als protojson auf Disk.
// Anders als showcontrol (manuelles Feld-Mapping) nutzen wir hier protojson —
// das deckt die oneof-Payloads ohne Mehraufwand vollständig ab.
type Persistence struct {
	writer  *persistence.LockedWriter
	dataDir string
}

func NewPersistence(dataDir string) *Persistence {
	_ = os.MkdirAll(dataDir, 0o755)
	return &Persistence{
		writer:  persistence.NewLockedWriter("grid persist"),
		dataDir: dataDir,
	}
}

func (p *Persistence) path(sessionID string) string {
	return filepath.Join(p.dataDir, "grid_"+sessionID+".json")
}

// gridFile ist das On-Disk-Format: eine Liste von Grids als protojson-Bytes.
type gridFile struct {
	Grids []string `json:"grids"` // jedes Element: protojson eines pb.Grid
}

// Save schreibt alle Grids der Session nicht-blockierend auf Disk.
func (p *Persistence) Save(sessionID string, store *Store) {
	store.mu.RLock()
	grids := make([]*pb.Grid, 0, len(store.grids))
	for _, g := range store.grids {
		grids = append(grids, g)
	}
	store.mu.RUnlock()

	marshaler := protojson.MarshalOptions{UseProtoNames: true}
	file := gridFile{}
	for _, g := range grids {
		b, err := marshaler.Marshal(g)
		if err != nil {
			continue
		}
		file.Grids = append(file.Grids, string(b))
	}
	data, err := json.MarshalIndent(file, "", "  ")
	if err != nil {
		return
	}
	p.writer.WriteAsync(p.path(sessionID), data)
}

// Load stellt die Grids der Session aus der JSON-Datei wieder her.
func (p *Persistence) Load(sessionID string, store *Store) {
	data, ok := persistence.ReadFile(p.path(sessionID), "grid persist")
	if !ok {
		return
	}
	var file gridFile
	if err := json.Unmarshal(data, &file); err != nil {
		return
	}
	for _, s := range file.Grids {
		g := &pb.Grid{}
		if err := protojson.Unmarshal([]byte(s), g); err != nil {
			continue
		}
		store.ReplaceGrid(g)
	}
}
