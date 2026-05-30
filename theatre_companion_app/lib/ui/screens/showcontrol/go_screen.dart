import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import '../../../showcontrol/grpc/generated/stagesync/v1/showcontrol.pb.dart';
import '../../../showcontrol/nodes/audio_node/audio_node_service.dart';
import '../../../showcontrol/nodes/ma_node/ma_node_service.dart';
import '../../../showcontrol/providers/audio_node_provider.dart';
import '../../../showcontrol/providers/ma_node_provider.dart';
import '../../../showcontrol/providers/session_provider.dart';
import '../../../showcontrol/providers/show_control_provider.dart';
import '../../../showcontrol/session/clock_sync.dart';
import 'audio_engineer_screen.dart';
import 'cue_list_editor_screen.dart';
import 'network_debug_screen.dart';

// ── Farben ────────────────────────────────────────────────────────────────────
const _green = Color(0xFF00E676);
const _amber = Color(0xFFFFAB00);
const _dimText = Color(0xFF555555);
const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF141414);

class GoScreen extends ConsumerStatefulWidget {
  const GoScreen({super.key});

  @override
  ConsumerState<GoScreen> createState() => _GoScreenState();
}

class _GoScreenState extends ConsumerState<GoScreen> {
  final _scrollCtrl = ScrollController();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showControlProvider.notifier).initialize();
      _handleAutoReconnectNodeStart();
    });
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// 50 ms Ticker → fließende Progress-Balken, server-synchronisiert.
  void _startTicker() {
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() {});
    });
  }

  /// Verstrichene Millisekunden, abgeleitet aus Server-Startzeit.
  /// Alle Geräte zeigen denselben Wert.
  int _elapsedMs(ShowControlState show) {
    final startMs = show.activeCueStartedServerMs;
    if (startMs == null || show.activeCue == null) return 0;
    final endMs = show.pausedAtServerMs ?? ClockSync.instance.serverNow();
    final ms = endMs - startMs;
    return ms <= 0 ? 0 : ms;
  }

  void _handleAutoReconnectNodeStart() {
    final session = ref.read(sessionProvider);
    if (!session.needsNodeStart) return;
    ref.read(sessionProvider.notifier).clearNeedsNodeStart();

    final tasks = session.myNode?.tasks.toList() ?? <NodeTask>[];
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

  void _scrollToActive(List<Cue> cues, String? activeCueId) {
    if (activeCueId == null) return;
    final idx = cues.indexWhere((c) => c.cueId == activeCueId);
    if (idx < 0) return;
    const itemH = 64.0;
    final target = (idx * itemH) - 120;
    _scrollCtrl.animateTo(
      target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final show = ref.watch(showControlProvider);
    final tasks = session.myNode?.tasks.toList() ?? <NodeTask>[];
    final audioStatus = ref.watch(audioNodeProvider);
    final maStatus = ref.watch(maNodeProvider);

    // Cue-Wechsel → zur aktiven Cue scrollen (Zeit kommt aus der Server-Startzeit)
    ref.listen<ShowControlState>(showControlProvider, (prev, next) {
      if (prev?.activeCue?.cueId != next.activeCue?.cueId) {
        if (show.cueList != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToActive(show.cueList!.cues, next.activeCue?.cueId);
          });
        }
      }
    });

    final elapsedMs = _elapsedMs(show);

    final cues = show.cueList?.cues ?? [];
    final activeIdx = cues.indexWhere((c) => c.cueId == show.activeCue?.cueId);
    final progress = cues.isEmpty ? 0.0 : (activeIdx + 1) / cues.length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context, session, show, tasks, audioStatus, maStatus),
      body: Column(
        children: [
          // ── Verbindungs-Banner ─────────────────────────────────────────────
          if (session.isDisconnected || session.isReconnecting)
            _ConnectionBanner(health: session.health, onLeave: _leaveSession),

          // ── Gesamtfortschritt ──────────────────────────────────────────────
          _ProgressHeader(
            progress: progress,
            activeIdx: activeIdx,
            total: cues.length,
            showName: session.session?.showName ?? '',
          ),

          // ── Fahrplanscroller ───────────────────────────────────────────────
          Expanded(
            child: cues.isEmpty
                ? Center(
                    child: Text(
                      show.isLoading ? 'Lade Cue-Liste…' : 'Keine Cues vorhanden',
                      style: const TextStyle(color: _dimText),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cues.length,
                    itemBuilder: (ctx, i) {
                      final cue = cues[i];
                      final isActive = cue.cueId == show.activeCue?.cueId;
                      final isPast = activeIdx >= 0 && i < activeIdx;
                      return _CueRow(
                        cue: cue,
                        isActive: isActive,
                        isPast: isPast,
                        elapsedMs: isActive ? elapsedMs : 0,
                        isPaused: show.isPaused,
                        onTap: () => ref.read(showControlProvider.notifier).go(cueId: cue.cueId),
                      );
                    },
                  ),
          ),

          // ── GO-Button ──────────────────────────────────────────────────────
          _GoButton(
            isLoading: show.isLoading,
            isPaused: show.isPaused,
            onGo: show.isPaused
                ? () => ref.read(showControlProvider.notifier).resume()
                : () => ref.read(showControlProvider.notifier).go(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    SessionState session,
    ShowControlState show,
    List<NodeTask> tasks,
    AudioNodeStatus audioStatus,
    MaNodeStatus maStatus,
  ) {
    return AppBar(
      backgroundColor: _surface,
      foregroundColor: Colors.white,
      title: Text(
        session.session?.name ?? 'Show Control',
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      actions: [
        if (tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT))
          _AudioStatusChip(audioStatus),
        if (tasks.contains(NodeTask.NODE_TASK_MA_OSC))
          _MaStatusChip(maStatus),
        if (show.activeCue != null) ...[
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
            tooltip: 'Stop',
            onPressed: () => ref.read(showControlProvider.notifier).stop(),
          ),
          IconButton(
            icon: Icon(
              show.isPaused ? Icons.play_circle_outline : Icons.pause_circle_outlined,
              color: _amber,
            ),
            tooltip: show.isPaused ? 'Fortsetzen' : 'Pause',
            onPressed: show.isPaused
                ? () => ref.read(showControlProvider.notifier).resume()
                : () => ref.read(showControlProvider.notifier).pause(),
          ),
        ],
        if (session.myNode?.nodeType == NodeType.NODE_TYPE_MASTER ||
            session.myNode?.nodeRole == NodeRole.NODE_ROLE_BACKUP ||
            (session.myNode?.tasks.contains(NodeTask.NODE_TASK_MASTER) ?? false) ||
            (session.myNode?.tasks.contains(NodeTask.NODE_TASK_EDITOR) ?? false))
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.white70),
            tooltip: 'CueList-Editor',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CueListEditorScreen()),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.equalizer, color: Colors.white70),
          tooltip: 'Audio-Ingenieur',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AudioEngineerScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.network_check, color: Colors.white70),
          tooltip: 'Netzwerk-Debug',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NetworkDebugScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white38),
          tooltip: 'Session verlassen',
          onPressed: _leaveSession,
        ),
      ],
    );
  }
}

