import 'dart:async';

import 'package:flutter/material.dart';
import '../../../domain/show.dart';
import '../../../domain/cue_params.dart';
import '../../../domain/playhead.dart';
import '../../../session/clock_sync.dart';
import '../sc_colors.dart';
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(CueListRow old) {
    super.didUpdateWidget(old);
    _syncTimer();
  }

  void _syncTimer() {
    // Run timer whenever active (even when paused) so the bottom bar and
    // indeterminate animation stay alive. Stop only when idle or done.
    final running = widget.isActive && !(widget.playhead?.isDone ?? false);
    if (running && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (mounted) setState(() {});
      });
    } else if (!running && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void deactivate() {
    // Cancel immediately so no setState fires while element is in inactive pool.
    _timer?.cancel();
    _timer = null;
    super.deactivate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progressFraction {
    if (!widget.isActive) return 0.0;
    final ph = widget.playhead;
    final start = ph?.startedServerMs;
    final duration = widget.cue.displayDurationMs;
    if (start == null || duration == null || duration == 0) return 0.0;
    final now = ph!.isPaused
        ? (ph.pausedAtServerMs ?? ClockSync.instance.serverNow())
        : ph.isDone
            ? (ph.doneServerMs ?? ClockSync.instance.serverNow())
            : ClockSync.instance.serverNow();
    return ((now - start) / duration).clamp(0.0, 1.0);
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

    final height =
        widget.expanded ? ScSpacing.rowHeightActive : ScSpacing.rowHeight;
    final fraction = _progressFraction;
    final indent = widget.depth * 20.0;

    Widget row = SizedBox(
      height: height,
      child: Stack(
        children: [
          // ── Background: progress sweep (QLab-style, nur bei bekannter Dauer) ──
          if (widget.isActive && fraction > 0)
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: Container(color: _typeColor.withValues(alpha: 0.12)),
              ),
            ),

          // ── Row selection/active tint ──
          Container(
            color: widget.isSelected
                ? ScColors.selected
                : widget.isActive
                    ? _typeColor.withValues(alpha: 0.06)
                    : Colors.transparent,
          ),

          // ── Left accent bar ──
          if (widget.isActive || widget.hasError)
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 3, color: _stateColor),
            ),

          // ── Bottom progress line ──
          // value: fraction wenn Dauer bekannt (0→1 Fill), null = indeterminate
          // wenn Dauer unbekannt aber Cue aktiv (animierter Ladebalken).
          if (widget.isActive)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: LinearProgressIndicator(
                value: fraction > 0 ? fraction : null,
                backgroundColor: _typeColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  widget.isPaused
                      ? ScColors.warn
                      : widget.playhead?.isDone == true
                          ? ScColors.textDim
                          : _typeColor,
                ),
                minHeight: 2,
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
    if (!widget.isActive && !widget.hasError && !widget.isPaused) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _stateColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: _stateColor.withValues(alpha: 0.5), blurRadius: 4)
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

    return SizedBox(
      width: ScSpacing.cueDurationWidth + 10,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isActive &&
              duration != null &&
              playhead?.startedServerMs != null)
            _RemainingTime(playhead: playhead!, duration: duration)
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
  final double duration;

  const _RemainingTime({required this.playhead, required this.duration});

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
    final start = playhead.startedServerMs!;
    final now = playhead.isPaused
        ? (playhead.pausedAtServerMs ?? ClockSync.instance.serverNow())
        : playhead.isDone
            ? (playhead.doneServerMs ?? ClockSync.instance.serverNow())
            : ClockSync.instance.serverNow();
    final elapsed = (now - start).clamp(0, 99 * 60 * 1000).toDouble();
    final remaining = (duration - elapsed).clamp(0.0, duration);
    return Text(
      '-${_fmt(remaining)}',
      style: ScText.number.copyWith(
        color: playhead.isPaused ? ScColors.warn : ScColors.active,
        fontSize: 13,
      ),
    );
  }
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
