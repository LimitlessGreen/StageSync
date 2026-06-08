import 'package:flutter/material.dart';
import '../../../domain/patch_config.dart';
import '../../../domain/node_status.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';
import '../sc_spacing.dart';
import '../primitives/sc_chip.dart';

/// Desktop-only patch matrix with three tabs:
/// 1. Cue-Bus Assignment (logical outputs → nodes)
/// 2. Node Patch (bus → node assignment)
/// 3. Device Patch (node-local physical device assignment)
///
/// Knows [PatchConfig] and [NodeStatus] — no gRPC/proto.
class PatchMatrix extends StatefulWidget {
  final PatchConfig config;
  final List<NodeStatus> nodes;
  final ValueChanged<PatchConfig>? onChanged;

  const PatchMatrix({
    super.key,
    required this.config,
    required this.nodes,
    this.onChanged,
  });

  @override
  State<PatchMatrix> createState() => _PatchMatrixState();
}

class _PatchMatrixState extends State<PatchMatrix>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: ScColors.surface,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            indicatorColor: ScColors.active,
            labelColor: ScColors.active,
            unselectedLabelColor: ScColors.textDim,
            labelStyle: ScText.labelBold,
            unselectedLabelStyle: ScText.label,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'CUE-BUS'),
              Tab(text: 'NODE-PATCH'),
              Tab(text: 'DEVICE-PATCH'),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _CueBusTab(config: widget.config, nodes: widget.nodes),
              _NodePatchTab(
                  config: widget.config,
                  nodes: widget.nodes,
                  onChanged: widget.onChanged),
              _DevicePatchTab(config: widget.config, nodes: widget.nodes),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab 1: Cue-Bus Assignment ─────────────────────────────────────────────────

class _CueBusTab extends StatelessWidget {
  final PatchConfig config;
  final List<NodeStatus> nodes;

  const _CueBusTab({required this.config, required this.nodes});

  @override
  Widget build(BuildContext context) {
    if (config.logicalOutputs.isEmpty) {
      return _EmptyState(
        message: 'Keine logischen Ausgänge definiert.',
        hint: 'Füge Ausgänge im Node-Patch-Tab hinzu.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(ScSpacing.panelPad),
      children: config.logicalOutputs.map((output) {
        final assignedNodes = config.nodesForOutput(output.id);
        final hasConflict = config.hasConflict(output.id);

        return _MatrixRow(
          label: output.name,
          hasConflict: hasConflict,
          trailing: assignedNodes.isEmpty
              ? Text('— kein Node',
                  style: ScText.label.copyWith(color: ScColors.textDim))
              : Wrap(
                  spacing: 4,
                  children: assignedNodes.map((nid) {
                    final node =
                        nodes.where((n) => n.nodeId == nid).firstOrNull;
                    return ScChip(
                      label: node?.name ?? nid,
                      state: node == null
                          ? ScChipState.error
                          : _nodeChipState(node.health),
                    );
                  }).toList(),
                ),
        );
      }).toList(),
    );
  }
}

// ── Tab 2: Node Patch ─────────────────────────────────────────────────────────

class _NodePatchTab extends StatelessWidget {
  final PatchConfig config;
  final List<NodeStatus> nodes;
  final ValueChanged<PatchConfig>? onChanged;

