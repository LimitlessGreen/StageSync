import 'package:flutter/material.dart';

import '../sc_colors.dart';
import '../sc_spacing.dart';
import '../sc_typography.dart';

/// Wiederverwendbares floating Panel mit Slide-up + Fade-Animation.
///
/// Platzierung: in einem [Stack] als [Positioned]-Kind verwenden.
/// [visible] steuert Einblenden/Ausblenden — die Animation läuft automatisch.
///
/// Beispiel:
/// ```dart
/// Stack(children: [
///   content,
///   Positioned(
///     right: 12, bottom: 12, width: 340,
///     child: ScFloatingPanel(
///       visible: showPanel,
///       title: 'UPLOADS',
///       onClose: () => setState(() => showPanel = false),
///       child: myContent,
///     ),
///   ),
/// ])
/// ```
class ScFloatingPanel extends StatefulWidget {
  final bool visible;
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final List<Widget> actions;
  final Widget child;

  const ScFloatingPanel({
    super.key,
    required this.visible,
    required this.title,
    required this.child,
    this.subtitle,
    this.onClose,
    this.actions = const [],
  });

  @override
  State<ScFloatingPanel> createState() => _ScFloatingPanelState();
}

class _ScFloatingPanelState extends State<ScFloatingPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    if (widget.visible) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(ScFloatingPanel old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      if (widget.visible) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
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
      builder: (context, child) {
        if (_ctrl.isDismissed) return const SizedBox.shrink();
        return FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: child,
          ),
        );
      },
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(8),
        color: ScColors.surface2,
        shadowColor: Colors.black54,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                height: 36,
                color: ScColors.surface,
                padding: const EdgeInsets.symmetric(
                    horizontal: ScSpacing.panelPad, vertical: 0),
                child: Row(
                  children: [
                    Text(widget.title, style: ScText.panelTitle),
                    if (widget.subtitle != null) ...[
                      const SizedBox(width: 8),
                      Text(widget.subtitle!, style: ScText.statusSmall),
                    ],
                    const Spacer(),
                    ...widget.actions,
                    if (widget.onClose != null) ...[
                      if (widget.actions.isNotEmpty)
                        const SizedBox(width: 4),
                      _CloseButton(onTap: widget.onClose!),
                    ],
                  ],
                ),
              ),
              // ── Content ───────────────────────────────────────────────
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Schließen',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 14, color: ScColors.textDim),
        ),
      ),
    );
  }
}
