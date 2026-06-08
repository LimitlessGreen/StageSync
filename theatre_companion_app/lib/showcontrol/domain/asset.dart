import 'package:meta/meta.dart';

/// 4-tier asset readiness — cumulative (each level requires all previous).
///
/// Responsibility:
///   [present] / [validated] / [renderable] → set by the **Node** locally
///     after download and codec check; reported via MediaSyncChanged event.
///   [patched] → computed by the **Server** (has full PatchConfig + NodeRegistry);
///     propagated in ShowDefinitionEvent snapshots to all clients.
enum AssetReadiness {
  /// SHA-256 file exists in the local cache directory.
  present,

  /// SHA-256 verified locally — file is not corrupted.
  validated,

  /// Engine codec-check passed: this node can decode and play the format.
  renderable,

  /// Cue references this asset AND it is assigned to a reachable patched output.
  patched,
}

@immutable
class AudioMetadata {
  final double declaredDurationMs; // from file header
  final int channelCount; // 1=mono, 2=stereo, 6=5.1, etc.
  final int sampleRateHz; // 44100, 48000, 96000, etc.

  /// Integrated loudness in LUFS (EBU R128).
  /// null = not yet measured; requires server-side ffprobe analysis on upload.
  final double? loudnessLufs;

  final String codec; // wav, flac, mp3, aac, ogg, m4a, aiff
  final int bitDepth; // 16, 24, 32

  const AudioMetadata({
    required this.declaredDurationMs,
    required this.channelCount,
    required this.sampleRateHz,
    this.loudnessLufs,
    required this.codec,
    required this.bitDepth,
  });

  String get channelLabel => switch (channelCount) {
        1 => 'Mono',
        2 => 'Stereo',
        6 => '5.1',
        8 => '7.1',
        _ => '$channelCount ch',
      };
}

@immutable
class Asset {
  /// Content-addressable ID = SHA-256 hex of the file content.
  /// Guarantees deduplication: same content → same ID, no re-upload needed.
  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;
  final DateTime uploadedAt;

  /// Null for non-audio assets (video, image, script, etc.)
  final AudioMetadata? audio;

  /// Current readiness on the querying node (or server-computed for [patched]).
  final AssetReadiness readiness;

  const Asset({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.uploadedAt,
    this.audio,
    this.readiness = AssetReadiness.present,
  });

  Asset copyWith({
    String? id,
    String? name,
    int? sizeBytes,
    String? mimeType,
    DateTime? uploadedAt,
    AudioMetadata? audio,
    AssetReadiness? readiness,
  }) =>
      Asset(
        id: id ?? this.id,
        name: name ?? this.name,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        mimeType: mimeType ?? this.mimeType,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        audio: audio ?? this.audio,
        readiness: readiness ?? this.readiness,
      );

  bool get isFullyReady => readiness == AssetReadiness.patched;

  String get readinessLabel => switch (readiness) {
        AssetReadiness.present => 'Vorhanden',
        AssetReadiness.validated => 'Verifiziert',
        AssetReadiness.renderable => 'Abspielbar',
        AssetReadiness.patched => 'Bereit',
      };
}
