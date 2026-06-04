import 'package:flutter/material.dart';
import '../../../domain/show.dart';
import '../../../domain/cue_params.dart';
import '../../../domain/playhead.dart';
import '../../../session/clock_sync.dart';
import '../sc_colors.dart';
import '../sc_tick.dart';
import '../sc_typography.dart';
import '../sc_spacing.dart';
import '../primitives/sc_chip.dart';

/// QLab-style cue row with real-time progress fill and group expansion.
///
/// Converts to StatefulWidget to drive a 60-fps Ticker only while the cue
/// is actively running (avoids battery drain when idle).
class CueListRow extends StatefulWidget {
  final Cue cue;
  final CueRunState? runState;

  /// Full playhead state — used for timing computation.
  final PlayheadState? playhead;

  final bool isActive;
  final bool isPast;
  final bool isSelected;

  /// 80-px active mode (GoScreen) vs 48-px compact (editor).
  final bool expanded;

  // ── Reorder ──────────────────────────────────────────────────────────────
  final bool showDragHandle;
  final int? dragIndex;

  // ── Group expansion ───────────────────────────────────────────────────────
  final int depth; // 0 = top-level, 1 = group child
  final List<Cue>? groupChildren; // non-null only for group cues
  final bool isGroupExpanded;
  final VoidCallback? onToggleExpand;
  final Map<String, CueRunState>? childRunStates;

   // ── Action callbacks ──────────────────────────────────────────────────────
   final VoidCallback? onTap;
   final VoidCallback? onDoubleTap;
   final VoidCallback? onLongPress;
   final VoidCallback? onDelete;
   final VoidCallback? onGo;
   final VoidCallback? onInsertBefore;
   final VoidCallback? onInsertAfter;
    final VoidCallback? onDuplicate;
    final VoidCallback? onGroup;

    const CueListRow({
     super.key,
     required this.cue,
     this.runState,
     this.playhead,
     this.isActive = false,
     this.isPast = false,
     this.isSelected = false,
     this.expanded = false,
     this.showDragHandle = false,
     this.dragIndex,
     this.depth = 0,
     this.groupChildren,
     this.isGroupExpanded = false,
     this.onToggleExpand,
     this.childRunStates,
     this.onTap,
     this.onDoubleTap,
     this.onLongPress,
     this.onDelete,
     this.onGo,
     this.onInsertBefore,
     this.onInsertAfter,
      this.onDuplicate,
      this.onGroup,
    });

    bool get hasError => runState?.lifecycle == CueLifecycle.error;
  bool get isPaused => runState?.lifecycle == CueLifecycle.paused;
  bool get isGroup => cue.params is GroupParams;

  /// Cue ist Teil von runningCueIds (auch wenn nicht die primär-aktive Cue).
  bool _isAlsoRunning(PlayheadState? playhead) =>
      !isActive && (playhead?.runningCueIds.contains(cue.id) ?? false);

  @override
  State<CueListRow> createState() => _CueListRowState();

  // ── Static helpers shared with child widgets ──────────────────────────────

  static IconData typeIcon(CueParams p) => switch (p) {
        AudioParams()  => Icons.volume_up,
        WaitParams()   => Icons.timer_outlined,
        MaOscParams()  => Icons.light_mode,
        GroupParams()  => Icons.folder_outlined,
        GotoParams()   => Icons.redo,
        OscParams()    => Icons.settings_ethernet,
        MidiParams()   => Icons.piano,
        ScriptParams() => Icons.code,
        NoteParams()   => Icons.text_fields,
        FadeParams()   => Icons.tune,
      };

  static Color typeColor(CueParams p) => switch (p) {
        AudioParams()  => const Color(0xFF1E88E5),
        WaitParams()   => const Color(0xFF8E24AA),
        MaOscParams()  => const Color(0xFFF4511E),
        GroupParams()  => const Color(0xFF00897B),
        GotoParams()   => const Color(0xFF00ACC1),
        OscParams()    => const Color(0xFF7CB342),
        MidiParams()   => const Color(0xFFE91E8C),
        ScriptParams() => const Color(0xFF757575),
        NoteParams  p  => p.color ?? const Color(0xFF616161),
        FadeParams()   => const Color(0xFFAB47BC),
      };
}

class _CueListRowState extends State<CueListRow> {
  /// True wenn diese Row live-Updates braucht:
  /// entweder primär aktiv ODER im Hintergrund noch spielend (isAlsoRunning).
  bool get _isLiveRunning =>
      widget.isActive || widget._isAlsoRunning(widget.playhead);

