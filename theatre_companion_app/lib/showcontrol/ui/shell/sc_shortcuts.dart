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

// ── Text-field aware activator ────────────────────────────────────────────────

/// Wraps [SingleActivator] and suppresses itself when a text field has focus.
/// This lets Space, Delete, Backspace, Enter, P, arrow keys reach text inputs
/// normally while still working as transport shortcuts everywhere else.
class _TextFieldAwareActivator extends ShortcutActivator {
  final SingleActivator _inner;
  const _TextFieldAwareActivator(this._inner);

  static bool _textFieldFocused() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    // Walk up to find the nearest EditableText — covers TextField, TextFormField,
    // ScInlineField, and any other widget that embeds an EditableText.
    bool found = false;
    ctx.visitAncestorElements((el) {
      if (el.widget is EditableText) { found = true; return false; }
      return true;
    });
    return found;
  }

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    if (_textFieldFocused()) return false;
    return _inner.accepts(event, state);
  }

  @override
  String debugDescribeKeys() => _inner.debugDescribeKeys();

  @override
  Iterable<LogicalKeyboardKey>? get triggers => _inner.triggers;
}

// ── Shortcut map ──────────────────────────────────────────────────────────────

abstract final class ScShortcuts {
  static _TextFieldAwareActivator _key(LogicalKeyboardKey k) =>
      _TextFieldAwareActivator(SingleActivator(k));

  /// All keyboard shortcuts for the show-control shell.
  /// Each activator suppresses itself when a text field has focus so the user
  /// can type normally in any inspector or search field.
  static Map<ShortcutActivator, Intent> get all => {
    _key(LogicalKeyboardKey.space):     const GoIntent(),
    _key(LogicalKeyboardKey.escape):    const StopIntent(),
    _key(LogicalKeyboardKey.keyP):      const PauseIntent(),
    _key(LogicalKeyboardKey.arrowUp):   const PrevCueIntent(),
    _key(LogicalKeyboardKey.arrowDown): const NextCueIntent(),
    _key(LogicalKeyboardKey.enter):     const SelectCueIntent(),
    _key(LogicalKeyboardKey.delete):    const DeleteCueIntent(),
    _key(LogicalKeyboardKey.backspace): const DeleteCueIntent(),
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

