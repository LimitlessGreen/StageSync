package midinode

import (
	"errors"

	pb "stagesync-server/gen/go/stagesync/v1"
)

var errNoPorts = errors.New("keine MIDI-Ports gefunden")

// APC Mini (MK1) Pad-Layout:
//
//	Das 8×8-Grid sendet Note-On auf Kanal 0 mit Noten 0..63. Note 0 liegt
//	UNTEN LINKS, Note 56 oben links. Innerhalb einer Reihe steigt die Note
//	von links nach rechts. Also: note = col + row*8, wobei row 0 = unterste Reihe.
//
//	Ableton-/StageSync-Konvention: scene_index 0 = OBERSTE Reihe. Daher
//	scene = 7 - (note/8), track = note % 8.
const apcGridSize = 8

// noteToCell wandelt eine APC-Pad-Note in (track, scene). Liefert ok=false für
// Noten außerhalb des 8×8-Grids (z.B. die seitlichen Scene-/Track-Tasten).
func noteToCell(note uint8) (track, scene int32, ok bool) {
	if note >= apcGridSize*apcGridSize {
		return 0, 0, false
	}
	col := int32(note % apcGridSize)
	row := int32(note / apcGridSize)
	return col, (apcGridSize - 1) - row, true
}

// cellToNote ist die Umkehrung — für LED-Feedback an ein Pad.
func cellToNote(track, scene int32) (uint8, bool) {
	if track < 0 || track >= apcGridSize || scene < 0 || scene >= apcGridSize {
		return 0, false
	}
	row := (apcGridSize - 1) - scene
	return uint8(row*apcGridSize + track), true
}

// ledVelocity übersetzt eine LedFeedbackCommand-Farbe in den APC-Mini-Velocity-
// Code. Die Codes sind identisch zur Proto-Enum-Reihenfolge:
//
//	0=off, 1=green, 2=green-blink, 3=red, 4=red-blink, 5=yellow, 6=yellow-blink
func ledVelocity(color pb.LedFeedbackCommand_Color) uint8 {
	switch color {
	case pb.LedFeedbackCommand_LED_GREEN:
		return 1
	case pb.LedFeedbackCommand_LED_GREEN_BLINK:
		return 2
	case pb.LedFeedbackCommand_LED_RED:
		return 3
	case pb.LedFeedbackCommand_LED_RED_BLINK:
		return 4
	case pb.LedFeedbackCommand_LED_YELLOW:
		return 5
	case pb.LedFeedbackCommand_LED_YELLOW_BLINK:
		return 6
	default:
		return 0
	}
}