  /// Per-Cue-Pause: direkt aus dem server-autoritativen PlayheadState lesen.
  bool get _perCuePaused =>
      widget.playhead?.isCuePaused(widget.cue.id) ?? false;

  // ── Fade-aware progress ──────────────────────────────────────────────────

  /// Current server time for this cue — frozen if per-cue or globally paused.
  int _effectiveNowMs() {
    final ph = widget.playhead;
    if (ph == null) return ClockSync.instance.serverNow();
    return ph.effectiveNowMsForCue(widget.cue.id);
  }

  /// Start-Serverzeit dieser Cue.
  /// Für primär-aktive Cues: per-Cue-Zeit oder globaler Fallback.
  /// Für Hintergrund-Cues (isAlsoRunning): nur per-Cue-Zeit —
  /// startedServerMs gehört zur anderen (aktiven) Cue.
  int? get _cueStartMs {
    final ph = widget.playhead;
    if (ph == null) return null;
    final perCueStart = ph.cueStartedServerMsByCueId[widget.cue.id];
    if (perCueStart != null) return perCueStart;
    if (widget.isActive) return ph.startedServerMs; // Fallback nur für aktive Cue
    return null;
  }

  double get _progressFraction {
    if (!_isLiveRunning) return 0.0;
    final start = _cueStartMs;
    final duration = widget.cue.displayDurationMs;
    if (start == null || duration == null || duration <= 0) return 0.0;
    return ((_effectiveNowMs() - start) / duration).clamp(0.0, 1.0);
  }

  double get _elapsedMs {
    final start = _cueStartMs;
    if (start == null) return 0.0;
    return (_effectiveNowMs() - start).toDouble().clamp(0.0, double.maxFinite);
  }

  /// Audio-Phase — steuert Bar-Farbe und Overlay.
  /// Hintergrund-Cues (isAlsoRunning): vereinfachte Phase, kein globaler
  /// Pause-Status (der gehört zur primär-aktiven Cue).
  _AudioPhase get _audioPhase {
    if (!_isLiveRunning) return _AudioPhase.idle;
    final ph = widget.playhead;
    if (ph == null) return _AudioPhase.idle;

    final elapsed = _elapsedMs;
    final isAlsoRunning = widget._isAlsoRunning(widget.playhead);

    // Hintergrund-Cues: per-Cue- und globale Pause + Fade-Zonen.
    if (isAlsoRunning && !widget.isActive) {
      if (_perCuePaused) return _AudioPhase.paused;
      if (ph.isPaused) return _AudioPhase.paused;
      if (widget.cue.params case AudioParams p) {
        if (p.fadeInMs > 0 && elapsed < p.fadeInMs) return _AudioPhase.fadeIn;
        final duration = widget.cue.displayDurationMs;
        if (duration != null && p.fadeOutMs > 0) {
          if (elapsed > duration - p.fadeOutMs) return _AudioPhase.fadeOut;
        }
      }
      return _AudioPhase.playing;
    }

    // Primär-aktive Cue: volle Pause-/Done-Logik.
    if (_perCuePaused) return _AudioPhase.paused;
    if (ph.isPaused) {
      final pausedAt = ph.pausedAtServerMs;
      if (pausedAt != null && ClockSync.instance.serverNow() < pausedAt) {
        return _AudioPhase.pauseFading;
      }
      return _AudioPhase.paused;
    }

    if (ph.isDone) return _AudioPhase.done;

    if (widget.cue.params case AudioParams p) {
      if (p.fadeInMs > 0 && elapsed < p.fadeInMs) return _AudioPhase.fadeIn;
      final duration = widget.cue.displayDurationMs;
      if (duration != null && p.fadeOutMs > 0) {
        if (elapsed > duration - p.fadeOutMs) return _AudioPhase.fadeOut;
      }
    }
    return _AudioPhase.playing;
  }

  Color get _stateColor => ScColors.forCueState(
        isActive: widget.isActive,
        isPast: widget.isPast,
        isError: widget.hasError,
        isPaused: widget.isPaused,
      );

  Color get _typeColor => CueListRow.typeColor(widget.cue.params);

