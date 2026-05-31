import 'package:flutter/material.dart';
import '../../../domain/cue_params.dart';
import '../../../domain/asset.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';

/// Compact audio cue visualization bar.
/// Phase 1: duration + fade visualization only (no waveform renderer).
/// Phase 3+: can add a waveform painter here without changing the API.
class AudioCueMinibar extends StatelessWidget {
  final AudioParams params;
  final Asset? asset;           // null if asset not yet resolved
  final double? knownDurationMs; // from asset metadata if available

  const AudioCueMinibar({
    super.key,
    required this.params,
    this.asset,
    this.knownDurationMs,
  });

  double get _durationMs =>
      knownDurationMs ??
      asset?.audio?.declaredDurationMs ??
      params.effectiveDurationMs ??
      0;

  @override
  Widget build(BuildContext context) {
    final duration = _durationMs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Asset info row ────────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.audio_file, size: 14, color: Colors.blue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                asset?.name ?? (params.assetId.isEmpty ? 'Kein Asset' : params.assetId),
                style: ScText.cueLabel.copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (asset != null) ...[
              const SizedBox(width: 8),
              _ReadinessBadge(readiness: asset!.readiness),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // ── Waveform placeholder / duration bar ───────────────────────
        _DurationFadeBar(
          durationMs: duration,
          fadeInMs: params.fadeInMs,
          fadeOutMs: params.fadeOutMs,
        ),
        const SizedBox(height: 4),
        // ── Metadata row ──────────────────────────────────────────────
        Row(
          children: [
            Text(_formatDuration(duration), style: ScText.numberSmall),
            if (params.volumeDb != 0) ...[
              const SizedBox(width: 12),
              Text(
                '${params.volumeDb > 0 ? "+" : ""}${params.volumeDb.toStringAsFixed(1)} dB',
                style: ScText.numberSmall,
              ),
            ],
            if (params.loop) ...[
              const SizedBox(width: 12),
              const Icon(Icons.loop, size: 12, color: ScColors.textDim),
            ],
            // Startzeit-Anzeige
            if (params.assetId.isNotEmpty && params.startTimeMs == 0) ...[
              const SizedBox(width: 12),
              const Icon(Icons.skip_next, size: 11, color: ScColors.active),
              Text(
                'AUTO',
                style: ScText.label.copyWith(color: ScColors.active, fontSize: 9),
              ),
            ] else if (params.startTimeMs > 0.001) ...[
              const SizedBox(width: 12),
              Icon(Icons.skip_next, size: 11, color: ScColors.textDim),
              Text(
                _formatDuration(params.startTimeMs),
                style: ScText.label.copyWith(color: ScColors.textDim),
              ),
            ],
            if (asset?.audio != null) ...[
              const SizedBox(width: 12),
              Text(
                '${asset!.audio!.channelLabel} · ${asset!.audio!.codec}',
                style: ScText.label,
              ),
            ],
          ],
        ),
      ],
    );
  }

  static String _formatDuration(double ms) {
    if (ms <= 0) return '—';
    final s = ms / 1000;
    if (s < 60) return '${s.toStringAsFixed(1)}s';
    final m = (s / 60).floor();
    final rs = (s % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$rs';
  }
}

class _DurationFadeBar extends StatelessWidget {
  final double durationMs;
  final double fadeInMs;
  final double fadeOutMs;

  const _DurationFadeBar({
    required this.durationMs,
    required this.fadeInMs,
    required this.fadeOutMs,
  });

  @override
  Widget build(BuildContext context) {
    if (durationMs <= 0) {
      return Container(
        height: 24,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text('Dauer unbekannt', style: ScText.label),
        ),
      );
    }

    final fadeInFrac  = (fadeInMs / durationMs).clamp(0.0, 0.45);
    final fadeOutFrac = (fadeOutMs / durationMs).clamp(0.0, 0.45);

    return Container(
      height: 24,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: CustomPaint(
        painter: _FadePainter(
          fadeInFrac: fadeInFrac,
          fadeOutFrac: fadeOutFrac,
        ),
      ),
    );
  }
}

class _FadePainter extends CustomPainter {
  final double fadeInFrac;
  final double fadeOutFrac;

  _FadePainter({required this.fadeInFrac, required this.fadeOutFrac});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue.withValues(alpha: 0.35);

    // Sustained level fill
    final fadeInW  = size.width * fadeInFrac;
    final fadeOutW = size.width * fadeOutFrac;
    canvas.drawRect(
      Rect.fromLTWH(fadeInW, 0, size.width - fadeInW - fadeOutW, size.height),
      paint,
    );

    // Fade-in ramp (triangle)
    if (fadeInW > 0) {
      final path = Path()
        ..moveTo(0, size.height)
        ..lineTo(fadeInW, 0)
        ..lineTo(fadeInW, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }

    // Fade-out ramp (triangle)
    if (fadeOutW > 0) {
      final path = Path()
        ..moveTo(size.width - fadeOutW, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - fadeOutW, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FadePainter old) =>
      old.fadeInFrac != fadeInFrac || old.fadeOutFrac != fadeOutFrac;
}

class _ReadinessBadge extends StatelessWidget {
  final AssetReadiness readiness;
  const _ReadinessBadge({required this.readiness});

  Color get _color => switch (readiness) {
        AssetReadiness.patched    => ScColors.active,
        AssetReadiness.renderable => ScColors.warn,
        AssetReadiness.validated  => const Color(0xFF42A5F5),
        AssetReadiness.present    => ScColors.warn,
      };

  String get _label => switch (readiness) {
        AssetReadiness.patched    => '✓',
        AssetReadiness.renderable => '▶',
        AssetReadiness.validated  => '✓',
        AssetReadiness.present    => '↑',
      };

  String get _tooltip => switch (readiness) {
        AssetReadiness.patched    => 'Bereit auf allen Nodes',
        AssetReadiness.renderable => 'Abspielbar (nicht vollständig verteilt)',
        AssetReadiness.validated  => 'Geprüft',
        AssetReadiness.present    => 'Auf Server – wird auf Nodes verteilt',
      };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _color.withValues(alpha: 0.4)),
        ),
        child: Text(
          _label,
          style: ScText.labelBold.copyWith(color: _color, fontSize: 10),
        ),
      ),
    );
  }
}
