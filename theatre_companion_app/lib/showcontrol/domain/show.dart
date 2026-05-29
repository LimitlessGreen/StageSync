import 'package:meta/meta.dart';
import 'cue_params.dart';
import 'cue_trigger.dart';

enum CueListPlayMode { sequential, follow, manual }

@immutable
class CueTiming {
  final double preWaitMs;
  final double postWaitMs;
  final bool autoContinue;
  final double? durationMs;

  const CueTiming({
    this.preWaitMs = 0.0,
    this.postWaitMs = 0.0,
    this.autoContinue = false,
    this.durationMs,
  });

  CueTiming copyWith({
    double? preWaitMs,
    double? postWaitMs,
    bool? autoContinue,
    double? durationMs,
  }) =>
      CueTiming(
        preWaitMs: preWaitMs ?? this.preWaitMs,
        postWaitMs: postWaitMs ?? this.postWaitMs,
        autoContinue: autoContinue ?? this.autoContinue,
        durationMs: durationMs ?? this.durationMs,
      );
}

@immutable
class Cue {
  final String id;
  final String number; // display number: "1", "1.5", "2A"
  final String label;
  final CueParams params;
  final CueTrigger trigger;
  final CueTiming timing;

  /// References a [LogicalOutput.id] in [PatchConfig].
  /// MIGRATION NOTE: currently mapped from proto `targetNodeId` until the server
  /// supports proper logical output IDs (Phase 2 proto extension).
  final String? logicalOutputId;

  final bool armed;

  const Cue({
    required this.id,
    required this.number,
    required this.label,
    required this.params,
    this.trigger = const CueTrigger(),
    this.timing = const CueTiming(),
    this.logicalOutputId,
    this.armed = false,
  });

  Cue copyWith({
    String? id,
    String? number,
    String? label,
    CueParams? params,
    CueTrigger? trigger,
    CueTiming? timing,
    String? logicalOutputId,
    bool? armed,
  }) =>
      Cue(
        id: id ?? this.id,
        number: number ?? this.number,
        label: label ?? this.label,
        params: params ?? this.params,
        trigger: trigger ?? this.trigger,
        timing: timing ?? this.timing,
        logicalOutputId: logicalOutputId ?? this.logicalOutputId,
        armed: armed ?? this.armed,
      );

  /// Derived display duration in ms (from params).
  double? get displayDurationMs => switch (params) {
        AudioParams p => p.effectiveDurationMs,
        WaitParams p  => p.durationMs,
        _             => null,
      };
}

@immutable
class CueList {
  final String id;
  final String name;
  final CueListPlayMode playMode;
  final List<Cue> cues;

  const CueList({
    required this.id,
    required this.name,
    this.playMode = CueListPlayMode.sequential,
    required this.cues,
  });

  CueList copyWith({
    String? id,
    String? name,
    CueListPlayMode? playMode,
    List<Cue>? cues,
  }) =>
      CueList(
        id: id ?? this.id,
        name: name ?? this.name,
        playMode: playMode ?? this.playMode,
        cues: cues ?? this.cues,
      );

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
