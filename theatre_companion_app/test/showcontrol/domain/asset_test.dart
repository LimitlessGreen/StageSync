import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/showcontrol/domain/asset.dart';

void main() {
  final base = Asset(
    id: 'sha256abc',
    name: 'intro.wav',
    sizeBytes: 1024 * 1024,
    mimeType: 'audio/wav',
    uploadedAt: DateTime(2024, 1, 1),
    readiness: AssetReadiness.present,
  );

  group('AssetReadiness ordering', () {
    test('enum values are in ascending readiness order', () {
      final values = AssetReadiness.values;
      expect(values[0], AssetReadiness.present);
      expect(values[1], AssetReadiness.validated);
      expect(values[2], AssetReadiness.renderable);
      expect(values[3], AssetReadiness.patched);
    });
  });

  group('Asset', () {
    test('isFullyReady only when patched', () {
      expect(base.isFullyReady, isFalse);
      final patched = base.copyWith(readiness: AssetReadiness.patched);
      expect(patched.isFullyReady, isTrue);
    });

    test('readinessLabel has all 4 states', () {
      for (final r in AssetReadiness.values) {
        final label = base.copyWith(readiness: r).readinessLabel;
        expect(label, isNotEmpty);
      }
    });

    test('copyWith preserves audio metadata', () {
      const meta = AudioMetadata(
        declaredDurationMs: 60000,
        channelCount: 2,
        sampleRateHz: 48000,
        codec: 'wav',
        bitDepth: 24,
      );
      final withAudio = base.copyWith(audio: meta);
      final renamed = withAudio.copyWith(name: 'outro.wav');
      expect(renamed.audio?.codec, 'wav');
      expect(renamed.name, 'outro.wav');
    });
  });

  group('AudioMetadata', () {
    test('channelLabel for standard configs', () {
      expect(
          const AudioMetadata(
                  declaredDurationMs: 0,
                  channelCount: 1,
                  sampleRateHz: 44100,
                  codec: 'wav',
                  bitDepth: 16)
              .channelLabel,
          'Mono');
      expect(
          const AudioMetadata(
                  declaredDurationMs: 0,
                  channelCount: 2,
                  sampleRateHz: 44100,
                  codec: 'wav',
                  bitDepth: 16)
              .channelLabel,
          'Stereo');
      expect(
          const AudioMetadata(
                  declaredDurationMs: 0,
                  channelCount: 6,
                  sampleRateHz: 48000,
                  codec: 'wav',
                  bitDepth: 24)
              .channelLabel,
          '5.1');
    });

    test('channelLabel fallback for non-standard count', () {
      expect(
          const AudioMetadata(
                  declaredDurationMs: 0,
                  channelCount: 4,
                  sampleRateHz: 48000,
                  codec: 'wav',
                  bitDepth: 24)
              .channelLabel,
          '4 ch');
    });
  });
}
