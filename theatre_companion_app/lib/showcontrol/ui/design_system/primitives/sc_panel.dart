import 'package:flutter/material.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';
import '../sc_spacing.dart';

/// Gemeinsamer Panel-Header (Title + optionales Trailing-Widget).
class ScPanelHeader extends StatelessWidget {
  final String? title;
  final Widget? trailing;

  const ScPanelHeader({super.key, this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    if (title == null && trailing == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ScSpacing.panelPad,
        ScSpacing.panelPad,
        ScSpacing.panelPad,
        4,
      ),
      child: Row(
        children: [
          if (title != null)
            Expanded(
              child: Text(title!.toUpperCase(), style: ScText.panelTitle),
            ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Dark-surface panel container — no domain knowledge.
class ScPanel extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const ScPanel({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? ScColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScPanelHeader(title: title, trailing: trailing),
          Expanded(
            child: Padding(
              padding: padding ??
                  EdgeInsets.fromLTRB(
                    ScSpacing.panelPad,
                    title != null ? 4 : ScSpacing.panelPad,
                    ScSpacing.panelPad,
                    ScSpacing.panelPad,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Non-expanding variant for fixed-height use cases.
class ScPanelFixed extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ScPanelFixed({
    super.key,
    this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ScColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ScPanelHeader(title: title),
          Padding(
            padding: padding ??
                EdgeInsets.fromLTRB(
                  ScSpacing.panelPad,
                  title != null ? 4 : ScSpacing.panelPad,
                  ScSpacing.panelPad,
                  ScSpacing.panelPad,
                ),
            child: child,
          ),
        ],
      ),
    );
  }
}
