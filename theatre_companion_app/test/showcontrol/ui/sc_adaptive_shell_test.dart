import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theatre_companion_app/showcontrol/providers/audio_node_provider.dart';
import 'package:theatre_companion_app/showcontrol/providers/session_provider.dart';
import 'package:theatre_companion_app/showcontrol/session/session_service.dart';
import 'package:theatre_companion_app/showcontrol/ui/shell/sc_adaptive_shell.dart';
import 'package:theatre_companion_app/showcontrol/ui/shell/sc_shell.dart';
import 'package:theatre_companion_app/showcontrol/ui/shell/sc_shortcuts.dart';

/// Test-only SessionNotifier — no stored credentials → auto-reconnect exits
/// immediately, no gRPC calls.
class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier() : super(SessionService());
}

// ── Unit tests: shortcut map ───────────────────────────────────────────────────

void main() {
  group('ScShortcuts — shortcut map contents', () {
    test('Space → GoIntent', () {
      expect(ScShortcuts.intentFor(LogicalKeyboardKey.space), isA<GoIntent>());
    });

    test('Escape → StopIntent', () {
      expect(ScShortcuts.intentFor(LogicalKeyboardKey.escape), isA<StopIntent>());
    });

    test('P → PauseIntent', () {
      expect(ScShortcuts.intentFor(LogicalKeyboardKey.keyP), isA<PauseIntent>());
    });

    test('ArrowUp → PrevCueIntent', () {
      expect(ScShortcuts.intentFor(LogicalKeyboardKey.arrowUp), isA<PrevCueIntent>());
    });

    test('ArrowDown → NextCueIntent', () {
      expect(ScShortcuts.intentFor(LogicalKeyboardKey.arrowDown), isA<NextCueIntent>());
    });

    test('Enter → SelectCueIntent', () {
      expect(ScShortcuts.intentFor(LogicalKeyboardKey.enter), isA<SelectCueIntent>());
    });

    test('Delete → DeleteCueIntent', () {
      expect(ScShortcuts.intentFor(LogicalKeyboardKey.delete), isA<DeleteCueIntent>());
    });

    test('Backspace → DeleteCueIntent', () {
      expect(ScShortcuts.intentFor(LogicalKeyboardKey.backspace), isA<DeleteCueIntent>());
    });

    test('all 8 shortcuts are registered', () {
      expect(ScShortcuts.all, hasLength(8));
    });
  });

  // ── Widget tests: keyboard dispatch via standalone Shortcuts widget ────────

  group('ScShortcuts — keyboard dispatch', () {
    // Build a minimal widget that wires the ScShortcuts map to trackable
    // callback actions — no Riverpod, no gRPC, no provider overrides.
    Widget _harness({
      required VoidCallback onGo,
      required VoidCallback onStop,
      required VoidCallback onPause,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Shortcuts(
            shortcuts: ScShortcuts.all,
            child: Actions(
              actions: {
                GoIntent: CallbackAction<GoIntent>(
                    onInvoke: (_) { onGo(); return null; }),
                StopIntent: CallbackAction<StopIntent>(
                    onInvoke: (_) { onStop(); return null; }),
                PauseIntent: CallbackAction<PauseIntent>(
                    onInvoke: (_) { onPause(); return null; }),
                // Navigation intents — NoopAction already in sc_shortcuts;
                // for the test we only need the transport intents wired.
                PrevCueIntent: CallbackAction<PrevCueIntent>(
                    onInvoke: (_) => null),
                NextCueIntent: CallbackAction<NextCueIntent>(
                    onInvoke: (_) => null),
                SelectCueIntent: CallbackAction<SelectCueIntent>(
                    onInvoke: (_) => null),
                DeleteCueIntent: CallbackAction<DeleteCueIntent>(
                    onInvoke: (_) => null),
              },
              child: const Focus(autofocus: true, child: SizedBox.expand()),
            ),
          ),
        ),
      );
    }

    testWidgets('Space key dispatches GoIntent', (tester) async {
      var count = 0;
      await tester.pumpWidget(_harness(
        onGo: () => count++,
        onStop: () {},
        onPause: () {},
      ));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(count, 1);
    });

    testWidgets('Escape key dispatches StopIntent', (tester) async {
      var count = 0;
      await tester.pumpWidget(_harness(
        onGo: () {},
        onStop: () => count++,
        onPause: () {},
      ));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(count, 1);
    });

    testWidgets('P key dispatches PauseIntent', (tester) async {
      var count = 0;
      await tester.pumpWidget(_harness(
        onGo: () {},
        onStop: () {},
        onPause: () => count++,
      ));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump();
      expect(count, 1);
    });

    testWidgets('each shortcut fires exactly once per keypress', (tester) async {
      var goCalls = 0;
      await tester.pumpWidget(_harness(
        onGo: () => goCalls++,
        onStop: () {},
        onPause: () {},
      ));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(goCalls, 2);
    });
  });

  group('ScAdaptiveShell — responsive routing', () {
    testWidgets('renders ScShell', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith((ref) => _TestSessionNotifier()),
            audioNodeProvider.overrideWith((ref) => AudioNodeNotifier.forTest()),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(420, 900)),
              child: ScAdaptiveShell(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ScShell), findsOneWidget);
    });
  });
}
