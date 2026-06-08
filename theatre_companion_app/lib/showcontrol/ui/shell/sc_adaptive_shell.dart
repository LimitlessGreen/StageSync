import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/sc_theme.dart';
import 'sc_shortcuts.dart';
import 'sc_shell.dart';

/// Top-level adaptive shell for Show-Control.
///
/// Registers keyboard [Shortcuts] and [Actions] at root level, then delegates
/// all layout decisions to [ScShell], which handles both desktop and mobile
/// in a single widget tree.
class ScAdaptiveShell extends ConsumerWidget {
  const ScAdaptiveShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: ScTheme.build(context),
      child: Shortcuts(
        shortcuts: ScShortcuts.all,
        child: Actions(
          actions: ScShortcuts.actions(ref),
          child: const ScShell(),
        ),
      ),
    );
  }
}
