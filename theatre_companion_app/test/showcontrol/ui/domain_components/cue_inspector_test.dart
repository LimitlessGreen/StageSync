import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:theatre_companion_app/showcontrol/domain/show.dart';
import 'package:theatre_companion_app/showcontrol/domain/cue_params.dart';
import 'package:theatre_companion_app/showcontrol/providers/show_control_provider.dart';
import 'package:theatre_companion_app/showcontrol/providers/audio_node_provider.dart';
import 'package:theatre_companion_app/showcontrol/providers/media_provider.dart';
import 'package:theatre_companion_app/showcontrol/providers/show_control_domain_provider.dart';
import 'package:theatre_companion_app/showcontrol/domain/asset.dart';
import 'package:theatre_companion_app/showcontrol/ui/design_system/domain_components/cue_inspector.dart';

// ── Stub notifier ─────────────────────────────────────────────────────────────

class _MockRef extends Mock implements Ref {}

class _StubNotifier extends ShowControlNotifier {
  _StubNotifier() : super(_MockRef());

  final List<Cue> upsertCalls = [];

  @override
  Future<void> upsertDomainCue(Cue cue) async => upsertCalls.add(cue);

  @override
  Future<void> deleteCueById(String id) async {}

  @override
  Future<void> goToCue(String id) async {}

  @override
  Future<Cue?> addCue(
          {CueParams params = const AudioParams(assetId: '')}) async =>
      null;
}

// ── Provider overrides to avoid native library loads ─────────────────────────

List<Override> _audioProviderOverrides() => [
      // AudioNodeNotifier.forTest() skips FFI/AudioNodeService initialisation
      audioNodeProvider.overrideWith((_) => AudioNodeNotifier.forTest()),
      assetWithReadinessProvider.overrideWith((ref, id) => null),
      enrichedAssetsProvider.overrideWithValue([]),
      domainCueListProvider.overrideWithValue(null),
    ];

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [..._audioProviderOverrides(), ...overrides],
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(body: SizedBox(width: 400, height: 800, child: child)),
      ),
    );

// Cues that do NOT require native libs (no AudioParams → no _AudioParamsEditor)
const _waitCue = Cue(
  id: 'cue-2',
  number: '4',
  label: 'Warten',
  params: WaitParams(durationMs: 5000),
);

const _noteCue = Cue(
  id: 'cue-3',
  number: '5',
  label: 'Notiz',
  params: NoteParams(text: 'Szenenumbruch'),
);

const _maOscCue = Cue(
  id: 'cue-4',
  number: '6',
  label: 'Light Cue',
  params: MaOscParams(oscAddress: '/gma2/cmd'),
);

