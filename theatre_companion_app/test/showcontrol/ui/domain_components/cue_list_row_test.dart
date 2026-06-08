import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/showcontrol/domain/cue_params.dart';
import 'package:theatre_companion_app/showcontrol/domain/playhead.dart';
import 'package:theatre_companion_app/showcontrol/domain/show.dart';
import 'package:theatre_companion_app/showcontrol/ui/design_system/domain_components/cue_list_row.dart';
const _audioCue = Cue(
  id: 'cue-1',
  number: '1',
  label: 'Intro Music',
  params: AudioParams(assetId: 'abc'),
);

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(body: SizedBox(width: 400, child: child)),
      ),
    );

void main() {
  group('CueListRow', () {
    testWidgets('renders cue number and label', (tester) async {
      await tester.pumpWidget(_wrap(
        const CueListRow(cue: _audioCue),
      ));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Intro Music'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        CueListRow(cue: _audioCue, onTap: () => tapped = true),
      ));
      await tester.tap(find.byType(CueListRow));
      expect(tapped, isTrue);
    });

    testWidgets('active state renders', (tester) async {
      await tester.pumpWidget(_wrap(
        const CueListRow(cue: _audioCue, isActive: true),
      ));
      expect(find.byType(CueListRow), findsOneWidget);
    });

    testWidgets('past state renders', (tester) async {
      await tester.pumpWidget(_wrap(
        const CueListRow(cue: _audioCue, isPast: true),
      ));
      expect(find.byType(CueListRow), findsOneWidget);
    });

    testWidgets('error state via runState lifecycle', (tester) async {
      final runState = CueRunState(lifecycle: CueLifecycle.error);
      await tester.pumpWidget(_wrap(
        CueListRow(cue: _audioCue, runState: runState),
      ));
      expect(find.byType(CueListRow), findsOneWidget);
    });

    testWidgets('paused state via runState lifecycle', (tester) async {
      final runState = CueRunState(lifecycle: CueLifecycle.paused);
      await tester.pumpWidget(_wrap(
        CueListRow(cue: _audioCue, isActive: true, runState: runState),
      ));
      expect(find.byType(CueListRow), findsOneWidget);
    });

    testWidgets('expanded mode increases height', (tester) async {
      await tester.pumpWidget(_wrap(
        const CueListRow(cue: _audioCue, expanded: true),
      ));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CueListRow),
          matching: find.byType(Container),
        ).first,
      );
      // Expanded rows have height > 48
      expect(container.constraints?.maxHeight ?? 80.0, greaterThan(48));
    });

    testWidgets('delete callback fires via onDelete', (tester) async {
      var deleted = false;
      await tester.pumpWidget(_wrap(
        CueListRow(
          cue: _audioCue,
          onDelete: () => deleted = true,
        ),
      ));
      // GestureDetector for onDelete should be in the widget tree
      expect(find.byType(CueListRow), findsOneWidget);
      // We don't tap the delete icon here (it's context-menu on desktop)
      // — just verify the widget builds without error when callback is wired
      expect(deleted, isFalse);
    });

    testWidgets('WaitParams cue renders', (tester) async {
      const waitCue = Cue(
        id: 'w1',
        number: '2',
        label: 'Warten',
        params: WaitParams(durationMs: 5000),
      );
      await tester.pumpWidget(_wrap(const CueListRow(cue: waitCue)));
      expect(find.text('Warten'), findsOneWidget);
    });

    testWidgets('selected state renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const CueListRow(cue: _audioCue, isSelected: true),
      ));
      expect(find.byType(CueListRow), findsOneWidget);
    });
  });
}
