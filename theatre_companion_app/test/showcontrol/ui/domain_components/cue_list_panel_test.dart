import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:theatre_companion_app/showcontrol/domain/show.dart';
import 'package:theatre_companion_app/showcontrol/domain/cue_params.dart';
import 'package:theatre_companion_app/showcontrol/domain/playhead.dart';
import 'package:theatre_companion_app/showcontrol/providers/show_control_provider.dart';
import 'package:theatre_companion_app/showcontrol/ui/design_system/domain_components/cue_list_panel.dart';

// ── Stub notifier ─────────────────────────────────────────────────────────────

class _MockRef extends Mock implements Ref {}

class _StubNotifier extends ShowControlNotifier {
  _StubNotifier() : super(_MockRef());

  @override
  Future<void> goToCue(String cueId) async {}

  @override
  Future<void> deleteCueById(String id) async {}

  @override
  Future<void> reorderCue({required List<String> orderedIds}) async {}

  @override
  Future<Cue?> addCue({CueParams params = const AudioParams(assetId: '')}) async => null;

  @override
  Future<String?> insertDomainCue(CueParams params, {String? afterId, String label = 'Neue Cue'}) async => null;

  @override
  Future<void> duplicateDomainCue(String cueId) async {}

  @override
  Future<void> wrapInGroup(String cueId) async {}

  @override
  Future<void> fadeUpAudio(String cueId, {double durationMs = 1000.0}) async {}

  @override
  Future<void> fadeOutAudio(String cueId, {double durationMs = 1000.0}) async {}

  @override
  Future<void> stopCueAudio(String cueId, {double fadeOutMs = 200.0}) async {}

  @override
  Future<void> pauseCueAudio(String cueId, {double fadeOutMs = 120.0}) async {}

  @override
  Future<void> resumeCueAudio(String cueId, {double fadeInMs = 120.0}) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
    );

const _audioCue = Cue(
  id: 'cue-1',
  number: '1',
  label: 'Intro Musik',
  params: AudioParams(assetId: 'abc'),
);

const _waitCue = Cue(
  id: 'cue-2',
  number: '2',
  label: 'Pause',
  params: WaitParams(durationMs: 3000),
);

// ── isCuePast logic (mirrors private static in _CueListViewState) ─────────────

bool _isCuePast(Cue cue, CueList list, PlayheadState playhead) {
  final activeId = playhead.activeCueId;
  if (activeId == null) return false;
  final activeIdx = list.cues.indexWhere((c) => c.id == activeId);
  final thisIdx   = list.cues.indexWhere((c) => c.id == cue.id);
  return thisIdx < activeIdx;
}

// ── childIds logic (mirrors private method in _CueListViewState) ──────────────

Set<String> _childIds(List<Cue> cues) {
  final s = <String>{};
  for (final c in cues) {
    if (c.params case GroupParams gp) s.addAll(gp.childCueIds);
  }
  return s;
}

// ── Unit: _isCuePast logic ────────────────────────────────────────────────────

