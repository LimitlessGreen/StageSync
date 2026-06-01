import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../nodes/audio_node/audio_device.dart';
import '../nodes/audio_node/audio_node_service.dart';
import '../nodes/audio_node/media_server.dart';

export '../nodes/audio_node/audio_device.dart';

final audioNodeProvider =
    StateNotifierProvider<AudioNodeNotifier, AudioNodeStatus>((ref) {
  return AudioNodeNotifier(ref);
});

class AudioNodeNotifier extends StateNotifier<AudioNodeStatus> {
  AudioNodeService? _service;

  AudioNodeNotifier(Ref ref) : super(const AudioNodeStatus()) {
    _service = AudioNodeService(ref);
    _service!.statusStream.listen((s) => state = s);
  }

  /// Test-only constructor: no FFI, no AudioNodeService, idle state only.
  @visibleForTesting
  AudioNodeNotifier.forTest() : super(const AudioNodeStatus());

  String? get mediaServerUrl => _service?.mediaServerUrl;

  Future<void> startAudioNode() => _service?.start() ?? Future.value();
  Future<void> stopAudioNode() => _service?.stop() ?? Future.value();
  Future<void> selectDevice(AudioDevice device) => _service?.switchDevice(device) ?? Future.value();
  Future<void> selectInterface(NetworkInterfaceInfo iface) => _service?.switchInterface(iface) ?? Future.value();
  Future<void> resetToDefaultDevice() => _service?.resetToDefaultDevice() ?? Future.value();
  Future<void> ensureEngineInitialized() => _service?.ensureEngineInitialized() ?? Future.value();
  Future<void> playWavBytesLocally(String cueId, List<int> wavBytes) =>
      _service?.playWavBytesLocally(cueId, wavBytes) ?? Future.value();
  Future<void> stopLocalPlayback(String cueId) => _service?.stopLocalPlayback(cueId) ?? Future.value();
  Future<void> stopAllLocalPlayback() => _service?.stopAllLocalPlayback() ?? Future.value();

  Future<void> auditionPlay({
    required String assetId,
    required double volumeDb,
    double startMs = 0,
  }) => _service?.auditionPlay(assetId: assetId, volumeDb: volumeDb, startMs: startMs) ?? Future.value();

  Future<void> auditionStop() => _service?.auditionStop() ?? Future.value();

  /// Sets the master output volume in dB immediately.
  /// Affects all active handles; safe to call while cues are playing.
  void setMasterVolume(double db) {
    _service?.setMasterVolume(db);
    state = state.copyWith(masterVolumeDb: db);
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}