// ── Gesamtfortschritt ─────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final double progress;
  final int activeIdx;
  final int total;
  final String showName;

  const _ProgressHeader({
    required this.progress,
    required this.activeIdx,
    required this.total,
    required this.showName,
  });

  @override
  Widget build(BuildContext context) {
    final progressLabel = total == 0
        ? 'Bereit'
        : activeIdx < 0
            ? '$total Cues'
            : 'Cue ${activeIdx + 1} / $total';

    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progressLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)} %',
                style: const TextStyle(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cue-Zeile (Fahrplanscroller) ──────────────────────────────────────────────

class _CueRow extends StatelessWidget {
  final Cue cue;
  final bool isActive;
  final bool isPast;
  final int elapsedMs;
  final bool isPaused;
  final VoidCallback onTap;

  const _CueRow({
    required this.cue,
    required this.isActive,
    required this.isPast,
    required this.elapsedMs,
    required this.isPaused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final numberColor = isActive
        ? _green
        : isPast
            ? _dimText
            : Colors.white38;
    final labelColor = isActive
        ? Colors.white
        : isPast
            ? _dimText
            : Colors.white70;

    final typeColor = _typeColorFor(cue);
    final durationMs = _cueDurationMs(cue);
    final fraction = durationMs != null && durationMs > 0
        ? (elapsedMs / durationMs).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isActive ? 80 : 56,
        child: Stack(
          children: [
            // QLab-style: type-colored background sweep
            if (isActive && fraction > 0)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: Container(
                    color: typeColor.withValues(alpha: isPaused ? 0.06 : 0.09),
                  ),
                ),
              ),
            // Left accent bar
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 3,
                color: isActive
                    ? (isPaused ? _amber : typeColor)
                    : Colors.transparent,
              ),
            ),
            // Bottom progress line
            if (isActive && durationMs != null)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    isPaused ? _amber : typeColor,
                  ),
                  minHeight: 2,
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Number
                  SizedBox(
                    width: 44,
                    child: Text(
                      cue.number,
                      style: TextStyle(
                        color: numberColor,
                        fontSize: isActive ? 18 : 14,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Type icon
                  SizedBox(
                    width: 20,
                    child: Icon(
                      _typeIcon(cue),
                      size: 14,
                      color: isActive ? typeColor : (isPast ? _dimText : Colors.white24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Label + countdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cue.label.isEmpty ? '—' : cue.label,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: isActive ? 15 : 14,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                            decorationColor: _dimText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isActive)
                          _CountdownRow(
                            elapsedMs: elapsedMs,
                            durationMs: durationMs,
                            fraction: fraction,
                            isPaused: isPaused,
                            typeColor: typeColor,
                          ),
                      ],
                    ),
                  ),
                  // Duration label
                  _DurationLabel(cue: cue, isActive: isActive, isPast: isPast),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(Cue c) => switch (c.cueType.value) {
        2 => Icons.volume_up,
        3 => Icons.light_mode,
        4 => Icons.timer_outlined,
        5 => Icons.skip_next,
        _ => Icons.play_arrow,
      };

  Color _typeColorFor(Cue c) => switch (c.cueType.value) {
        2 => const Color(0xFF1E88E5), // audio: blue
        3 => const Color(0xFFF4511E), // MA: orange
        4 => const Color(0xFF8E24AA), // wait: purple
        5 => const Color(0xFF00ACC1), // goto: cyan
        _ => _green,
      };

  double? _cueDurationMs(Cue c) {
    if (c.cueType.value == 4 && c.hasWait()) return c.wait.durationMs;
    if (c.cueType.value == 2 && c.hasAudio()) {
      final end = c.audio.endTimeMs;
      final start = c.audio.startTimeMs;
      if (end > start && end > 0) return end - start;
      final declared = c.audio.declaredDurationMs;
      if (declared > 0) return declared;
    }
    return null;
  }
}

// ── Countdown row (shown below label for active cue) ─────────────────────────

class _CountdownRow extends StatelessWidget {
  final int elapsedMs;
  final double? durationMs;
  final double fraction;
  final bool isPaused;
  final Color typeColor;

  const _CountdownRow({
    required this.elapsedMs,
    required this.durationMs,
    required this.fraction,
    required this.isPaused,
    required this.typeColor,
  });

  static String _fmtMs(double ms) {
    if (ms <= 0) return '0.0s';
    if (ms < 1000) return '${(ms / 1000).toStringAsFixed(1)}s';
    final s = ms / 1000;
    if (s < 60) return '${s.toStringAsFixed(1)}s';
    final m = s ~/ 60;
    final rs = (s % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$rs';
  }

  @override
  Widget build(BuildContext context) {
    final color = isPaused ? _amber : typeColor;

    if (durationMs == null) {
      // No known duration — show elapsed in dim style (not a "happy counting" timer)
      final elapsed = elapsedMs / 1000.0;
      final s = elapsed < 60
          ? '+${elapsed.toStringAsFixed(0)}s'
          : '+${(elapsed ~/ 60)}:${(elapsed % 60).toStringAsFixed(0).padLeft(2, "0")}';
      return Text(s,
          style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10));
    }

    final remainingMs = (durationMs! - elapsedMs).clamp(0.0, durationMs!);
    return Text(
      '-${_fmtMs(remainingMs)}',
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _DurationLabel extends StatelessWidget {
  final Cue cue;
  final bool isActive;
  final bool isPast;

  const _DurationLabel({required this.cue, required this.isActive, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final label = _label(cue);
    if (label == null) return const SizedBox(width: 52);
    return SizedBox(
      width: 52,
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: isActive ? _green : (isPast ? _dimText : Colors.white24),
          fontSize: 12,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  String? _label(Cue c) {
    if (c.preWaitMs > 0) {
      final s = (c.preWaitMs / 1000).round();
      return 'W $s s';
    }
    if (c.cueType.value == 4 && c.hasWait()) {
      final s = (c.wait.durationMs / 1000).round();
      return _fmt(s);
    }
    if (c.cueType.value == 2 && c.hasAudio()) {
      final end = c.audio.endTimeMs;
      final start = c.audio.startTimeMs;
      if (end > start && end > 0) return _fmt(((end - start) / 1000).round());
    }
    return null;
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return m > 0 ? '${m}m ${sec}s' : '${sec}s';
  }
}

// ── GO-Button ─────────────────────────────────────────────────────────────────

class _GoButton extends StatelessWidget {
  final bool isLoading;
  final bool isPaused;
  final VoidCallback onGo;

  const _GoButton({required this.isLoading, required this.isPaused, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final color = isPaused ? _amber : _green;
    final label = isPaused ? 'RESUME' : 'GO';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: GestureDetector(
          onTap: isLoading ? null : onGo,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 80,
            decoration: BoxDecoration(
              color: isLoading ? Colors.grey[850] : color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status-Chips ──────────────────────────────────────────────────────────────

class _AudioStatusChip extends ConsumerWidget {
  final AudioNodeStatus status;
  const _AudioStatusChip(this.status);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, color) = switch (status.state) {
      AudioNodeState.connected => ('AUDIO ●', _green),
      AudioNodeState.error     => ('AUDIO ✕', Colors.red),
      _                        => ('AUDIO ○', Colors.white38),
    };

    return GestureDetector(
      onTap: status.state == AudioNodeState.connected && status.availableDevices.length > 1
          ? () => _showDevicePicker(context, ref, status)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              if (status.availableDevices.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.expand_more, size: 12, color: color),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDevicePicker(BuildContext context, WidgetRef ref, AudioNodeStatus status) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Audiogerät wählen',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...status.availableDevices.map((device) {
            final isSelected = device.id == status.selectedDevice?.id;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.speaker : Icons.speaker_outlined,
                color: isSelected ? _green : Colors.white54,
              ),
              title: Text(device.name, style: TextStyle(color: isSelected ? _green : Colors.white)),
              trailing: isSelected ? const Icon(Icons.check, color: _green) : null,
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(audioNodeProvider.notifier).selectDevice(device);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Verbindungs-Banner ────────────────────────────────────────────────────────

class _ConnectionBanner extends StatelessWidget {
  final ConnectionHealth health;
  final VoidCallback onLeave;

  const _ConnectionBanner({required this.health, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final isDisconnected = health == ConnectionHealth.disconnected;
    final color = isDisconnected ? Colors.red : Colors.orange;
    final label = isDisconnected
        ? 'Verbindung zum Server getrennt'
        : 'Verbindung wird wiederhergestellt…';
    final icon = isDisconnected ? Icons.cloud_off : Icons.cloud_sync;

    return Container(
      color: color.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(color: color, fontSize: 12)),
          ),
          if (isDisconnected)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              onPressed: onLeave,
              child: const Text('Verlassen', style: TextStyle(fontSize: 12)),
            )
          else
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: color),
            ),
        ],
      ),
    );
  }
}

class _MaStatusChip extends StatelessWidget {
  final MaNodeStatus status;
  const _MaStatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status.state) {
      MaNodeState.connected => ('MA ●', _amber),
      MaNodeState.error     => ('MA ✕', Colors.red),
      _                     => ('MA ○', Colors.white38),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