  const _NodePatchTab({
    required this.config,
    required this.nodes,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const _EmptyState(
        message: 'Keine Nodes verbunden.',
        hint:
            'Verbinde mindestens einen Audio-Node um Routing zu konfigurieren.',
      );
    }

    // Grid: rows = logical outputs, columns = nodes
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ScSpacing.panelPad),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {
          0: const FixedColumnWidth(160),
          for (var i = 0; i < nodes.length; i++)
            i + 1: const FixedColumnWidth(80),
        },
        children: [
          // Header row
          TableRow(
            decoration: const BoxDecoration(color: ScColors.surface),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('AUSGANG', style: ScText.panelTitle),
              ),
              ...nodes.map((n) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(n.name,
                        style: ScText.label, overflow: TextOverflow.ellipsis),
                  )),
            ],
          ),
          // Output rows
          ...config.logicalOutputs.map((output) {
            final assignedNodeIds = config.nodesForOutput(output.id).toSet();
            return TableRow(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(output.name, style: ScText.label),
                ),
                ...nodes.map((node) {
                  final isAssigned = assignedNodeIds.contains(node.nodeId);
                  return _PatchCell(
                    isAssigned: isAssigned,
                    onTap: onChanged == null
                        ? null
                        : () =>
                            _togglePatch(output.id, node.nodeId, isAssigned),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _togglePatch(String outputId, String nodeId, bool wasAssigned) {
    if (onChanged == null) return;
    final patches = List<NodePatch>.from(config.nodePatches);
    final idx = patches.indexWhere((p) => p.logicalOutputId == outputId);
    if (idx < 0) {
      patches.add(NodePatch(logicalOutputId: outputId, nodeIds: [nodeId]));
    } else {
      final existing = patches[idx];
      final ids = List<String>.from(existing.nodeIds);
      wasAssigned ? ids.remove(nodeId) : ids.add(nodeId);
      patches[idx] = NodePatch(logicalOutputId: outputId, nodeIds: ids);
    }
    onChanged!(config.copyWith(nodePatches: patches));
  }
}

class _PatchCell extends StatelessWidget {
  final bool isAssigned;
  final VoidCallback? onTap;

  const _PatchCell({required this.isAssigned, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isAssigned ? ScColors.active : Colors.transparent,
            border: Border.all(
              color: isAssigned ? ScColors.active : ScColors.textDim,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: isAssigned
              ? const Icon(Icons.check, size: 14, color: ScColors.bg)
              : null,
        ),
      ),
    );
  }
}

// ── Tab 3: Device Patch ───────────────────────────────────────────────────────

class _DevicePatchTab extends StatelessWidget {
  final PatchConfig config;
  final List<NodeStatus> nodes;

  const _DevicePatchTab({required this.config, required this.nodes});

  @override
  Widget build(BuildContext context) {
    if (config.devicePatches.isEmpty) {
      return const _EmptyState(
        message: 'Keine Device-Patches konfiguriert.',
        hint:
            'Device-Patches werden automatisch gemeldet wenn ein Audio-Node connected.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(ScSpacing.panelPad),
      children: config.devicePatches.map((dp) {
        final output = config.logicalOutputs
            .where((o) => o.id == dp.logicalOutputId)
            .firstOrNull;
        final node = nodes.where((n) => n.nodeId == dp.nodeId).firstOrNull;

        return _MatrixRow(
          label: output?.name ?? dp.logicalOutputId,
          hasConflict: false,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScChip(
                label: node?.name ?? dp.nodeId,
                state: node == null ? ScChipState.error : ScChipState.ok,
              ),
              const SizedBox(width: 8),
              Text('→  ${dp.deviceName}', style: ScText.label),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _MatrixRow extends StatelessWidget {
  final String label;
  final bool hasConflict;
  final Widget trailing;

  const _MatrixRow({
    required this.label,
    required this.hasConflict,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ScSpacing.rowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ScColors.divider),
          left: hasConflict
              ? const BorderSide(color: ScColors.error, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.only(
        left: hasConflict ? ScSpacing.panelPad - 3 : ScSpacing.panelPad,
        right: ScSpacing.panelPad,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: ScText.label, overflow: TextOverflow.ellipsis),
          ),
          if (hasConflict) ...[
            const Icon(Icons.warning_amber_rounded,
                size: 14, color: ScColors.error),
            const SizedBox(width: 6),
          ],
          Expanded(child: trailing),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String hint;

  const _EmptyState({required this.message, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ScSpacing.panelPadLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: ScText.label),
          const SizedBox(height: 8),
          Text(hint, style: ScText.label.copyWith(color: ScColors.textDim)),
        ],
      ),
    );
  }
}

ScChipState _nodeChipState(NodeHealthPhase health) => switch (health) {
      NodeHealthPhase.online => ScChipState.ok,
      NodeHealthPhase.degraded => ScChipState.warn,
      NodeHealthPhase.reconnecting => ScChipState.syncing,
      NodeHealthPhase.offline => ScChipState.error,
    };
