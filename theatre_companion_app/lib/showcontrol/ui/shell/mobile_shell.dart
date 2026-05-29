import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/show_control_provider.dart';
import '../../providers/show_control_domain_provider.dart';
import '../design_system/sc_colors.dart';
import '../design_system/sc_spacing.dart';
import '../design_system/sc_typography.dart';
import '../design_system/primitives/sc_button.dart';
import '../design_system/domain_components/cue_list_row.dart';
import '../design_system/domain_components/node_status_badge.dart';
import '../../domain/show.dart';
import '../../domain/playhead.dart';

/// Mobile shell — read-only cue view + large GO button.
///
/// No editing: no CueList editor, no Inspector, no Patch, no Media.
/// Intentionally minimal for safe live operation.
class MobileShell extends ConsumerWidget {
  const MobileShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainState = ref.watch(showControlDomainProvider);
    final notifier = ref.read(showControlProvider.notifier);

    return Scaffold(
      backgroundColor: ScColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Status strip ─────────────────────────────────────────────
            _StatusStrip(nodes: domainState.nodes),
            const Divider(height: 1, color: ScColors.divider),
            // ── Read-only cue list ────────────────────────────────────────
            Expanded(
              child: _MobileCueList(
                cueList: domainState.cueList,
                playhead: domainState.playhead,
              ),
            ),
            const Divider(height: 1, color: ScColors.divider),
            // ── Transport controls ────────────────────────────────────────
            _TransportControls(
              playhead: domainState.playhead,
              onGo: () => notifier.go(),
              onStop: () => notifier.stop(),
              onPause: () => notifier.pause(),
              onResume: () => notifier.resume(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Strip ───────────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  final List nodes;

  const _StatusStrip({required this.nodes});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          Text('SHOW CONTROL', style: ScText.panelTitle),
          const Spacer(),
          NodeHealthStrip(nodes: nodes.cast()),
        ],
      ),
    );
  }
}

// ── Cue List ───────────────────────────────────────────────────────────────────

class _MobileCueList extends StatelessWidget {
  final CueList? cueList;
  final PlayheadState playhead;

  const _MobileCueList({required this.cueList, required this.playhead});

  @override
  Widget build(BuildContext context) {
    if (cueList == null) {
      return Center(
        child: Text('Keine CueList', style: TextStyle(color: ScColors.textDim)),
      );
    }

    final cues = cueList!.cues;
    final activeIdx = playhead.activeCueId != null
        ? cues.indexWhere((c) => c.id == playhead.activeCueId)
        : -1;

    return ListView.builder(
      itemCount: cues.length,
      itemBuilder: (context, i) {
        final cue = cues[i];
        final isActive = playhead.activeCueId == cue.id;
        final isPast = activeIdx >= 0 && i < activeIdx;

        return CueListRow(
          key: ValueKey(cue.id),
          cue: cue,
          runState: playhead.runStateFor(cue.id),
          isActive: isActive,
          isPast: isPast,
          expanded: isActive,
          // Mobile: read-only, no drag/delete/context actions
          showDragHandle: false,
        );
      },
    );
  }
}

// ── Transport Controls ─────────────────────────────────────────────────────────

class _TransportControls extends StatelessWidget {
  final PlayheadState playhead;
  final VoidCallback onGo;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _TransportControls({
    required this.playhead,
    required this.onGo,
    required this.onStop,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ScColors.surface,
      padding: const EdgeInsets.all(ScSpacing.panelPadLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large GO button
          SizedBox(
            width: double.infinity,
            height: ScSpacing.buttonHeightLarge,
            child: ScButton(
              label: 'GO',
              variant: ScButtonVariant.primary,
              size: ScButtonSize.large,
              onPressed: onGo,
            ),
          ),
          const SizedBox(height: 12),
          // Secondary controls
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: ScSpacing.buttonHeightDefault,
                  child: playhead.isPaused
                      ? ScButton(
                          label: 'RESUME',
                          icon: Icons.play_arrow,
                          variant: ScButtonVariant.secondary,
                          size: ScButtonSize.normal,
                          onPressed: onResume,
                        )
                      : ScButton(
                          label: 'PAUSE',
                          icon: Icons.pause,
                          variant: ScButtonVariant.secondary,
                          size: ScButtonSize.normal,
                          onPressed: onPause,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: ScSpacing.buttonHeightDefault,
                  child: ScButton(
                    label: 'STOP',
                    icon: Icons.stop,
                    variant: ScButtonVariant.danger,
                    size: ScButtonSize.normal,
                    onPressed: onStop,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
