import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/show_control_provider.dart';
import '../../providers/show_control_domain_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/audio_node_provider.dart';
import '../../providers/ma_node_provider.dart';
import '../../grpc/generated/stagesync/v1/common.pb.dart' show NodeTask;
import '../screens/settings/settings_screen.dart';
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
class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key});

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(sessionProvider).isInSession) return;
      ref.read(showControlProvider.notifier).initialize();
    });
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (!mounted) return;
        if (ref.read(sessionProvider).isInSession) {
          ref.read(showControlProvider.notifier).initialize();
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _leaveSession() async {
    final tasks = ref.read(sessionProvider).myNode?.tasks ?? [];
    if (tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) {
      await ref.read(audioNodeProvider.notifier).stopAudioNode();
    }
    if (tasks.contains(NodeTask.NODE_TASK_MA_OSC)) {
      await ref.read(maNodeProvider.notifier).stopMaNode();
    }
    await ref.read(sessionProvider.notifier).leaveSession();
  }

  @override
  Widget build(BuildContext context) {
    final domainState = ref.watch(showControlDomainProvider);
    final sessionState = ref.watch(sessionProvider);
    final notifier = ref.read(showControlProvider.notifier);

    return Scaffold(
      backgroundColor: ScColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Status strip ─────────────────────────────────────────────
            _StatusStrip(
              sessionName: sessionState.session?.name ?? 'Show Control',
              nodes: domainState.nodes,
              shellContext: context,
            ),
            const Divider(height: 1, color: ScColors.divider),
            // ── Read-only cue list ────────────────────────────────────────
            Expanded(
              child: _MobileCueList(
                cueList: domainState.cueList,
                playhead: domainState.playhead,
                notifier: notifier,
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
              onLeave: _leaveSession,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Strip ───────────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  final String sessionName;
  final List nodes;
  final BuildContext shellContext;

  const _StatusStrip({
    required this.sessionName,
    required this.nodes,
    required this.shellContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          const Icon(Icons.theater_comedy, size: 12, color: ScColors.textDim),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              sessionName,
              style: ScText.panelTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (nodes.isNotEmpty) ...[
            NodeHealthStrip(nodes: nodes.cast()),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.settings, size: 16),
            color: ScColors.textDim,
            tooltip: 'Einstellungen',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => Navigator.of(shellContext).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cue List ───────────────────────────────────────────────────────────────────

class _MobileCueList extends StatelessWidget {
  final CueList? cueList;
  final PlayheadState playhead;
  final ShowControlNotifier notifier;

  const _MobileCueList({required this.cueList, required this.playhead, required this.notifier});

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
          // Mobile: tap to jump to cue; no drag/delete/context actions
          showDragHandle: false,
          onTap: () => notifier.goToCue(cue.id),
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
  final VoidCallback onLeave;

  const _TransportControls({
    required this.playhead,
    required this.onGo,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onLeave,
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
          const SizedBox(height: 16),
          // Leave session — full-width outlined button
          SizedBox(
            width: double.infinity,
            child: ScButton(
              label: 'Session verlassen',
              icon: Icons.logout,
              variant: ScButtonVariant.danger,
              size: ScButtonSize.compact,
              onPressed: onLeave,
            ),
          ),
        ],
      ),
    );
  }
}
