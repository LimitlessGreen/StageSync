import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sc_shortcuts.dart';
import '../../../ui/widgets/talkback_bar.dart';
import '../../../ui/widgets/bus_config_sheet.dart';
import '../../providers/show_control_provider.dart';
import '../../providers/show_control_domain_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/audio_node_provider.dart';
import '../../providers/ma_node_provider.dart';
import '../../nodes/audio_node/audio_node_service.dart';
import '../../nodes/ma_node/ma_node_service.dart';
import '../../grpc/generated/stagesync/v1/common.pb.dart' show NodeTask;
import '../design_system/sc_colors.dart';
import '../design_system/sc_spacing.dart';
import '../design_system/sc_typography.dart';
import '../design_system/primitives/sc_button.dart';
import '../design_system/primitives/sc_panel.dart';
import '../design_system/primitives/sc_split_view.dart';
import '../design_system/domain_components/transport_bar.dart';
import '../design_system/domain_components/cue_inspector.dart';
import '../design_system/domain_components/cue_list_panel.dart';
import '../design_system/domain_components/cue_list_row.dart';
import '../design_system/domain_components/active_cue_monitor.dart';
import '../design_system/domain_components/active_cue_control_strip.dart';
import '../design_system/domain_components/active_next_cue_display.dart';
import '../design_system/domain_components/master_volume_slider.dart';
import '../design_system/domain_components/node_status_badge.dart';
import '../design_system/domain_components/patch_matrix.dart';
import '../design_system/domain_components/grid_view.dart';
import '../design_system/domain_components/cue_type_picker.dart';
import '../design_system/domain_components/sc_cue_detail_sheet.dart';
import '../design_system/domain_components/bulk_add_cues_dialog.dart';
import '../design_system/sc_tick.dart';
import '../screens/nodes/node_management_panel.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/media/media_manager_screen.dart';
import '../screens/audio/local_audio_panel.dart';
import '../../providers/embedded_server_provider.dart';
import '../../providers/standalone_bootstrap_provider.dart';
import '../../preferences/device_preferences.dart';
import '../../providers/grid_provider.dart';
import '../../domain/patch_config.dart';
import '../../domain/show.dart';
import '../../domain/cue_params.dart';
import '../../domain/playhead.dart';

/// Unified adaptive shell for Show-Control.
///
/// All state lives in one class. [_buildDesktopLayout] and [_buildMobileLayout]
/// arrange the same set of shared child widgets differently based on screen
/// width. Adding a new feature means editing this one file and explicitly
/// deciding where it appears on each form-factor.
class ScShell extends ConsumerStatefulWidget {
  const ScShell({super.key});

  @override
  ConsumerState<ScShell> createState() => _ScShellState();
}

