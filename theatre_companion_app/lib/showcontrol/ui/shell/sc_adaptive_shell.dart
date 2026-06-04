import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/sc_spacing.dart';
import '../design_system/sc_theme.dart';
import 'sc_shortcuts.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';

/// Top-level adaptive shell for Show-Control.
///
/// - Registers keyboard [Shortcuts] and [Actions] at root level (not per-widget).
/// - Routes to [DesktopShell] on wide layouts or [MobileShell] on narrow layouts.
/// - Wrap the navigation push to this widget instead of branching in callers.
class ScAdaptiveShell extends ConsumerWidget {
  const ScAdaptiveShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= ScSpacing.desktopBreakpoint;

    return Theme(
      data: ScTheme.build(context),
      child: Shortcuts(
        shortcuts: ScShortcuts.all,
        child: Actions(
          actions: ScShortcuts.actions(ref),
          child: isDesktop ? const DesktopShell() : const MobileShell(),
        ),
      ),
    );
  }
}
