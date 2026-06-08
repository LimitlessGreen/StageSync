import 'package:freezed_annotation/freezed_annotation.dart';
import 'cue_params.dart';
import 'cue_trigger.dart';

part 'show.freezed.dart';

enum CueListPlayMode { sequential, follow, manual }

@freezed
class CueTiming with _$CueTiming {
  const factory CueTiming({
    @Default(0.0) double preWaitMs,
    @Default(0.0) double postWaitMs,
    @Default(false) bool autoContinue,
    double? durationMs,
  }) = _CueTiming;
}

@freezed
class Cue with _$Cue {
  const Cue._();

  const factory Cue({
    required String id,
    required String number, // display number: "1", "1.5", "2A"
    required String label,
    required CueParams params,
    @Default(CueTrigger()) CueTrigger trigger,
    @Default(CueTiming()) CueTiming timing,
    String? logicalOutputId,
    @Default(false) bool armed,
  }) = _Cue;

  /// Derived display duration in ms (from params).
  double? get displayDurationMs => switch (params) {
        AudioParams p => p.effectiveDurationMs ?? p.declaredDurationMs,
        WaitParams p => p.durationMs,
        FadeParams p => p.durationMs,
        _ => null,
      };
}

@freezed
class CueList with _$CueList {
  const CueList._();

  const factory CueList({
    required String id,
    required String name,
    @Default(CueListPlayMode.sequential) CueListPlayMode playMode,
    required List<Cue> cues,
  }) = _CueList;

  Cue? cueById(String id) {
    for (final c in cues) {
      if (c.id == id) return c;
    }
    return null;
  }

  Cue? cueAfter(String cueId) {
    final idx = cues.indexWhere((c) => c.id == cueId);
    if (idx < 0 || idx >= cues.length - 1) return null;
    return cues[idx + 1];
  }
}
