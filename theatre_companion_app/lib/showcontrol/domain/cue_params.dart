import 'package:meta/meta.dart';

/// Sealed hierarchy of cue-type-specific parameters.
/// Every subtype is immutable.
/// Add new cue types by adding a new [final class] — existing code remains unchanged.
sealed class CueParams {
  const CueParams();
}

@immutable
final class AudioParams extends CueParams {
  /// Content-addressable asset ID (SHA-256 of the audio file).
  /// Maps to proto field AudioCueParams.asset_id; server stores and returns
  /// the full SHA-256 hex string. Empty = asset not yet assigned.
  final String assetId;
  final double volumeDb;
  final double fadeInMs;
  final double fadeOutMs;
  final bool loop;
  final double startTimeMs;
  final double endTimeMs;

  /// Total playback duration from asset file header metadata (ms).
  /// null = not known (old cue or asset not yet resolved).
  final double? declaredDurationMs;

  const AudioParams({
    required this.assetId,
    this.volumeDb = 0.0,
    this.fadeInMs = 0.0,
    this.fadeOutMs = 0.0,
    this.loop = false,
    this.startTimeMs = 0.0,
    this.endTimeMs = 0.0,
    this.declaredDurationMs,
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
      );

  /// Duration in ms derived from startTimeMs/endTimeMs.
  double? get effectiveDurationMs {
    if (endTimeMs > startTimeMs && endTimeMs > 0) {
      return endTimeMs - startTimeMs;
    }
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

