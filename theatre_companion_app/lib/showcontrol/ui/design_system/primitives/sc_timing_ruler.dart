import 'package:flutter/material.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';

/// Audio-timing visualizer — no domain knowledge.
///
/// Shows a horizontal ruler representing [totalDurationMs] with colored bands for:
/// - Start offset (before active region): dimmed left region
/// - Fade-In ramp (green gradient)
/// - Active playback region (mid tint)
/// - Fade-Out ramp (amber gradient)
/// - End offset (after active region): dimmed right region
///
/// Parameters are all in milliseconds. Pass `null` for totalDurationMs to show
/// an indeterminate state (no ruler, just a placeholder).
///
/// Non-interactive by default. Set [onStartChanged], [onEndChanged],
/// [onFadeInChanged], [onFadeOutChanged] to enable draggable handles.
class ScTimingRuler extends StatefulWidget {
  final double? totalDurationMs;
  final double startMs;
  final double endMs;       // 0 = use totalDurationMs
  final double fadeInMs;
  final double fadeOutMs;

  final ValueChanged<double>? onStartChanged;
  final ValueChanged<double>? onEndChanged;
  final ValueChanged<double>? onFadeInChanged;
  final ValueChanged<double>? onFadeOutChanged;

  const ScTimingRuler({
    super.key,
    required this.totalDurationMs,
    required this.startMs,
    required this.endMs,
    required this.fadeInMs,
    required this.fadeOutMs,
    this.onStartChanged,
    this.onEndChanged,
    this.onFadeInChanged,
    this.onFadeOutChanged,
  });

  @override
  State<ScTimingRuler> createState() => _ScTimingRulerState();
}

class _ScTimingRulerState extends State<ScTimingRuler> {
  // Track which handle is being dragged
  _Handle? _dragging;

  bool get _interactive =>
      widget.onStartChanged != null ||
      widget.onEndChanged != null ||
      widget.onFadeInChanged != null ||
      widget.onFadeOutChanged != null;