  @override
  Widget build(BuildContext context) {
    // Note cues render as visual dividers, not as regular rows.
    if (widget.cue.params case NoteParams note) {
      return _NoteRow(cue: widget.cue, note: note, onTap: widget.onTap);
    }

    final isAlsoRunning = widget._isAlsoRunning(widget.playhead);
    // Subscribe to vsync ticker only while time is actually advancing.
    // Per-cue paused → frozen → no tick needed.
    final needsTick = _isLiveRunning &&
        !_perCuePaused &&
        !(widget.playhead?.isDone ?? false) &&
        !(widget.playhead?.isPaused ?? false);
    if (needsTick) ScTick.of(context);
    final height =
        widget.expanded ? ScSpacing.rowHeightActive : ScSpacing.rowHeight;
    final fraction = _progressFraction;
    final indent = widget.depth * 20.0;

    final audioPhase = _audioPhase;

    Widget row = SizedBox(
      height: height,
      child: Stack(
        children: [
          // ── Background tint (base) ──────────────────────────────────────
          Container(
            color: widget.isSelected
                ? ScColors.selected
                : widget.isActive
                    ? _typeColor.withValues(alpha: 0.06)
                    : isAlsoRunning
                        ? _typeColor.withValues(alpha: 0.03)
                        : Colors.transparent,
          ),

          // ── Progress sweep (QLab-style fill from left) ──────────────────
          // Zeigt auch für Hintergrund-Audio-Cues (isAlsoRunning) — gedimmt.
          if ((widget.isActive || isAlsoRunning) && fraction > 0)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (_, constraints) => Opacity(
                  opacity: isAlsoRunning && !widget.isActive ? 0.45 : 1.0,
                  child: _ProgressSweepPainter(
                    fraction: fraction,
                    typeColor: _typeColor,
                    audioPhase: audioPhase,
                    cue: widget.cue,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                ),
              ),
            ),

          // ── Left accent bar ─────────────────────────────────────────────
          if (widget.isActive || widget.hasError || isAlsoRunning)
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 3,
                color: isAlsoRunning && !widget.isActive
                    ? _typeColor.withValues(alpha: 0.5)
                    : _stateColor,
              ),
            ),

          // ── Bottom progress line ────────────────────────────────────────
          if (widget.isActive || isAlsoRunning)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Opacity(
                opacity: isAlsoRunning && !widget.isActive ? 0.5 : 1.0,
                child: _CueProgressBar(
                  fraction: fraction,
                  audioPhase: audioPhase,
                  typeColor: _typeColor,
                  cue: widget.cue,
                ),
              ),
            ),

