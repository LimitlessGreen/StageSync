import 'dart:typed_data';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wrapper für SimpleOpusEncoder aus opus_dart.
/// Muss mit [init()] initialisiert werden bevor encode() aufgerufen werden kann.
class OpusEncoderWrapper {
  SimpleOpusEncoder? _encoder;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    // libopus laden und in opus_dart registrieren.
    // load() gibt die DynamicLibrary zurück — initOpus() muss sie erhalten.
    final lib = await opus_flutter.load();
    initOpus(lib);
    _encoder = SimpleOpusEncoder(
      sampleRate: 48000,
      channels: 1,
      application: Application.voip, // optimiert für Sprachübertragung
    );
    _initialized = true;
  }

  /// Kodiert einen Int16-PCM-Frame zu einem Opus-Paket.
  /// [input] muss genau 480 Samples enthalten (20ms @ 48kHz Mono).
  /// Gibt null zurück wenn der Encoder nicht initialisiert ist.
  Uint8List? encode(Int16List input) {
    if (_encoder == null) return null;
    try {
      return _encoder!.encode(input: input);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _encoder?.destroy();
    _encoder = null;
    _initialized = false;
  }
}

/// Riverpod Provider für den OpusEncoder (ein Encoder pro App).
final opusEncoderProvider = Provider<OpusEncoderWrapper>((ref) {
  final enc = OpusEncoderWrapper();
  ref.onDispose(enc.dispose);
  return enc;
});
