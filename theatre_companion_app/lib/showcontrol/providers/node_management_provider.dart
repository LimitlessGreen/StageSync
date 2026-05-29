import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/node.pb.dart';
import 'session_provider.dart';

const _uuid = Uuid();

// ── State ─────────────────────────────────────────────────────────────────────

class NodeManagementState {
  final bool isSending;
  final String? error;
  final String? lastAction;

  const NodeManagementState({
    this.isSending = false,
    this.error,
    this.lastAction,
  });

  NodeManagementState copyWith({
    bool? isSending,
    String? error,
    String? lastAction,
    bool clearError = false,
  }) =>
      NodeManagementState(
        isSending: isSending ?? this.isSending,
        error: clearError ? null : (error ?? this.error),
        lastAction: lastAction ?? this.lastAction,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final nodeManagementProvider =
    StateNotifierProvider<NodeManagementNotifier, NodeManagementState>((ref) {
  return NodeManagementNotifier(ref);
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class NodeManagementNotifier extends StateNotifier<NodeManagementState> {
  final Ref _ref;

  NodeManagementNotifier(this._ref) : super(const NodeManagementState());

  SessionState get _session => _ref.read(sessionProvider);

  /// Setzt das Audio-Ausgabegerät auf einem remote Node.
  Future<void> setAudioDevice({
    required String targetNodeId,
    required int deviceIndex,
    required String deviceName,
  }) => _sendConfig(
        targetNodeId: targetNodeId,
        config: NodeConfigCommand()
          ..audioDeviceIndex = deviceIndex
          ..audioDeviceName = deviceName,
        actionLabel: 'Gerät "$deviceName" auf ${_shortId(targetNodeId)} gesetzt',
      );

  /// Setzt das Netzwerk-Interface auf einem remote Node.
  Future<void> setNetworkInterface({
    required String targetNodeId,
    required String interfaceAddress,
  }) => _sendConfig(
        targetNodeId: targetNodeId,
        config: NodeConfigCommand()..networkInterfaceAddress = interfaceAddress,
        actionLabel: 'Interface $interfaceAddress auf ${_shortId(targetNodeId)} gesetzt',
      );

  /// Setzt das Gerät auf System-Default zurück.
  Future<void> resetToDefault({required String targetNodeId}) => _sendConfig(
        targetNodeId: targetNodeId,
        config: NodeConfigCommand()..audioDeviceIndex = -1,
        actionLabel: 'System-Default auf ${_shortId(targetNodeId)} gesetzt',
      );

  /// Sendet ein Test-Signal an einen Node.
  Future<void> sendTestTone({
    required String targetNodeId,
    double frequencyHz = 1000,
    double durationMs = 1000,
    double amplitude = 0.5,
  }) async {
    await _sendNodeCommand(
      targetNodeId: targetNodeId,
      command: NodeCommandRequest()
        ..sessionId = _session.session!.sessionId
        ..commandId = _uuid.v4()
        ..targetNodeId = targetNodeId
        ..audioTest = (AudioTestSignalCommand()
          ..cueId = 'test_${targetNodeId.substring(0, 6)}'
          ..kind = AudioTestSignalCommand_Kind.KIND_TONE
          ..frequencyHz = frequencyHz
          ..durationMs = durationMs
          ..amplitude = amplitude),
      actionLabel: 'Test-Ton an ${_shortId(targetNodeId)}',
    );
  }

  Future<void> sendTestSweep({
    required String targetNodeId,
    double durationMs = 3000,
    double amplitude = 0.5,
  }) async {
    await _sendNodeCommand(
      targetNodeId: targetNodeId,
      command: NodeCommandRequest()
        ..sessionId = _session.session!.sessionId
        ..commandId = _uuid.v4()
        ..targetNodeId = targetNodeId
        ..audioTest = (AudioTestSignalCommand()
          ..cueId = 'sweep_${targetNodeId.substring(0, 6)}'
          ..kind = AudioTestSignalCommand_Kind.KIND_SWEEP
          ..startHz = 20
          ..endHz = 20000
          ..durationMs = durationMs
          ..amplitude = amplitude),
      actionLabel: 'Sweep an ${_shortId(targetNodeId)}',
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _sendConfig({
    required String targetNodeId,
    required NodeConfigCommand config,
    required String actionLabel,
  }) async {
    await _sendNodeCommand(
      targetNodeId: targetNodeId,
      command: NodeCommandRequest()
        ..sessionId = _session.session!.sessionId
        ..commandId = _uuid.v4()
        ..targetNodeId = targetNodeId
        ..nodeConfig = config,
      actionLabel: actionLabel,
    );
  }

  Future<void> _sendNodeCommand({
    required String targetNodeId,
    required NodeCommandRequest command,
    required String actionLabel,
  }) async {
    if (!_session.isInSession) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final req = SendNodeCommandRequest()
        ..sessionId = _session.session!.sessionId
        ..token = _session.token!
        ..targetNodeId = targetNodeId
        ..command = command;
      await StageSyncClient.instance.node.sendNodeCommand(req);
      state = state.copyWith(isSending: false, lastAction: actionLabel);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: '$actionLabel fehlgeschlagen: $e',
      );
    }
  }

  static String _shortId(String id) =>
      id.length > 8 ? id.substring(0, 8) : id;
}
