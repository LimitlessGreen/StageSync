import 'package:flutter_test/flutter_test.dart';
import 'package:fixnum/fixnum.dart';

import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/grid.pb.dart';
import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/grid.pbenum.dart';
import 'package:theatre_companion_app/showcontrol/domain/grid_run_state.dart';
import 'package:theatre_companion_app/showcontrol/providers/grid_execution_reducer.dart';

GridExecutionEvent ev(
  GridExecutionEvent_Type type, {
  String clipId = '',
  int startedAtMs = 0,
  double lengthMs = 0,
  List<String> running = const [],
  String error = '',
}) {
  return GridExecutionEvent()
    ..type = type
    ..clipId = clipId
    ..startedAtMs = Int64(startedAtMs)
    ..clipLengthMs = lengthMs
    ..errorMsg = error
    ..runningClipIds.addAll(running);
}

void main() {
  group('applyGridExecutionEvent', () {
    test('CLIP_PLAYING setzt playing mit Startzeit und Länge', () {
      final out = applyGridExecutionEvent(
        const {},
        ev(GridExecutionEvent_Type.CLIP_PLAYING,
            clipId: 'c1', startedAtMs: 1000, lengthMs: 5000),
      );
      expect(out['c1']!.lifecycle, ClipLifecycle.playing);
      expect(out['c1']!.startedServerMs, 1000);
      expect(out['c1']!.lengthMs, 5000);
    });

    test('CLIP_DONE entfernt den Clip', () {
      var s = applyGridExecutionEvent(
          const {}, ev(GridExecutionEvent_Type.CLIP_PLAYING, clipId: 'c1'));
      s = applyGridExecutionEvent(
          s, ev(GridExecutionEvent_Type.CLIP_DONE, clipId: 'c1'));
      expect(s.containsKey('c1'), isFalse);
    });

    test('CLIP_STOPPED entfernt den Clip', () {
      var s = applyGridExecutionEvent(
          const {}, ev(GridExecutionEvent_Type.CLIP_PLAYING, clipId: 'c1'));
      s = applyGridExecutionEvent(
          s, ev(GridExecutionEvent_Type.CLIP_STOPPED, clipId: 'c1'));
      expect(s.containsKey('c1'), isFalse);
    });

    test('CLIP_ERROR setzt error-Lifecycle mit Meldung', () {
      final out = applyGridExecutionEvent(
        const {},
        ev(GridExecutionEvent_Type.CLIP_ERROR, clipId: 'c1', error: 'boom'),
      );
      expect(out['c1']!.lifecycle, ClipLifecycle.error);
      expect(out['c1']!.error, 'boom');
    });

    test('GRID_SNAPSHOT ersetzt State mit laufenden Clips', () {
      final pre = applyGridExecutionEvent(
          const {}, ev(GridExecutionEvent_Type.CLIP_PLAYING, clipId: 'old'));
      final out = applyGridExecutionEvent(
        pre,
        ev(GridExecutionEvent_Type.GRID_SNAPSHOT, running: ['a', 'b']),
      );
      expect(out.containsKey('old'), isFalse);
      expect(out['a']!.lifecycle, ClipLifecycle.playing);
      expect(out['b']!.lifecycle, ClipLifecycle.playing);
    });

    test('startedAtMs == 0 → startedServerMs null', () {
      final out = applyGridExecutionEvent(
          const {},
          ev(GridExecutionEvent_Type.CLIP_PLAYING,
              clipId: 'c1', startedAtMs: 0));
      expect(out['c1']!.startedServerMs, isNull);
    });
  });
}
