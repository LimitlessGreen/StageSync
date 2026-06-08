package showcontrol

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"

	pb "stagesync-server/gen/go/stagesync/v1"
	"stagesync-server/internal/persistence"
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

type busSendEntry struct {
	BusID       string  `json:"bus_id"`
	SendLevelDb float32 `json:"send_level_db"`
	Enabled     bool    `json:"enabled"`
}

type cueEntry struct {
	CueID           string  `json:"cue_id"`
	Number          string  `json:"number"`
	Label           string  `json:"label"`
	CueType         int32   `json:"cue_type"`
	LogicalOutputID string  `json:"logical_output_id,omitempty"`
	TargetNodeID    string  `json:"target_node_id,omitempty"`
	AutoContinue    bool    `json:"auto_continue"`
	PreWaitMs       float64 `json:"pre_wait_ms"`
	PostWaitMs      float64 `json:"post_wait_ms"`
	Version         int64   `json:"version"`

	// Audio
	AssetId            string         `json:"asset_id,omitempty"`
	FilePath           string         `json:"file_path,omitempty"` // Legacy-Fallback
	VolumeDb           float64        `json:"volume_db,omitempty"`
	FadeInMs           float64        `json:"fade_in_ms,omitempty"`
	FadeOutMs          float64        `json:"fade_out_ms,omitempty"`
	Loop               bool           `json:"loop,omitempty"`
	StartTimeMs        float64        `json:"start_time_ms,omitempty"`
	EndTimeMs          float64        `json:"end_time_ms,omitempty"`
	DeclaredDurationMs float64        `json:"declared_duration_ms,omitempty"`
	PauseBehavior      int32          `json:"pause_behavior,omitempty"`
	PauseFadeMs        float64        `json:"pause_fade_ms,omitempty"`
	ResumeBehavior     int32          `json:"resume_behavior,omitempty"`
	ResumeFadeMs       float64        `json:"resume_fade_ms,omitempty"`
	BusSends           []busSendEntry `json:"bus_sends,omitempty"`

	// MA-OSC
	OscAddress   string `json:"osc_address,omitempty"`
	OscArgument  string `json:"osc_argument,omitempty"`
	ExecutorPage int32  `json:"executor_page,omitempty"`
	ExecutorNo   int32  `json:"executor_no,omitempty"`
	MaCommand    int32  `json:"ma_command,omitempty"`
	MaGotoCue    int32  `json:"ma_goto_cue,omitempty"`

	// Wait
	WaitDurationMs float64 `json:"wait_duration_ms,omitempty"`

	// Goto
	GotoCueID  string `json:"goto_cue_id,omitempty"`
	GotoNumber string `json:"goto_number,omitempty"`

	// Group
	ChildCueIds []string `json:"child_cue_ids,omitempty"`
	Sequential  bool     `json:"sequential,omitempty"`

	// Note
	NoteText     string `json:"note_text,omitempty"`
	NoteColorHex string `json:"note_color_hex,omitempty"`
	NoteLandable bool   `json:"note_landable,omitempty"`

	// Fade
	FadeTargetCueID     string  `json:"fade_target_cue_id,omitempty"`
	FadeTargetCueNumber string  `json:"fade_target_cue_number,omitempty"`
	FadeAction          int32   `json:"fade_action,omitempty"`
	FadeTargetVolumeDb  float64 `json:"fade_target_volume_db,omitempty"`
	FadeDurationMs      float64 `json:"fade_duration_ms,omitempty"`
	FadeStopWhenDone    bool    `json:"fade_stop_when_done,omitempty"`
}

// Persistence speichert und lädt den kompletten Show-State als JSON.
type Persistence struct {
	writer  *persistence.LockedWriter
	dataDir string
}

func NewPersistence(dataDir string) *Persistence {
	_ = os.MkdirAll(dataDir, 0o755)
	return &Persistence{
		writer:  persistence.NewLockedWriter("persist"),
		dataDir: dataDir,
	}
}

func (p *Persistence) snapshotPath(sessionID string) string {
	return filepath.Join(p.dataDir, "session_"+sessionID+".json")
}

// Save schreibt den Store-Inhalt auf Disk (nicht-blockierend).
func (p *Persistence) Save(sessionID string, store *Store) {
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
		return
	}
	p.writer.WriteAsync(p.snapshotPath(sessionID), data)
}

