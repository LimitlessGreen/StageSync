import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../sc_typography.dart';

/// Blender-style combined drag+text numeric field.
///
/// - Horizontal drag changes the value (sensitivity configurable).
/// - Double-tap or single-tap while focused enters text-edit mode.
/// - Shows a subtle fill bar proportional to the value in [min]..[max].
/// - Displays value + optional suffix (e.g. "dB", "ms").
class ScDragField extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double step;          // per-pixel drag sensitivity
  final int decimalPlaces;
  final String? suffix;
  final String? label;        // optional label shown left of the field
  final bool readOnly;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onSubmitted; // fires when text confirmed

  const ScDragField({
    super.key,
    required this.value,
    this.min = double.negativeInfinity,
    this.max = double.infinity,
    this.step = 0.1,
    this.decimalPlaces = 1,
    this.suffix,
    this.label,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<ScDragField> createState() => _ScDragFieldState();
}

class _ScDragFieldState extends State<ScDragField> {
  bool _editing   = false;
  bool _dragging  = false;
  bool _hovered   = false;
  double _dragStart = 0;
  double _valueAtDragStart = 0;
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl  = TextEditingController(text: _fmt(widget.value));
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commitText();
    });
  }

  @override
  void didUpdateWidget(ScDragField old) {
    super.didUpdateWidget(old);
    if (!_editing && old.value != widget.value) {
      _ctrl.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _fmt(double v) => v.toStringAsFixed(widget.decimalPlaces);

  double _clamp(double v) => v.clamp(
        widget.min.isInfinite ? v : widget.min,
        widget.max.isInfinite ? v : widget.max,
      );

  void _commitText() {
    final parsed = double.tryParse(_ctrl.text.replaceAll(',', '.').trim());
    if (parsed != null) {
      final clamped = _clamp(parsed);
      widget.onSubmitted?.call(clamped);
      widget.onChanged?.call(clamped);
    } else {
      _ctrl.text = _fmt(widget.value);
    }
    setState(() => _editing = false);
  }

  void _enterEdit() {
    if (widget.readOnly) return;
    setState(() => _editing = true);
    _ctrl.text = _fmt(widget.value);
    _ctrl.selection = TextSelection(
      baseOffset: 0, extentOffset: _ctrl.text.length);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  double get _fillFraction {
    if (widget.min.isInfinite || widget.max.isInfinite) return 0;
    final range = widget.max - widget.min;
    if (range == 0) return 0;
    return ((widget.value - widget.min) / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final hasLabel = widget.label != null;

    final field = MouseRegion(
      cursor: widget.readOnly
          ? SystemMouseCursors.basic
          : (_editing ? SystemMouseCursors.text : SystemMouseCursors.resizeLeftRight),
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onDoubleTap: _enterEdit,
        onTap: _editing ? null : (_dragging ? null : _enterEdit),
        onHorizontalDragStart: widget.readOnly || _editing
            ? null
            : (d) {
                setState(() {
                  _dragging = true;
                  _dragStart = d.globalPosition.dx;
                  _valueAtDragStart = widget.value;
                });
                HapticFeedback.selectionClick();
              },
        onHorizontalDragUpdate: widget.readOnly || _editing
            ? null
            : (d) {
                final delta = d.globalPosition.dx - _dragStart;
                final newVal = _clamp(_valueAtDragStart + delta * widget.step);
                widget.onChanged?.call(newVal);
              },
        onHorizontalDragEnd: widget.readOnly || _editing
            ? null
            : (d) {
                setState(() => _dragging = false);
                widget.onSubmitted?.call(widget.value);
              },
        child: _editing
            ? _EditingField(ctrl: _ctrl, focus: _focus, suffix: widget.suffix, onSubmit: _commitText)
            : _DisplayField(
                value: widget.value,
                suffix: widget.suffix,
                fillFraction: _fillFraction,
                hovered: _hovered || _dragging,
                decimalPlaces: widget.decimalPlaces,
              ),
      ),
    );

    if (!hasLabel) return field;

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(widget.label!, style: ScText.label),
        ),
        Expanded(child: field),
      ],
    );
  }
}

// ── Display mode ──────────────────────────────────────────────────────────────

class _DisplayField extends StatelessWidget {
  final double value;
  final String? suffix;
  final double fillFraction;
  final bool hovered;
  final int decimalPlaces;

  const _DisplayField({
    required this.value,
    required this.suffix,
    required this.fillFraction,
    required this.hovered,
    required this.decimalPlaces,
  });

  @override
  Widget build(BuildContext context) {
    final text = value.toStringAsFixed(decimalPlaces);
    final display = suffix != null ? '$text ${suffix!}' : text;

    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: hovered
            ? const Color(0xFF252525)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Fill bar
            if (fillFraction > 0)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillFraction,
                  child: Container(
                    color: const Color(0xFF00E676).withValues(alpha: 0.18),
                  ),
                ),
              ),
            // Value text
            Center(
              child: Text(
                display,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit mode ─────────────────────────────────────────────────────────────────

class _EditingField extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final String? suffix;
  final VoidCallback onSubmit;

  const _EditingField({
    required this.ctrl,
    required this.focus,
    required this.suffix,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF2D2D2D),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: const BorderSide(color: Color(0xFF00E676), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: const BorderSide(color: Color(0xFF00E676), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: const BorderSide(color: Color(0xFF00E676), width: 1),
          ),
          suffix: suffix != null
              ? Text(suffix!, style: const TextStyle(color: Color(0xFF888888), fontSize: 10))
              : null,
          isDense: true,
        ),
        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
        textAlign: TextAlign.center,
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }
}
