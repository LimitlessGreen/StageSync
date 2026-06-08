/// stub_ble_service.dart
/// ──────────────────────
/// No-op [AbstractBleService] für Plattformen ohne BLE-Unterstützung:
///   • Windows (WinRT-BLE noch nicht integriert)
///   • Web (WebBluetooth nur in Chrome/Edge, kein Peripheral-Modus)
///   • macOS / Linux
///
/// Das Netzwerk läuft im **WebSocket-only-Modus**: Der Server ist die einzige
/// Kommunikationsachse. Alle Pakete gehen direkt via WebSocket.
/// Der Store-Carry-Forward-Queue wird weiterhin verwendet, liefert aber nur
/// beim nächsten Server-Reconnect aus (nicht via BLE).
library stub_ble_service;

import 'dart:async';
import 'dart:typed_data';

import 'abstract_ble_service.dart';

class StubBleService implements AbstractBleService {
  final StreamController<IncomingBlePacket> _controller =
      StreamController<IncomingBlePacket>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  @override
  Stream<IncomingBlePacket> get onPacketReceived => _controller.stream;

  @override
  Stream<String> get onBleError => _errorController.stream;

  @override
  bool get isAdvertising => false;

  @override
  bool get isScanning => false;

  @override
  bool get isFallbackScanMode => false;

  @override
  int get activeConnectionCount => 0;

  @override
  Future<void> start() async {
    // BLE nicht verfügbar – kein Scan, kein Advertising.
    // Der Weaver erkennt via PeerRegistry.aliveCount == 0, dass kein Mesh
    // verfügbar ist, und leitet alles über WebSocket.
  }

  @override
  Future<void> stop() async {
    await _controller.close();
    await _errorController.close();
  }

  @override
  Future<void> sendPacket(
      String targetDeviceId, Uint8List plainPacketBytes) async {
    // Intentional No-op: auf dieser Plattform kein BLE.
    // Der Weaver muss die Nachricht alternativ via WebSocket senden.
  }

  @override
  Future<void> sendRawEncryptedPacket(
      String targetDeviceId, Uint8List alreadyEncryptedBytes) async {
    // Intentional No-op: kein BLE vorhanden.
  }

  @override
  Future<void> broadcastToSubscribers(Uint8List alreadyEncryptedBytes) async {
    // Intentional No-op: kein BLE vorhanden, keine Subscribers.
  }
}