class _ScShellState extends ConsumerState<ScShell>
    with TickerProviderStateMixin {
  // ── Desktop-specific state ────────────────────────────────────────────────
  String? _selectedCueId;
  late TabController _tabController;       // bottom panel tabs (6)
  late TabController _rightTabController;  // Inspector / Monitor
  bool _bottomPanelOpen = false;
  int _lastOpenTab = 0;
  double _bottomPanelHeight = 320.0;

  // ── Mobile-specific state ─────────────────────────────────────────────────
  bool _talkbackExpanded = false;

  // ── Shared ────────────────────────────────────────────────────────────────
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _tabController      = TabController(length: 6, vsync: this);
    _rightTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showControlProvider.notifier).initialize();
      ref.read(gridProvider.notifier).initialize();
      _handleAutoReconnectNodeStart();
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
    _tabController.dispose();
    _rightTabController.dispose();
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _handleAutoReconnectNodeStart() {
    final session = ref.read(sessionProvider);
    if (!session.needsNodeStart) return;
    ref.read(sessionProvider.notifier).clearNeedsNodeStart();
    final tasks = session.myNode?.tasks.toList() ?? [];
    if (tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) {
      ref.read(audioNodeProvider.notifier).startAudioNode();
    }
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

  void _selectOffset(int delta) {
    final cues = ref.read(showControlDomainProvider).cueList?.cues ?? [];
    if (cues.isEmpty) return;
    final idx  = cues.indexWhere((c) => c.id == _selectedCueId);
    final next = (idx + delta).clamp(0, cues.length - 1);
    setState(() => _selectedCueId = cues[next].id);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop    = MediaQuery.sizeOf(context).width >= ScSpacing.desktopBreakpoint;
    final domainState  = ref.watch(showControlDomainProvider);
    final sessionState = ref.watch(sessionProvider);
    final notifier     = ref.read(showControlProvider.notifier);

    return ScTick(
      child: Actions(
        // Desktop keyboard actions — no-ops on mobile (intents are already
        // registered as no-ops in ScAdaptiveShell; these override them).
        actions: isDesktop
            ? {
                PrevCueIntent:   CallbackAction<PrevCueIntent>(onInvoke:   (_) { _selectOffset(-1); return null; }),
                NextCueIntent:   CallbackAction<NextCueIntent>(onInvoke:   (_) { _selectOffset(1);  return null; }),
                SelectCueIntent: CallbackAction<SelectCueIntent>(onInvoke: (_) {
                  if (_selectedCueId != null) notifier.goToCue(_selectedCueId!);
                  return null;
                }),
                DeleteCueIntent: CallbackAction<DeleteCueIntent>(onInvoke: (_) {
                  if (_selectedCueId != null) notifier.deleteCueById(_selectedCueId!);
                  return null;
                }),
              }
            : {},
        child: isDesktop
            ? _buildDesktopLayout(context, domainState, sessionState, notifier)
            : _buildMobileLayout(context, domainState, sessionState, notifier),
      ),
    );
  }

  // ── Desktop Layout ────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
    BuildContext context,
    ShowControlDomainState domainState,
    SessionState sessionState,
    ShowControlNotifier notifier,
  ) {
    return Scaffold(
      backgroundColor: ScColors.bg,
      body: Column(
        children: [
          _HeaderBar(
            sessionName: sessionState.session?.name ?? 'Show Control',
            onLeave: _leaveSession,
            onOpenAudioPanel: () => setState(() {
              _bottomPanelOpen = true;
              _lastOpenTab = 3;
              _tabController.animateTo(3);
            }),
            onOpenNodesPanel: () => setState(() {
              _bottomPanelOpen = true;
              _lastOpenTab = 2;
              _tabController.animateTo(2);
            }),
          ),
          if (sessionState.health != ConnectionHealth.connected)
            _ConnectionBanner(health: sessionState.health, onLeave: _leaveSession),
          TransportBar(
            playhead: domainState.playhead,
            cueList: domainState.cueList,
            onGo:     () => notifier.go(),
            onStop:   () => notifier.stop(),
            onPause:  () => notifier.pause(),
            onResume: () => notifier.resume(),
          ),
          const Divider(height: 1, color: ScColors.divider),
          Expanded(
            child: ScSplitView(
              persistKey: 'desktop.mainSplit',
              initialFraction: 0.40,
              minFraction: 0.20,
              maxFraction: 0.65,
              left: CueListPanel(
                cueList: domainState.cueList,
                playhead: domainState.playhead,
                selectedCueId: _selectedCueId,
                onCueSelected: (id) {
                  setState(() => _selectedCueId = id);
                  _rightTabController.animateTo(0);
                },
                notifier: notifier,
              ),
              right: _RightPanel(
                tabController: _rightTabController,
                selectedCueId: _selectedCueId,
                domainState: domainState,
                notifier: notifier,
              ),
            ),
          ),
          const Divider(height: 1, color: ScColors.divider),
          if (_bottomPanelOpen) ...[
            GestureDetector(
              onPanUpdate: (d) => setState(() {
                _bottomPanelHeight =
                    (_bottomPanelHeight - d.delta.dy).clamp(160.0, 600.0);
              }),
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: Container(
                  height: 8,
                  color: ScColors.surface,
                  child: Center(
                    child: Container(
                      width: 40, height: 3,
                      decoration: BoxDecoration(
                        color: ScColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: _bottomPanelHeight,
              child: _BottomTabPanel(controller: _tabController),
            ),
            const Divider(height: 1, color: ScColors.divider),
          ],
          _BottomBar(
            controller: _tabController,
            onTabTap: (i) => setState(() {
              if (_bottomPanelOpen && _lastOpenTab == i) {
                _bottomPanelOpen = false;
              } else {
                _bottomPanelOpen = true;
                _lastOpenTab = i;
              }
            }),
          ),
        ],
      ),
    );
  }

  // ── Mobile Layout ─────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
    BuildContext context,
    ShowControlDomainState domainState,
    SessionState sessionState,
    ShowControlNotifier notifier,
  ) {
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
      onGo:     () => notifier.go(),
      onStop:   () => notifier.stop(),
      onPause:  () => notifier.pause(),
      onResume: () => notifier.resume(),
    );

    return Scaffold(
      backgroundColor: ScColors.bg,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (ctx, orientation) {
            if (orientation == Orientation.landscape) {
              return Column(
                children: [
                  statusStrip,
                  if (connectionBanner != null) connectionBanner,
                  Expanded(
                    child: Row(
                      children: [
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

            // Portrait
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

// ═══════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _ConnectionBanner extends StatelessWidget {
  final ConnectionHealth health;
  final VoidCallback onLeave;

  const _ConnectionBanner({required this.health, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final isDisconnected = health == ConnectionHealth.disconnected;
    final color  = isDisconnected ? ScColors.error : ScColors.warn;
    final label  = isDisconnected
        ? 'Verbindung zum Server getrennt'
        : 'Verbindung wird wiederhergestellt…';

    return Container(
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            isDisconnected ? Icons.cloud_off : Icons.cloud_sync,
            size: 14, color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: ScText.label.copyWith(color: color)),
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
              width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Desktop-specific widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _HeaderBar extends ConsumerWidget {
  final String sessionName;
  final VoidCallback onLeave;
  final VoidCallback onOpenAudioPanel;
  final VoidCallback onOpenNodesPanel;

  const _HeaderBar({
    required this.sessionName,
    required this.onLeave,
    required this.onOpenAudioPanel,
    required this.onOpenNodesPanel,
  });

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const SettingsScreen(),
    ));
  }

  void _showShareDialog(BuildContext context, WidgetRef ref) {
    final session   = ref.read(sessionProvider).session;
    final port      = ref.read(embeddedPortProvider);
    final sessionId = session?.sessionId ?? '—';
    final sessionName = session?.name ?? '—';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share_outlined, size: 20),
            SizedBox(width: 8),
            Text('Session teilen'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Andere Geräte im Netz können dieser Session beitreten:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _ShareInfoRow(label: 'Session', value: sessionName),
            _ShareInfoRow(label: 'Port', value: '$port'),
            _ShareInfoRow(label: 'Session-ID', value: sessionId),
            const SizedBox(height: 8),
            const Text(
              'Tipp: Der Server kündigt sich via mDNS an — andere StageSync-Geräte '
              'finden ihn automatisch über "Im Netz suchen".',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showSwitchSessionDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _SwitchSessionDialog(onLeave: onLeave),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioStatus  = ref.watch(audioNodeProvider);
    final maStatus     = ref.watch(maNodeProvider);
    final tasks        = ref.watch(sessionProvider).myNode?.tasks.toList() ?? [];
    final isStandalone = ref.watch(isStandaloneSupportedProvider);

    return Container(
      height: 36,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.theater_comedy, size: 14, color: ScColors.textDim),
          const SizedBox(width: 8),
          Text(sessionName, style: ScText.panelTitle),
          const Spacer(),
          if (tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) ...[
            _ServiceStatusPill(
              icon: Icons.speaker,
              label: _audioLabel(audioStatus),
              sublabel: audioStatus.state == AudioNodeState.connected &&
                      audioStatus.playingCueIds.isNotEmpty
                  ? '${audioStatus.playingCueIds.length}♪'
                  : null,
              color: _audioColor(audioStatus),
              tooltip: _audioTooltip(audioStatus),
              onTap: onOpenAudioPanel,
            ),
            const SizedBox(width: 8),
          ],
          if (tasks.contains(NodeTask.NODE_TASK_MA_OSC)) ...[
            _ServiceStatusPill(
              icon: Icons.tune,
              label: _maLabel(maStatus),
              color: _maColor(maStatus),
              tooltip: _maTooltip(maStatus),
              onTap: onOpenNodesPanel,
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.settings, size: 16),
            color: ScColors.textDim,
            tooltip: 'Einstellungen',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _openSettings(context),
          ),
          // Standalone: Share + Switch; Remote: nur Logout.
          if (isStandalone) ...[
            IconButton(
              icon: const Icon(Icons.group_add_outlined, size: 16),
              color: ScColors.textDim,
              tooltip: 'Session teilen — andere Geräte einladen',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _showShareDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 16),
              color: ScColors.textDim,
              tooltip: 'Andere Session verbinden',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _showSwitchSessionDialog(context, ref),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.logout, size: 16),
              color: ScColors.textDim,
              tooltip: 'Session verlassen',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onLeave,
            ),
        ],
      ),
    );
  }

  static String _audioLabel(AudioNodeStatus s) => switch (s.state) {
    AudioNodeState.connected => 'Wiedergabe bereit',
    AudioNodeState.error     => 'Audio-Fehler',
    _                        => 'Audio gestoppt',
  };

  static Color _audioColor(AudioNodeStatus s) => switch (s.state) {
    AudioNodeState.connected => ScColors.active,
    AudioNodeState.error     => ScColors.error,
    _                        => ScColors.textDim,
  };

  static String _audioTooltip(AudioNodeStatus s) => switch (s.state) {
    AudioNodeState.connected =>
      s.selectedDevice != null
          ? 'Ausgang: ${s.selectedDevice!.name}  ·  Klicken → Audio-Panel'
          : 'Audio-Engine läuft  ·  Klicken → Audio-Panel',
    AudioNodeState.error =>
      s.errorMessage != null
          ? '${s.errorMessage}  ·  Klicken → Audio-Panel'
          : 'Fehler  ·  Klicken → Audio-Panel',
    _ => 'Audio-Engine ist nicht gestartet  ·  Klicken → Audio-Panel',
  };

  static String _maLabel(MaNodeStatus s) => switch (s.state) {
    MaNodeState.connected => 'MA verbunden',
    MaNodeState.error     => 'MA-Fehler',
    _                     => 'MA getrennt',
  };

  static Color _maColor(MaNodeStatus s) => switch (s.state) {
    MaNodeState.connected => ScColors.active,
    MaNodeState.error     => ScColors.error,
    _                     => ScColors.textDim,
  };

  static String _maTooltip(MaNodeStatus s) => switch (s.state) {
    MaNodeState.connected => 'GrandMA OSC verbunden  ·  Klicken → Nodes-Panel',
    MaNodeState.error     => 'GrandMA OSC Verbindungsfehler  ·  Klicken → Nodes-Panel',
    _                     => 'GrandMA OSC nicht verbunden  ·  Klicken → Nodes-Panel',
  };
}

// ── Share-Dialog Helper ───────────────────────────────────────────────────────

class _ShareInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _ShareInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text('$label:',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      );
}

// ── Switch-Session-Dialog ─────────────────────────────────────────────────────

class _SwitchSessionDialog extends ConsumerStatefulWidget {
  final VoidCallback onLeave;
  const _SwitchSessionDialog({required this.onLeave});

  @override
  ConsumerState<_SwitchSessionDialog> createState() => _SwitchSessionDialogState();
}

class _SwitchSessionDialogState extends ConsumerState<_SwitchSessionDialog> {
  final _hostCtrl = TextEditingController(text: '');
  final _portCtrl = TextEditingController(text: '50051');
  String? _error;

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 50051;
    if (host.isEmpty) {
      setState(() => _error = 'IP-Adresse eingeben.');
      return;
    }
    // Host/Port in Preferences speichern — SessionScreen liest sie beim Start.
    // deviceName aus bestehenden Prefs übernehmen um ihn nicht zu löschen.
    final existing = await DevicePreferences.loadConnectDefaults();
    await DevicePreferences.saveConnectDefaults(
        host: host, port: port, deviceName: existing.deviceName);
    if (!mounted) return;
    // Dialog schließen, dann Session verlassen.
    // _StandaloneBootstrapScreen erkennt !isInSession und zeigt SessionScreen.
    Navigator.pop(context);
    widget.onLeave();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.swap_horiz, size: 20),
            SizedBox(width: 8),
            Text('Andere Session verbinden'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Verlässt die lokale Standalone-Session und öffnet die Verbindungsansicht '
              'für einen Remote-Server.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hostCtrl,
                    decoration: const InputDecoration(
                      labelText: 'IP-Adresse (optional)',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _portCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: _connect,
            child: const Text('Weiter'),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _ServiceStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ServiceStatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    final isError = color == ScColors.error;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (isError) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
              if (sublabel != null) ...[
                const SizedBox(width: 4),
                Text(
                  sublabel!,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InspectorPanel extends ConsumerWidget {
  final String? selectedCueId;
  final ShowControlDomainState domainState;
  final ShowControlNotifier notifier;

  const _InspectorPanel({
    required this.selectedCueId,
    required this.domainState,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cue = selectedCueId != null
        ? domainState.cueList?.cueById(selectedCueId!)
        : null;

    if (cue == null) {
      return Container(
        color: ScColors.surface,
        child: Center(
          child: Text('Cue auswählen', style: TextStyle(color: ScColors.textDim)),
        ),
      );
    }
    return CueInspector(cue: cue, notifier: notifier);
  }
}

class _RightPanel extends StatelessWidget {
  final TabController tabController;
  final String? selectedCueId;
  final ShowControlDomainState domainState;
  final ShowControlNotifier notifier;

  const _RightPanel({
    required this.tabController,
    required this.selectedCueId,
    required this.domainState,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 36,
          color: ScColors.surface,
          child: TabBar(
            controller: tabController,
            dividerHeight: 0,
            indicatorColor: ScColors.active,
            labelColor: ScColors.active,
            unselectedLabelColor: ScColors.textDim,
            labelStyle: ScText.labelBold,
            unselectedLabelStyle: ScText.label,
            tabs: const [
              Tab(text: 'INSPECTOR', height: 36),
              Tab(text: 'MONITOR',   height: 36),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        Expanded(
          child: TabBarView(
            controller: tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _InspectorPanel(
                selectedCueId: selectedCueId,
                domainState: domainState,
                notifier: notifier,
              ),
              _MonitoringPanel(domainState: domainState),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonitoringPanel extends StatelessWidget {
  final ShowControlDomainState domainState;
  const _MonitoringPanel({required this.domainState});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: ScColors.surface,
          padding: const EdgeInsets.all(ScSpacing.panelPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NODES', style: ScText.panelTitle),
              const SizedBox(height: 8),
              NodeHealthStrip(nodes: domainState.nodes),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        Expanded(
          child: ScPanel(
            title: 'Aktiver Cue',
            child: ActiveCueMonitor(
              playhead: domainState.playhead,
              cueList: domainState.cueList,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomTabPanel extends ConsumerWidget {
  final TabController controller;
  const _BottomTabPanel({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainState = ref.watch(showControlDomainProvider);
    final notifier    = ref.read(showControlProvider.notifier);

    return TabBarView(
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PatchMatrix(
          config: domainState.patchConfig,
          nodes: domainState.nodes,
          onChanged: (updated) => notifier.updatePatchConfig(updated),
        ),
        const MediaManagerScreen(),
        const NodeManagementPanel(),
        const LocalAudioPanel(),
        _DesktopTalkbackPanel(domainState: domainState),
        const Padding(padding: EdgeInsets.all(8), child: ScGridView()),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final TabController controller;
  final ValueChanged<int> onTabTap;

  const _BottomBar({required this.controller, required this.onTabTap});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ScColors.surface,
      child: Row(
        children: [
          TabBar(
            controller: controller,
            isScrollable: true,
            dividerHeight: 0,
            indicatorColor: ScColors.active,
            labelColor: ScColors.active,
            unselectedLabelColor: ScColors.textDim,
            labelStyle: ScText.labelBold,
            unselectedLabelStyle: ScText.label,
            tabAlignment: TabAlignment.start,
            onTap: onTabTap,
            tabs: const [
              Tab(text: 'PATCH',    height: 36),
              Tab(text: 'MEDIA',    height: 36),
              Tab(text: 'NODES',    height: 36),
              Tab(text: 'AUDIO',    height: 36),
              Tab(text: 'TALKBACK', height: 36),
              Tab(text: 'GRID',     height: 36),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _KeyboardHints(),
          ),
        ],
      ),
    );
  }
}

class _KeyboardHints extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _hint('Space', 'GO'),
        const SizedBox(width: 12),
        _hint('Esc', 'STOP'),
        const SizedBox(width: 12),
        _hint('P', 'PAUSE'),
        const SizedBox(width: 12),
        _hint('↑↓', 'Nav'),
        const SizedBox(width: 12),
        _hint('Del', 'DEL'),
      ],
    );
  }

  Widget _hint(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: ScColors.divider),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(key, style: ScText.statusSmall),
        ),
        const SizedBox(width: 3),
        Text(label, style: ScText.statusSmall),
      ],
    );
  }
}

class _DesktopTalkbackPanel extends ConsumerWidget {
  final ShowControlDomainState domainState;
  const _DesktopTalkbackPanel({required this.domainState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buses    = domainState.patchConfig.busesOfType(AudioBusType.talkback);
    final busIds   = buses.map((b) => b.id).toList();
    final busNames = {for (final b in buses) b.id: b.name};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              const Text(
                'Talkback-Routing',
                style: TextStyle(color: Color(0xFF888888), fontSize: 11, letterSpacing: 0.8),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showBusConfigSheet(context, ref),
                icon: const Icon(Icons.speaker_group_outlined, size: 16, color: Color(0xFF64B5F6)),
                label: const Text(
                  'Buses konfigurieren',
                  style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: TalkbackBar(availableBusIds: busIds, busNames: busNames),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Mobile-specific widgets
// ═══════════════════════════════════════════════════════════════════════════════

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
        title: const Text(
          'Session verlassen?',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: const Text(
          'Dieses Gerät verlässt die Session. Der Server und laufende Cues bleiben aktiv.',
          style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('Abbrechen', style: TextStyle(color: Color(0xFFB0B0B0))),
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
            icon: const Icon(Icons.library_music_outlined, size: 16),
            color: ScColors.textDim,
            tooltip: 'Medienbibliothek',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => Navigator.of(shellContext).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: ScColors.bg,
                  appBar: AppBar(
                    backgroundColor: ScColors.surface,
                    foregroundColor: ScColors.textPrimary,
                    title: const Text('Medienbibliothek',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    elevation: 0,
                  ),
                  body: const MediaManagerScreen(),
                ),
              ),
            ),
          ),
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

class _MobileCueList extends ConsumerStatefulWidget {
  final CueList? cueList;
  final PlayheadState playhead;
  final ShowControlNotifier notifier;

  const _MobileCueList({
    required this.cueList,
    required this.playhead,
    required this.notifier,
  });

  @override
  ConsumerState<_MobileCueList> createState() => _MobileCueListState();
}

class _MobileCueListState extends ConsumerState<_MobileCueList> {
  final ScrollController _scrollController = ScrollController();
  String? _lastActiveCueId;
  List<String>? _pendingOrder;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MobileCueList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cueList?.cues != oldWidget.cueList?.cues) {
      _pendingOrder = null;
    }
    final newActiveId = widget.playhead.activeCueId;
    if (newActiveId != null && newActiveId != _lastActiveCueId) {
      _lastActiveCueId = newActiveId;
      _scrollToActive(newActiveId);
    }
  }

  Future<void> _addCue(BuildContext context) async {
    final params = await showCueTypePicker(context);
    if (params == null || !mounted) return;
    final cue = await widget.notifier.addCue(params: params);
    if (cue != null && mounted) {
      // ignore: use_build_context_synchronously
      await showCueDetailSheet(context, cue, widget.notifier);
    }
  }

  void _scrollToActive(String activeId) {
    final cues = widget.cueList?.cues;
    if (cues == null) return;
    final activeIdx = cues.indexWhere((c) => c.id == activeId);
    if (activeIdx < 0) return;
    final offset = activeIdx * ScSpacing.rowHeight;
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
    return Column(
      children: [
        Container(
          height: 36,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'CUE LIST',
                  style: TextStyle(
                    color: ScColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Builder(
                builder: (btnCtx) => IconButton(
                  icon: const Icon(Icons.playlist_add, size: 18),
                  color: ScColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Mehrere Cues hinzufügen',
                  onPressed: () => showBulkAddCuesDialog(btnCtx, ref),
                ),
              ),
              Builder(
                builder: (btnCtx) => IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: ScColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Cue hinzufügen',
                  onPressed: () => _addCue(btnCtx),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        if (widget.cueList == null)
          Expanded(
            child: Center(
              child: Text('Keine CueList', style: TextStyle(color: ScColors.textDim)),
            ),
          )
        else
          Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    final allCues = widget.cueList!.cues;
    final orderedCues = _pendingOrder != null
        ? _pendingOrder!
            .map((id) => allCues.firstWhere((c) => c.id == id,
                orElse: () => allCues.first))
            .where((c) => allCues.any((a) => a.id == c.id))
            .toList()
        : allCues;

    final activeIdx = widget.playhead.activeCueId != null
        ? orderedCues.indexWhere((c) => c.id == widget.playhead.activeCueId)
        : -1;

    return ReorderableListView.builder(
      scrollController: _scrollController,
      buildDefaultDragHandles: false,
      itemCount: orderedCues.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final ids = orderedCues.map((c) => c.id).toList();
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        setState(() => _pendingOrder = ids);
        widget.notifier.reorderCue(orderedIds: ids);
      },
      proxyDecorator: (child, _, __) => Material(
        elevation: 4,
        color: ScColors.surface2,
        borderRadius: BorderRadius.circular(4),
        child: child,
      ),
      itemBuilder: (context, i) {
        final cue       = orderedCues[i];
        final isRunning = widget.playhead.runningCueIds.contains(cue.id);
        final isActive  = widget.playhead.activeCueId == cue.id;
        final isPast    = !isRunning && activeIdx >= 0 && i < activeIdx;

        final cueRow = CueListRow(
          key: ValueKey('row_${cue.id}'),
          cue: cue,
          runState: widget.playhead.runStateFor(cue.id),
          playhead: widget.playhead,
          isActive: isActive,
          isPast: isPast,
          expanded: isRunning,
          showDragHandle: false,
          onTap: () => widget.notifier.goToCue(cue.id),
        );

        final row = _SwipeActionsRow(
          key: ValueKey('swipe_${cue.id}'),
          onEdit:   () => showCueDetailSheet(context, cue, widget.notifier),
          onDelete: () {
            widget.notifier.deleteCueById(cue.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cue "${cue.label.isNotEmpty ? cue.label : cue.number}" gelöscht',
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: ScColors.surface2,
                action: SnackBarAction(
                  label: 'Rückgängig',
                  textColor: ScColors.active,
                  onPressed: () {},
                ),
              ),
            );
          },
          child: ReorderableDelayedDragStartListener(
            index: i,
            child: cueRow,
          ),
        );

        final showStrip = isRunning && cue.params is AudioParams;
        return Column(
          key: ValueKey(cue.id),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row,
            if (showStrip)
              ActiveCueControlStrip(
                key: ValueKey('strip_${cue.id}'),
                cue: cue,
                playhead: widget.playhead,
                onFadeUp:  (ms) => widget.notifier.fadeUpAudio(cue.id, durationMs: ms),
                onFadeOut: (ms) => widget.notifier.fadeOutAudio(cue.id, durationMs: ms),
                onStop:    ()   => widget.notifier.stopCueAudio(cue.id),
                onPause:   ()   => widget.notifier.pauseCueAudio(cue.id),
                onResume:  ()   => widget.notifier.resumeCueAudio(cue.id),
                onFadeDurationSaved: (ms) {
                  if (cue.params case AudioParams p) {
                    widget.notifier.upsertDomainCue(cue.copyWith(
                      params: p.copyWith(fadeInMs: ms, fadeOutMs: ms),
                    ));
                  }
                },
              ),
          ],
        );
      },
    );
  }
}

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
                      child: TalkbackBar(availableBusIds: busIds, busNames: busNames),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

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
    final elapsedMs     = widget.playhead.effectiveNowMs() - started;
    final totalSeconds  = (elapsedMs / 1000).floor().clamp(0, double.maxFinite.toInt());
    final m = totalSeconds ~/ 60;
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final showTimer      = widget.playhead.startedServerMs != null &&
        (widget.playhead.isRunning || widget.playhead.isPaused);
    final audioStatus    = ref.watch(audioNodeProvider);
    final audioNotifier  = ref.read(audioNodeProvider.notifier);
    final isAudioActive  = audioStatus.state == AudioNodeState.connected;

    return Container(
      color: ScColors.surface,
      padding: const EdgeInsets.all(ScSpacing.panelPadLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAudioActive) ...[
            MasterVolumeSlider(
              value: audioStatus.masterVolumeDb,
              onChanged: audioNotifier.setMasterVolume,
            ),
            const SizedBox(height: 12),
          ],
          if (showTimer) ...[
            Text(_formatElapsed(), style: ScText.timer),
            const SizedBox(height: 8),
          ],
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

// Swipe-to-reveal Edit / Delete actions.
// Swipe left → reveals buttons. Long-press events pass through so
// ReorderableDelayedDragStartListener still works.
class _SwipeActionsRow extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SwipeActionsRow({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SwipeActionsRow> createState() => _SwipeActionsRowState();
}

class _SwipeActionsRowState extends State<_SwipeActionsRow>
    with SingleTickerProviderStateMixin {
  static const _panelWidth     = 116.0;
  static const _snapThreshold  = _panelWidth * 0.35;

  late final AnimationController _ctrl;
  late Animation<double> _anim;
  double _dragStart      = 0;
  double _dragBaseOffset = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _anim = Tween(begin: 0.0, end: 0.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _currentOffset => _anim.value;

  void _animateTo(double target) {
    _anim = Tween(begin: _currentOffset, end: target)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_ctrl);
    _ctrl.forward(from: 0);
  }

  void _close() => _animateTo(0);
  void _open()  => _animateTo(-_panelWidth);

  void _onHorizontalDragStart(DragStartDetails d) {
    _ctrl.stop();
    _dragStart      = d.globalPosition.dx;
    _dragBaseOffset = _currentOffset;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    final delta = d.globalPosition.dx - _dragStart;
    final raw   = (_dragBaseOffset + delta).clamp(-_panelWidth, 0.0);
    _anim = AlwaysStoppedAnimation(raw);
    setState(() {});
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -300) {
      _open();
    } else if (v > 300) {
      _close();
    } else if (_currentOffset < -_snapThreshold) {
      _open();
    } else {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final offset = _anim.value;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart:  _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd:    _onHorizontalDragEnd,
          onTap: offset < -4 ? _close : null,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () { _close(); widget.onEdit(); },
                        child: Container(
                          width: 58,
                          color: ScColors.active.withValues(alpha: 0.85),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                              SizedBox(height: 2),
                              Text(
                                'Bearbeiten',
                                style: TextStyle(
                                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () { _close(); widget.onDelete(); },
                        child: Container(
                          width: 58,
                          color: ScColors.error,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline, color: Colors.white, size: 20),
                              SizedBox(height: 2),
                              Text(
                                'Löschen',
                                style: TextStyle(
                                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: Offset(offset, 0),
                  child: ColoredBox(color: ScColors.bg, child: widget.child),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
