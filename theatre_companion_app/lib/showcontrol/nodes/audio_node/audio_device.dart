import 'package:meta/meta.dart';

/// Audio backend identifier — maps to miniaudio's ma_backend enum.
enum AudioBackend {
  wasapi,        // Windows — WASAPI (exclusive mode = low latency)
  asio,          // Windows — ASIO (requires driver, lowest latency)
  directSound,   // Windows — DirectSound (legacy fallback)
  coreAudio,     // macOS / iOS
  alsa,          // Linux
  pulseAudio,    // Linux
  jack,          // Linux / macOS (pro audio)
  aaudio,        // Android (API 26+, low latency)
  openSLES,      // Android (legacy fallback)
  unknown,
}

/// Platform-independent audio output device descriptor.
///
/// Replaces `flutter_soloud`'s `PlaybackDevice` throughout the codebase so
/// the audio interface is independent of any particular backend library.
@immutable
class AudioDevice {
  /// Opaque, platform-specific device identifier (hex-encoded bytes).
  /// Used internally by the miniaudio backend to select the device.
  final String id;

  /// Human-readable name as reported by the OS driver.
  final String name;

  /// The audio backend this device belongs to.
  final AudioBackend backend;

  /// Sequential enumeration index — only valid for the current enumeration.
  /// Used for proto-level communication (NodeCapabilities.AudioDeviceInfo.index).
  /// -1 = not known / system default.
  final int index;

  const AudioDevice({
    required this.id,
    required this.name,
    this.backend = AudioBackend.unknown,
    this.index = -1,
  });

  /// A sentinel representing the system default output device.
  static const AudioDevice systemDefault = AudioDevice(
    id: '',
    name: 'System Default',
    backend: AudioBackend.unknown,
  );

  bool get isSystemDefault => id.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is AudioDevice && other.id == id && other.backend == backend;

  AudioDevice copyWith({String? id, String? name, AudioBackend? backend, int? index}) =>
      AudioDevice(
        id:      id      ?? this.id,
        name:    name    ?? this.name,
        backend: backend ?? this.backend,
        index:   index   ?? this.index,
      );

  @override
  int get hashCode => Object.hash(id, backend);

  @override
  String toString() => 'AudioDevice(${backend.name}: $name)';
}
