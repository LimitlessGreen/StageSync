package showcontrol

import (
	"encoding/json"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"

	pb "stagesync-server/gen/go/stagesync/v1"
)

// snapshotEntry ist das On-Disk-Format für eine CueList.
type snapshotEntry struct {
	SessionID string    `json:"session_id"`
	UpdatedAt time.Time `json:"updated_at"`
	// CueList serialisiert als JSON via protojson wäre ideal,
	// aber für Phase 3 serialisieren wir die Felder manuell.
	CueListID string      `json:"cue_list_id"`
	Name      string      `json:"name"`
	Version   int64       `json:"version"`
	Cues      []*cueEntry `json:"cues"`
}

type cueEntry struct {
	CueID        string  `json:"cue_id"`
	Number       string  `json:"number"`
	Label        string  `json:"label"`
	CueType      int32   `json:"cue_type"`
	TargetNodeID string  `json:"target_node_id"`
	AutoContinue bool    `json:"auto_continue"`
	PreWaitMs    float64 `json:"pre_wait_ms"`
	PostWaitMs   float64 `json:"post_wait_ms"`
	Version      int64   `json:"version"`

	// Audio
	FilePath    string  `json:"file_path,omitempty"`
	VolumeDb    float64 `json:"volume_db,omitempty"`
	FadeInMs    float64 `json:"fade_in_ms,omitempty"`
	FadeOutMs   float64 `json:"fade_out_ms,omitempty"`
	Loop        bool    `json:"loop,omitempty"`

	// MA-OSC
	OscAddress   string `json:"osc_address,omitempty"`
	OscArgument  string `json:"osc_argument,omitempty"`
	ExecutorPage int32  `json:"executor_page,omitempty"`
	ExecutorNo   int32  `json:"executor_no,omitempty"`
	MaCommand    int32  `json:"ma_command,omitempty"`

	// Wait
	WaitDurationMs float64 `json:"wait_duration_ms,omitempty"`

	// Goto
	GotoCueID     string `json:"goto_cue_id,omitempty"`
	GotoNumber    string `json:"goto_number,omitempty"`
}

// Persistence speichert und lädt den kompletten Show-State als JSON.
type Persistence struct {
	mu      sync.Mutex
	dataDir string
}

func NewPersistence(dataDir string) *Persistence {
	_ = os.MkdirAll(dataDir, 0o755)
	return &Persistence{dataDir: dataDir}
}

func (p *Persistence) snapshotPath(sessionID string) string {
	return filepath.Join(p.dataDir, "session_"+sessionID+".json")
}

// Save schreibt den Store-Inhalt auf Disk (nicht-blockierend).
func (p *Persistence) Save(sessionID string, store *Store) {
	go func() {
		p.mu.Lock()
		defer p.mu.Unlock()

		entries := make([]*snapshotEntry, 0)
		store.mu.RLock()
		for _, cl := range store.cueLists {
			cl.mu.RLock()
			entry := p.clToEntry(sessionID, cl)
			cl.mu.RUnlock()
			entries = append(entries, entry)
		}
		store.mu.RUnlock()

		data, err := json.MarshalIndent(entries, "", "  ")
		if err != nil {
			log.Printf("[persist] marshal error: %v", err)
			return
		}
		if err := os.WriteFile(p.snapshotPath(sessionID), data, 0o644); err != nil {
			log.Printf("[persist] write error: %v", err)
		}
	}()
}

// Load stellt den Store aus einer gespeicherten JSON-Datei wieder her.
func (p *Persistence) Load(sessionID string, store *Store) {
	data, err := os.ReadFile(p.snapshotPath(sessionID))
	if err != nil {
		if !os.IsNotExist(err) {
			log.Printf("[persist] read error: %v", err)
		}
		return
	}

	var entries []*snapshotEntry
	if err := json.Unmarshal(data, &entries); err != nil {
		log.Printf("[persist] unmarshal error: %v", err)
		return
	}

	for _, entry := range entries {
		cl := p.entryToCueList(entry)
		store.ReplaceCueList(cl)
	}
	log.Printf("[persist] loaded %d cue lists for session %s", len(entries), sessionID)
}

// ── Konvertierungen ───────────────────────────────────────────────────────────

