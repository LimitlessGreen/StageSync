import 'package:flutter/material.dart' show Color;
import 'package:meta/meta.dart';

/// Sealed hierarchy of cue-type-specific parameters.
/// Every subtype is immutable.
/// Add new cue types by adding a new [final class] — existing code remains unchanged.
sealed class CueParams {
  const CueParams();
}

// ── Audio Pause / Resume behavior enums ──────────────────────────────────────

enum PauseBehavior {
  hard,     // sofort stoppen (default)
  fadeOut,  // ausblenden, dann pausieren
}

enum ResumeBehavior {
  continuePlaying, // nahtlos weitermachen (default)
  fadeIn,          // einblenden beim Weiterspielen
  fromStart,       // von vorne beginnen
}

@immutable
final class AudioParams extends CueParams {
  /// Content-addressable asset ID (SHA-256 of the audio file).
  final String assetId;
  final double volumeDb;
  final double fadeInMs;
  final double fadeOutMs;
  final bool loop;
  final double startTimeMs;
  final double endTimeMs;

  /// Total playback duration from asset file header metadata (ms).
  final double? declaredDurationMs;

  // ── Pause / Resume ──────────────────────────────────────────────────────
  final PauseBehavior pauseBehavior;
  final double pauseFadeMs;     // Fade-Dauer bei pauseBehavior.fadeOut
  final ResumeBehavior resumeBehavior;
  final double resumeFadeMs;    // Fade-Dauer bei resumeBehavior.fadeIn

  /// Stille am Anfang der Aufnahme automatisch überspringen.
  ///
  /// Wenn true und [startTimeMs] == 0: der Server erkennt beim Preload den
  /// ersten nicht-stillen Frame und setzt ihn als effektive Startzeit. Der
  /// Operator sieht den erkannten Offset in der Cue-Anzeige.
  /// Wenn [startTimeMs] > 0: manueller Offset hat Vorrang vor der Erkennung.
  final bool autoSkipSilence;

  const AudioParams({
    required this.assetId,
    this.volumeDb = 0.0,
    this.fadeInMs = 0.0,
    this.fadeOutMs = 0.0,
    this.loop = false,
    this.startTimeMs = 0.0,
    this.endTimeMs = 0.0,
    this.declaredDurationMs,
    this.pauseBehavior = PauseBehavior.hard,
    this.pauseFadeMs = 1000.0,
    this.resumeBehavior = ResumeBehavior.continuePlaying,
    this.resumeFadeMs = 500.0,
    this.autoSkipSilence = false,
  });

  AudioParams copyWith({
    String? assetId,
    double? volumeDb,
    double? fadeInMs,
    double? fadeOutMs,
    bool? loop,
    double? startTimeMs,
    double? endTimeMs,
    double? declaredDurationMs,
    PauseBehavior? pauseBehavior,
    double? pauseFadeMs,
    ResumeBehavior? resumeBehavior,
    double? resumeFadeMs,
    bool? autoSkipSilence,
  }) =>
      AudioParams(
        assetId: assetId ?? this.assetId,
        volumeDb: volumeDb ?? this.volumeDb,
        fadeInMs: fadeInMs ?? this.fadeInMs,
        fadeOutMs: fadeOutMs ?? this.fadeOutMs,
        loop: loop ?? this.loop,
        startTimeMs: startTimeMs ?? this.startTimeMs,
        endTimeMs: endTimeMs ?? this.endTimeMs,
        declaredDurationMs: declaredDurationMs ?? this.declaredDurationMs,
        pauseBehavior: pauseBehavior ?? this.pauseBehavior,
        pauseFadeMs: pauseFadeMs ?? this.pauseFadeMs,
        resumeBehavior: resumeBehavior ?? this.resumeBehavior,
        resumeFadeMs: resumeFadeMs ?? this.resumeFadeMs,
        autoSkipSilence: autoSkipSilence ?? this.autoSkipSilence,
      );

  double? get effectiveDurationMs {
    if (endTimeMs > startTimeMs && endTimeMs > 0) return endTimeMs - startTimeMs;
    return null;
  }
}

@immutable
final class WaitParams extends CueParams {
  final double durationMs;
  const WaitParams({required this.durationMs});

  WaitParams copyWith({double? durationMs}) =>
      WaitParams(durationMs: durationMs ?? this.durationMs);
}

