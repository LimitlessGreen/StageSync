import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Konfiguration für Mikrofon-Aufnahme.
/// PCM16-Mono mit 48 kHz für Opus-Kompatibilität.
const _micConfig = RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 48000,
  numChannels: 1,
);

/// Größe eines 20ms-Frames @ 48kHz Mono (960 Samples × 2 Bytes = 1920 Bytes).
const _frameBytes = 48000 * 20 ~/ 1000 * 1 * 2; // = 1920 bytes

/// MicCapture akkumuliert PCM16-Bytes aus dem Mikrofon-Stream und liefert
/// exakt 20ms-Frames (960 Samples = 1920 Bytes bei Mono). Übergabe über [onFrame].
class MicCapture {
  final AudioRecorder _recorder = AudioRecorder();
  final List<int> _buffer = [];
  bool _running = false;
  void Function(Int16List)? _onFrame; // gespeichert für Flush bei stop()

  /// Startet die Aufnahme. [onFrame] wird mit jedem vollständigen PCM16-Frame
  /// (als Int16List) aufgerufen — im Isolate des Stream-Listeners.
  Future<void> start({required void Function(Int16List frame) onFrame}) async {
    if (_running) return;
    _running = true;
    _onFrame = onFrame;
    _buffer.clear();

    final stream = await _recorder.startStream(_micConfig);
    stream.listen(
      (bytes) {
        if (!_running) return;
        _buffer.addAll(bytes);
        while (_buffer.length >= _frameBytes) {
          final frame = Uint8List.fromList(_buffer.sublist(0, _frameBytes));
          _buffer.removeRange(0, _frameBytes);
          onFrame(frame.buffer.asInt16List());
        }
      },
      onError: (_) => stop(),
      onDone: () => _running = false,
      cancelOnError: true,
    );
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    // Restpuffer mit Nullen auffüllen und als letztes Frame abgeben,
    // damit das Ende einer Aufnahme nicht abgeschnitten wird.
    final remainder = _buffer.length % _frameBytes;
    if (_buffer.isNotEmpty && remainder > 0) {
      _buffer.addAll(List.filled(_frameBytes - remainder, 0));
      final frame = Uint8List.fromList(_buffer.sublist(0, _frameBytes));
      _onFrame?.call(frame.buffer.asInt16List());
    }
    _buffer.clear();
    _onFrame = null;
    await _recorder.stop();
  }

  bool get isRunning => _running;

  void dispose() {
    stop();
    _recorder.dispose();
  }
}

/// Riverpod Provider für den gemeinsam genutzten MicCapture.
final micCaptureProvider = Provider<MicCapture>((ref) {
  final capture = MicCapture();
  ref.onDispose(capture.dispose);
  return capture;
});
