import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/show_control_provider.dart';

// ── Intents ────────────────────────────────────────────────────────────────────

class GoIntent extends Intent { const GoIntent(); }
class StopIntent extends Intent { const StopIntent(); }
class PauseIntent extends Intent { const PauseIntent(); }
class PrevCueIntent extends Intent { const PrevCueIntent(); }
class NextCueIntent extends Intent { const NextCueIntent(); }
class SelectCueIntent extends Intent { const SelectCueIntent(); }
class DeleteCueIntent extends Intent { const DeleteCueIntent(); }

// ── Shortcut map ──────────────────────────────────────────────────────────────

abstract final class ScShortcuts {
  /// All keyboard shortcuts for the show-control shell.
  /// Registered on the [ScAdaptiveShell] level — available everywhere.
  static const Map<ShortcutActivator, Intent> all = {
    SingleActivator(LogicalKeyboardKey.space):     GoIntent(),
    SingleActivator(LogicalKeyboardKey.escape):    StopIntent(),
    SingleActivator(LogicalKeyboardKey.keyP):      PauseIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp):   PrevCueIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): NextCueIntent(),
    SingleActivator(LogicalKeyboardKey.enter):     SelectCueIntent(),
    SingleActivator(LogicalKeyboardKey.delete):    DeleteCueIntent(),
    SingleActivator(LogicalKeyboardKey.backspace): DeleteCueIntent(),
  };

  /// Builds the [Action] map bound to the current [WidgetRef].
  /// Delegates to [showControlProvider.notifier] — no UI logic here.
  static Map<Type, Action<Intent>> actions(WidgetRef ref) => {
    GoIntent: CallbackAction<GoIntent>(
      onInvoke: (_) => ref.read(showControlProvider.notifier).go(),
    ),
    StopIntent: CallbackAction<StopIntent>(
      onInvoke: (_) => ref.read(showControlProvider.notifier).stop(),
    ),
    PauseIntent: CallbackAction<PauseIntent>(
      onInvoke: (_) {
        final state = ref.read(showControlProvider);
        if (state.isPaused) {
          ref.read(showControlProvider.notifier).resume();
        } else {
          ref.read(showControlProvider.notifier).pause();
        }
        return null;
      },
    ),
    // Navigation intents are handled by the shell's selected-cue state.
    // They dispatch to a Notifier that can be overridden per shell.
    PrevCueIntent:   _NoopAction<PrevCueIntent>(),
    NextCueIntent:   _NoopAction<NextCueIntent>(),
    SelectCueIntent: _NoopAction<SelectCueIntent>(),
    DeleteCueIntent: _NoopAction<DeleteCueIntent>(),
  };
}

/// Placeholder action — replaced by the desktop shell with real navigation logic.
class _NoopAction<T extends Intent> extends Action<T> {
  @override
  Object? invoke(T intent) => null;
}
