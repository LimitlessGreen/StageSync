import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sc_colors.dart';

/// Horizontal split view with a draggable divider — no domain knowledge.
///
/// [leftFraction] is the fraction of available width given to the left pane (0.0–1.0).
/// Pass a [persistKey] to save/restore the divider position via SharedPreferences.
class ScSplitView extends StatefulWidget {
  final Widget left;
  final Widget right;
  final double initialFraction;
  final double minFraction;
  final double maxFraction;
  final ValueChanged<double>? onFractionChanged;

  /// SharedPreferences key for persisting the divider position.
  /// If null, position is only kept in memory.
  final String? persistKey;

  const ScSplitView({
    super.key,
    required this.left,
    required this.right,
    this.initialFraction = 0.35,
    this.minFraction = 0.15,
    this.maxFraction = 0.75,
    this.onFractionChanged,
    this.persistKey,
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
    if (widget.persistKey != null) _loadPersistedFraction();
  }

  Future<void> _loadPersistedFraction() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefKey);
    if (saved != null && mounted) {
      setState(() {
        _fraction = saved.clamp(widget.minFraction, widget.maxFraction);
      });
    }
  }

  Future<void> _persistFraction(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, value);
  }

  String get _prefKey => 'sc_split_view.${widget.persistKey}';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        final leftW = (totalW * _fraction).clamp(
          totalW * widget.minFraction,
          totalW * widget.maxFraction,
        );

        return Row(
          children: [
            SizedBox(width: leftW, child: widget.left),
            _Divider(
              onDrag: (dx) {
                setState(() {
                  _fraction = ((_fraction * totalW + dx) / totalW).clamp(
                    widget.minFraction,
                    widget.maxFraction,
                  );
                });
                widget.onFractionChanged?.call(_fraction);
                if (widget.persistKey != null) _persistFraction(_fraction);
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

/// Three-pane horizontal split (left | center | right) with optional persistence.
class ScThreePaneView extends StatefulWidget {
  final Widget left;
  final Widget center;
  final Widget right;
  final double leftWidth;
  final double rightWidth;

  /// SharedPreferences key prefix for persisting both divider positions.
  /// Saves as <persistKey>.left and <persistKey>.right.
  final String? persistKey;

  const ScThreePaneView({
    super.key,
    required this.left,
    required this.center,
    required this.right,
    this.leftWidth = 280,
    this.rightWidth = 260,
    this.persistKey,
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
    _leftW = widget.leftWidth;
    _rightW = widget.rightWidth;
    if (widget.persistKey != null) _loadPersistedWidths();
  }

  Future<void> _loadPersistedWidths() async {
    final prefs = await SharedPreferences.getInstance();
    final left = prefs.getDouble('${widget.persistKey}.left');
    final right = prefs.getDouble('${widget.persistKey}.right');
    if (mounted) {
      setState(() {
        if (left != null) _leftW = left.clamp(160.0, 480.0);
        if (right != null) _rightW = right.clamp(160.0, 400.0);
      });
    }
  }

  Future<void> _persistWidths() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble('${widget.persistKey}.left', _leftW),
      prefs.setDouble('${widget.persistKey}.right', _rightW),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: _leftW, child: widget.left),
        _ThreePaneDivider(onDrag: (dx) {
          setState(() => _leftW = (_leftW + dx).clamp(160, 480));
          if (widget.persistKey != null) _persistWidths();
        }),
        Expanded(child: widget.center),
        _ThreePaneDivider(onDrag: (dx) {
          setState(() => _rightW = (_rightW - dx).clamp(160, 400));
          if (widget.persistKey != null) _persistWidths();
        }),
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
            child: Center(
                child: Container(width: 1, color: const Color(0xFF2A2A2A))),
          ),
        ),
      );
}
