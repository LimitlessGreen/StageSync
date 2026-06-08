import 'package:meta/meta.dart';

enum TriggerType {
  manual,
  follow, // Auto-start after previous cue completes
  timecode,
  osc,
  midi,
}

@immutable
class CueTrigger {
  final TriggerType type;

  /// Context-dependent value:
  /// - [TriggerType.timecode] → "HH:MM:SS:FF"
  /// - [TriggerType.osc]      → OSC address pattern
  /// - [TriggerType.midi]     → MIDI note/CC pattern
  final String? value;

  const CueTrigger({
    this.type = TriggerType.manual,
    this.value,
  });

  CueTrigger copyWith({TriggerType? type, String? value}) =>
      CueTrigger(type: type ?? this.type, value: value ?? this.value);
}