          // ── Row content ──
          Padding(
            padding: EdgeInsets.only(left: 6 + indent, right: 8),
            child: Row(
              children: [
                // Group toggle or type icon
                if (widget.isGroup)
                  GestureDetector(
                    onTap: widget.onToggleExpand,
                    child: SizedBox(
                      width: ScSpacing.cueTypeIconWidth + 6,
                      child: Icon(
                        widget.isGroupExpanded
                            ? Icons.expand_more
                            : Icons.chevron_right,
                        size: 18,
                        color: _typeColor,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: ScSpacing.cueTypeIconWidth,
                    child: Icon(
                      CueListRow.typeIcon(widget.cue.params),
                      size: 14,
                      color: _typeColor,
                    ),
                  ),
                const SizedBox(width: 6),

                // Cue number — AnimatedSwitcher so renumber after reorder is visible
                SizedBox(
                  width: ScSpacing.cueNumberWidth,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.4),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      widget.cue.number,
                      key: ValueKey(widget.cue.number),
                      style: (widget.isActive
                              ? ScText.numberLarge
                              : ScText.number)
                          .copyWith(color: _stateColor),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Label + node state row (expanded mode)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cue.label.isEmpty ? '—' : widget.cue.label,
                        style: widget.isPast
                            ? ScText.cueLabelPast
                            : widget.isActive
                                ? ScText.cueLabelActive
                                : ScText.cueLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.expanded && widget.runState != null)
                        _NodeStateRow(runState: widget.runState!),
                    ],
                  ),
                ),

                // Timing column: remaining-time when active, total otherwise
                 _TimingColumn(
                   cue: widget.cue,
                   playhead: widget.playhead,
                   isActive: widget.isActive,
                  ),

                  // Status dot
                  SizedBox(
                    width: ScSpacing.cueStatusDotWidth,
                    child: Center(child: _statusDot()),
                  ),

                // Delete button (desktop editor)
                if (widget.showDragHandle && widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: widget.onDelete,
                    color: ScColors.error,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),

                // Drag handle (desktop editor)
                if (widget.showDragHandle && widget.dragIndex != null)
                  ReorderableDragStartListener(
                    index: widget.dragIndex!,
                    child: const Icon(Icons.drag_handle,
                        size: 18, color: ScColors.textDim),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    // Gesture detection
    if (widget.onTap != null ||
        widget.onGo != null ||
        widget.onDoubleTap != null ||
        widget.onLongPress != null) {
      row = GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress,
        onSecondaryTapUp: (details) =>
            _showContextMenu(context, details.localPosition),
        child: row,
      );
    }

    // Group expansion: children shown inline, indented
    if (widget.isGroup &&
        widget.isGroupExpanded &&
        widget.groupChildren != null &&
        widget.groupChildren!.isNotEmpty) {
      final params = widget.cue.params as GroupParams;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          // Group mode badge
          Padding(
            padding: EdgeInsets.only(left: 24 + indent, bottom: 2),
            child: Text(
              params.sequential ? 'SEQUENTIAL' : 'PARALLEL',
              style: ScText.statusSmall.copyWith(color: _typeColor),
            ),
          ),
          ...widget.groupChildren!.map((child) {
            final isChildActive =
                widget.playhead?.runningCueIds.contains(child.id) ?? false;
            return CueListRow(
              key: ValueKey('child_${child.id}'),
              cue: child,
              runState: widget.childRunStates?[child.id],
              playhead: widget.playhead,
              isActive: isChildActive,
              depth: widget.depth + 1,
            );
          }),
          // Group end-line
          Container(
            height: 1,
            margin: EdgeInsets.only(left: 24 + indent),
            color: _typeColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 2),
        ],
      );
    }

    return row;
  }

  void _showContextMenu(BuildContext context, Offset localPos) {
    final box = context.findRenderObject() as RenderBox;
    final global = box.localToGlobal(localPos);
    final size = MediaQuery.sizeOf(context);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        global.dx, global.dy,
        size.width - global.dx, size.height - global.dy,
      ),
      color: ScColors.surface2,
      items: [
        if (widget.onGo != null)
          const PopupMenuItem(value: 'go', child: Text('GO here')),
        const PopupMenuDivider(),
        if (widget.onInsertBefore != null)
          const PopupMenuItem(
              value: 'insert_before', child: Text('Insert Before')),
        if (widget.onInsertAfter != null)
          const PopupMenuItem(
              value: 'insert_after', child: Text('Insert After')),
        if (widget.onDuplicate != null)
          const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        if (widget.onGroup != null)
          const PopupMenuItem(value: 'group', child: Text('Group')),
        const PopupMenuDivider(),
        if (widget.onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: ScColors.error)),
          ),
      ],
    ).then((v) {
      switch (v) {
        case 'go':
          widget.onGo?.call();
        case 'insert_before':
          widget.onInsertBefore?.call();
        case 'insert_after':
          widget.onInsertAfter?.call();
        case 'duplicate':
          widget.onDuplicate?.call();
        case 'group':
          widget.onGroup?.call();
        case 'delete':
          widget.onDelete?.call();
      }
    });
  }

  Widget _statusDot() {
    final isAlsoRunning = widget._isAlsoRunning(widget.playhead);
    if (!widget.isActive && !widget.hasError && !widget.isPaused && !isAlsoRunning) {
      return const SizedBox.shrink();
    }
    final color = isAlsoRunning && !widget.isActive
        ? _typeColor.withValues(alpha: 0.6)
        : _stateColor;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)
        ],
      ),
    );
  }
}

// ── Timing column ─────────────────────────────────────────────────────────────

class _TimingColumn extends StatelessWidget {
  final Cue cue;
  final PlayheadState? playhead;
  final bool isActive;

