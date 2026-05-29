import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/showcontrol/ui/design_system/primitives/sc_button.dart';
import 'package:theatre_companion_app/showcontrol/ui/design_system/primitives/sc_chip.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('ScButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        const ScButton(label: 'GO'),
      ));
      expect(find.text('GO'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        ScButton(label: 'GO', onPressed: () => tapped = true),
      ));
      await tester.tap(find.byType(ScButton));
      expect(tapped, isTrue);
    });

    testWidgets('disabled (null onPressed) — no callback on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        ScButton(label: 'GO', onPressed: null),
      ));
      await tester.tap(find.byType(ScButton));
      expect(tapped, isFalse);
    });

    testWidgets('isLoading shows CircularProgressIndicator, not label', (tester) async {
      await tester.pumpWidget(_wrap(
        const ScButton(label: 'GO', isLoading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Label text should NOT be visible while loading
      expect(find.text('GO'), findsNothing);
    });

    testWidgets('shortcutHint is rendered when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const ScButton(label: 'GO', shortcutHint: 'Space'),
      ));
      expect(find.text('Space'), findsOneWidget);
    });

    testWidgets('all variants render without error', (tester) async {
      for (final variant in ScButtonVariant.values) {
        await tester.pumpWidget(_wrap(
          ScButton(
            label: variant.name,
            variant: variant,
            onPressed: () {},
          ),
        ));
        expect(find.text(variant.name), findsOneWidget);
      }
    });

    testWidgets('large size renders', (tester) async {
      await tester.pumpWidget(_wrap(
        const ScButton(
          label: 'GO',
          size: ScButtonSize.large,
          onPressed: null,
        ),
      ));
      expect(find.text('GO'), findsOneWidget);
    });
  });

  group('ScChip', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(_wrap(
        const ScChip(label: 'AudioNode'),
      ));
      expect(find.text('AudioNode'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        ScChip(label: 'Node', onTap: () => tapped = true),
      ));
      await tester.tap(find.byType(ScChip));
      expect(tapped, isTrue);
    });

    testWidgets('all states render without error', (tester) async {
      for (final state in ScChipState.values) {
        await tester.pumpWidget(_wrap(
          ScChip(label: state.name, state: state),
        ));
        expect(find.text(state.name), findsOneWidget);
      }
    });

    testWidgets('showExpandArrow shows icon', (tester) async {
      await tester.pumpWidget(_wrap(
        const ScChip(label: 'Node', showExpandArrow: true),
      ));
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });
  });
}
