import 'audio_device.dart';

export 'audio_device.dart';

/// Platform-independent audio engine interface.
///
/// Implementations:
/// - [MiniaudioEngine] — miniaudio via dart:ffi (recommended: ASIO/WASAPI
///   exclusive, CoreAudio, AAudio; reliable device selection, low latency)
/// - [SoLoudAudioEngine] — legacy SoLoud wrapper (kept for fallback/migration)
/// - In tests: `FakeAudioEngine extends Fake implements AbstractAudioEngine`
abstract class AbstractAudioEngine {
  // ── State ─────────────────────────────────────────────────────────────────

  bool get isInitialized;

  /// Currently active output device, null = system default.
  AudioDevice? get selectedDevice;

  /// All cue IDs with an active (playing or preloaded) handle.
  List<String> get activeCueIds;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Initialises the engine on [device]. Falls back to system default if
  /// [device] is null or cannot be opened.
  Future<void> init({AudioDevice? device});

  /// Stops all playback and releases native resources.
  Future<void> deinit();

  /// Switches to [device] without restarting the session.
  ///
  /// A miniaudio-based implementation can do this without audible interruption
  /// to handles that are already loaded. Returns the device that was actually
  /// activated (may differ if [device] is unavailable).
  Future<AudioDevice?> switchDevice(AudioDevice device);

  /// Returns all available output devices on this machine, grouped by backend.
  Future<List<AudioDevice>> listDevices();

  // ── Playback ──────────────────────────────────────────────────────────────

  /// Pre-decodes [filePath] into memory under [cueId]. Fast-path for [playAt].
  Future<void> preload(String cueId, String filePath);

  /// Plays [cueId].
  ///
  /// If [startUnixMillis] > 0 the engine schedules playback at that server
  /// timestamp (clock-sync). If the timestamp is already in the past the
  /// engine seeks to the correct position so the timeline stays aligned.
  Future<void> playAt({
    required String cueId,
    required String filePath,
    required int startUnixMillis,
    double volumeDb = 0.0,
    double fadeInMs = 0.0,
    double fadeOutMs = 0.0,
    bool loop = false,
    double startTimeMs = 0.0,
    double endTimeMs = 0.0,
  });

  /// Plays raw WAV bytes (used for test signals and audition).
  Future<void> playWavBytes(String cueId, List<int> wavBytes,
      {double volumeDb = 0.0});

  /// Stops [cueId], optionally with a fade-out.
  Future<void> stop(String cueId, {double fadeOutMs = 0.0});

  /// Stops all active cues (panic/emergency stop).
  Future<void> stopAll({double fadeOutMs = 0.0});

  /// Pauses [cueId] (playhead stays at current position).
  Future<void> pause(String cueId, {double fadeOutMs = 0.0});

  /// Resumes a paused cue.
  Future<void> resume(String cueId, {double fadeInMs = 0.0});

  /// Releases all preloaded handles without deinitialising the engine.
  Future<void> disposeAll();
}
