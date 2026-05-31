import 'dart:async';
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
import '../design_system/domain_components/active_next_cue_display.dart';
import '../design_system/domain_components/sc_cue_detail_sheet.dart';
import '../design_system/domain_components/master_volume_slider.dart';
import '../../nodes/audio_node/audio_node_service.dart' show AudioNodeState;
import '../../domain/show.dart';
import '../../domain/patch_config.dart';
import '../../domain/playhead.dart';
import '../../../ui/widgets/talkback_bar.dart';

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
  bool _talkbackExpanded = false;

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

    final talkbackBuses = domainState.patchConfig.busesOfType(AudioBusType.talkback);
    final busIds   = talkbackBuses.map((b) => b.id).toList();
    final busNames = {for (final b in talkbackBuses) b.id: b.name};

    final statusStrip = _StatusStrip(
      sessionName: sessionState.session?.name ?? 'Show Control',
      nodes: domainState.nodes,
      shellContext: context,
      onLeave: _leaveSession,
    );
    final connectionBanner = sessionState.health != ConnectionHealth.connected
        ? _ConnectionBanner(health: sessionState.health, onLeave: _leaveSession)
        : null;
    final nextDisplay = ActiveNextCueDisplay(
      cueList: domainState.cueList,
      playhead: domainState.playhead,
    );
    final cueList = _MobileCueList(
      cueList: domainState.cueList,
      playhead: domainState.playhead,
      notifier: notifier,
    );
    final talkback = _TalkbackSection(
      busIds: busIds,
      busNames: busNames,
      expanded: _talkbackExpanded,
      onToggle: () => setState(() => _talkbackExpanded = !_talkbackExpanded),
    );
    final transport = _TransportControls(
      playhead: domainState.playhead,
      onGo: () => notifier.go(),
      onStop: () => notifier.stop(),
      onPause: () => notifier.pause(),
      onResume: () => notifier.resume(),
    );

    return Scaffold(
      backgroundColor: ScColors.bg,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (ctx, orientation) {
            if (orientation == Orientation.landscape) {
              // ── Landscape: cue list left, transport right ──────────────
              return Column(
                children: [
                  statusStrip,
                  if (connectionBanner != null) connectionBanner,
                  Expanded(
                    child: Row(
                      children: [
                        // Left pane: 60% — cue info + list + talkback
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              const Divider(height: 1, color: ScColors.divider),
                              nextDisplay,
                              Expanded(child: cueList),
                              talkback,
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 1, color: ScColors.divider),
                        // Right pane: 40% — transport controls
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(child: transport),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // ── Portrait (default) ─────────────────────────────────────
            return Column(
              children: [
                statusStrip,
                if (connectionBanner != null) connectionBanner,
                const Divider(height: 1, color: ScColors.divider),
                nextDisplay,
                Expanded(child: cueList),
                talkback,
                const Divider(height: 1, color: ScColors.divider),
                transport,
              ],
            );
          },
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
  final VoidCallback onLeave;

  const _StatusStrip({
    required this.sessionName,
    required this.nodes,
    required this.shellContext,
    required this.onLeave,
  });

  Future<void> _confirmLeave(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Session verlassen?',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        content: const Text(
          'Dieses Gerät verlässt die Session. Der Server und laufende Cues bleiben aktiv.',
          style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Color(0xFFB0B0B0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
    if (confirmed == true) onLeave();
  }

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
          IconButton(
            icon: const Icon(Icons.logout, size: 16),
            color: ScColors.textDim,
            tooltip: 'Session verlassen',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _confirmLeave(context),
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
          onLongPress: () => showCueDetailSheet(context, cue, widget.notifier),
        );
      },
    );
  }
}

// ── Talkback Section (kollabierbar) ───────────────────────────────────────────

class _TalkbackSection extends StatelessWidget {
  final List<String> busIds;
  final Map<String, String> busNames;
  final bool expanded;
  final VoidCallback onToggle;

  const _TalkbackSection({
    required this.busIds,
    required this.busNames,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, color: ScColors.divider),
        // Toggle row
        InkWell(
          onTap: onToggle,
          child: Container(
            height: 32,
            color: ScColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
            child: Row(
              children: [
                const Icon(Icons.mic_none, size: 14, color: ScColors.textDim),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'TALKBACK',
                    style: TextStyle(
                      color: ScColors.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.expand_more, size: 16, color: ScColors.textDim),
                ),
              ],
            ),
          ),
        ),
        // Collapsible content
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: expanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: ScColors.divider),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TalkbackBar(
                        availableBusIds: busIds,
                        busNames: busNames,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Connection Banner ──────────────────────────────────────────────────────────

class _ConnectionBanner extends StatelessWidget {
  final ConnectionHealth health;
  final VoidCallback onLeave;

  const _ConnectionBanner({required this.health, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final isDisconnected = health == ConnectionHealth.disconnected;
    final color = isDisconnected ? ScColors.error : ScColors.warn;
    final label = isDisconnected
        ? 'Verbindung zum Server getrennt'
        : 'Verbindung wird wiederhergestellt…';
    final icon = isDisconnected ? Icons.cloud_off : Icons.cloud_sync;

    return Container(
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: ScText.statusSmall.copyWith(color: color)),
          ),
          if (isDisconnected)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
              ),
              onPressed: onLeave,
              child: const Text('Verlassen', style: TextStyle(fontSize: 12)),
            )
          else
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
        ],
      ),
    );
  }
}

// ── Transport Controls ─────────────────────────────────────────────────────────

class _TransportControls extends ConsumerStatefulWidget {
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
  ConsumerState<_TransportControls> createState() => _TransportControlsState();
}

class _TransportControlsState extends ConsumerState<_TransportControls> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _updateTimer();
  }

  @override
  void didUpdateWidget(_TransportControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playhead.needsTick != widget.playhead.needsTick) {
      _updateTimer();
    }
  }

  void _updateTimer() {
    if (widget.playhead.needsTick) {
      _ticker ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
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
    final elapsedMs = widget.playhead.effectiveNowMs() - started;
    final totalSeconds = (elapsedMs / 1000).floor().clamp(0, double.maxFinite.toInt());
    final m = totalSeconds ~/ 60;
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final showTimer = widget.playhead.startedServerMs != null &&
        (widget.playhead.isRunning || widget.playhead.isPaused);
    final audioStatus   = ref.watch(audioNodeProvider);
    final audioNotifier = ref.read(audioNodeProvider.notifier);
    final isAudioActive = audioStatus.state == AudioNodeState.connected;

    return Container(
      color: ScColors.surface,
      padding: const EdgeInsets.all(ScSpacing.panelPadLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Master Volume Slider ──────────────────────────────────────
          if (isAudioActive) ...[
            _MasterVolumeSlider(
              value: audioStatus.masterVolumeDb,
              onChanged: audioNotifier.setMasterVolume,
            ),
            const SizedBox(height: 12),
          ],

          // ── Elapsed timer ─────────────────────────────────────────────
          if (showTimer) ...[
            Text(_formatElapsed(), style: ScText.timer),
            const SizedBox(height: 8),
          ],
          // ── Large GO button ───────────────────────────────────────────
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
          // ── Secondary controls ────────────────────────────────────────
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
        ],
      ),
    );
  }
}

// Private alias so _TransportControlsState can reference it without import noise
class _MasterVolumeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _MasterVolumeSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) =>
      MasterVolumeSlider(value: value, onChanged: onChanged);
}
