import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/showcontrol/domain/playhead.dart';
import 'package:theatre_companion_app/showcontrol/ui/design_system/domain_components/transport_bar.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(body: SizedBox(width: 800, child: child)),
      ),
    );

const _idle = PlayheadState.empty;
final _running = PlayheadState(
  cueListId: 'list-1',
  activeCueId: 'cue-1',
  phase: CueListPhase.running,
  startedServerMs: DateTime.now().millisecondsSinceEpoch - 5000,
);
final _paused = PlayheadState(
  cueListId: 'list-1',
  activeCueId: 'cue-1',
  phase: CueListPhase.paused,
  startedServerMs: DateTime.now().millisecondsSinceEpoch - 5000,
  pausedAtServerMs: DateTime.now().millisecondsSinceEpoch - 2000,
);

// TransportBar.build schedules a Future.delayed(1s) when running.
// Switching to idle before draining prevents the timer from re-scheduling.
Future<void> _drainRunningTimer(WidgetTester tester) async {
  await tester.pumpWidget(_wrap(const TransportBar(playhead: _idle)));
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  group('TransportBar — callbacks', () {
    testWidgets('GO button fires onGo callback', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(
        TransportBar(playhead: _idle, onGo: () => called = true),
      ));
      await tester.tap(find.text('GO'));
      expect(called, isTrue);
    });

    testWidgets('STOP button fires onStop callback', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(
        TransportBar(playhead: _running, onStop: () => called = true),
      ));
      await tester.tap(find.text('STOP'));
      expect(called, isTrue);
      await _drainRunningTimer(tester);
    });

    testWidgets('PAUSE button fires onPause callback when running',
        (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(
        TransportBar(playhead: _running, onPause: () => called = true),
      ));
      await tester.tap(find.text('PAUSE'));
      expect(called, isTrue);
      await _drainRunningTimer(tester);
    });

    testWidgets('RESUME button fires onResume callback when paused',
        (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(
        TransportBar(
          playhead: _paused,
          onResume: () => called = true,
        ),
      ));
      await tester.tap(find.text('RESUME'));
      expect(called, isTrue);
    });
  });

  group('TransportBar — rendering', () {
    testWidgets('renders in idle state', (tester) async {
      await tester.pumpWidget(_wrap(
        const TransportBar(playhead: _idle),
      ));
      expect(find.byType(TransportBar), findsOneWidget);
      expect(find.text('GO'), findsOneWidget);
      expect(find.text('STOP'), findsOneWidget);
    });

    testWidgets('compact mode renders', (tester) async {
      await tester.pumpWidget(_wrap(
        const TransportBar(playhead: _idle, compact: true),
      ));
      expect(find.byType(TransportBar), findsOneWidget);
    });

    testWidgets('paused state renders RESUME button', (tester) async {
      await tester.pumpWidget(_wrap(
        TransportBar(playhead: _paused),
      ));
      expect(find.text('RESUME'), findsOneWidget);
    });
  });

  group('TransportBar — Space shortcut integration', () {
    testWidgets('Space key fires onGo via Shortcuts wrapper', (tester) async {
      var goCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              child: Actions(
                actions: {
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (_) {
                      goCalls++;
                      return null;
                    },
                  ),
                },
                child: Focus(
                  autofocus: true,
                  child: SizedBox(
                    width: 800,
                    child: TransportBar(
                      playhead: _idle,
                      onGo: () => goCalls++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(goCalls, greaterThan(0));
    });
  });
}
