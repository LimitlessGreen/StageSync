import 'package:flutter/material.dart';
import '../sc_colors.dart';

/// Horizontal split view with a draggable divider — no domain knowledge.
///
/// [leftFraction] is the fraction of available width given to the left pane (0.0–1.0).
/// Persists its position in memory; persistence to SharedPreferences can be
/// added by the caller via [onFractionChanged].
class ScSplitView extends StatefulWidget {
  final Widget left;
  final Widget right;
  final double initialFraction;
  final double minFraction;
  final double maxFraction;
  final ValueChanged<double>? onFractionChanged;

  const ScSplitView({
    super.key,
    required this.left,
    required this.right,
    this.initialFraction = 0.35,
    this.minFraction = 0.15,
    this.maxFraction = 0.75,
    this.onFractionChanged,
  });

  @override
  State<ScSplitView> createState() => _ScSplitViewState();
}

class _ScSplitViewState extends State<ScSplitView> {
  late double _fraction;

  @override
  void initState() {
    super.initState();
    _fraction = widget.initialFraction;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        final leftW  = (totalW * _fraction).clamp(
          totalW * widget.minFraction,
          totalW * widget.maxFraction,
        );

        return Row(
          children: [
            SizedBox(width: leftW, child: widget.left),
            _Divider(
              onDrag: (dx) {
                setState(() {
                  _fraction =
                      ((_fraction * totalW + dx) / totalW).clamp(
                        widget.minFraction,
                        widget.maxFraction,
                      );
                });
                widget.onFractionChanged?.call(_fraction);
              },
            ),
            Expanded(child: widget.right),
          ],
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  final ValueChanged<double> onDrag;
  const _Divider({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (d) => onDrag(d.delta.dx),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 5,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              color: ScColors.divider,
            ),
          ),
        ),
      ),
    );
  }
}

/// Three-pane horizontal split (left | center | right).
class ScThreePaneView extends StatefulWidget {
  final Widget left;
  final Widget center;
  final Widget right;
  final double leftWidth;
  final double rightWidth;

  const ScThreePaneView({
    super.key,
    required this.left,
    required this.center,
    required this.right,
    this.leftWidth = 280,
    this.rightWidth = 260,
  });

  @override
  State<ScThreePaneView> createState() => _ScThreePaneViewState();
}

class _ScThreePaneViewState extends State<ScThreePaneView> {
  late double _leftW;
  late double _rightW;

  @override
  void initState() {
    super.initState();
    _leftW  = widget.leftWidth;
    _rightW = widget.rightWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: _leftW,  child: widget.left),
        _ThreePaneDivider(onDrag: (dx) => setState(() =>
            _leftW = (_leftW + dx).clamp(160, 480))),
        Expanded(child: widget.center),
        _ThreePaneDivider(onDrag: (dx) => setState(() =>
            _rightW = (_rightW - dx).clamp(160, 400))),
        SizedBox(width: _rightW, child: widget.right),
      ],
    );
  }
}

class _ThreePaneDivider extends StatelessWidget {
  final ValueChanged<double> onDrag;
  const _ThreePaneDivider({required this.onDrag});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (d) => onDrag(d.delta.dx),
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: Container(
            width: 5,
            color: Colors.transparent,
            child: Center(child: Container(width: 1, color: const Color(0xFF2A2A2A))),
          ),
        ),
      );
}
