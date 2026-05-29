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
class NodeManagementPanel extends ConsumerWidget {
  const NodeManagementPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mgmtState = ref.watch(nodeManagementProvider);
    final session   = ref.watch(sessionProvider);
    final nodes     = ref.watch(nodeStatusListProvider);
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
              const SizedBox(width: 10),
              Text(
                '${nodes.length} verbunden',
                style: ScText.label.copyWith(color: ScColors.textDim),
              ),
              if (!isMasterOrEditor) ...[
                const SizedBox(width: 10),
                ScChip(label: 'Nur lesen', state: ScChipState.idle),
              ],
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
                const Icon(Icons.check_circle_outline,
                    size: 12, color: ScColors.active),
                const SizedBox(width: 4),
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
                const SizedBox(width: 6),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.device_hub,
                          size: 32, color: ScColors.textDim),
                      const SizedBox(height: 8),
                      Text('Keine Nodes verbunden',
                          style: ScText.label.copyWith(
                              color: ScColors.textDim)),
                    ],
                  ),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      color: _expanded
          ? ScColors.surface.withValues(alpha: 0.6)
          : Colors.transparent,
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            highlightColor: ScColors.active.withValues(alpha: 0.06),
            splashColor: ScColors.active.withValues(alpha: 0.08),
            child: Container(
              height: ScSpacing.rowHeight,
              padding:
                  const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
              child: Row(
                children: [
                  _StatusDot(health: node.health),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(node.name,
                            style: ScText.cueLabel.copyWith(fontSize: 13)),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 4,
                          children: node.tasks
                              .map((t) => ScChip(
                                    label: t.toUpperCase(),
                                    state: _taskChipState(t),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  // Clock delta
                  if (node.clockDeltaMs != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.av_timer,
                              size: 11,
                              color: _clockDeltaColor(node.clockDeltaMs!)),
                          const SizedBox(width: 3),
                          Text(
                            'Δ${node.clockDeltaMs}ms',
                            style: ScText.numberSmall.copyWith(
                              color: _clockDeltaColor(node.clockDeltaMs!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Audition badge
                  if (node.audition.supported)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Tooltip(
                        message:
                            'Audition: ${node.audition.deviceName ?? "verfügbar"}',
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
      ),
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
      NodeHealthPhase.online       => ScColors.active,
      NodeHealthPhase.degraded     => ScColors.warn,
      NodeHealthPhase.reconnecting => ScColors.warn,
      NodeHealthPhase.offline      => ScColors.error,
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
    return Container(
      decoration: BoxDecoration(
        color: ScColors.bg,
        border: Border(
          left: BorderSide(color: ScColors.active.withValues(alpha: 0.3), width: 2),
        ),
      ),
      margin: const EdgeInsets.only(left: ScSpacing.panelPad + 18),
      padding: const EdgeInsets.fromLTRB(12, 10, ScSpacing.panelPad, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node ID row
          Row(
            children: [
              const Icon(Icons.fingerprint, size: 11, color: ScColors.textDim),
              const SizedBox(width: 4),
              Text(node.nodeId,
                  style: ScText.numberSmall.copyWith(
                      fontSize: 10, color: ScColors.textDim)),
            ],
          ),
          if (node.isAudio) ...[
            const SizedBox(height: 14),
            _SectionHeader(title: 'Audio-Ausgabe', icon: Icons.speaker),
            const SizedBox(height: 8),
            if (isMaster)
              _AudioDeviceSection(node: node)
            else
              Text('Nur Master kann Gerät setzen',
                  style: ScText.label.copyWith(color: ScColors.textDim)),
            const SizedBox(height: 14),
            _SectionHeader(title: 'Test-Signal', icon: Icons.graphic_eq),
            const SizedBox(height: 8),
            _TestSignalRow(node: node, isMaster: isMaster),
          ],
          if (!node.isAudio && !node.isMaNode) ...[
            const SizedBox(height: 10),
            Text('Keine Konfigurations-Optionen für diesen Node-Typ',
                style: ScText.label.copyWith(color: ScColors.textDim)),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: ScColors.textDim),
        const SizedBox(width: 6),
        Text(title.toUpperCase(),
            style: ScText.label.copyWith(
                color: ScColors.textDim,
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Expanded(
            child: Container(height: 1, color: ScColors.divider)),
      ],
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
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              isLocalNode
                  ? (isLocalAudioConnected
                      ? 'Keine Audiogeräte gefunden'
                      : 'Audio-Node nicht aktiv')
                  : 'Keine Gerätliste empfangen',
              style: ScText.label.copyWith(color: ScColors.textDim),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: ScColors.divider),
              borderRadius: BorderRadius.circular(6),
              color: ScColors.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _selectedIndex ??
                    (isLocalNode
                        ? audioStatus.selectedDevice?.let((d) =>
                            devices.contains(d) ? devices.indexOf(d) : null)
                        : null),
                hint: Text(
                  isLocalNode
                      ? (audioStatus.selectedDevice?.name ?? 'Gerät auswählen')
                      : 'Gerät auswählen',
                  style: ScText.label.copyWith(color: ScColors.textDim),
                  overflow: TextOverflow.ellipsis,
                ),
                dropdownColor: ScColors.surface,
                style: ScText.label.copyWith(color: ScColors.textPrimary),
                icon: const Icon(Icons.unfold_more,
                    size: 16, color: ScColors.textDim),
                items: devices
                    .asMap()
                    .entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value.name,
                              overflow: TextOverflow.ellipsis,
                              style: ScText.label
                                  .copyWith(color: ScColors.textPrimary)),
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
            ),
          ),
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
        if (widget.node.audition.supported && isLocalNode) ...[
          const SizedBox(height: 12),
          _SectionHeader(title: 'Audition (Vorhören)', icon: Icons.headphones),
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

class _TestSignalRow extends ConsumerStatefulWidget {
  final NodeStatus node;
  final bool isMaster;

  const _TestSignalRow({required this.node, required this.isMaster});

  @override
  ConsumerState<_TestSignalRow> createState() => _TestSignalRowState();
}

class _TestSignalRowState extends ConsumerState<_TestSignalRow> {
  bool _toneActive = false;
  bool _sweepActive = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(nodeManagementProvider.notifier);

    return Row(
      children: [
        ScButton(
          label: '1 kHz',
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
        const SizedBox(width: 8),
        ScButton(
          label: 'Sweep',
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
          const SizedBox(width: 10),
          Text('Nur Master',
              style: ScText.label.copyWith(color: ScColors.textDim)),
        ],
      ],
    );
  }
}