@immutable
final class GroupParams extends CueParams {
  final List<String> childCueIds;
  final bool sequential; // false = parallel execution

  const GroupParams({
    required this.childCueIds,
    this.sequential = true,
  });

  GroupParams copyWith({
    List<String>? childCueIds,
    bool? sequential,
  }) =>
      GroupParams(
        childCueIds: childCueIds ?? this.childCueIds,
        sequential: sequential ?? this.sequential,
      );
}

enum MaOscCommand { unspecified, go, off, pause, gotoP }

@immutable
final class MaOscParams extends CueParams {
  final String oscAddress;
  final String oscArgument;
  final int executorPage;
  final int executorNo;
  final MaOscCommand command;
  final double gotoCue;

  const MaOscParams({
    required this.oscAddress,
    this.oscArgument = '',
    this.executorPage = 0,
    this.executorNo = 0,
    this.command = MaOscCommand.unspecified,
    this.gotoCue = 0,
  });

  MaOscParams copyWith({
    String? oscAddress,
    String? oscArgument,
    int? executorPage,
    int? executorNo,
    MaOscCommand? command,
    double? gotoCue,
  }) =>
      MaOscParams(
        oscAddress: oscAddress ?? this.oscAddress,
        oscArgument: oscArgument ?? this.oscArgument,
        executorPage: executorPage ?? this.executorPage,
        executorNo: executorNo ?? this.executorNo,
        command: command ?? this.command,
        gotoCue: gotoCue ?? this.gotoCue,
      );
}

@immutable
final class GotoParams extends CueParams {
  final String targetCueId;
  final String targetNumber;

  const GotoParams({
    required this.targetCueId,
    this.targetNumber = '',
  });

  GotoParams copyWith({
    String? targetCueId,
    String? targetNumber,
  }) =>
      GotoParams(
        targetCueId: targetCueId ?? this.targetCueId,
        targetNumber: targetNumber ?? this.targetNumber,
      );
}

@immutable
final class OscParams extends CueParams {
  final String address;
  final List<String> args;

  const OscParams({required this.address, this.args = const []});
}

@immutable
final class MidiParams extends CueParams {
  final int channel;
  final int command;
  final int data1;
  final int data2;

  const MidiParams({
    required this.channel,
    required this.command,
    this.data1 = 0,
    this.data2 = 0,
  });
}

@immutable
final class ScriptParams extends CueParams {
  final String script;
  const ScriptParams({required this.script});
}

// ── Note / Placeholder cue ────────────────────────────────────────────────────

/// Textmarker oder Trennlinie in der CueList — kein Execution.
/// Hilft bei der Übersicht, besonders auf mobilen Geräten.
@immutable
final class NoteParams extends CueParams {
  final String text;
  final Color? color; // null = Standard-Grau

  const NoteParams({this.text = '', this.color});

  NoteParams copyWith({String? text, Color? color}) =>
      NoteParams(text: text ?? this.text, color: color ?? this.color);
}

// ── Fade / Control cue ────────────────────────────────────────────────────────

enum FadeAction {
  volume,  // nur Lautstärke anpassen
  stop,    // mit Fade stoppen
  pause,   // mit Fade pausieren
  resume,  // mit Fade-In fortsetzen
}

/// Steuert eine andere laufende Cue (entspricht QLab Fade-Cue).
@immutable
final class FadeParams extends CueParams {
  final String targetCueId;
  final String targetCueNumber; // Anzeigenummer als Referenz
  final FadeAction action;
  final double targetVolumeDb;
  final double durationMs;
  final bool stopWhenDone;

  const FadeParams({
    this.targetCueId = '',
    this.targetCueNumber = '',
    this.action = FadeAction.volume,
    this.targetVolumeDb = 0.0,
    this.durationMs = 2000.0,
    this.stopWhenDone = false,
  });

  FadeParams copyWith({
    String? targetCueId,
    String? targetCueNumber,
    FadeAction? action,
    double? targetVolumeDb,
    double? durationMs,
    bool? stopWhenDone,
  }) =>
      FadeParams(
        targetCueId: targetCueId ?? this.targetCueId,
        targetCueNumber: targetCueNumber ?? this.targetCueNumber,
        action: action ?? this.action,
        targetVolumeDb: targetVolumeDb ?? this.targetVolumeDb,
        durationMs: durationMs ?? this.durationMs,
        stopWhenDone: stopWhenDone ?? this.stopWhenDone,
      );
}

