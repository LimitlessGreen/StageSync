import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/go/go_screen.dart';

/// Mobile shell — read-only cue view + large GO button.
///
/// No editing: no CueList editor, no Inspector, no Patch, no Media.
/// Intentionally minimal for safe live operation.
class MobileShell extends ConsumerWidget {
  const MobileShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const GoScreen();
}
