import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/show.dart';
import '../../../domain/playhead.dart';
import '../../../providers/show_control_provider.dart';
import '../../../providers/show_control_domain_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';
import '../../design_system/domain_components/cue_list_row.dart';
import '../../design_system/domain_components/transport_bar.dart';
import '../../design_system/domain_components/node_status_badge.dart';

/// Standalone GO screen — read-only cue view + transport controls.
///
/// Works as a full-screen view for mobile/tablet, or as the primary
/// panel in the desktop shell's live-view mode.
/// No editing: no CueList editor, no Inspector, no Patch, no Media.
class GoScreen extends ConsumerWidget {
  const GoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domain   = ref.watch(showControlDomainProvider);
    final notifier = ref.read(showControlProvider.notifier);

    return Scaffold(
      backgroundColor: ScColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            if (domain.nodes.isNotEmpty)
              _StatusStrip(nodes: domain.nodes),
            TransportBar(
              playhead: domain.playhead,
              cueList:  domain.cueList,
              onGo:     () => notifier.go(),
              onStop:   () => notifier.stop(),
              onPause:  () => notifier.pause(),
              onResume: () => notifier.resume(),
              compact:  true,
            ),
            const Divider(height: 1, color: ScColors.divider),
            Expanded(
              child: _ReadOnlyCueList(
                cueList:  domain.cueList,
                playhead: domain.playhead,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final List<dynamic> nodes;
  const _StatusStrip({required this.nodes});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          for (final node in nodes) ...[
            NodeStatusBadge(node: node),
            const SizedBox(width: 8),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _ReadOnlyCueList extends StatelessWidget {
  final CueList? cueList;
  final PlayheadState playhead;
  const _ReadOnlyCueList({required this.cueList, required this.playhead});

  @override
  Widget build(BuildContext context) {
    final list = cueList;
    if (list == null || list.cues.isEmpty) {
      return Center(
        child: Text('Keine Cues', style: ScText.label.copyWith(color: ScColors.textDim)),
      );
    }
    return ListView.builder(
      itemCount: list.cues.length,
      itemBuilder: (context, i) {
        final cue = list.cues[i];
        final activeIdx = list.cues.indexWhere((c) => c.id == playhead.activeCueId);
        final isPast    = activeIdx >= 0 && i < activeIdx;
        return CueListRow(
          cue:      cue,
          isActive: cue.id == playhead.activeCueId,
          isPast:   isPast,
        );
      },
    );
  }
}