// Load stellt den Store aus einer gespeicherten JSON-Datei wieder her.
func (p *Persistence) Load(sessionID string, store *Store) {
	data, ok := persistence.ReadFile(p.snapshotPath(sessionID), "persist")
	if !ok {
		return
	}

	var entries []*snapshotEntry
	if err := json.Unmarshal(data, &entries); err != nil {
		return
	}

	for _, entry := range entries {
		cl := p.entryToCueList(entry)
		store.ReplaceCueList(cl)
	}
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
		CueID:           c.CueId,
		Number:          c.Number,
		Label:           c.Label,
		CueType:         int32(c.CueType),
		LogicalOutputID: c.LogicalOutputId,
		TargetNodeID:    c.TargetNodeId,
		AutoContinue:    c.AutoContinue,
		PreWaitMs:       c.PreWaitMs,
		PostWaitMs:      c.PostWaitMs,
		Version:         c.Version,
	}
	switch params := c.Params.(type) {
	case *pb.Cue_Audio:
		if params.Audio != nil {
			a := params.Audio
			e.AssetId            = a.AssetId
			e.FilePath           = a.FilePath
			e.VolumeDb           = a.VolumeDb
			e.FadeInMs           = a.FadeInMs
			e.FadeOutMs          = a.FadeOutMs
			e.Loop               = a.Loop
			e.StartTimeMs        = a.StartTimeMs
			e.EndTimeMs          = a.EndTimeMs
			e.DeclaredDurationMs = a.DeclaredDurationMs
			e.PauseBehavior      = int32(a.PauseBehavior)
			e.PauseFadeMs        = a.PauseFadeMs
			e.ResumeBehavior     = int32(a.ResumeBehavior)
			e.ResumeFadeMs       = a.ResumeFadeMs
			for _, bs := range a.BusSends {
				e.BusSends = append(e.BusSends, busSendEntry{
					BusID:       bs.BusId,
					SendLevelDb: bs.SendLevelDb,
					Enabled:     bs.Enabled,
				})
			}
		}
	case *pb.Cue_MaOsc:
		if params.MaOsc != nil {
			e.OscAddress   = params.MaOsc.OscAddress
			e.OscArgument  = params.MaOsc.OscArgument
			e.ExecutorPage = params.MaOsc.ExecutorPage
			e.ExecutorNo   = params.MaOsc.ExecutorNo
			e.MaCommand    = int32(params.MaOsc.Command)
			e.MaGotoCue    = params.MaOsc.GotoCue
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
	case *pb.Cue_Group:
		if params.Group != nil {
			e.ChildCueIds = params.Group.ChildCueIds
			e.Sequential  = params.Group.Sequential
		}
	case *pb.Cue_Note:
		if params.Note != nil {
			e.NoteText     = params.Note.Text
			e.NoteColorHex = params.Note.ColorHex
			e.NoteLandable = params.Note.Landable
		}
	case *pb.Cue_Fade:
		if params.Fade != nil {
			e.FadeTargetCueID     = params.Fade.TargetCueId
			e.FadeTargetCueNumber = params.Fade.TargetCueNumber
			e.FadeAction          = int32(params.Fade.Action)
			e.FadeTargetVolumeDb  = params.Fade.TargetVolumeDb
			e.FadeDurationMs      = params.Fade.DurationMs
			e.FadeStopWhenDone    = params.Fade.StopWhenDone
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
		CueId:           e.CueID,
		Number:          e.Number,
		Label:           e.Label,
		CueType:         pb.CueType(e.CueType),
		LogicalOutputId: e.LogicalOutputID,
		TargetNodeId:    e.TargetNodeID,
		AutoContinue:    e.AutoContinue,
		PreWaitMs:       e.PreWaitMs,
		PostWaitMs:      e.PostWaitMs,
		Version:         e.Version,
	}
	switch pb.CueType(e.CueType) {
	case pb.CueType_CUE_TYPE_AUDIO:
		audio := &pb.AudioCueParams{
			AssetId:            e.AssetId,
			FilePath:           e.FilePath,
			VolumeDb:           e.VolumeDb,
			FadeInMs:           e.FadeInMs,
			FadeOutMs:          e.FadeOutMs,
			Loop:               e.Loop,
			StartTimeMs:        e.StartTimeMs,
			EndTimeMs:          e.EndTimeMs,
			DeclaredDurationMs: e.DeclaredDurationMs,
			PauseBehavior:      pb.AudioCueParams_PauseBehavior(e.PauseBehavior),
			PauseFadeMs:        e.PauseFadeMs,
			ResumeBehavior:     pb.AudioCueParams_ResumeBehavior(e.ResumeBehavior),
			ResumeFadeMs:       e.ResumeFadeMs,
		}
		for _, bs := range e.BusSends {
			audio.BusSends = append(audio.BusSends, &pb.BusSend{
				BusId:       bs.BusID,
				SendLevelDb: bs.SendLevelDb,
				Enabled:     bs.Enabled,
			})
		}
		c.Params = &pb.Cue_Audio{Audio: audio}
	case pb.CueType_CUE_TYPE_MA_OSC:
		c.Params = &pb.Cue_MaOsc{MaOsc: &pb.MaOscCueParams{
			OscAddress:   e.OscAddress,
			OscArgument:  e.OscArgument,
			ExecutorPage: e.ExecutorPage,
			ExecutorNo:   e.ExecutorNo,
			Command:      pb.MaOscCueParams_MaCommand(e.MaCommand),
			GotoCue:      e.MaGotoCue,
		}}
	case pb.CueType_CUE_TYPE_WAIT:
		c.Params = &pb.Cue_Wait{Wait: &pb.WaitCueParams{DurationMs: e.WaitDurationMs}}
	case pb.CueType_CUE_TYPE_GOTO:
		c.Params = &pb.Cue_GotoP{GotoP: &pb.GotoCueParams{
			TargetCueId:  e.GotoCueID,
			TargetNumber: e.GotoNumber,
		}}
	case pb.CueType_CUE_TYPE_GROUP:
		c.Params = &pb.Cue_Group{Group: &pb.GroupCueParams{
			ChildCueIds: e.ChildCueIds,
			Sequential:  e.Sequential,
		}}
	case pb.CueType_CUE_TYPE_NOTE:
		c.Params = &pb.Cue_Note{Note: &pb.NoteCueParams{
			Text:     e.NoteText,
			ColorHex: e.NoteColorHex,
			Landable: e.NoteLandable,
		}}
	case pb.CueType_CUE_TYPE_FADE:
		c.Params = &pb.Cue_Fade{Fade: &pb.FadeCueParams{
			TargetCueId:    e.FadeTargetCueID,
			TargetCueNumber: e.FadeTargetCueNumber,
			Action:         pb.FadeCueParams_FadeAction(e.FadeAction),
			TargetVolumeDb: e.FadeTargetVolumeDb,
			DurationMs:     e.FadeDurationMs,
			StopWhenDone:   e.FadeStopWhenDone,
		}}
	}
	return c
}
