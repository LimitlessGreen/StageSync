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

/// Desktop-only Node-Management-Panel.
/// Liest Nodes aus [nodeStatusListProvider] (WatchNodeHealth-Stream).
/// Master und Editor können: Audio-Gerät remote setzen, Test-Signale senden.
class NodeManagementPanel extends ConsumerWidget {
  const NodeManagementPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mgmtState = ref.watch(nodeManagementProvider);
    final session   = ref.watch(sessionProvider);
    final nodes     = ref.watch(nodeStatusListProvider);
    // Master (value=1) und Editor (value=3) dürfen Transport-Commands senden.
    final isMasterOrEditor = session.myNode?.tasks.any(
          (t) => t.value == 1 || t.value == 3,
        ) ??
        false;

    return Column(
      children: [
        // ── Toolbar ─────────────────────────────────────────────────────
        Container(
          height: 44,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              Text('NODES', style: ScText.panelTitle),
              const SizedBox(width: 12),
              if (!isMasterOrEditor)
                ScChip(label: 'Nur lesen', state: ScChipState.idle),
              const Spacer(),
              if (mgmtState.isSending)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: ScColors.active),
                ),
              if (mgmtState.lastAction != null && !mgmtState.isSending) ...[
                const SizedBox(width: 8),
                Text(mgmtState.lastAction!, style: ScText.statusSmall),
              ],
            ],
          ),
        ),
        if (mgmtState.error != null)
          Container(
            color: ScColors.error.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(
                horizontal: ScSpacing.panelPad, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: ScColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(mgmtState.error!,
                      style: ScText.label.copyWith(color: ScColors.error)),
                ),
              ],
            ),
          ),
        const Divider(height: 1, color: ScColors.divider),
        // ── Node list ────────────────────────────────────────────────────
        Expanded(
          child: nodes.isEmpty
              ? Center(
                  child: Text('Keine Nodes verbunden',
                      style: TextStyle(color: ScColors.textDim)),
                )
              : ListView.separated(
                  itemCount: nodes.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: ScColors.divider),
                  itemBuilder: (context, i) => _NodeCard(
                    node: nodes[i],
                    isMaster: isMasterOrEditor,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Node Card ─────────────────────────────────────────────────────────────────

class _NodeCard extends ConsumerStatefulWidget {
  final NodeStatus node;
  final bool isMaster;

  const _NodeCard({required this.node, required this.isMaster});

  @override
  ConsumerState<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends ConsumerState<_NodeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;

    // Capabilities aus dem Session-State holen
    // NodeInfo trägt keine Capabilities direkt — die kommen via WatchNodes
    // in zukünftiger Phase 2. Für jetzt: aus audio-Task ableiten.

    return Column(
      children: [
        // ── Header row ──────────────────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            height: ScSpacing.rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
            child: Row(
              children: [
                // Status dot
                _StatusDot(health: node.health),
                const SizedBox(width: 10),
                // Name + role chips
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.name,
                          style: ScText.cueLabel.copyWith(fontSize: 13)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...node.tasks.map((t) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: ScChip(
                                  label: t.toUpperCase(),
                                  state: _taskChipState(t),
                                ),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
                // Clock delta
                if (node.clockDeltaMs != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      'Δ${node.clockDeltaMs}ms',
                      style: ScText.numberSmall.copyWith(
                        color: _clockDeltaColor(node.clockDeltaMs!),
                      ),
                    ),
                  ),
                // Audition badge
                if (node.audition.supported)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: 'Audition: ${node.audition.deviceName ?? "verfügbar"}',
                      child: const Icon(Icons.headphones,
                          size: 14, color: ScColors.textDim),
                    ),
                  ),
                // Expand arrow
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: ScColors.textDim,
                ),
              ],
            ),
          ),
        ),
        // ── Expanded detail ──────────────────────────────────────────────
        if (_expanded)
          _NodeDetail(node: node, isMaster: widget.isMaster),
      ],
    );
  }

  static ScChipState _taskChipState(String task) => switch (task) {
        'master' => ScChipState.ok,
        'audio'  => ScChipState.ok,
        'editor' => ScChipState.warn,
        'ma_osc' => ScChipState.idle,
        _        => ScChipState.idle,
      };

  static Color _clockDeltaColor(int deltaMs) {
    final abs = deltaMs.abs();
    if (abs <= 5) return ScColors.active;
    if (abs <= 20) return ScColors.warn;
    return ScColors.error;
  }
}

class _StatusDot extends StatelessWidget {
  final NodeHealthPhase health;
  const _StatusDot({required this.health});

  @override
  Widget build(BuildContext context) {
    final color = switch (health) {
      NodeHealthPhase.online      => ScColors.active,
      NodeHealthPhase.degraded    => ScColors.warn,
      NodeHealthPhase.reconnecting => ScColors.warn,
      NodeHealthPhase.offline     => ScColors.error,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Node Detail (expanded) ────────────────────────────────────────────────────

class _NodeDetail extends ConsumerWidget {
  final NodeStatus node;
  final bool isMaster;

  const _NodeDetail({required this.node, required this.isMaster});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAudio = node.isAudio;

    return Container(
      color: ScColors.bg,
      padding: const EdgeInsets.fromLTRB(
          ScSpacing.panelPad + 18, 8, ScSpacing.panelPad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node ID
          Text('ID: ${node.nodeId}',
              style: ScText.numberSmall.copyWith(fontSize: 10)),
          const SizedBox(height: 10),
          if (isAudio) ...[
            Text('Audio', style: ScText.panelTitle),
            const SizedBox(height: 8),
            // Audio device section
            if (isMaster)
              _AudioDeviceSection(node: node)
            else
              Text('Nur Master kann Gerät setzen',
                  style: ScText.label.copyWith(color: ScColors.textDim)),
            const SizedBox(height: 12),
            // Test signals
            Text('Test-Signal', style: ScText.panelTitle),
            const SizedBox(height: 8),
            _TestSignalRow(node: node, isMaster: isMaster),
          ],
          if (!isAudio && !node.isMaNode)
            Text('Keine Konfigurations-Optionen für diesen Node-Typ',
                style: ScText.label.copyWith(color: ScColors.textDim)),
        ],
      ),
    );
  }
}

// ── Audio Device Section ──────────────────────────────────────────────────────

class _AudioDeviceSection extends ConsumerStatefulWidget {
  final NodeStatus node;
  const _AudioDeviceSection({required this.node});

