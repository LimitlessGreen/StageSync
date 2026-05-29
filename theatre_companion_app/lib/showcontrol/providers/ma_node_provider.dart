import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../nodes/ma_node/ma_node_service.dart';

final maNodeProvider =
    StateNotifierProvider<MaNodeNotifier, MaNodeStatus>((ref) {
  return MaNodeNotifier(ref);
});

class MaNodeNotifier extends StateNotifier<MaNodeStatus> {
  MaNodeService? _service;
  final Ref _ref;

  MaNodeNotifier(this._ref) : super(const MaNodeStatus());

  Future<void> startMaNode({required String maHost, int maPort = 8000}) async {
    _service?.dispose();
    _service = MaNodeService(_ref, maHost: maHost, maPort: maPort);
    _service!.statusStream.listen((s) => state = s);
    await _service!.start();
  }

  Future<void> stopMaNode() async {
    await _service?.stop();
    _service = null;
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}