func (p *Persistence) clToEntry(sessionID string, cl *CueList) *snapshotEntry {
	e := &snapshotEntry{
		SessionID: sessionID,
		UpdatedAt: time.Now(),
		CueListID: cl.proto.CueListId,
		Name:      cl.proto.Name,
		Version:   cl.proto.Version,
		Cues:      make([]*cueEntry, 0, len(cl.proto.Cues)),
	}
	for _, c := range cl.proto.Cues {
		e.Cues = append(e.Cues, p.cueToEntry(c))
	}
	return e
}

func (p *Persistence) cueToEntry(c *pb.Cue) *cueEntry {
	e := &cueEntry{
		CueID:        c.CueId,
		Number:       c.Number,
		Label:        c.Label,
		CueType:      int32(c.CueType),
		TargetNodeID: c.TargetNodeId,
		AutoContinue: c.AutoContinue,
		PreWaitMs:    c.PreWaitMs,
		PostWaitMs:   c.PostWaitMs,
		Version:      c.Version,
	}
	switch params := c.Params.(type) {
	case *pb.Cue_Audio:
		if params.Audio != nil {
			e.FilePath  = params.Audio.FilePath
			e.VolumeDb  = params.Audio.VolumeDb
			e.FadeInMs  = params.Audio.FadeInMs
			e.FadeOutMs = params.Audio.FadeOutMs
			e.Loop      = params.Audio.Loop
		}
	case *pb.Cue_MaOsc:
		if params.MaOsc != nil {
			e.OscAddress   = params.MaOsc.OscAddress
			e.OscArgument  = params.MaOsc.OscArgument
			e.ExecutorPage = params.MaOsc.ExecutorPage
			e.ExecutorNo   = params.MaOsc.ExecutorNo
			e.MaCommand    = int32(params.MaOsc.Command)
		}
	case *pb.Cue_Wait:
		if params.Wait != nil {
			e.WaitDurationMs = params.Wait.DurationMs
		}
	case *pb.Cue_GotoP:
		if params.GotoP != nil {
			e.GotoCueID  = params.GotoP.TargetCueId
			e.GotoNumber = params.GotoP.TargetNumber
		}
	}
	return e
}

func (p *Persistence) entryToCueList(entry *snapshotEntry) *pb.CueList {
	cl := &pb.CueList{
		CueListId: entry.CueListID,
		Name:      entry.Name,
		Version:   entry.Version,
		UpdatedAt: nowProto(),
	}
	for _, ce := range entry.Cues {
		cl.Cues = append(cl.Cues, p.entryToCue(ce))
	}
	return cl
}

func (p *Persistence) entryToCue(e *cueEntry) *pb.Cue {
	c := &pb.Cue{
		CueId:        e.CueID,
		Number:       e.Number,
		Label:        e.Label,
		CueType:      pb.CueType(e.CueType),
		TargetNodeId: e.TargetNodeID,
		AutoContinue: e.AutoContinue,
		PreWaitMs:    e.PreWaitMs,
		PostWaitMs:   e.PostWaitMs,
		Version:      e.Version,
	}
	switch pb.CueType(e.CueType) {
	case pb.CueType_CUE_TYPE_AUDIO:
		c.Params = &pb.Cue_Audio{Audio: &pb.AudioCueParams{
			FilePath:  e.FilePath,
			VolumeDb:  e.VolumeDb,
			FadeInMs:  e.FadeInMs,
			FadeOutMs: e.FadeOutMs,
			Loop:      e.Loop,
		}}
	case pb.CueType_CUE_TYPE_MA_OSC:
		c.Params = &pb.Cue_MaOsc{MaOsc: &pb.MaOscCueParams{
			OscAddress:   e.OscAddress,
			OscArgument:  e.OscArgument,
			ExecutorPage: e.ExecutorPage,
			ExecutorNo:   e.ExecutorNo,
			Command:      pb.MaOscCueParams_MaCommand(e.MaCommand),
		}}
	case pb.CueType_CUE_TYPE_WAIT:
		c.Params = &pb.Cue_Wait{Wait: &pb.WaitCueParams{DurationMs: e.WaitDurationMs}}
	case pb.CueType_CUE_TYPE_GOTO:
		c.Params = &pb.Cue_GotoP{GotoP: &pb.GotoCueParams{
			TargetCueId: e.GotoCueID,
			TargetNumber: e.GotoNumber,
		}}
	}
	return c
}
