import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../sc_colors.dart';
import '../sc_spacing.dart';
import '../sc_typography.dart';

enum ScButtonVariant { primary, danger, secondary, ghost }

/// [large]     → 80px (mobile full-screen GO)
/// [transport] → 44px (desktop transport-bar GO, visually dominant)
/// [normal]    → 36px
/// [compact]   → 28px
enum ScButtonSize { large, transport, normal, compact }

/// Primitive SC button — no domain knowledge.
///
/// [primary]   → GO-style (Arc Light signature design)
/// [danger]    → STOP-style (red outlined or fill)
/// [secondary] → PAUSE/RESUME-style (amber outlined)
/// [ghost]     → toolbar icon-buttons (transparent)
class ScButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ScButtonVariant variant;
  final ScButtonSize size;
  final bool isLoading;
  final String? shortcutHint;

  /// Wenn gesetzt: Button ist bis zu diesem Zeitpunkt gesperrt (Arc-Light-Lock-Animation).
  final DateTime? lockEndTime;

  const ScButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = ScButtonVariant.primary,
    this.size = ScButtonSize.normal,
    this.isLoading = false,
    this.shortcutHint,
    this.lockEndTime,
  });

  @override
  State<ScButton> createState() => _ScButtonState();
}

class _ScButtonState extends State<ScButton> with TickerProviderStateMixin {
  bool _pressed = false;

  // Bounce on tap
  late final AnimationController _bounceCtrl;
  late final Animation<double> _scaleAnim;

  // Arc Light: breathing inner radial glow
  late final AnimationController _breatheCtrl;
  late final Animation<double> _breatheAnim;

  // Arc Light: press flash burst
  late final AnimationController _flashCtrl;
  late final Animation<double> _flashAnim;

  // Legacy outer pulse (non-primary variants)
  late final AnimationController _pulseCtrl;
  late final Animation<double> _glowAnim;

