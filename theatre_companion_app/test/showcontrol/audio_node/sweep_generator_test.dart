import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:theatre_companion_app/showcontrol/nodes/audio_node/sweep_generator.dart';

void main() {
  // ── WAV-Header-Hilfsklasse ─────────────────────────────────────────────────

  /// Liest eine uint32-Zahl little-endian aus [bytes] ab [offset].
  int _readU32(Uint8List bytes, int offset) =>
      bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);

  /// Liest eine uint16-Zahl little-endian aus [bytes] ab [offset].
  int _readU16(Uint8List bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8);

  /// Liest 4 ASCII-Zeichen aus [bytes] ab [offset] als String.
  String _readTag(Uint8List bytes, int offset) =>
      String.fromCharCodes(bytes.sublist(offset, offset + 4));

  // ── SweepGenerator.generateTone ───────────────────────────────────────────

  group('SweepGenerator.generateTone', () {
    test('produziert valides RIFF/WAVE-Header', () {
      final wav = SweepGenerator.generateTone(
        frequencyHz: 1000,
        durationSeconds: 0.1,
      );

      expect(_readTag(wav, 0), 'RIFF', reason: 'RIFF-Chunk-ID');
      expect(_readTag(wav, 8), 'WAVE', reason: 'WAVE-Format');
      expect(_readTag(wav, 12), 'fmt ', reason: 'fmt-Chunk-ID');
      expect(_readTag(wav, 36), 'data', reason: 'data-Chunk-ID');
    });

    test('PCM-Format (audioFormat = 1)', () {
      final wav = SweepGenerator.generateTone(
        frequencyHz: 440,
        durationSeconds: 0.1,
      );
      expect(_readU16(wav, 20), 1, reason: 'PCM = 1');
    });

    test('Mono 44100 Hz 16-bit', () {
      final wav = SweepGenerator.generateTone(
        frequencyHz: 440,
        durationSeconds: 0.1,
      );
      expect(_readU16(wav, 22), 1, reason: '1 Kanal = Mono');
      expect(_readU32(wav, 24), 44100, reason: 'Sample-Rate');
      expect(_readU16(wav, 34), 16, reason: 'Bits per Sample');
    });

    test('korrekte Datenmenge für 0,1 Sekunden', () {
      final wav = SweepGenerator.generateTone(
        frequencyHz: 1000,
        durationSeconds: 0.1,
      );
      // 44100 Hz × 0,1 s = 4410 Samples × 2 Bytes = 8820 Bytes
      final dataSize = _readU32(wav, 40);
      expect(dataSize, 8820);
      // Gesamt: 44 (Header) + dataSize
      expect(wav.length, 44 + dataSize);
    });

    test('RIFF-Chunk-Größe stimmt mit Dateilänge überein', () {
      final wav = SweepGenerator.generateTone(
        frequencyHz: 1000,
        durationSeconds: 0.5,
      );
      final riffSize = _readU32(wav, 4);
      // RIFF-Chunk-Größe = Dateilänge - 8 Bytes (für "RIFF" + Größenfeld)
      expect(riffSize, wav.length - 8);
    });

    test('Amplitude 0,8 hält alle Samples in gültigem 16-bit-Bereich', () {
      final wav = SweepGenerator.generateTone(
        frequencyHz: 440,
        durationSeconds: 0.1,
        amplitude: 0.8,
      );
      final bd = ByteData.sublistView(wav, 44);
      for (var i = 0; i < bd.lengthInBytes - 1; i += 2) {
        final sample = bd.getInt16(i, Endian.little);
        expect(sample, inInclusiveRange(-32768, 32767));
      }
    });

    test('Amplitude 1,0 erzeugt Samples nahe ±32767', () {
      final wav = SweepGenerator.generateTone(
        frequencyHz: 1000,
        durationSeconds: 0.5, // genug Samples für Spitzenwert
        amplitude: 1.0,
      );
      final bd = ByteData.sublistView(wav, 44);
      int maxAbs = 0;
      for (var i = 0; i < bd.lengthInBytes - 1; i += 2) {
        final s = bd.getInt16(i, Endian.little).abs();
        if (s > maxAbs) maxAbs = s;
      }
      // Bei 1,0 Amplitude sollte Maximum nahe 32767 sein
      expect(maxAbs, greaterThan(30000));
    });

    test('Fade-In: erstes Sample ist nahe 0', () {
      final wav = SweepGenerator.generateTone(
        frequencyHz: 1000,
        durationSeconds: 0.5,
        amplitude: 1.0,
      );
      // 1. Sample (nach Header bei Offset 44) — Fade-In beginnt bei 0
      final bd = ByteData.sublistView(wav, 44);
      final firstSample = bd.getInt16(0, Endian.little).abs();
      // Erster Sample sollte durch Fade auf fast 0 sein (Index 0 / fadeLen ≈ 0)
      expect(firstSample, lessThan(100));
    });

    test('unterschiedliche Frequenzen erzeugen unterschiedliche Wellenformen',
        () {
      final wav440 = SweepGenerator.generateTone(
        frequencyHz: 440,
        durationSeconds: 0.1,
      );
      final wav880 = SweepGenerator.generateTone(
        frequencyHz: 880,
        durationSeconds: 0.1,
      );
      // Die Wellenformen müssen sich unterscheiden
      bool differ = false;
      for (var i = 44; i < wav440.length; i++) {
        if (wav440[i] != wav880[i]) {
          differ = true;
          break;
        }
      }
      expect(differ, isTrue);
    });
  });

  // ── SweepGenerator.generateSweep ──────────────────────────────────────────

  group('SweepGenerator.generateSweep', () {
    test('produziert valides RIFF/WAVE-Header', () {
      final wav = SweepGenerator.generateSweep(
        startHz: 20,
        endHz: 20000,
        durationSeconds: 0.5,
      );
      expect(_readTag(wav, 0), 'RIFF');
      expect(_readTag(wav, 8), 'WAVE');
      expect(_readTag(wav, 36), 'data');
    });

    test('korrekte Länge für 1 Sekunde Sweep', () {
      final wav = SweepGenerator.generateSweep(
        startHz: 20,
        endHz: 20000,
        durationSeconds: 1.0,
      );
      // 44100 Samples × 2 Bytes + 44 Header
      expect(wav.length, 44 + 44100 * 2);
    });

    test('alle Samples in gültigem 16-bit-Bereich', () {
      final wav = SweepGenerator.generateSweep(
        startHz: 20,
        endHz: 20000,
        durationSeconds: 0.1,
        amplitude: 1.0,
      );
      final bd = ByteData.sublistView(wav, 44);
      for (var i = 0; i < bd.lengthInBytes - 1; i += 2) {
        final s = bd.getInt16(i, Endian.little);
        expect(s, inInclusiveRange(-32768, 32767));
      }
    });

    test('Sweep mit vertauschten Start/End-Frequenzen ist verschieden', () {
      final wavUp = SweepGenerator.generateSweep(
        startHz: 100,
        endHz: 10000,
        durationSeconds: 0.2,
      );
      final wavDown = SweepGenerator.generateSweep(
        startHz: 10000,
        endHz: 100,
        durationSeconds: 0.2,
      );
      bool differ = false;
      for (var i = 44; i < wavUp.length; i++) {
        if (wavUp[i] != wavDown[i]) {
          differ = true;
          break;
        }
      }
      expect(differ, isTrue,
          reason: 'Aufwärts- und Abwärts-Sweep müssen sich unterscheiden');
    });

    test('Sweep und Ton gleicher Dauer haben gleiche Byte-Länge', () {
      final sweep = SweepGenerator.generateSweep(
        startHz: 100,
        endHz: 1000,
        durationSeconds: 0.3,
      );
      final tone = SweepGenerator.generateTone(
        frequencyHz: 440,
        durationSeconds: 0.3,
      );
      expect(sweep.length, tone.length);
    });
  });

  // ── Grenzfälle ────────────────────────────────────────────────────────────

  group('SweepGenerator Grenzfälle', () {
    test('sehr kurzer Ton (10 ms) hat korrekten Header', () {
      final wav = SweepGenerator.generateTone(
        frequencyHz: 1000,
        durationSeconds: 0.01,
      );
      expect(_readTag(wav, 0), 'RIFF');
      // 44100 × 0,01 = 441 Samples × 2 = 882 Bytes Daten
      expect(_readU32(wav, 40), 882);
    });

    test('amplitude = 0,0 erzeugt Stille', () {
      final wav = SweepGenerator.generateTone(
        frequencyHz: 1000,
        durationSeconds: 0.1,
        amplitude: 0.0,
      );
      final bd = ByteData.sublistView(wav, 44);
      for (var i = 0; i < bd.lengthInBytes - 1; i += 2) {
        expect(bd.getInt16(i, Endian.little), 0);
      }
    });
  });
}
