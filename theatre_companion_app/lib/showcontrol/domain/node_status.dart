import 'package:meta/meta.dart';

enum NodeHealthPhase { online, reconnecting, offline, degraded }

/// Audition/preview capability of a node.
///
/// This is a NODE-LOCAL capability — not part of the authoritative show state.
/// The server never writes or modifies this; the node self-reports it on
/// [RegisterNode].
@immutable
class AuditionCapability {
  final bool supported;
  final String? deviceName;  // e.g. "Headphones", "Kopfhörer"
  final int? deviceIndex;

  const AuditionCapability({
    required this.supported,
    this.deviceName,
    this.deviceIndex,
  });

  static const AuditionCapability none =
      AuditionCapability(supported: false);
}

@immutable
class NodeStatus {
  final String nodeId;
  final String name;

  /// String task codes: 'master', 'audio', 'editor', 'viewer', 'ma_osc'.
  final List<String> tasks;

  final NodeHealthPhase health;

  /// Measured offset in ms against the server clock (from heartbeat NTP-style).
  final int? clockDeltaMs;

  final AuditionCapability audition;

  const NodeStatus({
    required this.nodeId,
    required this.name,
    required this.tasks,
    required this.health,
    this.clockDeltaMs,
    this.audition = AuditionCapability.none,
  });

  bool get isOnline   => health == NodeHealthPhase.online ||
                         health == NodeHealthPhase.degraded;
  bool get isAudio    => tasks.contains('audio');
  bool get isMaNode   => tasks.contains('ma_osc');
  bool get isMaster   => tasks.contains('master');
  bool get isEditor   => tasks.contains('editor');

  NodeStatus copyWith({
    String? nodeId,
    String? name,
    List<String>? tasks,
    NodeHealthPhase? health,
    int? clockDeltaMs,
    AuditionCapability? audition,
  }) =>
      NodeStatus(
        nodeId: nodeId ?? this.nodeId,
        name: name ?? this.name,
        tasks: tasks ?? this.tasks,
        health: health ?? this.health,
        clockDeltaMs: clockDeltaMs ?? this.clockDeltaMs,
        audition: audition ?? this.audition,
      );
}
