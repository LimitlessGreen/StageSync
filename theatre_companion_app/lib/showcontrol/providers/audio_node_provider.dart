import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../nodes/audio_node/audio_device.dart';
import '../nodes/audio_node/audio_node_service.dart';
import '../nodes/audio_node/media_server.dart';

export '../nodes/audio_node/audio_device.dart';

final audioNodeProvider =
    StateNotifierProvider<AudioNodeNotifier, AudioNodeStatus>((ref) {
  return AudioNodeNotifier(ref);
});

class AudioNodeNotifier extends StateNotifier<AudioNodeStatus> {
  late final AudioNodeService _service;

  AudioNodeNotifier(Ref ref) : super(const AudioNodeStatus()) {
    _service = AudioNodeService(ref);
    _service.statusStream.listen((s) => state = s);
  }

  String? get mediaServerUrl => _service.mediaServerUrl;

  Future<void> startAudioNode() => _service.start();
  Future<void> stopAudioNode() => _service.stop();
  Future<void> selectDevice(AudioDevice device) => _service.switchDevice(device);
  Future<void> selectInterface(NetworkInterfaceInfo iface) => _service.switchInterface(iface);
  Future<void> resetToDefaultDevice() => _service.resetToDefaultDevice();
  Future<void> ensureEngineInitialized() => _service.ensureEngineInitialized();
  Future<void> playWavBytesLocally(String cueId, List<int> wavBytes) =>
      _service.playWavBytesLocally(cueId, wavBytes);
  Future<void> stopLocalPlayback(String cueId) => _service.stopLocalPlayback(cueId);
  Future<void> stopAllLocalPlayback() => _service.stopAllLocalPlayback();

  Future<void> auditionPlay({
    required String assetId,
    required double volumeDb,
    double startMs = 0,
  }) => _service.auditionPlay(assetId: assetId, volumeDb: volumeDb, startMs: startMs);

  Future<void> auditionStop() => _service.auditionStop();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