  const _TimingColumn({
    required this.cue,
    required this.playhead,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final duration = cue.displayDurationMs;
    final preWait = cue.timing.preWaitMs;
    final postWait = cue.timing.postWaitMs;

    final autoContinue = cue.timing.autoContinue;
    // Läuft die Cue im Hintergrund (nicht die primär-aktive)?
    final isAlsoRunning =
        !isActive && (playhead?.runningCueIds.contains(cue.id) ?? false);
    final hasStartTime = (playhead?.cueStartedServerMsByCueId[cue.id] ??
            (isActive ? playhead?.startedServerMs : null)) !=
        null;

    return SizedBox(
      width: ScSpacing.cueDurationWidth + 10,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if ((isActive || isAlsoRunning) && duration != null && hasStartTime)
            _RemainingTime(playhead: playhead!, cueId: cue.id, duration: duration)
          else
            Text(
              _fmt(duration),
              style: ScText.numberSmall,
              textAlign: TextAlign.right,
            ),
          if (preWait > 0 || postWait > 0)
            Text(
              _waitHint(preWait, postWait),
              style: ScText.statusSmall.copyWith(fontSize: 9),
            ),
          // Kleiner Indikator wenn Auto-Continue aktiv ist
          if (autoContinue && !isActive && !isAlsoRunning)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, size: 9, color: ScColors.textDim),
                Text('AUTO',
                    style: ScText.statusSmall
                        .copyWith(fontSize: 8, color: ScColors.textDim)),
              ],
            ),
        ],
      ),
    );
  }

  static String _fmt(double? ms) {
    if (ms == null) return '';
    if (ms < 1000) return '${ms.toInt()}ms';
    final s = ms / 1000;
    if (s < 60) return '${s.toStringAsFixed(1)}s';
    final m = (s / 60).floor();
    final rs = (s % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$rs';
  }

  static String _waitHint(double pre, double post) {
    if (pre > 0 && post > 0) return '↓${_fmt(pre)} ↑${_fmt(post)}';
    if (pre > 0) return '↓ ${_fmt(pre)}';
    return '↑ ${_fmt(post)}';
  }
}

// Shows remaining time counting down (QLab style: -3.4s)
class _RemainingTime extends StatelessWidget {
  final PlayheadState playhead;
  final String cueId;
  final double duration;

  const _RemainingTime({
    required this.playhead,
    required this.cueId,
    required this.duration,
  });

  static String _fmt(double ms) {
    if (ms <= 0) return '0.0s';
    if (ms < 1000) return '${(ms / 1000).toStringAsFixed(1)}s';
    final s = ms / 1000;
    if (s < 60) return '${s.toStringAsFixed(1)}s';
    final m = (s / 60).floor();
    final rs = (s % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$rs';
  }

  @override
  Widget build(BuildContext context) {
    // Per-Cue-Start hat Priorität; für primär-aktive Cues ist Fallback ok.
    // Für Hintergrund-Cues darf der Fallback nicht verwendet werden (falsche Zeit).
    final start = playhead.cueStartedServerMsByCueId[cueId]
        ?? playhead.startedServerMs
        ?? ClockSync.instance.serverNow();
    final now = playhead.effectiveNowMsForCue(cueId);
    final elapsed = (now - start).clamp(0, 99 * 60 * 1000).toDouble();
    final remaining = (duration - elapsed).clamp(0.0, duration);
    final paused = playhead.isCuePaused(cueId) || playhead.isPaused;
    return Text(
      '-${_fmt(remaining)}',
      style: ScText.number.copyWith(
        color: paused ? ScColors.warn : ScColors.active,
        fontSize: 13,
      ),
    );
  }
}

// ── Audio phase enum ─────────────────────────────────────────────────────────

/// Current audio sub-phase — drives visual feedback in progress bars.
enum _AudioPhase {
  idle,
  fadeIn,       // audio is ramping up (start of cue)
  playing,      // full-volume playback
  fadeOut,      // audio is ramping down (end of cue)
  pauseFading,  // PAUSE fired with fadeOut behavior — audio still audible
  paused,       // fully paused, silent
  done,
}

// ── Progress sweep painter ────────────────────────────────────────────────────

/// Full-height background sweep with fade-in / fade-out gradient overlays.
/// Replaces the simple `FractionallySizedBox` fill.
class _ProgressSweepPainter extends StatelessWidget {
  final double fraction;
  final Color typeColor;
  final _AudioPhase audioPhase;
  final Cue cue;
  final double width;
  final double height;

  const _ProgressSweepPainter({
    required this.fraction,
    required this.typeColor,
    required this.audioPhase,
    required this.cue,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SweepPaint(
        fraction: fraction,
        typeColor: typeColor,
        audioPhase: audioPhase,
        cue: cue,
        totalWidth: width,
        totalHeight: height,
      ),
    );
  }
}

class _SweepPaint extends CustomPainter {
  final double fraction;
  final Color typeColor;
  final _AudioPhase audioPhase;
  final Cue cue;
  final double totalWidth;
  final double totalHeight;