  @override
  ConsumerState<_AudioDeviceSection> createState() => _AudioDeviceSectionState();
}

class _AudioDeviceSectionState extends ConsumerState<_AudioDeviceSection> {
  int? _selectedIndex;
  String _selectedName = '';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final audioStatus = ref.watch(audioNodeProvider);
    final isLocalNode = widget.node.nodeId == session.myNode?.nodeId;

    // Local node: live device list from AudioNodeService.
    // Remote node: device list from NodeStatus.availableDevices (populated via NodeHealthEvent).
    final devices = isLocalNode
        ? audioStatus.availableDevices
        : widget.node.availableDevices;
    final isLocalAudioConnected =
        isLocalNode && audioStatus.state == AudioNodeState.connected;
    final canInteract = isLocalNode ? isLocalAudioConnected : devices.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (devices.isEmpty)
          Text(
            isLocalNode
                ? (isLocalAudioConnected
                    ? 'Keine Audiogeräte gefunden'
                    : 'Audio-Node nicht aktiv')
                : 'Keine Gerätliste empfangen',
            style: ScText.label.copyWith(color: ScColors.textDim),
          )
        else
          DropdownButton<int>(
            value: _selectedIndex ??
                (isLocalNode
                    ? audioStatus.selectedDevice?.let((d) =>
                        devices.contains(d) ? devices.indexOf(d) : null)
                    : null),
            hint: Text(
              isLocalNode
                  ? (audioStatus.selectedDevice?.name ?? 'Gerät auswählen')
                  : 'Gerät auswählen',
              style: ScText.label,
            ),
            dropdownColor: ScColors.surface,
            style: ScText.label.copyWith(color: ScColors.textPrimary),
            isExpanded: true,
            items: devices
                .asMap()
                .entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child:
                          Text(e.value.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (idx) {
              if (idx == null || idx >= devices.length) return;
              setState(() {
                _selectedIndex = idx;
                _selectedName = devices[idx].name;
              });
            },
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            ScButton(
              label: 'Setzen',
              icon: Icons.check,
              variant: ScButtonVariant.secondary,
              size: ScButtonSize.compact,
              onPressed: (_selectedIndex != null && canInteract)
                  ? () {
                      if (isLocalNode) {
                        ref
                            .read(audioNodeProvider.notifier)
                            .selectDevice(devices[_selectedIndex!]);
                      }
                      ref.read(nodeManagementProvider.notifier).setAudioDevice(
                            targetNodeId: widget.node.nodeId,
                            deviceIndex: devices[_selectedIndex!].index,
                            deviceName: _selectedName,
                          );
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            ScButton(
              label: 'System-Default',
              icon: Icons.restore,
              variant: ScButtonVariant.ghost,
              size: ScButtonSize.compact,
              onPressed: canInteract
                  ? () {
                      if (isLocalNode) {
                        ref
                            .read(audioNodeProvider.notifier)
                            .resetToDefaultDevice();
                      }
                      ref.read(nodeManagementProvider.notifier).resetToDefault(
                            targetNodeId: widget.node.nodeId,
                          );
                    }
                  : null,
            ),
          ],
        ),
        // ── Audition ───────────────────────────────────────────────────
        if (widget.node.audition.supported && isLocalNode) ...[
          const SizedBox(height: 12),
          Text('Audition (Vorhören)', style: ScText.panelTitle),
          const SizedBox(height: 6),
          Text(
            widget.node.audition.deviceName != null
                ? 'Gerät: ${widget.node.audition.deviceName}'
                : 'Kopfhörer-Kanal verfügbar',
            style: ScText.label.copyWith(color: ScColors.textDim),
          ),
        ],
      ],
    );
  }
}

extension _Let<T> on T {
  R? let<R>(R? Function(T) block) => block(this);
}

// ── Test Signal Row ───────────────────────────────────────────────────────────

class _TestSignalRow extends ConsumerWidget {
  final NodeStatus node;
  final bool isMaster;

  const _TestSignalRow({required this.node, required this.isMaster});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(nodeManagementProvider.notifier);

    return Row(
      children: [
        ScButton(
          label: '1kHz Ton',
          icon: Icons.graphic_eq,
          variant: ScButtonVariant.ghost,
          size: ScButtonSize.compact,
          onPressed: isMaster
              ? () => notifier.sendTestTone(targetNodeId: node.nodeId)
              : null,
        ),
        const SizedBox(width: 8),
        ScButton(
          label: 'Sweep',
          icon: Icons.multiline_chart,
          variant: ScButtonVariant.ghost,
          size: ScButtonSize.compact,
          onPressed: isMaster
              ? () => notifier.sendTestSweep(targetNodeId: node.nodeId)
              : null,
        ),
      ],
    );
  }
}
