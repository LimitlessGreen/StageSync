import 'package:flutter/material.dart';

import '../sc_colors.dart';
import '../../../providers/waveform_provider.dart';

/// Zeichnet eine Waveform (min/max-Hüllkurve) mit In/Out-Markern und
/// Fade-In/Out-Rampen. Interaktion (Drag der Marker) übernimmt der Aufrufer
/// über [onSeekStart]/[onSeekEnd] mit normalisierten Positionen (0..1).
class ScWaveform extends StatelessWidget {
  final WaveformData data;

  /// In-/Out-Punkt als Anteil der Gesamtlänge (0..1).
  final double startFraction;
  final double endFraction;

  /// Fade-In/Out-Dauer als Anteil der Gesamtlänge (0..1).
  final double fadeInFraction;
  final double fadeOutFraction;

  /// Aktuelle Wiedergabeposition (0..1) oder null.
  final double? playheadFraction;

  /// Callbacks beim Ziehen der Marker (normalisierte X-Position 0..1).
  final ValueChanged<double>? onSeekStart;
  final ValueChanged<double>? onSeekEnd;

  const ScWaveform({
    super.key,
    required this.data,
    this.startFraction = 0.0,
    this.endFraction = 1.0,
    this.fadeInFraction = 0.0,
    this.fadeOutFraction = 0.0,
    this.playheadFraction,
    this.onSeekStart,
    this.onSeekEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handleDrag(d.localPosition.dx, width),
          onHorizontalDragUpdate: (d) => _handleDrag(d.localPosition.dx, width),
          child: CustomPaint(
            size: Size(width, constraints.maxHeight),
            painter: _WaveformPainter(
              data: data,
              startFraction: startFraction,
              endFraction: endFraction,
              fadeInFraction: fadeInFraction,
              fadeOutFraction: fadeOutFraction,
              playheadFraction: playheadFraction,
            ),
          ),
        );
      },
    );
  }

  void _handleDrag(double dx, double width) {
    if (width <= 0) return;
    final frac = (dx / width).clamp(0.0, 1.0);
    // Näheren Marker (In vs. Out) verschieben.
    final distStart = (frac - startFraction).abs();
    final distEnd = (frac - endFraction).abs();
    if (distStart <= distEnd) {
      onSeekStart?.call(frac.clamp(0.0, endFraction));
    } else {
      onSeekEnd?.call(frac.clamp(startFraction, 1.0));
    }
  }
}

class _WaveformPainter extends CustomPainter {
  final WaveformData data;
  final double startFraction;
  final double endFraction;
  final double fadeInFraction;
  final double fadeOutFraction;
  final double? playheadFraction;

  _WaveformPainter({
    required this.data,
    required this.startFraction,
    required this.endFraction,
    required this.fadeInFraction,
    required this.fadeOutFraction,
    this.playheadFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final bg = Paint()..color = ScColors.surface;
    canvas.drawRect(Offset.zero & size, bg);

    if (data.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'Keine Waveform',
          style: TextStyle(color: ScColors.textDim, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset((size.width - tp.width) / 2, mid - tp.height / 2));
      return;
    }

    final n = data.buckets;
    final dx = size.width / n;

    // Außerhalb [start,end] gedimmt, innerhalb aktiv.
    final activePaint = Paint()
      ..color = ScColors.active.withValues(alpha: 0.85);
    final dimPaint = Paint()..color = ScColors.textDim.withValues(alpha: 0.5);

    for (var i = 0; i < n; i++) {
      final frac = i / n;
      final x = i * dx;
      final top = mid - data.maxs[i] * mid;
      final bot = mid - data.mins[i] * mid;
      final inRange = frac >= startFraction && frac <= endFraction;
      canvas.drawLine(
          Offset(x, top), Offset(x, bot), inRange ? activePaint : dimPaint);
    }

    // Mittellinie
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()..color = ScColors.divider,
    );

    // Fade-In-Rampe (von start über fadeIn-Breite).
    final markerPaint = Paint()
      ..color = ScColors.warn
      ..strokeWidth = 1.5;
    if (fadeInFraction > 0) {
      final x0 = startFraction * size.width;
      final x1 = (startFraction + fadeInFraction).clamp(0.0, 1.0) * size.width;
      canvas.drawLine(Offset(x0, size.height), Offset(x1, 0), markerPaint);
    }
    if (fadeOutFraction > 0) {
      final x1 = endFraction * size.width;
      final x0 = (endFraction - fadeOutFraction).clamp(0.0, 1.0) * size.width;
      canvas.drawLine(Offset(x0, 0), Offset(x1, size.height), markerPaint);
    }

    // In/Out-Marker
    _drawMarker(canvas, size, startFraction, ScColors.active);
    _drawMarker(canvas, size, endFraction, ScColors.error);

    // Playhead
    final ph = playheadFraction;
    if (ph != null) {
      final x = ph.clamp(0.0, 1.0) * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = ScColors.textPrimary
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawMarker(Canvas canvas, Size size, double frac, Color color) {
    final x = frac.clamp(0.0, 1.0) * size.width;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.data != data ||
      old.startFraction != startFraction ||
      old.endFraction != endFraction ||
      old.fadeInFraction != fadeInFraction ||
      old.fadeOutFraction != fadeOutFraction ||
      old.playheadFraction != playheadFraction;
}
