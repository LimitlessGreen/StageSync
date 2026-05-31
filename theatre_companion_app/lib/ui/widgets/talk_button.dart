import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../talkback/talkback_provider.dart';

/// Schwellwert in logischen Pixeln ab dem Wischen als "Verwerfen" gilt.
const _kDiscardThreshold = 60.0;

/// Push-to-Talk Button (Momentary: halten = aktiv, loslassen = stop).
/// Im Delayed-Modus: während Halten wischen → Aufnahme verwerfen.
class TalkButton extends ConsumerStatefulWidget {
  const TalkButton({super.key, this.targetBusIds = const []});

  final List<String> targetBusIds;

  @override
  ConsumerState<TalkButton> createState() => _TalkButtonState();
}

class _TalkButtonState extends ConsumerState<TalkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  Timer? _releaseTimer;

  // Wisch-Tracking (nur im Delayed-Modus aktiv)
  Offset? _pointerDownPos;
  bool _discarding = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tbState = ref.watch(talkbackProvider).valueOrNull ?? const TalkbackState();
    final status = tbState.status;
    final isDelayed = tbState.mode == TalkbackMode.delayed;
    final isActive = status == TalkbackStatus.active;
    final isRequesting = status == TalkbackStatus.requesting;
    final isRecording = isActive && isDelayed;

    // Im Verwerfen-Modus: grau mit Papierkorb
    final Color bgColor = _discarding
        ? const Color(0xFF616161)
        : switch (status) {
            TalkbackStatus.active => isDelayed
                ? const Color(0xFF7B1FA2) // lila für Delayed-Aufnahme
                : const Color(0xFFD32F2F), // rot für Live
            TalkbackStatus.requesting => const Color(0xFFF57F17),
            TalkbackStatus.error => const Color(0xFFE65100),
            TalkbackStatus.idle => const Color(0xFF424242),
          };

    final IconData icon = _discarding
        ? Icons.delete_outline
        : (isActive ? Icons.mic : Icons.mic_none);

    final String label = _discarding
        ? 'LOSLASSEN ZUM VERWERFEN'
        : switch (status) {
            TalkbackStatus.active => isDelayed ? 'AUFNAHME...' : 'LIVE',
            TalkbackStatus.requesting => 'Verbinde...',
            TalkbackStatus.error => 'Fehler',
            TalkbackStatus.idle => 'HALTEN ZUM SPRECHEN',
          };

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isActive && !_discarding
            ? [BoxShadow(color: bgColor.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)]
            : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Wisch-Hinweis: kleiner Pfeil links wenn im Delayed-Modus aktiv
          if (isRecording && !_discarding)
            const Positioned(
              left: 10,
              child: Icon(Icons.swipe_left, color: Colors.white38, size: 18),
            ),
        ],
      ),
    );

    // Pulsieren wenn aktiv/requesting (nicht beim Verwerfen)
    if ((isActive || isRequesting) && !_discarding) {
      button = AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
        child: button,
      );
    }

    return Listener(
      onPointerDown: (e) => _onPressDown(e.position),
      onPointerMove: (e) => _onPointerMove(e.position),
      onPointerUp:   (_) => _onPressUp(),
      onPointerCancel: (_) => _onPressUp(),
      child: button,
    );
  }

  void _onPressDown(Offset pos) {
    _releaseTimer?.cancel();
    _releaseTimer = null;
    _pointerDownPos = pos;
    if (_discarding) setState(() => _discarding = false);

    final status = ref.read(talkbackProvider).valueOrNull?.status;
    if (status == TalkbackStatus.idle || status == TalkbackStatus.error) {
      ref.read(talkbackProvider.notifier).startTalking(
            targetBusIds: widget.targetBusIds,
          );
    }
  }

  void _onPointerMove(Offset pos) {
    final tbState = ref.read(talkbackProvider).valueOrNull;
    // Wischen nur im Delayed-Modus während Aufnahme auswerten
    if (tbState?.mode != TalkbackMode.delayed) return;
    if (tbState?.status != TalkbackStatus.active &&
        tbState?.status != TalkbackStatus.requesting) {
      return;
    }
    if (_pointerDownPos == null) return;

    final delta = pos - _pointerDownPos!;
    final dist = math.sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
    final shouldDiscard = dist >= _kDiscardThreshold;
    if (shouldDiscard != _discarding) {
      setState(() { _discarding = shouldDiscard; });
    }
  }

  void _onPressUp() {
    _pointerDownPos = null;
    final status = ref.read(talkbackProvider).valueOrNull?.status;

    if (_discarding) {
      setState(() => _discarding = false);
      if (status == TalkbackStatus.active || status == TalkbackStatus.requesting) {
        ref.read(talkbackProvider.notifier).cancelTalking();
      }
      return;
    }

    if (status == TalkbackStatus.active || status == TalkbackStatus.requesting) {
      _releaseTimer = Timer(const Duration(milliseconds: 500), () {
        final s = ref.read(talkbackProvider).valueOrNull?.status;
        if (s == TalkbackStatus.active || s == TalkbackStatus.requesting) {
          ref.read(talkbackProvider.notifier).stopTalking();
        }
      });
    }
  }
}