  // Lock-Ticker: feuert ~60fps während der Button gesperrt ist
  Timer? _lockTicker;
  DateTime? _lockStartTime;

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.93)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.93, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_bounceCtrl);

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _breatheAnim = CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut);

    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _flashAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.55)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.55, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 80,
      ),
    ]).animate(_flashCtrl);

    // Non-primary pulsing halo (kept for danger/secondary if ever needed)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ScButton old) {
    super.didUpdateWidget(old);
    final wasLocked = old.lockEndTime != null &&
        old.lockEndTime!.isAfter(DateTime.now());
    final isLocked = widget.lockEndTime != null &&
        widget.lockEndTime!.isAfter(DateTime.now());
    if (isLocked && !wasLocked) {
      _lockStartTime = DateTime.now();
      _lockTicker ??= Timer.periodic(
        const Duration(milliseconds: 16),
        (_) { if (mounted) setState(() {}); },
      );
    } else if (!isLocked) {
      _lockTicker?.cancel();
      _lockTicker = null;
      _lockStartTime = null;
    }
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    _bounceCtrl.dispose();
    _breatheCtrl.dispose();
    _flashCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isLocked = widget.lockEndTime != null &&
        widget.lockEndTime!.isAfter(now);

    // Fortschritt 0.0 (gerade gesperrt) → 1.0 (Sperre endet)
    double lockProgress = 0.0;
    if (isLocked && _lockStartTime != null) {
      final totalMs = widget.lockEndTime!
          .difference(_lockStartTime!)
          .inMicroseconds;
      final elapsedMs = now.difference(_lockStartTime!).inMicroseconds;
      lockProgress = totalMs > 0 ? (elapsedMs / totalMs).clamp(0.0, 1.0) : 0.0;
    }

    final enabled = widget.onPressed != null && !widget.isLoading && !isLocked;
    final isPrimary = widget.variant == ScButtonVariant.primary;
    final isArcLight = isPrimary &&
        (widget.size == ScButtonSize.large ||
            widget.size == ScButtonSize.transport);

    final height = switch (widget.size) {
      ScButtonSize.large => ScSpacing.buttonHeightLarge,
      ScButtonSize.transport => 44.0,
      ScButtonSize.normal => ScSpacing.buttonHeightDefault,
      ScButtonSize.compact => ScSpacing.buttonHeightCompact,
    };

    final radius = widget.size == ScButtonSize.large ? 16.0 : 8.0;

    Widget child;
    if (isArcLight) {
      child = _buildArcLight(enabled, isLocked, lockProgress, height, radius);
    } else {
      child = _buildStandard(enabled, height, radius);
    }

    return Tooltip(
      message: widget.shortcutHint != null
          ? '${widget.label}  [${widget.shortcutHint}]'
          : widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                _bounceCtrl.forward(from: 0);
                _flashCtrl.forward(from: 0);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: ScaleTransition(scale: _scaleAnim, child: child),
      ),
    );
  }

  // ── Arc Light (primary large/transport) ───────────────────────────────────

  Widget _buildArcLight(
      bool enabled, bool isLocked, double lockProgress, double height, double radius) {
    final isTransport = widget.size == ScButtonSize.transport;
    final bracketSize = isTransport ? 8.0 : 14.0;
    final padding = EdgeInsets.symmetric(horizontal: isTransport ? 16 : 20);

    return AnimatedBuilder(
      animation: Listenable.merge([_breatheAnim, _flashAnim]),
      builder: (context, _) {
        final t = enabled ? _breatheAnim.value : 0.0;
        final glowOpacity = enabled ? (0.18 + t * 0.42) : 0.05;
        final glowRadius = 0.55 + t * 0.30;
        final borderOpacity = isLocked
            ? 0.0 // Border wird durch Lock-Painter ersetzt
            : (enabled ? (_pressed ? 1.0 : 0.45 + t * 0.35) : 0.15);
        final flashOpacity = _flashAnim.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              // ── Base: deep dark background ──────────────────────────
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: isLocked
                      ? const Color(0xFF111111)
                      : (enabled
                          ? const Color(0xFF0B0B0B)
                          : const Color(0xFF111111)),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: ScColors.active.withValues(alpha: borderOpacity),
                    width: 1.5,
                  ),
                ),
              ),

              // ── Radial glow burst (nur wenn nicht gesperrt) ─────────
              if (enabled && !isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: glowRadius,
                        colors: [
                          ScColors.active.withValues(alpha: glowOpacity),
                          ScColors.active.withValues(alpha: glowOpacity * 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

              // ── Press flash burst ────────────────────────────────────
              if (flashOpacity > 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.white.withValues(alpha: flashOpacity),
                          ScColors.active.withValues(alpha: flashOpacity * 0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),

              // ── Content: GO text ─────────────────────────────────────
              SizedBox(
                height: height,
                child: Padding(
                  padding: padding,
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ScColors.active,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _arcLightLabel(enabled || isLocked, isTransport,
                                  dimmed: isLocked),
                              if (widget.shortcutHint != null)
                                Text(widget.shortcutHint!,
                                    style: ScText.shortcutHint),
                            ],
                          ),
                  ),
                ),
              ),

              // ── Corner brackets (ausgeblendet während Lock) ──────────
              if (!isLocked)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CornerBracketPainter(
                      color: ScColors.active,
                      opacity: enabled ? (0.5 + t * 0.5) : 0.15,
                      bracketSize: bracketSize,
                      strokeWidth: 1.5,
                      radius: radius,
                    ),
                  ),
                ),

              // ── Lock: umlaufender Fortschrittsbalken ─────────────────
              if (isLocked)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LockProgressPainter(
                      progress: lockProgress,
                      color: ScColors.active,
                      radius: radius,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _arcLightLabel(bool enabled, bool isTransport, {bool dimmed = false}) {
    final fontSize = isTransport ? 18.0 : 28.0;
    final letterSpacing = isTransport ? 5.0 : 8.0;

    return Text(
      widget.label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: letterSpacing,
        color: dimmed
            ? ScColors.textDim
            : (enabled ? Colors.white : ScColors.textDim),
        shadows: enabled && !dimmed
            ? [
                Shadow(
                  color: ScColors.active.withValues(alpha: 0.7),
                  blurRadius: 12,
                ),
                Shadow(
                  color: ScColors.active.withValues(alpha: 0.3),
                  blurRadius: 28,
                ),
              ]
            : null,
      ),
    );
  }

  // ── Standard buttons (danger / secondary / ghost / small primary) ─────────

  Widget _buildStandard(bool enabled, double height, double radius) {
    final (color, onColor, isFilled) = switch (widget.variant) {
      ScButtonVariant.primary => (ScColors.active, Colors.black, true),
      ScButtonVariant.danger => (ScColors.error, Colors.white, false),
      ScButtonVariant.secondary => (ScColors.warn, Colors.black, false),
      ScButtonVariant.ghost => (ScColors.textDim, Colors.white, false),
    };

    final effectiveColor =
        _pressed && enabled ? color.withValues(alpha: 0.55) : color;

    BoxDecoration buildDeco(double glowT) {
      final isPrimaryEnabled = isFilled && enabled;
      final blurRadius = isPrimaryEnabled && !_pressed
          ? 12.0 + glowT * 14.0
          : 0.0;
      final glowAlpha = isPrimaryEnabled && !_pressed
          ? 0.22 + glowT * 0.22
          : 0.0;
      return BoxDecoration(
        color: isFilled
            ? (enabled ? effectiveColor : ScColors.past)
            : (_pressed && enabled ? color.withValues(alpha: 0.12) : null),
        border: isFilled
            ? null
            : Border.all(
                color: effectiveColor.withValues(alpha: enabled ? 0.7 : 0.3)),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: blurRadius > 0
            ? [
                BoxShadow(
                  color: color.withValues(alpha: glowAlpha),
                  blurRadius: blurRadius,
                  spreadRadius: 2,
                ),
              ]
            : null,
      );
    }

    final content = widget.isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isFilled ? onColor : color,
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNormalContent(effectiveColor, onColor, enabled, isFilled),
              if (widget.shortcutHint != null)
                Text(widget.shortcutHint!, style: ScText.shortcutHint),
            ],
          );

    return isFilled && enabled
        ? AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) => Container(
              height: height,
              decoration: buildDeco(_glowAnim.value),
              padding: EdgeInsets.symmetric(
                horizontal: widget.size == ScButtonSize.compact ? 10 : 16,
              ),
              child: Center(child: content),
            ),
          )
        : AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            height: height,
            decoration: buildDeco(0),
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == ScButtonSize.compact ? 10 : 16,
            ),
            child: Center(child: content),
          );
  }

  Widget _buildNormalContent(
      Color color, Color onColor, bool enabled, bool isFilled) {
    final textColor = enabled ? (isFilled ? onColor : color) : ScColors.textDim;
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontSize: widget.size == ScButtonSize.compact ? 11 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    return Text(
      widget.label,
      style: TextStyle(
        color: textColor,
        fontSize: widget.size == ScButtonSize.compact ? 11 : 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Lock Progress Painter ─────────────────────────────────────────────────────

/// Zeichnet einen umlaufenden Fortschrittsbalken entlang des Button-Randes.
/// Startet oben-links, läuft im Uhrzeigersinn. Progress 0.0 → 1.0.
class _LockProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double radius;
  final double strokeWidth;

  const _LockProgressPainter({
    required this.progress,
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final inset = strokeWidth * 2.0;
    final rect = Rect.fromLTWH(inset, inset,
        size.width - inset * 2, size.height - inset * 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Umfang des Rounded-Rects
    final perimeter = _rrectPerimeter(rect.width, rect.height, radius);
    final drawn = perimeter * progress;

    // Track (volle Strecke, dunkel)
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    // Fortschritts-Pfad
    final path = _buildProgressPath(rect, radius, drawn, perimeter);

    // Glüh-Halo
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.28)
        ..strokeWidth = strokeWidth * 4.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    // Kern
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.95)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Leuchtpunkt an der Spitze
    if (drawn < perimeter) {
      final tip = _pointAtDistance(rect, radius, drawn, perimeter);
      canvas.drawCircle(tip, strokeWidth * 2.2,
          Paint()..color = Colors.white.withValues(alpha: 0.95));
      canvas.drawCircle(tip, strokeWidth * 4.0,
          Paint()..color = color.withValues(alpha: 0.35));
    }
  }

  // Perimeter eines Rounded-Rects
  double _rrectPerimeter(double w, double h, double r) {
    final straight = 2 * (w - 2 * r) + 2 * (h - 2 * r);
    final corners = 2 * math.pi * r;
    return straight + corners;
  }

  // Baut den Pfad für [drawn] Pixel ab dem Startpunkt (oben-links, Mitte der oberen Kante)
  Path _buildProgressPath(Rect r, double cr, double drawn, double total) {
    final path = Path();
    // Startpunkt: oben-links (nach dem Eckenradius), läuft im Uhrzeigersinn
    path.moveTo(r.left + cr, r.top);
    double rem = drawn;

    rem = _addSegment(path, rem, r.right - cr - (r.left + cr),
        r.left + cr, r.top, 1, 0); // → oben-rechts
    if (rem <= 0) return path;
    rem = _addArc(path, rem, cr, r.right - cr, r.top + cr, -math.pi / 2, math.pi / 2); // Ecke oben-rechts
    if (rem <= 0) return path;
    rem = _addSegment(path, rem, r.bottom - cr - (r.top + cr),
        r.right, r.top + cr, 0, 1); // → unten-rechts
    if (rem <= 0) return path;
    rem = _addArc(path, rem, cr, r.right - cr, r.bottom - cr, 0, math.pi / 2); // Ecke unten-rechts
    if (rem <= 0) return path;
    rem = _addSegment(path, rem, r.right - cr - (r.left + cr),
        r.right - cr, r.bottom, -1, 0); // → unten-links
    if (rem <= 0) return path;
    rem = _addArc(path, rem, cr, r.left + cr, r.bottom - cr, math.pi / 2, math.pi / 2); // Ecke unten-links
    if (rem <= 0) return path;
    rem = _addSegment(path, rem, r.bottom - cr - (r.top + cr),
        r.left, r.bottom - cr, 0, -1); // → oben-links
    if (rem <= 0) return path;
    _addArc(path, rem, cr, r.left + cr, r.top + cr, math.pi, math.pi / 2); // Ecke oben-links
    return path;
  }

  double _addSegment(Path path, double rem, double len,
      double x, double y, double dx, double dy) {
    if (rem <= 0) return rem;
    final d = rem < len ? rem : len;
    path.lineTo(x + dx * d, y + dy * d);
    return rem - len;
  }

  double _addArc(Path path, double rem, double r,
      double cx, double cy, double startAngle, double maxSweep) {
    if (rem <= 0) return rem;
    final arcLen = r * maxSweep;
    final sweep = rem < arcLen ? maxSweep * (rem / arcLen) : maxSweep;
    path.arcTo(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle, sweep, false,
    );
    return rem - arcLen;
  }

  // Berechnet den Punkt auf dem Pfad bei [drawn] Pixeln
  Offset _pointAtDistance(Rect r, double cr, double drawn, double total) {
    double rem = drawn;
    Offset pt = Offset(r.left + cr, r.top);

    double seg = r.width - 2 * cr;
    if (rem <= seg) return Offset(r.left + cr + rem, r.top);
    rem -= seg; pt = Offset(r.right - cr, r.top);

    double arcLen = cr * math.pi / 2;
    if (rem <= arcLen) {
      final a = -math.pi / 2 + (rem / arcLen) * (math.pi / 2);
      return Offset(r.right - cr + cr * math.cos(a), r.top + cr + cr * math.sin(a));
    }
    rem -= arcLen; pt = Offset(r.right, r.top + cr);

    seg = r.height - 2 * cr;
    if (rem <= seg) return Offset(r.right, r.top + cr + rem);
    rem -= seg; pt = Offset(r.right, r.bottom - cr);

    arcLen = cr * math.pi / 2;
    if (rem <= arcLen) {
      final a = 0.0 + (rem / arcLen) * (math.pi / 2);
      return Offset(r.right - cr + cr * math.cos(a), r.bottom - cr + cr * math.sin(a));
    }
    rem -= arcLen; pt = Offset(r.right - cr, r.bottom);

    seg = r.width - 2 * cr;
    if (rem <= seg) return Offset(r.right - cr - rem, r.bottom);
    rem -= seg; pt = Offset(r.left + cr, r.bottom);

    arcLen = cr * math.pi / 2;
    if (rem <= arcLen) {
      final a = math.pi / 2 + (rem / arcLen) * (math.pi / 2);
      return Offset(r.left + cr + cr * math.cos(a), r.bottom - cr + cr * math.sin(a));
    }
    rem -= arcLen; pt = Offset(r.left, r.bottom - cr);

    seg = r.height - 2 * cr;
    if (rem <= seg) return Offset(r.left, r.bottom - cr - rem);
    rem -= seg; pt = Offset(r.left, r.top + cr);

    arcLen = cr * math.pi / 2;
    if (rem <= arcLen) {
      final a = math.pi + (rem / arcLen) * (math.pi / 2);
      return Offset(r.left + cr + cr * math.cos(a), r.top + cr + cr * math.sin(a));
    }
    return pt;
  }

  @override
  bool shouldRepaint(_LockProgressPainter old) => old.progress != progress;
}

// ── Corner Bracket Painter ────────────────────────────────────────────────────

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double bracketSize;
  final double strokeWidth;
  final double radius;

  const _CornerBracketPainter({
    required this.color,
    required this.opacity,
    required this.bracketSize,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final inset = strokeWidth / 2;
    final b = bracketSize;
    final w = size.width;
    final h = size.height;

    // Top-left
    _drawBracket(canvas, paint, Offset(inset, inset + b), Offset(inset, inset),
        Offset(inset + b, inset));
    // Top-right
    _drawBracket(canvas, paint, Offset(w - inset - b, inset),
        Offset(w - inset, inset), Offset(w - inset, inset + b));
    // Bottom-left
    _drawBracket(canvas, paint, Offset(inset, h - inset - b),
        Offset(inset, h - inset), Offset(inset + b, h - inset));
    // Bottom-right
    _drawBracket(canvas, paint, Offset(w - inset - b, h - inset),
        Offset(w - inset, h - inset), Offset(w - inset, h - inset - b));
  }

  void _drawBracket(
      Canvas canvas, Paint paint, Offset a, Offset corner, Offset c) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(corner.dx, corner.dy)
      ..lineTo(c.dx, c.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) =>
      old.opacity != opacity || old.color != color;
}
