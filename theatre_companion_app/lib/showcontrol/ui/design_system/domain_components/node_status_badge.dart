import 'package:flutter/material.dart';
import '../../../domain/node_status.dart';
import '../sc_typography.dart';
import '../primitives/sc_chip.dart';

/// Node status chip — knows [NodeStatus] and [AuditionCapability].
/// No gRPC/proto knowledge.
class NodeStatusBadge extends StatelessWidget {
  final NodeStatus node;
  final VoidCallback? onTap;

  const NodeStatusBadge({super.key, required this.node, this.onTap});

  ScChipState get _chipState => switch (node.health) {
        NodeHealthPhase.online      => ScChipState.ok,
        NodeHealthPhase.degraded    => ScChipState.warn,
        NodeHealthPhase.reconnecting => ScChipState.syncing,
        NodeHealthPhase.offline     => ScChipState.error,
      };

  String get _taskLabel {
    if (node.isMaster && node.isAudio) return 'MASTER+AUDIO';
    if (node.isMaster) return 'MASTER';
    if (node.isAudio)  return 'AUDIO';
    if (node.isMaNode) return 'MA';
    if (node.isEditor) return 'EDITOR';
    return 'NODE';
  }

  String get _tooltip {
    final buf = StringBuffer()
      ..writeln(node.name)
      ..writeln('Tasks: ${node.tasks.join(', ')}')
      ..writeln('Status: ${node.health.name}');
    if (node.clockDeltaMs != null) {
      buf.writeln('Clock Δ: ${node.clockDeltaMs}ms');
    }
    if (node.audition.supported) {
      buf.writeln('Audition: ${node.audition.deviceName ?? "yes"}');
    }
    return buf.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return ScChip(
      label: _taskLabel,
      state: _chipState,
      showExpandArrow: onTap != null,
      onTap: onTap,
      tooltip: _tooltip,
    );
  }
}

/// Horizontal strip of node status badges.
class NodeHealthStrip extends StatelessWidget {
  final List<NodeStatus> nodes;
  final ValueChanged<NodeStatus>? onNodeTap;

  const NodeHealthStrip({super.key, required this.nodes, this.onNodeTap});

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return Text('Keine Nodes verbunden', style: ScText.label);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: nodes
          .map((n) => NodeStatusBadge(
                node: n,
                onTap: onNodeTap != null ? () => onNodeTap!(n) : null,
              ))
          .toList(),
    );
  }
}
