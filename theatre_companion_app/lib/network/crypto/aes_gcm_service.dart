// aes_gcm_service.dart
// ─────────────────────
// AES-256-GCM symmetric encryption layer for all BLE Mesh broadcast packets.
//
// ## Security Model
// All devices in a theater production share a single 256-bit symmetric key
// that is compiled into the application (or loaded from a secure key-store at
// first launch). This is appropriate for a **closed, private network** where
// all participants are trusted staff. The key prevents passive eavesdropping
// and packet injection by non-StageSync devices operating nearby BLE radios.
//
// ## Wire Format (after [encrypt])
// ┌──────────────┬───────────────────┬─────────────────┐
// │  Nonce 12 B  │  Ciphertext N B   │  Auth-Tag 16 B  │
// └──────────────┴───────────────────┴─────────────────┘
// Total overhead: +28 bytes per packet.
//
// ## Usage
// ```dart
// final svc = AesGcmService.fromHexKey('...');
// final ciphertext = await svc.encrypt(plaintext);
// final plaintext  = await svc.decrypt(ciphertext); // throws on tamper
// ```
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Production shared key – REPLACE with your actual secret before shipping.
// In a real deployment, load this from a secure key-store (Android Keystore /
// iOS Secure Enclave) or derive it via ECDH + HKDF at pairing time.
// The key below is 32 bytes = 256 bits, AES-256 compliant.
// ─────────────────────────────────────────────────────────────────────────────

/// Hex-encoded 256-bit production key.  ← CHANGE BEFORE DEPLOYMENT
const String kStageSyncSharedKeyHex =
    'a3f8c2e1d4b7906a12345678abcdef0123456789abcdef0123456789abcdef01';

// ─────────────────────────────────────────────────────────────────────────────

class AesGcmService {
  static const int _nonceLength = 12; // GCM standard nonce size
  static const int _macLength = 16;   // GCM authentication tag size

  final AesGcm _algorithm;
  final SecretKey _secretKey;

  /// Private constructor – use factories below.
  AesGcmService._(this._algorithm, this._secretKey);

  // ─── Factories ──────────────────────────────────────────────────────────

  /// Construct from a 64-character lower-case hex string (32 bytes / 256 bits).
  static Future<AesGcmService> fromHexKey(String hexKey) async {
    assert(hexKey.length == 64, 'AES-256 key must be 64 hex chars (32 bytes)');
    final keyBytes = _hexToBytes(hexKey);
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(keyBytes);
    return AesGcmService._(algorithm, secretKey);
  }

  /// Convenience factory using the compiled-in production key.
  static Future<AesGcmService> withProductionKey() =>
      fromHexKey(kStageSyncSharedKeyHex);

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Encrypts [plaintext] using AES-256-GCM with a fresh random nonce.
  ///
  /// Returns `nonce (12 B) ‖ ciphertext (N B) ‖ auth-tag (16 B)`.
  Future<Uint8List> encrypt(Uint8List plaintext) async {
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: _secretKey,
      // nonce = null → the library generates a cryptographically random nonce
    );

    // Concatenate: nonce || ciphertext || mac for compact wire encoding.
    return Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  /// Decrypts and authenticates a packet produced by [encrypt].
  ///
  /// Throws [SecretBoxAuthenticationError] if the authentication tag is invalid
  /// (packet was tampered with or key mismatch). Callers MUST handle this.
  Future<Uint8List> decrypt(Uint8List encryptedBytes) async {
    if (encryptedBytes.length < _nonceLength + _macLength) {
      throw FormatException(
        'Encrypted packet too short: ${encryptedBytes.length} bytes '
        '(minimum ${_nonceLength + _macLength})',
      );
    }

    final nonce = encryptedBytes.sublist(0, _nonceLength);
    final cipherText =
        encryptedBytes.sublist(_nonceLength, encryptedBytes.length - _macLength);
    final mac = encryptedBytes.sublist(encryptedBytes.length - _macLength);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final plaintext = await _algorithm.decrypt(secretBox, secretKey: _secretKey);
    return Uint8List.fromList(plaintext);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}

