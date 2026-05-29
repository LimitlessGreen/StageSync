import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/session_provider.dart';
import '../../../providers/node_management_provider.dart';
import '../../../providers/show_control_domain_provider.dart';
import '../../../providers/audio_node_provider.dart';
import '../../../nodes/audio_node/audio_node_service.dart';

import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';
import '../../design_system/primitives/sc_button.dart';
import '../../design_system/primitives/sc_chip.dart';
import '../../../domain/node_status.dart';

class NodeManagementPanel extends ConsumerStatefulWidget {
  const NodeManagementPanel({super.key});

  @override
  ConsumerState<NodeManagementPanel> createState() =>
      _NodeManagementPanelState();
}

class _NodeManagementPanelState extends ConsumerState<NodeManagementPanel> {
  String? _selectedNodeId;

  @override
  Widget build(BuildContext context) {
    final session           = ref.watch(sessionProvider);
    final nodes             = ref.watch(nodeStatusListProvider);
    final isMasterOrEditor  = session.myNode?.tasks.any(
          (t) => t.value == 1 || t.value == 3) ?? false;

    final selected = nodes.where((n) => n.nodeId == _selectedNodeId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Toolbar ──────────────────────────────────────────────────────
        Container(
          height: 36,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              Text('NODES', style: ScText.panelTitle),
              const SizedBox(width: 10),
              _NodeCountDot(count: nodes.length),
              const Spacer(),
              if (!isMasterOrEditor)
                ScChip(label: 'Nur lesen', state: ScChipState.idle),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: node list ─────────────────────────────────────────
              Expanded(
                flex: 2,
                child: _NodeListColumn(
                  nodes: nodes,
                  selectedId: _selectedNodeId,
                  onSelect: (id) => setState(() => _selectedNodeId = id),
                ),
              ),
              const VerticalDivider(width: 1, color: ScColors.divider),
              // ── Right: detail ───────────────────────────────────────────
              Expanded(
                flex: 3,
                child: selected == null
                    ? Center(
                        child: Text(
                          nodes.isEmpty ? 'Keine Nodes verbunden' : 'Node auswählen',
                          style: ScText.label.copyWith(color: ScColors.textDim),
                        ),
                      )
                    : _NodeDetailColumn(
                        node: selected,
                        isMaster: isMasterOrEditor,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Node Count Dot ─────────────────────────────────────────────────────────────

class _NodeCountDot extends StatelessWidget {
  final int count;
  const _NodeCountDot({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: count > 0 ? ScColors.active : ScColors.past,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: ScText.status.copyWith(
            color: count > 0 ? ScColors.active : ScColors.past,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ── Node List Column ──────────────────────────────────────────────────────────

class _NodeListColumn extends StatelessWidget {
  final List<NodeStatus> nodes;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _NodeListColumn({
    required this.nodes,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 28,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          alignment: Alignment.centerLeft,
          child: Text('VERBUNDEN', style: ScText.panelTitle),
        ),
        const Divider(height: 1, color: ScColors.divider),
        if (nodes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(ScSpacing.panelPad),
            child: Text(
              'Warte auf Nodes…',
              style: ScText.label.copyWith(color: ScColors.textDim),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: nodes.length,
              itemBuilder: (_, i) => _NodeRow(
                node: nodes[i],
                isSelected: nodes[i].nodeId == selectedId,
                onTap: () => onSelect(nodes[i].nodeId),
              ),
            ),
          ),
      ],
    );
  }
}

class _NodeRow extends StatefulWidget {
  final NodeStatus node;
  final bool isSelected;
  final VoidCallback onTap;

  const _NodeRow({required this.node, required this.isSelected, required this.onTap});

  @override
  State<_NodeRow> createState() => _NodeRowState();
}

class _NodeRowState extends State<_NodeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.node;
    final bg = widget.isSelected
        ? ScColors.active.withValues(alpha: 0.08)
        : _hovered ? ScColors.hover : Colors.transparent;

    final healthColor = switch (n.health) {
      NodeHealthPhase.online       => ScColors.active,
      NodeHealthPhase.degraded     => ScColors.warn,
      NodeHealthPhase.reconnecting => ScColors.warn,
      NodeHealthPhase.offline      => ScColors.error,
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              // Selection indicator
              SizedBox(
                width: 12,
                child: widget.isSelected
                    ? Container(
                        width: 4, height: 4,
                        decoration: const BoxDecoration(
                          color: ScColors.active, shape: BoxShape.circle),
                      )
                    : null,
              ),
              // Health dot
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(color: healthColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              // Name + tasks
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.name,
                      style: ScText.label.copyWith(
                        color: widget.isSelected
                            ? ScColors.textPrimary
                            : ScColors.textSecondary,
                        fontWeight: widget.isSelected ? FontWeight.w600 : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 3,
                      children: n.tasks.map((t) => _TaskBadge(task: t)).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  final String task;
  const _TaskBadge({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = switch (task) {
      'master' => ScColors.active,
      'audio'  => const Color(0xFF4FC3F7),
      'editor' => ScColors.warn,
      'ma_osc' => const Color(0xFFCE93D8),
      _        => ScColors.textDim,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        task.toUpperCase().replaceAll('_', ' '),
        style: ScText.statusSmall.copyWith(color: color, fontSize: 8),
      ),
    );
  }
}

// ── Node Detail Column ─────────────────────────────────────────────────────────

class _NodeDetailColumn extends ConsumerStatefulWidget {
  final NodeStatus node;
  final bool isMaster;

  const _NodeDetailColumn({required this.node, required this.isMaster});

  @override
  ConsumerState<_NodeDetailColumn> createState() => _NodeDetailColumnState();
}

class _NodeDetailColumnState extends ConsumerState<_NodeDetailColumn> {
  int? _selectedDeviceIdx;

  @override
  void didUpdateWidget(_NodeDetailColumn old) {
    super.didUpdateWidget(old);
    if (old.node.nodeId != widget.node.nodeId) {
      _selectedDeviceIdx = null;
    }
  }

  // Returns the effective selection: user-picked index OR the currently active device.
  int? _effectiveIdx(List<AudioDevice> devices, AudioDevice? activeDevice, bool isLocal) {
    if (_selectedDeviceIdx != null) return _selectedDeviceIdx;
    if (!isLocal || activeDevice == null) return null;
    final i = devices.indexWhere((d) => d.name == activeDevice.name);
    return i >= 0 ? i : null;
  }

  @override
  Widget build(BuildContext context) {
    final session      = ref.watch(sessionProvider);
    final audioStatus  = ref.watch(audioNodeProvider);
    final mgmtState    = ref.watch(nodeManagementProvider);
    final node         = widget.node;
    final isLocalNode  = node.nodeId == session.myNode?.nodeId;
    final devices      = isLocalNode ? audioStatus.availableDevices : node.availableDevices;
    final isLocalAudioOk = isLocalNode && audioStatus.state == AudioNodeState.connected;
    final canInteract  = isLocalNode ? isLocalAudioOk : devices.isNotEmpty;
    final effectiveIdx = _effectiveIdx(devices, audioStatus.selectedDevice, isLocalNode);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Info section ────────────────────────────────────────────────
          _SectionHeader('INFO'),
          _PropRow('Name', node.name),
          _PropRow(
            'ID',
            node.nodeId.length > 12
                ? '${node.nodeId.substring(0, 12)}…'
                : node.nodeId,
          ),
          _PropRow('Status', _healthLabel(node.health)),
          if (node.clockDeltaMs != null)
            _PropRow(
              'Clock Δ',
              '${node.clockDeltaMs} ms',
              valueColor: _clockColor(node.clockDeltaMs!),
            ),
          if (node.isAudio) ...[
            // ── Audio device section ──────────────────────────────────────
            const Divider(height: 1, color: ScColors.divider),
            _SectionHeader('AUDIO-GERÄT'),
            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: ScSpacing.panelPad, vertical: 6),
                child: Text(
                  isLocalNode
                      ? (isLocalAudioOk ? 'Keine Geräte gefunden' : 'Audio-Node inaktiv')
                      : 'Keine Gerätliste',
                  style: ScText.label.copyWith(color: ScColors.textDim),
                ),
              )
            else
              ...devices.asMap().entries.map((e) => _DeviceSelectRow(
                    device: e.value,
                    isSelected: effectiveIdx == e.key,
                    isCurrent: isLocalNode &&
                        audioStatus.selectedDevice?.name == e.value.name,
                    onTap: () => setState(() => _selectedDeviceIdx = e.key),
                  )),
            // Device action buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: ScSpacing.panelPad, vertical: 6),
              child: Row(
                children: [
                  ScButton(
                    label: 'Setzen',
                    icon: Icons.check,
                    variant: ScButtonVariant.secondary,
                    size: ScButtonSize.compact,
                    onPressed: (effectiveIdx != null && canInteract)
                        ? () {
                            if (isLocalNode) {
                              ref.read(audioNodeProvider.notifier)
                                  .selectDevice(devices[effectiveIdx!]);
                            }
                            ref.read(nodeManagementProvider.notifier).setAudioDevice(
                                  targetNodeId: node.nodeId,
                                  deviceIndex: devices[effectiveIdx!].index,
                                  deviceName: devices[effectiveIdx!].name,
                                );
                          }
                        : null,
                  ),
                  const SizedBox(width: 6),
                  ScButton(
                    label: 'Default',
                    icon: Icons.restore,
                    variant: ScButtonVariant.ghost,
                    size: ScButtonSize.compact,
                    onPressed: canInteract
                        ? () {
                            if (isLocalNode) {
                              ref.read(audioNodeProvider.notifier)
                                  .resetToDefaultDevice();
                            }
                            ref.read(nodeManagementProvider.notifier)
                                .resetToDefault(targetNodeId: node.nodeId);
                          }
                        : null,
                  ),
                  if (mgmtState.isSending) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: ScColors.active),
                    ),
                  ],
                ],
              ),
            ),
            // ── Test signal ───────────────────────────────────────────────
            const Divider(height: 1, color: ScColors.divider),
            _SectionHeader('TEST-SIGNAL'),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: ScSpacing.panelPad, vertical: 6),
              child: _TestSignalRow(node: node, isMaster: widget.isMaster),
            ),
          ],
          if (mgmtState.error != null) ...[
            const Divider(height: 1, color: ScColors.divider),
            Container(
              color: ScColors.error.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(
                  horizontal: ScSpacing.panelPad, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 12, color: ScColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(mgmtState.error!,
                        style: ScText.label.copyWith(color: ScColors.error)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _healthLabel(NodeHealthPhase h) => switch (h) {
    NodeHealthPhase.online       => 'Online',
    NodeHealthPhase.degraded     => 'Degraded',
    NodeHealthPhase.reconnecting => 'Reconnecting…',
    NodeHealthPhase.offline      => 'Offline',
  };

  static Color _clockColor(int ms) {
    final abs = ms.abs();
    if (abs <= 5)  return ScColors.active;
    if (abs <= 20) return ScColors.warn;
    return ScColors.error;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      alignment: Alignment.centerLeft,
      child: Text(title, style: ScText.panelTitle),
    );
  }
}

class _PropRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _PropRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: ScText.label),
          ),
          Expanded(
            child: Text(
              value,
              style: ScText.label.copyWith(
                color: valueColor ?? ScColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSelectRow extends StatefulWidget {
  final AudioDevice device;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;

  const _DeviceSelectRow({
    required this.device,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  State<_DeviceSelectRow> createState() => _DeviceSelectRowState();
}

class _DeviceSelectRowState extends State<_DeviceSelectRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? ScColors.active.withValues(alpha: 0.08)
        : _hovered ? ScColors.hover : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 28,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                child: widget.isCurrent
                    ? const Icon(Icons.volume_up, size: 11, color: ScColors.active)
                    : widget.isSelected
                        ? Container(
                            width: 4, height: 4,
                            decoration: const BoxDecoration(
                              color: ScColors.active, shape: BoxShape.circle),
                          )
                        : null,
              ),
              Expanded(
                child: Text(
                  widget.device.name,
                  style: ScText.label.copyWith(
                    color: widget.isSelected || widget.isCurrent
                        ? ScColors.textPrimary
                        : ScColors.textSecondary,
                    fontWeight: widget.isSelected ? FontWeight.w500 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: ScColors.surface2,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  widget.device.backend.name.toUpperCase(),
                  style: ScText.statusSmall.copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestSignalRow extends ConsumerStatefulWidget {
  final NodeStatus node;
  final bool isMaster;
  const _TestSignalRow({required this.node, required this.isMaster});

  @override
  ConsumerState<_TestSignalRow> createState() => _TestSignalRowState();
}

class _TestSignalRowState extends ConsumerState<_TestSignalRow> {
  bool _toneActive  = false;
  bool _sweepActive = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(nodeManagementProvider.notifier);
    return Row(
      children: [
        ScButton(
          label: _toneActive ? 'Stop' : '1 kHz',
          icon: _toneActive ? Icons.stop : Icons.graphic_eq,
          variant: _toneActive ? ScButtonVariant.danger : ScButtonVariant.ghost,
          size: ScButtonSize.compact,
          onPressed: widget.isMaster
              ? () async {
                  setState(() => _toneActive = true);
                  await notifier.sendTestTone(targetNodeId: widget.node.nodeId);
                  await Future.delayed(const Duration(milliseconds: 1100));
                  if (mounted) setState(() => _toneActive = false);
                }
              : null,
        ),
        const SizedBox(width: 6),
        ScButton(
          label: _sweepActive ? 'Stop' : 'Sweep',
          icon: _sweepActive ? Icons.stop : Icons.multiline_chart,
          variant: _sweepActive ? ScButtonVariant.danger : ScButtonVariant.ghost,
          size: ScButtonSize.compact,
          onPressed: widget.isMaster
              ? () async {
                  setState(() => _sweepActive = true);
                  await notifier.sendTestSweep(targetNodeId: widget.node.nodeId);
                  await Future.delayed(const Duration(milliseconds: 3100));
                  if (mounted) setState(() => _sweepActive = false);
                }
              : null,
        ),
        if (!widget.isMaster) ...[
          const SizedBox(width: 8),
          Text('Nur Master', style: ScText.label.copyWith(color: ScColors.textDim)),
        ],
      ],
    );
  }
}