  @override
  Widget build(BuildContext context) {
    final total = widget.totalDurationMs;

    if (total == null || total <= 0) {
      return _placeholder();
    }

    final effectiveEnd = widget.endMs > 0 && widget.endMs <= total
        ? widget.endMs
        : total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Ruler bar ────────────────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            // Normalized positions (0.0 – 1.0)
            final startF      = (widget.startMs / total).clamp(0.0, 1.0);
            final endF        = (effectiveEnd   / total).clamp(0.0, 1.0);
            final fadeInEndF  = ((widget.startMs + widget.fadeInMs) / total).clamp(startF, endF);
            final fadeOutStF  = ((effectiveEnd  - widget.fadeOutMs) / total).clamp(startF, endF);

            return GestureDetector(
              onPanStart: _interactive ? (d) => _onPanStart(d, w, total) : null,
              onPanUpdate: _interactive ? (d) => _onPanUpdate(d, w, total, effectiveEnd) : null,
              onPanEnd: _interactive ? (_) => setState(() => _dragging = null) : null,
              child: MouseRegion(
                cursor: _interactive ? SystemMouseCursors.resizeColumn : MouseCursor.defer,
                child: SizedBox(
                  height: 36,
                  child: CustomPaint(
                    size: Size(w, 36),
                    painter: _RulerPainter(
                      startF: startF,
                      endF: endF,
                      fadeInEndF: fadeInEndF,
                      fadeOutStF: fadeOutStF,
                      interactive: _interactive,
                      dragging: _dragging,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // ── Time labels ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _TimeLabels(
            totalMs: total,
            startMs: widget.startMs,
            endMs: effectiveEnd,
            fadeInMs: widget.fadeInMs,
            fadeOutMs: widget.fadeOutMs,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: ScColors.surface2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text('Keine Audiodatei', style: TextStyle(color: ScColors.textDim, fontSize: 11)),
      ),
    );
  }

  void _onPanStart(DragStartDetails d, double w, double total) {
    final x = d.localPosition.dx;
    final effectiveEnd = widget.endMs > 0 && widget.endMs <= total ? widget.endMs : total;

    // Determine which handle is closest (within 16px)
    final handles = <_Handle, double>{
      if (widget.onStartChanged != null)   _Handle.start:   (widget.startMs / total) * w,
      if (widget.onFadeInChanged != null)  _Handle.fadeIn:  ((widget.startMs + widget.fadeInMs) / total) * w,
      if (widget.onFadeOutChanged != null) _Handle.fadeOut: ((effectiveEnd - widget.fadeOutMs) / total) * w,
      if (widget.onEndChanged != null)     _Handle.end:     (effectiveEnd / total) * w,
    };

    _Handle? nearest;
    double minDist = 20;
    for (final e in handles.entries) {
      final dist = (e.value - x).abs();
      if (dist < minDist) { minDist = dist; nearest = e.key; }
    }
    setState(() => _dragging = nearest);
  }

  void _onPanUpdate(DragUpdateDetails d, double w, double total, double effectiveEnd) {
    if (_dragging == null) return;
    final dx = d.delta.dx;
    final dms = (dx / w) * total;

    switch (_dragging!) {
      case _Handle.start:
        final newStart = (widget.startMs + dms).clamp(0.0, effectiveEnd - widget.fadeInMs);
        widget.onStartChanged?.call(newStart);
      case _Handle.fadeIn:
        final newFi = (widget.fadeInMs + dms).clamp(0.0, effectiveEnd - widget.startMs);
        widget.onFadeInChanged?.call(newFi);
      case _Handle.fadeOut:
        final newFo = (widget.fadeOutMs - dms).clamp(0.0, effectiveEnd - widget.startMs);
        widget.onFadeOutChanged?.call(newFo);
      case _Handle.end:
        final newEnd = (effectiveEnd + dms).clamp(widget.startMs + widget.fadeOutMs, total);
        widget.onEndChanged?.call(newEnd);
    }
  }
}

enum _Handle { start, fadeIn, fadeOut, end }

// ── Ruler Painter ─────────────────────────────────────────────────────────────

class _RulerPainter extends CustomPainter {
  final double startF, endF, fadeInEndF, fadeOutStF;
  final bool interactive;
  final _Handle? dragging;

  const _RulerPainter({
    required this.startF,
    required this.endF,
    required this.fadeInEndF,
    required this.fadeOutStF,
    required this.interactive,
    required this.dragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rr = const Radius.circular(4);

    final startX    = startF   * w;
    final endX      = endF     * w;
    final fadeInX   = fadeInEndF * w;
    final fadeOutX  = fadeOutStF * w;

    // Background
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, w, h, rr),
      Paint()..color = ScColors.surface2,
    );

    // Pre-start: dimmed
    if (startX > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, startX, h),
        Paint()..color = ScColors.past.withValues(alpha: 0.3),
      );
    }

    // Active region base tint
    canvas.drawRect(
      Rect.fromLTRB(startX, 0, endX, h),
      Paint()..color = ScColors.active.withValues(alpha: 0.08),
    );

    // Fade-in ramp (green gradient)
    if (fadeInX > startX) {
      final fadeInPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            ScColors.active.withValues(alpha: 0.0),
            ScColors.active.withValues(alpha: 0.28),
          ],
        ).createShader(Rect.fromLTRB(startX, 0, fadeInX, h));
      canvas.drawRect(Rect.fromLTRB(startX, 0, fadeInX, h), fadeInPaint);
    }

    // Fade-out ramp (amber gradient)
    if (endX > fadeOutX) {
      final fadeOutPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            ScColors.warn.withValues(alpha: 0.25),
            ScColors.warn.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTRB(fadeOutX, 0, endX, h));
      canvas.drawRect(Rect.fromLTRB(fadeOutX, 0, endX, h), fadeOutPaint);
    }

    // Post-end: dimmed
    if (endX < w) {
      canvas.drawRect(
        Rect.fromLTRB(endX, 0, w, h),
        Paint()..color = ScColors.past.withValues(alpha: 0.3),
      );
    }

    // Handle lines
    if (interactive) {
      _drawHandle(canvas, startX, h, ScColors.active, dragging == _Handle.start);
      if (fadeInX > startX) _drawHandle(canvas, fadeInX, h, ScColors.active.withValues(alpha: 0.6), dragging == _Handle.fadeIn);
      if (endX > fadeOutX) _drawHandle(canvas, fadeOutX, h, ScColors.warn.withValues(alpha: 0.6), dragging == _Handle.fadeOut);
      _drawHandle(canvas, endX, h, ScColors.textDim, dragging == _Handle.end);
    }

    // Border
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, w, h, rr),
      Paint()
        ..color = ScColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawHandle(Canvas canvas, double x, double h, Color color, bool active) {
    canvas.drawLine(
      Offset(x, 0), Offset(x, h),
      Paint()
        ..color = active ? color : color.withValues(alpha: 0.7)
        ..strokeWidth = active ? 2 : 1,
    );
    // Diamond cap
    final p = Paint()..color = color;
    canvas.drawCircle(Offset(x, h / 2), active ? 5 : 3.5, p);
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.startF != startF || old.endF != endF ||
      old.fadeInEndF != fadeInEndF || old.fadeOutStF != fadeOutStF ||
      old.dragging != dragging;
}

// ── Time Labels ───────────────────────────────────────────────────────────────

class _TimeLabels extends StatelessWidget {
  final double totalMs, startMs, endMs, fadeInMs, fadeOutMs;

  const _TimeLabels({
    required this.totalMs,
    required this.startMs,
    required this.endMs,
    required this.fadeInMs,
    required this.fadeOutMs,
  });

  String _fmt(double ms) {
    final s = (ms / 1000).toStringAsFixed(1);
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Start
        if (startMs > 0) ...[
          Text('IN ${_fmt(startMs)}', style: ScText.statusSmall.copyWith(color: ScColors.textDim, fontSize: 9)),
          const SizedBox(width: 6),
        ],
        // Fade in
        if (fadeInMs > 0) ...[
          Text('FI ${_fmt(fadeInMs)}', style: ScText.statusSmall.copyWith(color: ScColors.active, fontSize: 9)),
          const SizedBox(width: 6),
        ],
        const Spacer(),
        // Fade out
        if (fadeOutMs > 0) ...[
          Text('FO ${_fmt(fadeOutMs)}', style: ScText.statusSmall.copyWith(color: ScColors.warn, fontSize: 9)),
          const SizedBox(width: 6),
        ],
        // End
        Text(
          _fmt(endMs),
          style: ScText.statusSmall.copyWith(color: ScColors.textDim, fontSize: 9),
        ),
      ],
    );
  }
}