// Audio cue can only be used in tests with _audioProviderOverrides
const _audioCue = Cue(
  id: 'cue-1',
  number: '3',
  label: 'Intro',
  params: AudioParams(assetId: 'abc123'),
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── Unit: params-cache logic ──────────────────────────────────────────────
  // Mirrors _onParamsChanged without needing the widget.

  group('CueInspector params-cache logic (unit)', () {
    late Map<Type, CueParams> cache;

    CueParams applyParamsChange(
      CueParams currentParams,
      CueParams newParams,
      Map<Type, CueParams> paramsCache,
    ) {
      if (newParams.runtimeType != currentParams.runtimeType) {
        paramsCache[currentParams.runtimeType] = currentParams;
        final restored = paramsCache[newParams.runtimeType];
        return restored ?? newParams;
      }
      return newParams;
    }

    setUp(() => cache = {});

    test('type switch to new type uses default (no cache)', () {
      const audio = AudioParams(assetId: 'abc', volumeDb: -6.0);
      const newWait = WaitParams(durationMs: 5000);

      final result = applyParamsChange(audio, newWait, cache);

      expect(result, isA<WaitParams>());
      expect((result as WaitParams).durationMs, 5000);
      expect(cache[AudioParams], isA<AudioParams>());
      expect((cache[AudioParams]! as AudioParams).volumeDb, -6.0);
    });

    test('type switch back restores cached params', () {
      const audio = AudioParams(assetId: 'abc', volumeDb: -12.0);
      const wait = WaitParams(durationMs: 5000);

      applyParamsChange(audio, wait, cache);
      final result =
          applyParamsChange(wait, const AudioParams(assetId: ''), cache);

      expect(result, isA<AudioParams>());
      expect((result as AudioParams).volumeDb, -12.0);
      expect(result.assetId, 'abc');
    });

    test('same type does not update cache', () {
      const audio1 = AudioParams(assetId: 'abc', volumeDb: -6.0);
      const audio2 = AudioParams(assetId: 'def', volumeDb: -3.0);

      final result = applyParamsChange(audio1, audio2, cache);

      expect(result, isA<AudioParams>());
      expect((result as AudioParams).assetId, 'def');
      expect(cache, isEmpty);
    });

    test('multiple type switches accumulate separate cache entries', () {
      const audio = AudioParams(assetId: 'x', fadeInMs: 500.0);
      const wait = WaitParams(durationMs: 2000);
      const fade = FadeParams(durationMs: 3000);

      applyParamsChange(audio, wait, cache);
      applyParamsChange(wait, fade, cache);

      expect(cache[AudioParams], isA<AudioParams>());
      expect(cache[WaitParams], isA<WaitParams>());
      expect((cache[WaitParams]! as WaitParams).durationMs, 2000);
    });

    test('switching to same type multiple times only caches latest', () {
      const audio1 = AudioParams(assetId: 'v1', volumeDb: -3.0);
      const wait = WaitParams(durationMs: 5000);
      const audio2 = AudioParams(assetId: 'v2', volumeDb: -6.0);

      applyParamsChange(audio1, wait, cache);
      applyParamsChange(audio2, wait, cache);

      expect((cache[AudioParams]! as AudioParams).assetId, 'v2');
    });

    test('restore from cache uses cached value, not new default', () {
      const wait = WaitParams(durationMs: 9876);
      const fade = FadeParams(durationMs: 1000);

      applyParamsChange(wait, fade, cache); // caches wait
      final result = applyParamsChange(
          fade, const WaitParams(durationMs: 0), cache); // should restore

      expect((result as WaitParams).durationMs, 9876);
    });
  });

  // ── Widget: CueInspector rendering ────────────────────────────────────────

  group('CueInspector widget', () {
    late _StubNotifier notifier;

    setUp(() => notifier = _StubNotifier());

    testWidgets('renders cue number and label in title (WaitParams)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _waitCue, notifier: notifier),
      ));
      await tester.pump();

      // ScPanel renders title.toUpperCase()
      expect(find.text('4 · WARTEN'), findsOneWidget);
    });

    testWidgets('renders cue number and label for NoteParams cue',
        (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _noteCue, notifier: notifier),
      ));
      await tester.pump();

      // ScPanel renders title.toUpperCase()
      expect(find.text('5 · NOTIZ'), findsOneWidget);
    });

    testWidgets('renders section headers ALLGEMEIN and TIMING', (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _waitCue, notifier: notifier),
      ));
      await tester.pump();

      expect(find.text('ALLGEMEIN'), findsOneWidget);
      expect(find.text('TIMING'), findsOneWidget);
    });

    testWidgets('shows WAIT section for WaitParams cue', (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _waitCue, notifier: notifier),
      ));
      await tester.pump();

      expect(find.text('WAIT'), findsOneWidget);
    });

    testWidgets('shows NOTE section for NoteParams cue', (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _noteCue, notifier: notifier),
      ));
      await tester.pump();

      expect(find.text('NOTE'), findsOneWidget);
    });

    testWidgets('shows GrandMA OSC section for MaOscParams cue',
        (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _maOscCue, notifier: notifier),
      ));
      await tester.pump();

      expect(find.text('GrandMA OSC'), findsOneWidget);
    });

    // Audio direct-render is covered by the type-switching test below.

    testWidgets('shows type switcher chips', (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _waitCue, notifier: notifier),
      ));
      await tester.pump();

      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Wait'), findsOneWidget);
      expect(find.text('Fade'), findsOneWidget);
      expect(find.text('MA'), findsOneWidget);
    });

    testWidgets('switching to Note type renders NOTE section', (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _waitCue, notifier: notifier),
      ));
      await tester.pump();

      await tester.tap(find.text('Note'));
      await tester.pump();

      expect(find.text('NOTE'), findsOneWidget);
    });

    testWidgets('switching Wait → Audio renders AUDIO section', (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _waitCue, notifier: notifier),
      ));
      await tester.pump();

      await tester.tap(find.text('Audio'));
      await tester.pump();

      expect(find.text('AUDIO'), findsOneWidget);
    });

    testWidgets('switching Audio → Wait → Audio restores Audio section',
        (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _audioCue, notifier: notifier),
      ));
      await tester.pump();

      // Audio → Wait
      await tester.tap(find.text('Wait'));
      await tester.pump();
      expect(find.text('WAIT'), findsOneWidget);

      // Wait → Audio (should restore Audio section)
      await tester.tap(find.text('Audio'));
      await tester.pump();
      expect(find.text('AUDIO'), findsOneWidget);
    });

    testWidgets('debounce: notifier not called before 350ms', (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _waitCue, notifier: notifier),
      ));
      await tester.pump();

      // Tap Note chip (triggers _update → sets _dirty, schedules 350ms timer)
      await tester.tap(find.text('Note'));
      await tester.pump(const Duration(milliseconds: 100));

      // 100ms → timer not yet fired
      expect(notifier.upsertCalls, isEmpty);
    });

    testWidgets('debounce: notifier called after 350ms', (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _waitCue, notifier: notifier),
      ));
      await tester.pump();

      await tester.tap(find.text('Note'));
      // Advance past the 350ms debounce
      await tester.pump(const Duration(milliseconds: 400));

      expect(notifier.upsertCalls, isNotEmpty);
    });

    testWidgets('didUpdateWidget: different cue id resets draft',
        (tester) async {
      late StateSetter outerSetState;
      var currentCue = _waitCue;

      // ProviderScope must be stable (outside StatefulBuilder) so that
      // CueInspector receives a widget update rather than a full remount.
      await tester.pumpWidget(
        ProviderScope(
          overrides: _audioProviderOverrides(),
          child: MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    outerSetState = setState;
                    return CueInspector(cue: currentCue, notifier: notifier);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // ScPanel renders title.toUpperCase() — verify the inspector mounted correctly
      expect(find.byType(CueInspector), findsOneWidget);

      outerSetState(() => currentCue = _noteCue);
      await tester.pump();

      // After cue id change, _draft must be reset to the new cue
      expect(find.byType(CueInspector), findsOneWidget);
      // The NOTE section should now be visible (NoteParams)
      expect(find.text('NOTE'), findsOneWidget);
    });

    testWidgets('Auto-Continue toggle renders', (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _waitCue, notifier: notifier),
      ));
      await tester.pump();

      expect(find.text('Auto-Continue'), findsOneWidget);
    });

    testWidgets('Pre-Wait and Post-Wait fields render', (tester) async {
      await tester.pumpWidget(_wrap(
        CueInspector(cue: _waitCue, notifier: notifier),
      ));
      await tester.pump();

      expect(find.text('Pre-Wait'), findsOneWidget);
      expect(find.text('Post-Wait'), findsOneWidget);
    });
  });
}
