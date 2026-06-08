import 'package:flutter/material.dart';
import '../sc_colors.dart';

/// Primitive level meter bar — no domain knowledge.
/// Horizontal or vertical orientation with peak-hold marker.
class ScMeter extends StatelessWidget {
  final double level; // 0.0–1.0
  final double peak; // 0.0–1.0 peak hold
  final bool vertical;
  final double thickness;
  final double
      clipThreshold; // level above which the bar turns red (default 0.9)

  const ScMeter({
    super.key,
    required this.level,
    this.peak = 0.0,
    this.vertical = true,
    this.thickness = 8,
    this.clipThreshold = 0.9,
  });

  Color _levelColor(double v) {
    if (v >= clipThreshold) return ScColors.meterHigh;
    if (v >= 0.65) return ScColors.meterMid;
    return ScColors.meterLow;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MeterPainter(
        level: level.clamp(0.0, 1.0),
        peak: peak.clamp(0.0, 1.0),
        color: _levelColor(level),
        peakColor: _levelColor(peak),
        vertical: vertical,
        clipThreshold: clipThreshold,
      ),
      size: vertical
          ? Size(thickness, double.infinity)
          : Size(double.infinity, thickness),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double level;
  final double peak;
  final Color color;
  final Color peakColor;
  final bool vertical;
  final double clipThreshold;

  _MeterPainter({
    required this.level,
    required this.peak,
    required this.color,
    required this.peakColor,
    required this.vertical,
    required this.clipThreshold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final fg = Paint()..color = color;
    final pk = Paint()..color = peakColor;

    if (vertical) {
      // Background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(3),
        ),
        bg,
      );
      // Level bar (from bottom)
      final barH = size.height * level;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height - barH, size.width, barH),
          const Radius.circular(3),
        ),
        fg,
      );
      // Peak marker
      if (peak > 0) {
        final pkY = size.height - (size.height * peak);
        canvas.drawRect(
          Rect.fromLTWH(0, pkY, size.width, 2),
          pk,
        );
      }
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(3),
        ),
        bg,
      );
      final barW = size.width * level;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, barW, size.height),
          const Radius.circular(3),
        ),
        fg,
      );
      if (peak > 0) {
        final pkX = size.width * peak;
        canvas.drawRect(Rect.fromLTWH(pkX - 1, 0, 2, size.height), pk);
      }
    }
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.level != level || old.peak != peak || old.color != color;
}
