/// abstract_ble_service.dart
/// ──────────────────────────
/// Abstrakte Schnittstelle für den BLE-Mesh-Layer.
/// Ermöglicht plattformspezifische Implementierungen ohne Änderungen
/// an GossipEngine oder NetworkRepositoryWeaver.
library abstract_ble_service;

import 'dart:typed_data';

/// Ein empfangenes, bereits entschlüsseltes BLE-Paket von einem Peer.
class IncomingBlePacket {
  /// BLE-Geräte-ID des Absenders.
  final String senderDeviceId;

  /// Das geparserte Paket (BleDataPacket / BleHeartbeatPacket / etc.).
  final Object packet;

  const IncomingBlePacket({
    required this.senderDeviceId,
    required this.packet,
  });
}

/// Abstrakte Schnittstelle für den BLE-Kommunikations-Layer.
///
/// Implementierungen:
///   • [BleMeshService]  – flutter_reactive_ble (Android, iOS)
///   • [StubBleService]  – No-op (Windows, Web, macOS, Linux)
abstract class AbstractBleService {
  /// Stream aller empfangenen, dekrypierten und geparseten Pakete.
  Stream<IncomingBlePacket> get onPacketReceived;

  /// Stream von Diagnosemeldungen und Fehlern aus dem BLE-Layer.
  /// Wird vom [NetworkRepositoryWeaver] abonniert und als [BleStatusEvent]
  /// an die UI weitergeleitet.
  /// Standard-Implementierung sendet nie (No-op für Stubs).
  Stream<String> get onBleError => Stream.empty();

  /// True wenn dieses Gerät aktuell als Peripheral advertised.
  bool get isAdvertising => false;

  /// True wenn aktiv gescannt wird.
  bool get isScanning => false;

  /// True wenn Scan-Fallback ohne UUID-Filter aktiv ist.
  bool get isFallbackScanMode => false;

  /// Anzahl aktiver GATT-Verbindungen zu Peers.
  int get activeConnectionCount => 0;

  /// Startet BLE-Scanning und macht das Gerät für andere sichtbar.
  Future<void> start();

  /// Stoppt alle BLE-Operationen sauber.
  Future<void> stop();

  /// Verschlüsselt [plainPacketBytes] mit AES-GCM und sendet an [targetDeviceId].
  /// Verbindet per GATT wenn noch nicht verbunden.
  Future<void> sendPacket(String targetDeviceId, Uint8List plainPacketBytes);

  /// Sendet [alreadyEncryptedBytes] **ohne erneute Verschlüsselung** an
  /// [targetDeviceId]. Wird ausschließlich für Store-Carry-Forward-Drain
  /// verwendet, weil die Queue-DB bereits verschlüsselte Bytes persistiert.
  ///
  /// Implementierungen müssen sicherstellen, dass die Bytes direkt per GATT
  /// Write gesendet werden (kein AES-GCM-Wrap-Around).
  Future<void> sendRawEncryptedPacket(
      String targetDeviceId, Uint8List alreadyEncryptedBytes);

  /// Sendet [alreadyEncryptedBytes] als BLE NOTIFY an alle Centrals, die auf
  /// die StageSync-Characteristic subscribed haben (z.B. Windows-Laptops).
  ///
  /// Wird von [GossipEngine] nach jedem weitergeleiteten Paket aufgerufen,
  /// damit Windows-Peers die Daten per NOTIFY erhalten ohne ein eigenes
  /// Gossip-WRITE starten zu müssen.
  ///
  /// Default-Implementierung: No-op (für Stub / Windows, die kein mobiles
  /// Peripheral sind).
  Future<void> broadcastToSubscribers(Uint8List alreadyEncryptedBytes) async {}
}
