import 'package:flutter/material.dart';

import '../sc_colors.dart';
import '../../../domain/grid_run_state.dart';
import '../../../grpc/generated/stagesync/v1/grid.pb.dart';

/// Eine einzelne Matrix-Zelle (Clip) im Grid-Controller.
///
/// Visualisiert Belegung, Payload-Typ und Lebenszyklus. Zeigt für laufende
/// Audio-Clips einen Fortschrittsbalken (per [progress] 0..1 vom Aufrufer
/// gespeist, der die Server-Zeit kennt).
class ScGridCell extends StatelessWidget {
  final GridClip? clip;
  final GridClipRunState runState;

  /// Fortschritt 0..1 für laufende Audio-Clips (sonst null).
  final double? progress;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  const ScGridCell({
    super.key,
    required this.clip,
    this.runState = const GridClipRunState(),
    this.progress,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final empty = clip == null;
    final borderColor = _borderColor();
    final fill = _fillColor();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? ScColors.active : borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Fortschrittsbalken (unten) für laufende Audio-Clips.
            if (progress != null && runState.lifecycle == ClipLifecycle.playing)
              Positioned(
                left: 0,
                bottom: 0,
                right: 0,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress!.clamp(0.0, 1.0),
                  child: Container(height: 3, color: ScColors.active),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!empty) _typeBadge(),
                  const Spacer(),
                  Text(
                    empty ? '' : (clip!.label.isEmpty ? '—' : clip!.label),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: empty ? ScColors.textDim : ScColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge() {
    final (label, color) = _payloadMeta();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  (String, Color) _payloadMeta() {
    final c = clip;
    if (c == null) return ('', ScColors.textDim);
    if (c.hasAudio()) return ('AUDIO', ScColors.active);
    if (c.hasOsc()) return ('OSC', ScColors.warn);
    if (c.hasMidi()) return ('MIDI', const Color(0xFF40C4FF));
    if (c.hasCueRef()) return ('CUE', const Color(0xFFB388FF));
    return ('?', ScColors.textDim);
  }

  Color _borderColor() {
    switch (runState.lifecycle) {
      case ClipLifecycle.playing:
        return ScColors.active;
      case ClipLifecycle.launched:
        return ScColors.warn;
      case ClipLifecycle.error:
        return ScColors.error;
      default:
        return clip == null ? ScColors.divider : ScColors.surface2;
    }
  }

  Color _fillColor() {
    if (clip == null) return ScColors.bg;
    final c = clip!;
    if (c.colorHex.isNotEmpty) {
      final parsed = _parseHex(c.colorHex);
      if (parsed != null) return parsed.withValues(alpha: 0.18);
    }
    if (runState.lifecycle == ClipLifecycle.playing) {
      return ScColors.active.withValues(alpha: 0.12);
    }
    return ScColors.surface;
  }

  Color? _parseHex(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }
}
