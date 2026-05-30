import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/showcontrol/domain/cue_params.dart';
import 'package:theatre_companion_app/showcontrol/domain/cue_trigger.dart';
import 'package:theatre_companion_app/showcontrol/domain/show.dart';

void main() {
  group('Cue', () {
    const baseCue = Cue(
      id: 'cue-1',
      number: '1',
      label: 'Intro',
      params: AudioParams(assetId: 'abc123'),
    );

    test('copyWith replaces only specified fields', () {
      final updated = baseCue.copyWith(label: 'Scene A', armed: true);
      expect(updated.id, 'cue-1');
      expect(updated.label, 'Scene A');
      expect(updated.armed, isTrue);
      expect(updated.params, isA<AudioParams>());
    });

    test('copyWith on params preserves other AudioParams fields', () {
      const audio = AudioParams(assetId: 'abc123', volumeDb: -6, fadeInMs: 500);
      final updated = audio.copyWith(volumeDb: -12);
      expect(updated.assetId, 'abc123');
      expect(updated.volumeDb, -12);
      expect(updated.fadeInMs, 500);
    });

    test('displayDurationMs for AudioParams with endTime > startTime', () {
      const audio = AudioParams(
          assetId: 'x', startTimeMs: 1000, endTimeMs: 5000);
      final cue = baseCue.copyWith(params: audio);
      expect(cue.displayDurationMs, 4000.0);
    });

    test('displayDurationMs null when endTime == 0', () {
      expect(baseCue.displayDurationMs, isNull);
    });

    test('displayDurationMs for WaitParams', () {
      final cue = baseCue.copyWith(params: const WaitParams(durationMs: 2000));
      expect(cue.displayDurationMs, 2000.0);
    });

    test('displayDurationMs null for GroupParams', () {
      final cue = baseCue.copyWith(
          params: const GroupParams(childCueIds: ['a', 'b']));
      expect(cue.displayDurationMs, isNull);
    });
  });

  group('CueParams sealed hierarchy', () {
    test('pattern matching covers all subtypes without warnings', () {
      const List<CueParams> params = [
        AudioParams(assetId: 'id'),
        WaitParams(durationMs: 100),
        GroupParams(childCueIds: []),
        MaOscParams(oscAddress: '/ma2/cmd'),
        GotoParams(targetCueId: 'x'),
        OscParams(address: '/foo'),
        MidiParams(channel: 1, command: 0x90),
        ScriptParams(script: 'print()'),
        NoteParams(text: 'test'),
        FadeParams(targetCueId: 'x'),
      ];
      for (final p in params) {
        final label = switch (p) {
          AudioParams()  => 'audio',
          WaitParams()   => 'wait',
          GroupParams()  => 'group',
          MaOscParams()  => 'maosc',
          GotoParams()   => 'goto',
          OscParams()    => 'osc',
          MidiParams()   => 'midi',
          ScriptParams() => 'script',
          NoteParams()   => 'note',
          FadeParams()   => 'fade',
        };
        expect(label, isNotEmpty);
      }
    });

    test('AudioParams.effectiveDurationMs null when endTime <= startTime', () {
      const p = AudioParams(assetId: 'x', startTimeMs: 5000, endTimeMs: 1000);
      expect(p.effectiveDurationMs, isNull);
    });
  });

  group('CueList', () {
    final list = CueList(
      id: 'list-1',
      name: 'Act 1',
      cues: const [
        Cue(id: 'a', number: '1', label: 'A', params: AudioParams(assetId: 'x')),
        Cue(id: 'b', number: '2', label: 'B', params: WaitParams(durationMs: 1000)),
        Cue(id: 'c', number: '3', label: 'C', params: AudioParams(assetId: 'y')),
      ],
    );

    test('cueById finds existing cue', () {
      expect(list.cueById('b')?.label, 'B');
    });

    test('cueById returns null for unknown id', () {
      expect(list.cueById('z'), isNull);
    });

    test('cueAfter returns next cue', () {
      expect(list.cueAfter('a')?.id, 'b');
      expect(list.cueAfter('b')?.id, 'c');
    });

    test('cueAfter returns null at end of list', () {
      expect(list.cueAfter('c'), isNull);
    });

    test('cueAfter returns null for unknown id', () {
      expect(list.cueAfter('z'), isNull);
    });

    test('copyWith replaces cues list', () {
      final updated = list.copyWith(cues: []);
      expect(updated.cues, isEmpty);
      expect(updated.name, 'Act 1');
    });
  });

  group('CueTiming', () {
    test('default values', () {
      const t = CueTiming();
      expect(t.preWaitMs, 0.0);
      expect(t.autoContinue, isFalse);
      expect(t.durationMs, isNull);
    });

    test('copyWith preserves unset fields', () {
      const t = CueTiming(preWaitMs: 500, autoContinue: true);
      final u = t.copyWith(postWaitMs: 200);
      expect(u.preWaitMs, 500);
      expect(u.autoContinue, isTrue);
      expect(u.postWaitMs, 200);
    });
  });
}
