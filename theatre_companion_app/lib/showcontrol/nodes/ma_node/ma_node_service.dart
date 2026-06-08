import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../grpc/stage_sync_client.dart';
import '../../grpc/generated/stagesync/v1/common.pb.dart';
import '../../grpc/generated/stagesync/v1/node.pb.dart';
import '../../grpc/generated/stagesync/v1/node.pbgrpc.dart';
import '../../providers/session_provider.dart';
import 'osc_bridge.dart';

enum MaNodeState { idle, connected, error }

class MaNodeStatus {
  final MaNodeState state;
  final String? errorMessage;
  final String? maHost;

  const MaNodeStatus({
    this.state = MaNodeState.idle,
    this.errorMessage,
    this.maHost,
  });

  MaNodeStatus copyWith(
          {MaNodeState? state, String? errorMessage, String? maHost}) =>
      MaNodeStatus(
        state: state ?? this.state,
        errorMessage: errorMessage,
        maHost: maHost ?? this.maHost,
      );
}

/// MANodeService verbindet sich als MA-Node, empfängt OSC-Commands vom Server
/// und leitet sie an eine GrandMA2/3 Konsole weiter.
class MaNodeService {
  final Ref _ref;
  final String maHost;
  final int maPort;

  late final OscBridge _bridge;
  StreamSubscription<NodeCommandRequest>? _commandSub;
  final _statusController = StreamController<MaNodeStatus>.broadcast();
  MaNodeStatus _status = const MaNodeStatus();

  MaNodeService(this._ref, {required this.maHost, this.maPort = 8000}) {
    _bridge = OscBridge(host: maHost, port: maPort);
  }

  Stream<MaNodeStatus> get statusStream => _statusController.stream;
  MaNodeStatus get status => _status;

  Future<void> start() async {
    final session = _ref.read(sessionProvider);
    if (!session.isInSession) return;

    try {
      await _bridge.connect();

      final client = StageSyncClient.instance;

      final caps = NodeCapabilities()
        ..ma = (MaCapabilities()
          ..grandmaAddress = maHost
          ..grandmaOscPort = maPort
          ..oscEnabled = true);

      final registerReq = RegisterNodeRequest()
        ..sessionId = session.session!.sessionId
        ..token = session.token!
        ..node = (NodeInfo()
          ..nodeId = session.myNode!.nodeId
          ..name = session.myNode!.name
          ..nodeType = NodeType.NODE_TYPE_MA
          ..tasks.addAll(session.myNode!.tasks)
          ..online = true)
        ..capabilities = caps;

      await client.node.registerNode(registerReq);

      final streamReq = StreamNodeCommandsRequest()
        ..sessionId = session.session!.sessionId
        ..nodeId = session.myNode!.nodeId
        ..token = session.token!;

      _commandSub = client.node.streamNodeCommands(streamReq).listen(
            _handleCommand,
            onError: (e) => _updateStatus(MaNodeStatus(
              state: MaNodeState.error,
              errorMessage: e.toString(),
            )),
            onDone: () =>
                _updateStatus(const MaNodeStatus(state: MaNodeState.idle)),
          );

      _updateStatus(
          _status.copyWith(state: MaNodeState.connected, maHost: maHost));
    } catch (e) {
      _updateStatus(MaNodeStatus(
        state: MaNodeState.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> stop() async {
    await _commandSub?.cancel();
    await _bridge.disconnect();
    _updateStatus(const MaNodeStatus(state: MaNodeState.idle));
  }

  void _handleCommand(NodeCommandRequest cmd) {
    switch (cmd.whichCommand()) {
      case NodeCommandRequest_Command.maOsc:
        _handleMaOsc(cmd.maOsc);
      default:
        break;
    }
  }

  void _handleMaOsc(MaOscCommand cmd) {
    if (cmd.oscAddress.isNotEmpty) {
      _bridge
          .sendRaw(address: cmd.oscAddress, argument: cmd.oscArgument)
          .ignore();
    }
  }

  void _updateStatus(MaNodeStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void dispose() {
    _commandSub?.cancel();
    _bridge.disconnect();
    _statusController.close();
  }
}
