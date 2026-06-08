import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/network/crypto/aes_gcm_service.dart';

void main() {
  late AesGcmService svc;
  setUpAll(() async {
    svc = await AesGcmService.withProductionKey();
  });
  group('AesGcmService', () {
    test('verschluesselter Output ist laenger als Input (+28 Bytes)', () async {
      final plain = Uint8List.fromList([1, 2, 3, 4, 5]);
      final enc = await svc.encrypt(plain);
      expect(enc.length, plain.length + 28); // 12 nonce + 16 tag
    });
    test('decrypt(encrypt(x)) == x', () async {
      final plain = Uint8List.fromList(List.generate(64, (i) => i));
      final enc = await svc.encrypt(plain);
      final dec = await svc.decrypt(enc);
      expect(dec, plain);
    });
    test(
        'zwei Verschluesselungen des gleichen Textes ergeben unterschiedliche Ciphertexte (random nonce)',
        () async {
      final plain = Uint8List.fromList([42, 43, 44]);
      final enc1 = await svc.encrypt(plain);
      final enc2 = await svc.encrypt(plain);
      expect(enc1, isNot(enc2)); // verschiedene Nonces
    });
    test('Manipulation des Ciphertexts wirft SecretBoxAuthenticationError',
        () async {
      final plain = Uint8List.fromList([1, 2, 3]);
      final enc = await svc.encrypt(plain);
      final tampered = Uint8List.fromList(enc)
        ..[15] ^= 0xFF; // Byte im Ciphertext flippen
      await expectLater(svc.decrypt(tampered), throwsException);
    });
    test('zu kurzes Byte-Array wirft FormatException', () async {
      final tooShort = Uint8List(10); // < 12 + 16 = 28
      await expectLater(svc.decrypt(tooShort), throwsFormatException);
    });
    test('leerer Plaintext verschlüsselbar und dekryptierbar', () async {
      final empty = Uint8List(0);
      final enc = await svc.encrypt(empty);
      final dec = await svc.decrypt(enc);
      expect(dec, empty);
    });
    test('fromHexKey mit falschem Format wirft AssertionError', () async {
      expect(() => AesGcmService.fromHexKey('zu-kurz'),
          throwsA(isA<AssertionError>()));
    });
  });
}
