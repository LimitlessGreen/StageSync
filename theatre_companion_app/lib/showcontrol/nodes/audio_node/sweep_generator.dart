import 'dart:math' as math;
import 'dart:typed_data';

/// Generiert einen Sinuston-Sweep als PCM-WAV-Bytes.
/// Exponentieller Sweep von [startHz] bis [endHz] über [durationSeconds].
class SweepGenerator {
  static const int _sampleRate = 44100;
  static const int _channels = 1;
  static const int _bitsPerSample = 16;

  static Uint8List generateSweep({
    required double startHz,
    required double endHz,
    required double durationSeconds,
    double amplitude = 0.8,
  }) {
    final numSamples = (_sampleRate * durationSeconds).round();
    final samples = Int16List(numSamples);

    // Exponentieller Sweep: f(t) = f1 * (f2/f1)^(t/T)
    // Phase:  φ(t) = 2π * f1 * T/ln(f2/f1) * [(f2/f1)^(t/T) - 1]
    final T = durationSeconds;
    final f1 = startHz;
    final f2 = endHz;
    final lnRatio = math.log(f2 / f1);
    final phaseCoeff = 2 * math.pi * f1 * T / lnRatio;

    for (var i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final phase = phaseCoeff * (math.pow(f2 / f1, t / T) - 1);
      final sample = amplitude * math.sin(phase);
      // Fade-in/out (10ms an jedem Ende)
      final fadeLen = (_sampleRate * 0.01).round();
      double env = 1.0;
      if (i < fadeLen) env = i / fadeLen;
      if (i > numSamples - fadeLen) env = (numSamples - i) / fadeLen;
      samples[i] = (sample * env * 32767).round().clamp(-32768, 32767);
    }

    return _buildWav(samples);
  }

  static Uint8List generateTone({
    required double frequencyHz,
    required double durationSeconds,
    double amplitude = 0.8,
  }) {
    final numSamples = (_sampleRate * durationSeconds).round();
    final samples = Int16List(numSamples);
    final fadeLen = (_sampleRate * 0.01).round();

    for (var i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final sample = amplitude * math.sin(2 * math.pi * frequencyHz * t);
      double env = 1.0;
      if (i < fadeLen) env = i / fadeLen;
      if (i > numSamples - fadeLen) env = (numSamples - i) / fadeLen;
      samples[i] = (sample * env * 32767).round().clamp(-32768, 32767);
    }

    return _buildWav(samples);
  }

  static Uint8List _buildWav(Int16List samples) {
    final dataSize = samples.length * 2; // 16-bit = 2 bytes per sample
    final totalSize = 44 + dataSize;
    final buf = ByteData(totalSize);

    // RIFF header
    _writeAscii(buf, 0, 'RIFF');
    buf.setUint32(4, totalSize - 8, Endian.little);
    _writeAscii(buf, 8, 'WAVE');

    // fmt chunk
    _writeAscii(buf, 12, 'fmt ');
    buf.setUint32(16, 16, Endian.little); // chunk size
    buf.setUint16(20, 1, Endian.little);  // PCM
    buf.setUint16(22, _channels, Endian.little);
    buf.setUint32(24, _sampleRate, Endian.little);
    buf.setUint32(28, _sampleRate * _channels * _bitsPerSample ~/ 8, Endian.little); // byte rate
    buf.setUint16(32, _channels * _bitsPerSample ~/ 8, Endian.little); // block align
    buf.setUint16(34, _bitsPerSample, Endian.little);

    // data chunk
    _writeAscii(buf, 36, 'data');
    buf.setUint32(40, dataSize, Endian.little);

    // samples
    for (var i = 0; i < samples.length; i++) {
      buf.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buf.buffer.asUint8List();
  }

  static void _writeAscii(ByteData buf, int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      buf.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
