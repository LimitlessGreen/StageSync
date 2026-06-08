// qr_scan_screen.dart
// ─────────────────────────────
// Wiederverwendbarer Vollbild-Scanner für QR-Codes und andere Binärcodes.
//
// Gibt beim ersten erkannten Code via [Navigator.pop] das Ergebnis zurück:
//   `Navigator.push<String>(context, ...)`  →  `String? qrValue`
//
// Unterstützte Formate (über mobile_scanner):
//   QR-Code, EAN-8/13, Code128, Code39, PDF417, Aztec, DataMatrix, …
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ─────────────────────────────────────────────────────────────────────────────

class QrScanScreen extends StatefulWidget {
  /// Titel in der AppBar (Standard: "Code scannen")
  final String title;

  /// Optionaler Hinweistext unterhalb des Suchers
  final String? hint;

  /// Erlaube mehrere Codes (gibt dann den ersten erkannten zurück, aber
  /// deaktiviert den automatischen Pop erst nach kurzem Feedback-Delay).
  const QrScanScreen({
    super.key,
    this.title = 'Code scannen',
    this.hint,
  });

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  late final MobileScannerController _controller;
  bool _scanned = false;
  String? _lastValue;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.pdf417,
        BarcodeFormat.aztec,
        BarcodeFormat.dataMatrix,
      ],
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    _scanned = true;
    _lastValue = raw;

    // Kurzes visuelles Feedback bevor der Screen geschlossen wird
    setState(() {});
    _feedbackTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) Navigator.of(context).pop(raw);
    });
  }

  void _toggleFlash() => _controller.toggleTorch();

  void _switchCamera() => _controller.switchCamera();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          // Taschenlampe
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (_, state, __) {
              final isOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(isOn ? Icons.flash_on : Icons.flash_off),
                tooltip: isOn ? 'Licht aus' : 'Licht an',
                onPressed: _toggleFlash,
              );
            },
          ),
          // Kamera wechseln
          IconButton(
            icon: const Icon(Icons.flip_camera_android_outlined),
            tooltip: 'Kamera wechseln',
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Scanner-Ansicht ────────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── Scan-Rahmen (visuelles Target) ─────────────────────────────
          _ScanOverlay(scanned: _scanned, accentColor: colors.primary),

          // ── Hinweistext ────────────────────────────────────────────────
          if (widget.hint != null || !_scanned)
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _scanned
                    ? _ScannedBadge(value: _lastValue ?? '')
                    : _HintLabel(
                        hint: widget.hint ?? 'QR-Code in den Rahmen halten'),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay – Eck-Rahmen + Scan-Linie
// ─────────────────────────────────────────────────────────────────────────────

class _ScanOverlay extends StatefulWidget {
  final bool scanned;
  final Color accentColor;
  const _ScanOverlay({required this.scanned, required this.accentColor});

  @override
  State<_ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<_ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scanLine;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLine = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.scanned ? Colors.greenAccent : widget.accentColor;

    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: AnimatedBuilder(
          animation: _scanLine,
          builder: (_, __) {
            return CustomPaint(
              painter: _FramePainter(
                color: color,
                scanLineY: _scanLine.value,
                scanned: widget.scanned,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final Color color;
  final double scanLineY;
  final bool scanned;

  _FramePainter({
    required this.color,
    required this.scanLineY,
    required this.scanned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 28.0;
    final w = size.width;
    final h = size.height;

    // Ecken zeichnen
    final corners = [
      // oben-links
      [Offset(0, corner), Offset.zero, Offset(corner, 0)],
      // oben-rechts
      [Offset(w - corner, 0), Offset(w, 0), Offset(w, corner)],
      // unten-rechts
      [Offset(w, h - corner), Offset(w, h), Offset(w - corner, h)],
      // unten-links
      [Offset(corner, h), Offset(0, h), Offset(0, h - corner)],
    ];

    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }

    // Scan-Linie (animiert)
    if (!scanned) {
      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 2;
      final y = scanLineY * h;
      canvas.drawLine(Offset(8, y), Offset(w - 8, y), linePaint);
    }

    // Erfolgs-Check (grüne Füllung)
    if (scanned) {
      final fillPaint = Paint()
        ..color = Colors.greenAccent.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.scanLineY != scanLineY ||
      old.scanned != scanned ||
      old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hilfwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _HintLabel extends StatelessWidget {
  final String hint;
  const _HintLabel({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('hint'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hint,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

class _ScannedBadge extends StatelessWidget {
  final String value;
  const _ScannedBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('scanned'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade800.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Erkannt – wird geladen…',
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
