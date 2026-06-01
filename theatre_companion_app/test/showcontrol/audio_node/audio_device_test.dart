import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/showcontrol/nodes/audio_node/audio_device.dart';

void main() {
  group('audioBackendFromWireName', () {
    test('normalisiert bekannte Alias-Namen', () {
      expect(audioBackendFromWireName('jack2'), AudioBackend.jack);
      expect(audioBackendFromWireName('pulse'), AudioBackend.pulseAudio);
      expect(audioBackendFromWireName('dsound'), AudioBackend.directSound);
      expect(audioBackendFromWireName('opensles'), AudioBackend.openSLES);
    });

    test('liefert unknown bei unbekannten Werten', () {
      expect(audioBackendFromWireName('foo-backend'), AudioBackend.unknown);
    });
  });

  group('audioBackendToWireName', () {
    test('mappt Enum-Werte in Proto-Strings', () {
      expect(audioBackendToWireName(AudioBackend.jack), 'jack');
      expect(audioBackendToWireName(AudioBackend.asio), 'asio');
      expect(audioBackendToWireName(AudioBackend.pulseAudio), 'pulseaudio');
    });
  });
}
