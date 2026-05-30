import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/show_control_provider.dart';
import '../../providers/show_control_domain_provider.dart';
import '../../providers/session_provider.dart';
import '../../session/clock_sync.dart';
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

class _MobileCueList extends StatefulWidget {
  final CueList? cueList;
  final PlayheadState playhead;
  final ShowControlNotifier notifier;

  const _MobileCueList({required this.cueList, required this.playhead, required this.notifier});

  @override
  State<_MobileCueList> createState() => _MobileCueListState();
}

class _MobileCueListState extends State<_MobileCueList> {
  final ScrollController _scrollController = ScrollController();
  String? _lastActiveCueId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MobileCueList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newActiveId = widget.playhead.activeCueId;
    if (newActiveId != null && newActiveId != _lastActiveCueId) {
      _lastActiveCueId = newActiveId;
      _scrollToActive(newActiveId);
    }
  }

  void _scrollToActive(String activeId) {
    final cues = widget.cueList?.cues;
    if (cues == null) return;
    final activeIdx = cues.indexWhere((c) => c.id == activeId);
    if (activeIdx < 0) return;

    // Calculate offset: rows before active use rowHeight, active row uses rowHeightActive.
    double offset = activeIdx * ScSpacing.rowHeight;
    // Subtract half the viewport height to center the active row.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final viewportHeight = _scrollController.position.viewportDimension;
      final target = (offset - viewportHeight / 2 + ScSpacing.rowHeightActive / 2)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cueList == null) {
      return Center(
        child: Text('Keine CueList', style: TextStyle(color: ScColors.textDim)),
      );
    }

    final cues = widget.cueList!.cues;
    final activeIdx = widget.playhead.activeCueId != null
        ? cues.indexWhere((c) => c.id == widget.playhead.activeCueId)
        : -1;

    return ListView.builder(
      controller: _scrollController,
      itemCount: cues.length,
      itemBuilder: (context, i) {
        final cue = cues[i];
        final isActive = widget.playhead.activeCueId == cue.id;
        final isPast = activeIdx >= 0 && i < activeIdx;

        return CueListRow(
          key: ValueKey(cue.id),
          cue: cue,
          runState: widget.playhead.runStateFor(cue.id),
          playhead: widget.playhead,
          isActive: isActive,
          isPast: isPast,
          expanded: isActive,
          showDragHandle: false,
          onTap: () => widget.notifier.goToCue(cue.id),
        );
      },
    );
  }
}

// ── Transport Controls ─────────────────────────────────────────────────────────

class _TransportControls extends StatefulWidget {
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
  State<_TransportControls> createState() => _TransportControlsState();
}

class _TransportControlsState extends State<_TransportControls> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _updateTimer();
  }

  @override
  void didUpdateWidget(_TransportControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playhead.isRunning != widget.playhead.isRunning) {
      _updateTimer();
    }
  }

  void _updateTimer() {
    if (widget.playhead.isRunning) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatElapsed() {
    final started = widget.playhead.startedServerMs;
    if (started == null) return '0:00';
    final int elapsedMs;
    if (widget.playhead.isPaused) {
      final paused = widget.playhead.pausedAtServerMs;
      elapsedMs = paused != null ? paused - started : 0;
    } else {
      elapsedMs = ClockSync.instance.serverNow() - started;
    }
    final totalSeconds = (elapsedMs / 1000).floor().clamp(0, double.maxFinite.toInt());
    final m = totalSeconds ~/ 60;
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final showTimer = widget.playhead.startedServerMs != null &&
        (widget.playhead.isRunning || widget.playhead.isPaused);

    return Container(
      color: ScColors.surface,
      padding: const EdgeInsets.all(ScSpacing.panelPadLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elapsed timer
          if (showTimer) ...[
            Text(
              _formatElapsed(),
              style: ScText.timer,
            ),
            const SizedBox(height: 8),
          ],
          // Large GO button
          SizedBox(
            width: double.infinity,
            height: ScSpacing.buttonHeightLarge,
            child: ScButton(
              label: 'GO',
              variant: ScButtonVariant.primary,
              size: ScButtonSize.large,
              onPressed: widget.onGo,
            ),
          ),
          const SizedBox(height: 12),
          // Secondary controls
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: ScSpacing.buttonHeightDefault,
                  child: widget.playhead.isPaused
                      ? ScButton(
                          label: 'RESUME',
                          icon: Icons.play_arrow,
                          variant: ScButtonVariant.secondary,
                          size: ScButtonSize.normal,
                          onPressed: widget.onResume,
                        )
                      : ScButton(
                          label: 'PAUSE',
                          icon: Icons.pause,
                          variant: ScButtonVariant.secondary,
                          size: ScButtonSize.normal,
                          onPressed: widget.onPause,
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
                    onPressed: widget.onStop,
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
              onPressed: widget.onLeave,
            ),
          ),
        ],
      ),
    );
  }
}
