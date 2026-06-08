package midinode

import (
	"testing"

	pb "stagesync-server/gen/go/stagesync/v1"
)

func TestNoteToCell_Corners(t *testing.T) {
	cases := []struct {
		note          uint8
		track, scene  int32
	}{
		{0, 0, 7},   // unten links → Spalte 0, unterste Scene (7)
		{7, 7, 7},   // unten rechts
		{56, 0, 0},  // oben links → Scene 0
		{63, 7, 0},  // oben rechts
	}
	for _, c := range cases {
		track, scene, ok := noteToCell(c.note)
		if !ok || track != c.track || scene != c.scene {
			t.Errorf("noteToCell(%d) = (%d,%d,%v), want (%d,%d,true)",
				c.note, track, scene, ok, c.track, c.scene)
		}
	}
}

func TestNoteToCell_OutOfGrid(t *testing.T) {
	if _, _, ok := noteToCell(64); ok {
		t.Error("note 64 should be outside the 8x8 grid")
	}
}

func TestCellToNote_RoundTrip(t *testing.T) {
	for note := uint8(0); note < 64; note++ {
		track, scene, ok := noteToCell(note)
		if !ok {
			t.Fatalf("noteToCell(%d) not ok", note)
		}
		back, ok := cellToNote(track, scene)
		if !ok || back != note {
			t.Errorf("roundtrip note %d → (%d,%d) → %d", note, track, scene, back)
		}
	}
}

func TestLedVelocity(t *testing.T) {
	if ledVelocity(pb.LedFeedbackCommand_LED_OFF) != 0 {
		t.Error("off should be 0")
	}
	if ledVelocity(pb.LedFeedbackCommand_LED_GREEN) != 1 {
		t.Error("green should be 1")
	}
	if ledVelocity(pb.LedFeedbackCommand_LED_RED) != 3 {
		t.Error("red should be 3")
	}
}
