import 'package:flutter/material.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';
import '../sc_spacing.dart';

/// Compact inline field — no domain knowledge.
///
/// Shows a fixed-width label on the left and an inline-editable value on the right.
/// No TextField chrome in view mode — the border appears only when focused.
///
/// Used in inspectors wherever a standard TextFormField would feel too heavy.
class ScInlineField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String>? onChanged;
  final String? suffix; // unit: 'dB', 'ms', 's'
  final bool readOnly;
  final TextInputType keyboardType;
  final String? tooltip;

  const ScInlineField({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.suffix,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.tooltip,
  });

  @override
  State<ScInlineField> createState() => _ScInlineFieldState();
}

class _ScInlineFieldState extends State<ScInlineField> {
  late TextEditingController _ctrl;
  late FocusNode _focus;
  bool _editing = false;

  bool get _isEditable => !widget.readOnly && widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focus = FocusNode()
      ..addListener(() {
        if (_focus.hasFocus && !widget.readOnly) {
          // Start editing immediately on focus (Tab navigation works)
          if (!_editing) {
            setState(() => _editing = true);
            // Select all text for quick replacement
            _ctrl.selection =
                TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
          }
        } else if (!_focus.hasFocus && _editing) {
          _commit();
        }
      });
  }

  @override
  void didUpdateWidget(ScInlineField old) {
    super.didUpdateWidget(old);
    // Update displayed value if changed externally while not editing
    if (old.value != widget.value && !_editing) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    setState(() => _editing = false);
    widget.onChanged?.call(_ctrl.text);
  }

  void _beginEditing() {
    if (!_isEditable) return;
    if (_editing) {
      _focus.requestFocus();
      return;
    }
    setState(() => _editing = true);
    // TextField exists only in edit mode, so focus must be requested next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      _ctrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final field = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isEditable ? _beginEditing : null,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: _editing
              ? ScColors.active.withValues(alpha: 0.07)
              : _isEditable
                  ? ScColors.surface2.withValues(alpha: 0.5)
                  : Colors.transparent,
          border: _editing
              ? Border.all(color: ScColors.active.withValues(alpha: 0.6))
              : _isEditable
                  ? Border.all(color: ScColors.divider)
                  : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: _editing
                  ? TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      style: ScText.number.copyWith(fontSize: 13),
                      keyboardType: widget.keyboardType,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onEditingComplete: () {
                        _commit();
                        _focus.unfocus();
                      },
                      onSubmitted: (_) {
                        _commit();
                        _focus.unfocus();
                      },
                    )
                  : Text(
                      widget.value,
                      style: ScText.number.copyWith(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (widget.suffix != null) ...[
              const SizedBox(width: 4),
              Text(widget.suffix!, style: ScText.label),
            ],
          ],
        ),
      ),
    );

    final row = Row(
      children: [
        SizedBox(
          width: ScSpacing.inspectorLabelWidth,
          child: Text(widget.label, style: ScText.label),
        ),
        Expanded(child: field),
      ],
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: row);
    }
    return row;
  }
}
