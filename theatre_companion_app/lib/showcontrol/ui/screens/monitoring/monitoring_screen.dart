import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/node_status.dart';
import '../../../providers/show_control_domain_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';
import '../../design_system/primitives/sc_panel.dart';
import '../../design_system/domain_components/active_cue_monitor.dart';
import '../../design_system/domain_components/node_status_badge.dart';

/// Full-screen monitoring view — Node health + active cue details.
///
/// Suitable as a dedicated monitoring display or as the right panel
/// in the desktop shell.
class MonitoringScreen extends ConsumerWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domain = ref.watch(showControlDomainProvider);

    return Column(
      children: [
        // ── Node health strip ─────────────────────────────────────────
        Container(
          color: ScColors.surface,
          padding: const EdgeInsets.all(ScSpacing.panelPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NODES', style: ScText.panelTitle),
              const SizedBox(height: 8),
              NodeHealthStrip(nodes: domain.nodes),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        // ── Active cue monitor ────────────────────────────────────────
        Expanded(
          child: ScPanel(
            title: 'AKTIVER CUE',
            child: ActiveCueMonitor(
              playhead: domain.playhead,
              cueList: domain.cueList,
            ),
          ),
        ),
        // ── Clock delta strip ─────────────────────────────────────────
        _ClockStrip(nodes: domain.nodes),
      ],
    );
  }
}

class _ClockStrip extends StatelessWidget {
  final List<NodeStatus> nodes;
  const _ClockStrip({required this.nodes});

  @override
  Widget build(BuildContext context) {
    final withClock = nodes.where((n) => n.clockDeltaMs != null).toList();
    if (withClock.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 28,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 11, color: ScColors.textDim),
          const SizedBox(width: 6),
          for (final n in withClock) ...[
            Text(
              '${n.name}: ${(n.clockDeltaMs! > 0 ? '+' : '')}${n.clockDeltaMs} ms',
              style:
                  ScText.label.copyWith(fontSize: 10, color: ScColors.textDim),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
