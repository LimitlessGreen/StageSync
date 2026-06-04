import 'dart:async';

import 'package:flutter/material.dart';
import 'sc_shortcuts.dart';
import '../../../ui/widgets/talkback_bar.dart';
import '../../../ui/widgets/bus_config_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../design_system/primitives/sc_panel.dart';
import '../design_system/primitives/sc_split_view.dart';
import '../design_system/domain_components/transport_bar.dart';
import '../design_system/domain_components/cue_inspector.dart';
import '../design_system/domain_components/cue_list_panel.dart';
import '../design_system/sc_tick.dart';
import '../design_system/domain_components/active_cue_monitor.dart';
import '../design_system/domain_components/node_status_badge.dart';
import '../screens/nodes/node_management_panel.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/media/media_manager_screen.dart';
import '../screens/audio/local_audio_panel.dart';
import '../design_system/domain_components/patch_matrix.dart';
import '../../domain/patch_config.dart';

/// Full desktop shell: TransportBar top + three panels + tab bar.
class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell>
    with TickerProviderStateMixin {
  String? _selectedCueId;
  late TabController _tabController;
  late TabController _rightTabController;
  late final AppLifecycleListener _lifecycleListener;
  bool _bottomPanelOpen = false;
  int _lastOpenTab = 0;
  double _bottomPanelHeight = 320.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _rightTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showControlProvider.notifier).initialize();
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

  @override
  void dispose() {
    _tabController.dispose();
    _rightTabController.dispose();
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _selectOffset(int delta) {
    final cues = ref.read(showControlDomainProvider).cueList?.cues ?? [];
    if (cues.isEmpty) return;
    final idx = cues.indexWhere((c) => c.id == _selectedCueId);
    final next = (idx + delta).clamp(0, cues.length - 1);
    setState(() => _selectedCueId = cues[next].id);
  }

  @override
  Widget build(BuildContext context) {
    final domainState  = ref.watch(showControlDomainProvider);
    final sessionState = ref.watch(sessionProvider);
    final notifier     = ref.read(showControlProvider.notifier);

    // Override the noop nav/select/delete shortcuts with real desktop behavior.
    return ScTick(child: Actions(
      actions: {
        PrevCueIntent:   CallbackAction<PrevCueIntent>(onInvoke: (_) { _selectOffset(-1); return null; }),
        NextCueIntent:   CallbackAction<NextCueIntent>(onInvoke: (_) { _selectOffset(1); return null; }),
        SelectCueIntent: CallbackAction<SelectCueIntent>(onInvoke: (_) {
          if (_selectedCueId != null) notifier.goToCue(_selectedCueId!);
          return null;
        }),
        DeleteCueIntent: CallbackAction<DeleteCueIntent>(onInvoke: (_) {
          if (_selectedCueId != null) notifier.deleteCueById(_selectedCueId!);
          return null;
        }),
      },
      child: Scaffold(
      backgroundColor: ScColors.bg,
      body: Column(
        children: [
          // ── Header bar (session name + status chips + leave) ─────────
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
          // ── Connection banner ─────────────────────────────────────────
          if (sessionState.health != ConnectionHealth.connected)
            _ConnectionBanner(health: sessionState.health, onLeave: _leaveSession),
          // ── Transport Bar (always visible) ───────────────────────────
          TransportBar(
            playhead: domainState.playhead,
            cueList: domainState.cueList,
            onGo:    () => notifier.go(),
            onStop:  () => notifier.stop(),
            onPause: () => notifier.pause(),
            onResume: () => notifier.resume(),
          ),
          const Divider(height: 1, color: ScColors.divider),
          // ── Main two-panel area (Cue-Liste | Inspector + Monitor) ────
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
                  _rightTabController.animateTo(0); // Inspector-Tab
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
          // ── Bottom tab bar + expandable panel ────────────────────────
          const Divider(height: 1, color: ScColors.divider),
          if (_bottomPanelOpen) ...[
            // Drag handle — vertical resize
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
    ))); // ScTick + Actions + Scaffold
  }
}

// ── Header Bar ────────────────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioStatus = ref.watch(audioNodeProvider);
    final maStatus    = ref.watch(maNodeProvider);
    final tasks       = ref.watch(sessionProvider).myNode?.tasks.toList() ?? [];

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
          // Service status indicators — only shown when this device runs the service
          if (tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) ...[
            _ServiceStatusPill(
              icon: Icons.speaker,
              label: _audioLabel(audioStatus),
              sublabel: audioStatus.state == AudioNodeState.connected && audioStatus.playingCueIds.isNotEmpty
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
      s.errorMessage != null ? '${s.errorMessage}  ·  Klicken → Audio-Panel' : 'Fehler  ·  Klicken → Audio-Panel',
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

/// Minimaler Service-Status-Indikator im Header.
///
/// Normalzustand: Icon + farbiger Dot. Text nur bei Fehler.
/// Laufende Cues: kleiner Zähler als Badge.
/// Tap öffnet das zugehörige Panel.
class _ServiceStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;        // Wird NUR bei Fehler angezeigt
  final String? sublabel;    // z.B. "3♪" für laufende Cues
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
              // Status dot
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              // Text label — nur bei Fehler sichtbar
              if (isError) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              // Spielende-Cues-Zähler
              if (sublabel != null) ...[
                const SizedBox(width: 4),
                Text(
                  sublabel!,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Connection Banner ─────────────────────────────────────────────────────────

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

// ── Center Panel: Inspector ────────────────────────────────────────────────────

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
          child: Text(
            'Cue auswählen',
            style: TextStyle(color: ScColors.textDim),
          ),
        ),
      );
    }

    return CueInspector(cue: cue, notifier: notifier);
  }
}


// ── Right Area: Inspector + Monitor Tabs ──────────────────────────────────────

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

// ── Right Panel: Monitoring ────────────────────────────────────────────────────

class _MonitoringPanel extends StatelessWidget {
  final ShowControlDomainState domainState;

  const _MonitoringPanel({required this.domainState});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Node health strip
        Container(
          color: ScColors.surface,
          padding: const EdgeInsets.all(ScSpacing.panelPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NODES', style: ScText.panelTitle),
              const SizedBox(height: 8),
              NodeHealthStrip(
                nodes: domainState.nodes,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        // Active cue monitor
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

// ── Bottom Tab Panel (expandable content) ────────────────────────────────────

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
        _TalkbackPanel(domainState: domainState),
      ],
    );
  }
}

// ── Bottom Bar ─────────────────────────────────────────────────────────────────

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
              Tab(text: 'PATCH',     height: 36),
              Tab(text: 'MEDIA',     height: 36),
              Tab(text: 'NODES',     height: 36),
              Tab(text: 'AUDIO',     height: 36),
              Tab(text: 'TALKBACK',  height: 36),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _ClockInfo(),
          ),
        ],
      ),
    );
  }
}

class _ClockInfo extends StatelessWidget {
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

// ── Talkback Panel (Desktop Bottom Tab) ───────────────────────────────────────

class _TalkbackPanel extends ConsumerWidget {
  final ShowControlDomainState domainState;
  const _TalkbackPanel({required this.domainState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buses    = domainState.patchConfig.busesOfType(AudioBusType.talkback);
    final busIds   = buses.map((b) => b.id).toList();
    final busNames = {for (final b in buses) b.id: b.name};

    return Column(
      children: [
        // Bus-Verwaltung öffnen
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              const Text('Talkback-Routing',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 11, letterSpacing: 0.8)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showBusConfigSheet(context, ref),
                icon: const Icon(Icons.speaker_group_outlined, size: 16, color: Color(0xFF64B5F6)),
                label: const Text('Buses konfigurieren',
                    style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12)),
              ),
            ],
          ),
        ),
        // Talkback-Bar
        Padding(
          padding: const EdgeInsets.all(8),
          child: TalkbackBar(availableBusIds: busIds, busNames: busNames),
        ),
      ],
    );
  }
}