void main() {
  group('_isCuePast logic', () {
    final list = CueList(
      id: 'l',
      name: 'Main',
      cues: const [
        Cue(id: 'a', number: '1', label: 'A', params: AudioParams(assetId: 'x')),
        Cue(id: 'b', number: '2', label: 'B', params: WaitParams(durationMs: 1000)),
        Cue(id: 'c', number: '3', label: 'C', params: AudioParams(assetId: 'y')),
      ],
    );

    test('all cues past when active is last', () {
      final playhead = PlayheadState(cueListId: 'l', activeCueId: 'c');
      expect(_isCuePast(list.cues[0], list, playhead), isTrue);
      expect(_isCuePast(list.cues[1], list, playhead), isTrue);
      expect(_isCuePast(list.cues[2], list, playhead), isFalse);
    });

    test('no cues past when active is first', () {
      final playhead = PlayheadState(cueListId: 'l', activeCueId: 'a');
      expect(_isCuePast(list.cues[0], list, playhead), isFalse);
      expect(_isCuePast(list.cues[1], list, playhead), isFalse);
    });

    test('false when no active cue', () {
      const playhead = PlayheadState(cueListId: 'l');
      expect(_isCuePast(list.cues[0], list, playhead), isFalse);
    });

    test('true for unknown cue id (indexWhere returns -1 < activeIdx)', () {
      // Implementation uses indexWhere which returns -1 for not-found cues.
      // -1 < any valid activeIdx → isCuePast returns true for unknown cue IDs.
      final playhead = PlayheadState(cueListId: 'l', activeCueId: 'b');
      final unknown = const Cue(
        id: 'z', number: '9', label: 'Z', params: AudioParams(assetId: 'z'));
      expect(_isCuePast(unknown, list, playhead), isTrue);
    });
  });

  // ── Unit: _childIds logic ─────────────────────────────────────────────────

  group('_childIds logic', () {
    test('empty for list with no group cues', () {
      expect(_childIds([_audioCue, _waitCue]), isEmpty);
    });

    test('collects child ids from group cue', () {
      const group = Cue(
        id: 'g1', number: '3', label: 'Group',
        params: GroupParams(childCueIds: ['cue-1', 'cue-2']),
      );
      final ids = _childIds([_audioCue, _waitCue, group]);
      expect(ids, containsAll(['cue-1', 'cue-2']));
      expect(ids, hasLength(2));
    });

    test('merges children from multiple groups', () {
      const g1 = Cue(
        id: 'g1', number: '3', label: 'G1',
        params: GroupParams(childCueIds: ['a', 'b']),
      );
      const g2 = Cue(
        id: 'g2', number: '4', label: 'G2',
        params: GroupParams(childCueIds: ['c']),
      );
      expect(_childIds([g1, g2]), containsAll(['a', 'b', 'c']));
    });
  });

  // ── Widget: CueListPanel ──────────────────────────────────────────────────

  group('CueListPanel widget', () {
    late _StubNotifier notifier;

    setUp(() => notifier = _StubNotifier());

    testWidgets('shows placeholder text when cueList is null', (tester) async {
      await tester.pumpWidget(_wrap(CueListPanel(
        cueList: null,
        playhead: PlayheadState.empty,
        selectedCueId: null,
        onCueSelected: (_) {},
        notifier: notifier,
      )));

      expect(find.text('Keine CueList'), findsOneWidget);
    });

    testWidgets('shows cue list name in header', (tester) async {
      final list = CueList(id: 'main', name: 'Akt 1', cues: const []);
      await tester.pumpWidget(_wrap(CueListPanel(
        cueList: list,
        playhead: PlayheadState.empty,
        selectedCueId: null,
        onCueSelected: (_) {},
        notifier: notifier,
      )));

      expect(find.text('AKT 1'), findsOneWidget);
    });

    testWidgets('renders cue labels', (tester) async {
      final list = CueList(
        id: 'main',
        name: 'Main',
        cues: const [_audioCue, _waitCue],
      );
      await tester.pumpWidget(_wrap(CueListPanel(
        cueList: list,
        playhead: PlayheadState.empty,
        selectedCueId: null,
        onCueSelected: (_) {},
        notifier: notifier,
      )));
      await tester.pump();

      expect(find.text('Intro Musik'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
    });

    testWidgets('calls onCueSelected when cue row tapped', (tester) async {
      String? selected;
      final list = CueList(id: 'main', name: 'Main', cues: const [_audioCue]);
      await tester.pumpWidget(_wrap(CueListPanel(
        cueList: list,
        playhead: PlayheadState.empty,
        selectedCueId: null,
        onCueSelected: (id) => selected = id,
        notifier: notifier,
      )));
      await tester.pump();

      await tester.tap(find.text('Intro Musik'));
      expect(selected, 'cue-1');
    });

    testWidgets('renders without error for empty cue list', (tester) async {
      final list = CueList(id: 'main', name: 'Empty Show', cues: const []);
      await tester.pumpWidget(_wrap(CueListPanel(
        cueList: list,
        playhead: PlayheadState.empty,
        selectedCueId: null,
        onCueSelected: (_) {},
        notifier: notifier,
      )));
      await tester.pump();

      expect(find.byType(CueListPanel), findsOneWidget);
    });

    testWidgets('group cue children are not shown as top-level', (tester) async {
      const child1 = Cue(id: 'c1', number: '1.1', label: 'Child A', params: AudioParams(assetId: 'x'));
      const child2 = Cue(id: 'c2', number: '1.2', label: 'Child B', params: AudioParams(assetId: 'y'));
      const group  = Cue(
        id: 'g1', number: '1', label: 'Group',
        params: GroupParams(childCueIds: ['c1', 'c2']),
      );
      final list = CueList(id: 'main', name: 'Main', cues: const [group, child1, child2]);

      await tester.pumpWidget(_wrap(CueListPanel(
        cueList: list,
        playhead: PlayheadState.empty,
        selectedCueId: null,
        onCueSelected: (_) {},
        notifier: notifier,
      )));
      await tester.pump();

      // Group itself is shown
      expect(find.text('Group'), findsOneWidget);
      // Children are NOT in the top-level list (childIds are excluded from topLevel)
      expect(find.text('Child A'), findsNothing);
      expect(find.text('Child B'), findsNothing);
    });
  });
}
