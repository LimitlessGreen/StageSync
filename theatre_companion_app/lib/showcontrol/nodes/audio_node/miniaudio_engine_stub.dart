// Stub for web — dart:ffi not available.
import 'audio_device.dart';
import 'abstract_audio_engine.dart';

class MiniaudioEngine implements AbstractAudioEngine {
  @override
  bool get isInitialized => false;
  @override
  AudioDevice? get selectedDevice => null;
  @override
  List<String> get activeCueIds => [];
  @override
  double get masterVolumeDb => 0;
  @override
  void setMasterVolume(double db) {}
  @override
  Future<void> init({AudioDevice? device}) async {}
  @override
  Future<void> deinit() async {}
  @override
  Future<AudioDevice?> switchDevice(AudioDevice device) async => null;
  @override
  Future<List<AudioDevice>> listDevices() async => [];
  @override
  Future<void> preload(String cueId, String filePath) async {}
  @override
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
  }) async {}
  @override
  Future<void> playWavBytes(String cueId, List<int> wavBytes,
      {double volumeDb = 0.0}) async {}
  @override
  Future<void> stop(String cueId, {double fadeOutMs = 0.0}) async {}
  @override
  Future<void> stopAll({double fadeOutMs = 0.0}) async {}
  @override
  Future<void> pause(String cueId, {double fadeOutMs = 0.0}) async {}
  @override
  Future<void> resume(String cueId, {double fadeInMs = 0.0}) async {}
  @override
  Future<void> fadeVolume(
    String cueId, {
    required double targetLinear,
    required double durationMs,
    bool stopWhenDone = false,
    bool pauseWhenDone = false,
  }) async {}
  @override
  Future<void> disposeAll() async {}
  @override
  Future<({double startMs, double endMs})?> detectSilence(
    String filePath, {
    double thresholdDb = -60.0,
    double padMs = 50.0,
  }) async =>
      null;
}