  const _SweepPaint({
    required this.fraction,
    required this.typeColor,
    required this.audioPhase,
    required this.cue,
    required this.totalWidth,
    required this.totalHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fillX = w * fraction;

    // ── Base fill (played region) ───────────────────────────────────────
    final fillColor = audioPhase == _AudioPhase.pauseFading
        ? ScColors.warn.withValues(alpha: 0.14)
        : typeColor.withValues(alpha: 0.11);

    canvas.drawRect(Rect.fromLTWH(0, 0, fillX, h), Paint()..color = fillColor);

    // ── Fade-In gradient (left edge of fill) ───────────────────────────
    if (cue.params case AudioParams p when p.fadeInMs > 0) {
      final duration = cue.displayDurationMs;
      if (duration != null && duration > 0) {
        final fadeInW = (p.fadeInMs / duration * w).clamp(0.0, fillX);
        if (fadeInW > 2) {
          canvas.drawRect(
            Rect.fromLTWH(0, 0, fadeInW, h),
            Paint()
              ..shader = LinearGradient(
                colors: [
                  typeColor.withValues(alpha: 0.0),
                  typeColor.withValues(alpha: 0.15),
                ],
              ).createShader(Rect.fromLTWH(0, 0, fadeInW, h)),
          );
        }
      }
    }

    // ── Fade-Out gradient (right portion of fill near end) ─────────────
    if (cue.params case AudioParams p when p.fadeOutMs > 0) {
      final duration = cue.displayDurationMs;
      if (duration != null && duration > 0) {
        final fadeOutStartF = (duration - p.fadeOutMs) / duration;
        final fadeOutStartX = (fadeOutStartF * w).clamp(0.0, w);
        final fadeOutEndX = (fraction * w).clamp(fadeOutStartX, w);
        final fadeOutW = fadeOutEndX - fadeOutStartX;
        if (fadeOutW > 2) {
          canvas.drawRect(
            Rect.fromLTWH(fadeOutStartX, 0, fadeOutW, h),
            Paint()
              ..shader = LinearGradient(
                colors: [
                  ScColors.warn.withValues(alpha: 0.0),
                  ScColors.warn.withValues(alpha: 0.18),
                ],
              ).createShader(Rect.fromLTWH(fadeOutStartX, 0, fadeOutW, h)),
          );
        }
      }
    }

    // ── Pause-fade "draining" gradient (entire fill region, warm) ──────
    if (audioPhase == _AudioPhase.pauseFading) {
      // Overlay a warm amber wash that suggests volume is draining.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, fillX, h),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              ScColors.warn.withValues(alpha: 0.0),
              ScColors.warn.withValues(alpha: 0.10),
            ],
          ).createShader(Rect.fromLTWH(0, 0, fillX, h)),
      );
    }
  }

  @override
  bool shouldRepaint(_SweepPaint old) =>
      old.fraction != fraction ||
      old.audioPhase != audioPhase ||
      old.typeColor != typeColor;
}

// ── Bottom progress bar ───────────────────────────────────────────────────────

/// 3px progress line at the bottom of each row.
///
/// Shows:
/// - A filled region (elapsed) with fade-in and fade-out color zones.
/// - An amber warning overlay during pause-fade.
/// - Indeterminate animation when duration is unknown.
class _CueProgressBar extends StatelessWidget {
  final double fraction;          // 0.0–1.0; 0 = indeterminate
  final _AudioPhase audioPhase;
  final Color typeColor;
  final Cue cue;

  const _CueProgressBar({
    required this.fraction,
    required this.audioPhase,
    required this.typeColor,
    required this.cue,
  });

  @override
  Widget build(BuildContext context) {
    if (fraction <= 0) {
      // Indeterminate — duration unknown or not yet started.
      return LinearProgressIndicator(
        backgroundColor: typeColor.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation(_barColor),
        minHeight: 3,
      );
    }
    return CustomPaint(
      size: const Size(double.infinity, 3),
      painter: _BarPaint(
        fraction: fraction,
        audioPhase: audioPhase,
        typeColor: typeColor,
        cue: cue,
      ),
    );
  }

  Color get _barColor => switch (audioPhase) {
    _AudioPhase.pauseFading => ScColors.warn,
    _AudioPhase.paused      => ScColors.warn,
    _AudioPhase.done        => ScColors.textDim,
    _AudioPhase.fadeIn      => typeColor.withValues(alpha: 0.6),
    _                       => typeColor,
  };
}

