import 'package:flutter/material.dart';
import '../primitives/sc_meter.dart';
import '../sc_typography.dart';

/// Audio level meter with peak hold — wraps [ScMeter].
/// Updated by caller via [level] and [peak] (0.0–1.0 normalized).
/// For real-time updates, rebuild this widget from a Stream/Timer.
class LevelMeter extends StatelessWidget {
  final double level;
  final double peak;
  final String? channelLabel;
  final double height;

  const LevelMeter({
    super.key,
    required this.level,
    required this.peak,
    this.channelLabel,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: 12,
          child: ScMeter(level: level, peak: peak),
        ),
        if (channelLabel != null) ...[
          const SizedBox(height: 4),
          Text(channelLabel!,
              style: ScText.labelBold, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

/// Stereo level meter pair (L + R).
class StereoLevelMeter extends StatelessWidget {
  final double levelL;
  final double levelR;
  final double peakL;
  final double peakR;
  final double height;

  const StereoLevelMeter({
    super.key,
    required this.levelL,
    required this.levelR,
    this.peakL = 0,
    this.peakR = 0,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LevelMeter(
            level: levelL, peak: peakL, channelLabel: 'L', height: height),
        const SizedBox(width: 4),
        LevelMeter(
            level: levelR, peak: peakR, channelLabel: 'R', height: height),
      ],
    );
  }
}

/// Placeholder meter with animated shimmer for "no data" state.
class LevelMeterPlaceholder extends StatefulWidget {
  final double height;
  const LevelMeterPlaceholder({super.key, this.height = 80});

  @override
  State<LevelMeterPlaceholder> createState() => _LevelMeterPlaceholderState();
}

class _LevelMeterPlaceholderState extends State<LevelMeterPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => StereoLevelMeter(
        levelL: 0.0,
        levelR: 0.0,
        height: widget.height,
      ),
    );
  }
}
