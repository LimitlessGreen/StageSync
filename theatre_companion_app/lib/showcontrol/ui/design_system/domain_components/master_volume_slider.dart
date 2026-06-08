import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';

/// DAW-style master volume slider.
///
/// Range: −60 dB (mute) to +6 dB (boost).
/// 0 dB (unity) is marked visually at the 90% position.
/// No domain knowledge — takes raw dB and emits dB.
class MasterVolumeSlider extends StatelessWidget {
  final double value; // current value in dB
  final ValueChanged<double> onChanged;
  final bool compact; // true = single-row, false = with label row

  static const double _min = -60.0;
  static const double _max = 6.0;

  const MasterVolumeSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  String get _label {
    if (value <= _min) return '−∞';
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)} dB';
  }

  Color get _trackColor {
    if (value <= _min) return ScColors.past;
    if (value > 0) return ScColors.warn;
    return ScColors.active;
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _compactRow(context);
    return _fullRow(context);
  }

  Widget _fullRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up, size: 14, color: ScColors.textDim),
            const SizedBox(width: 6),
            const Text('MASTER VOLUME',
                style: TextStyle(
                  color: ScColors.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                )),
            const Spacer(),
            Text(_label,
                style: ScText.numberSmall.copyWith(
                  color: _trackColor,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
        _slider(context),
      ],
    );
  }

  Widget _compactRow(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.volume_up, size: 14, color: ScColors.textDim),
        Expanded(child: _slider(context)),
        SizedBox(
          width: 44,
          child: Text(
            _label,
            style:
                ScText.numberSmall.copyWith(color: _trackColor, fontSize: 10),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _slider(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: _trackColor,
        inactiveTrackColor: ScColors.divider,
        thumbColor: _trackColor,
        overlayColor: _trackColor.withValues(alpha: 0.18),
      ),
      child: Slider(
        value: value.clamp(_min, _max),
        min: _min,
        max: _max,
        // Snap to 0 dB when within 0.5 dB
        onChanged: (v) {
          final snapped = (v - 0.0).abs() < 0.5 ? 0.0 : v;
          onChanged(double.parse(snapped.toStringAsFixed(1)));
        },
      ),
    );
  }
}

/// dB to linear conversion helper — exposed for reuse in engine glue.
double dbToLinear(double db) =>
    db <= -60.0 ? 0.0 : math.pow(10.0, db / 20.0).toDouble();