class _BarPaint extends CustomPainter {
  final double fraction;
  final _AudioPhase audioPhase;
  final Color typeColor;
  final Cue cue;

  const _BarPaint({
    required this.fraction,
    required this.audioPhase,
    required this.typeColor,
    required this.cue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fillX = w * fraction;

    // Track background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = typeColor.withValues(alpha: 0.12),
    );

    if (fillX <= 0) return;

    // Determine segments based on fade zones.
    final duration = cue.displayDurationMs;
    double fadeInEndX   = 0;
    double fadeOutStartX = fillX;

    if (cue.params case AudioParams p when duration != null && duration > 0) {
      fadeInEndX    = (p.fadeInMs  / duration * w).clamp(0.0, fillX);
      fadeOutStartX = ((duration - p.fadeOutMs) / duration * w).clamp(0.0, fillX);
    }

    // ── Fade-in segment (lighter) ───────────────────────────────────────
    if (fadeInEndX > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, fadeInEndX, h),
        Paint()
          ..shader = LinearGradient(
            colors: [
              typeColor.withValues(alpha: 0.3),
              typeColor,
            ],
          ).createShader(Rect.fromLTWH(0, 0, fadeInEndX, h)),
      );
    }

    // ── Main playback segment ───────────────────────────────────────────
    final mainColor = audioPhase == _AudioPhase.pauseFading
        ? ScColors.warn
        : audioPhase == _AudioPhase.paused
            ? ScColors.warn.withValues(alpha: 0.6)
            : audioPhase == _AudioPhase.done
                ? ScColors.textDim
                : typeColor;

    final mainStart = fadeInEndX;
    final mainEnd   = fadeOutStartX.clamp(mainStart, fillX);
    if (mainEnd > mainStart) {
      canvas.drawRect(
        Rect.fromLTWH(mainStart, 0, mainEnd - mainStart, h),
        Paint()..color = mainColor,
      );
    }

    // ── Fade-out segment (amber gradient) ───────────────────────────────
    if (fadeOutStartX < fillX) {
      canvas.drawRect(
        Rect.fromLTWH(fadeOutStartX, 0, fillX - fadeOutStartX, h),
        Paint()
          ..shader = LinearGradient(
            colors: [typeColor, ScColors.warn],
          ).createShader(Rect.fromLTWH(fadeOutStartX, 0, fillX - fadeOutStartX, h)),
      );
    }
  }

  @override
  bool shouldRepaint(_BarPaint old) =>
      old.fraction != fraction || old.audioPhase != audioPhase;
}

// ── Note / Placeholder row ────────────────────────────────────────────────────

/// Renders a NoteParams cue as a visual divider with optional text.
/// Tapping selects the cue for editing; no GO behavior.
class _NoteRow extends StatelessWidget {
  final Cue cue;
  final NoteParams note;
  final VoidCallback? onTap;

  const _NoteRow({required this.cue, required this.note, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = note.color ?? ScColors.textDim;
    final text = note.text.isNotEmpty ? note.text : cue.label;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            // Left accent
            Container(width: 3, color: color),
            const SizedBox(width: 8),
            // Optional cue number
            if (cue.number.isNotEmpty) ...[
              Text(cue.number,
                  style: ScText.numberSmall.copyWith(color: color)),
              const SizedBox(width: 8),
            ],
            // Divider line + text
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: color.withValues(alpha: 0.4)),
                  ),
                  if (text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      text.toUpperCase(),
                      style: ScText.panelTitle.copyWith(
                        color: color,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                          height: 1, color: color.withValues(alpha: 0.4)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}


// ── Node state chips ──────────────────────────────────────────────────────────

class _NodeStateRow extends StatelessWidget {
  final CueRunState runState;
  const _NodeStateRow({required this.runState});

  @override
  Widget build(BuildContext context) {
    if (runState.nodes.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      children: runState.nodes.entries.map((e) {
        final phase = e.value.phase;
        final short = e.key.length > 4 ? e.key.substring(0, 4) : e.key;
        return ScChip(
          label: short.toUpperCase(),
          state: phase == NodeExecPhase.error
              ? ScChipState.error
              : phase == NodeExecPhase.playing
                  ? ScChipState.ok
                  : ScChipState.idle,
        );
      }).toList(),
    );
  }
}
