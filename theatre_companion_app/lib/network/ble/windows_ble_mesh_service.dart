/// windows_ble_mesh_service.dart
/// ──────────────────────────────
/// VERALTET – Diese Datei ist nicht mehr in Verwendung.
///
/// Die Windows-BLE-Implementierung ist jetzt in [BleMeshService] integriert,
/// da `bluetooth_low_energy` v6.x eine einheitliche Dart-API für
/// Android, iOS, Windows und macOS bereitstellt.
///
/// Bitte [ble_mesh_service.dart] verwenden.
///
/// ## Dual-Role-Architektur
///
/// ┌───────────────────────────────────────────────────────────────────┐
/// │  WindowsBleMeshService                                            │
/// │                                                                   │
/// │  Central-Rolle (CentralManager):                                  │
/// │    • Scannt nach StageSync-Geräten                               │
/// │    • Verbindet sich als GATT-Client                               │
/// │    • Schreibt Pakete auf Peer-Charakteristik (WRITE)             │
/// │    • Abonniert NOTIFY auf Peer-Charakteristik (Empfang)          │
/// │                                                                   │
/// │  Peripheral-Rolle (PeripheralManager):                            │
/// │    • Advertised als "StageSync"                                   │
/// │    • GATT-Server mit kStageSyncCharUuidStr                       │
/// │    • Empfängt WRITE-Anfragen von mobilen Geräten                 │
/// │    • Sendet NOTIFY an subscribed Centrals                        │
/// └───────────────────────────────────────────────────────────────────┘
///
/// ## GATT-Profil (identisch mit BleMeshService für Interoperabilität)
///   Service UUID:        kStageSyncServiceUuidStr
///   Characteristic UUID: kStageSyncCharUuidStr
///     Properties: WRITE, WRITE_WITHOUT_RESPONSE, NOTIFY
///
/// ## Empfangs-Richtungen
///   1. Mobile → Windows: Mobile verbindet zu Windows-Peripheral, schreibt GATT
///   2. Mobile → Windows: Windows subscribed auf NOTIFY der Mobile-Charakteristik
///      (erfordert dass Mobile NOTIFY sendet; implementiert in ble_mesh_service.dart)
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../crypto/aes_gcm_service.dart';
import '../models/ble_packet.dart';
import '../platform/abstract_ble_service.dart';
import '../routing/peer_registry.dart';

// Re-Export für Backward-Kompatibilität
export '../platform/abstract_ble_service.dart' show IncomingBlePacket;

// ─── UUID-Konstanten (müssen mit ble_mesh_service.dart übereinstimmen) ────────

/// StageSync BLE Service UUID (muss mit kStageSyncServiceUuid übereinstimmen).
const String kStageSyncServiceUuidStr = '4a4d4553-482d-0000-0000-535441474553';

/// Characteristic UUID (muss mit kStageSyncCharUuid übereinstimmen).
const String kStageSyncCharUuidStr = '4a4d4553-482d-0001-0000-535441474553';

/// CCCD-Descriptor-UUID für Notification-Subscriptions.
const String kCccdUuidStr = '00002902-0000-1000-8000-00805f9b34fb';

/// Gerätename für BLE-Advertising.
const String kWindowsStageSyncDeviceName = 'StageSync';

/// Maximale GATT-Verbindungen (Windows BLE hat praktische Limits).
const int kMaxGattConnections = 7;

/// Intervall für Scan-Neustart (ms).
const int kWindowsScanRestartIntervalMs = 10000;

/// Timeout für das Aufbauen einer GATT-Verbindung.
const Duration kGattConnectTimeout = Duration(seconds: 12);

/// Retry-Verzögerung beim Peripheral-Fehler.
const Duration kWindowsPeripheralRetryDelay = Duration(seconds: 20);

// ─────────────────────────────────────────────────────────────────────────────

class WindowsBleMeshService implements AbstractBleService {
  final PeerRegistry _peers;
  final AesGcmService _crypto;

  // ── BLE Manager-Instanzen ──────────────────────────────────────────────────
  final CentralManager _central = CentralManager();
  final PeripheralManager _peripheral = PeripheralManager();

  // ── Error / Status Stream ──────────────────────────────────────────────────
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  @override
  Stream<String> get onBleError => _errorController.stream;

  // ── Incoming Packet Stream ─────────────────────────────────────────────────
  final StreamController<IncomingBlePacket> _incomingController =
      StreamController<IncomingBlePacket>.broadcast();

  @override
  Stream<IncomingBlePacket> get onPacketReceived => _incomingController.stream;

  // ── Central-Zustand ────────────────────────────────────────────────────────

  /// Entdeckte Peripherals: UUID-String → Peripheral-Objekt.
  final Map<String, Peripheral> _discovered = {};

  /// Aktive GATT-Verbindungen: UUID-String → bekannte Characteristic.
  final Map<String, GATTCharacteristic> _connectedChars = {};

  /// In-Progress-Verbindungen (verhindern doppelte connect()-Aufrufe).
  final Set<String> _connectingSet = {};

  bool _isScanning = false;
  Timer? _scanRestartTimer;

  // ── Peripheral-Zustand ─────────────────────────────────────────────────────

  bool _peripheralStarted = false;
  int _peripheralRetryCount = 0;
  Timer? _peripheralRetryTimer;

  /// Mutable GATT-Characteristic-Objekt (für GATT-Server auf Windows).
  GATTCharacteristic? _mutableChar;

  /// Centrals die auf NOTIFY subscribed sind: UUID-String → Central.
  final Map<String, Central> _notifySubscribers = {};

  // ── Lifecycle Guard ────────────────────────────────────────────────────────
  bool _stopped = false;

  // ── Stream Subscriptions ───────────────────────────────────────────────────
  StreamSubscription<DiscoveredEventArgs>? _discoverySub;
  StreamSubscription<PeripheralConnectionStateChangedEventArgs>? _connStateSub;
  StreamSubscription<GATTCharacteristicNotifiedEventArgs>? _notifySub;
  StreamSubscription<GATTCharacteristicWriteRequestedEventArgs>? _writeReqSub;
  StreamSubscription<GATTCharacteristicNotifyStateChangedEventArgs>?
      _notifyStateSub;

  WindowsBleMeshService({
    required PeerRegistry peers,
    required AesGcmService crypto,
  })  : _peers = peers,
        _crypto = crypto;

  // ─── Status-Getter ────────────────────────────────────────────────────────

  @override
  bool get isAdvertising => _peripheralStarted;

  @override
  bool get isScanning => _isScanning;

  @override
  bool get isFallbackScanMode => false; // Windows hat keinen Fallback-Modus

  @override
  int get activeConnectionCount => _connectedChars.length;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  Future<void> start() async {
    _stopped = false;

    // 1. Peripheral-Rolle starten (Advertising + GATT-Server).
    await _startPeripheral();

    // 2. Central-Rolle starten (Scan + Verbindungsaufbau).
    _subscribeConnectionEvents();
    _subscribeNotifyEvents();
    await _startScan();
    _scheduleScanRestart();

    _emitStatus(
      'Windows BLE-Mesh gestartet. '
      'Scanne nach StageSync-Geräten und advertise als "$kWindowsStageSyncDeviceName".',
    );
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    _isScanning = false;
    _scanRestartTimer?.cancel();
    _peripheralRetryTimer?.cancel();

    // Central aufräumen
    await _discoverySub?.cancel();
    await _connStateSub?.cancel();
    await _notifySub?.cancel();

    try {
      await _central.stopDiscovery();
    } catch (_) {}

    for (final peer in List.of(_discovered.values)) {
      try {
        await _central.disconnect(peer);
      } catch (_) {}
    }

    // Peripheral aufräumen
    await _writeReqSub?.cancel();
    await _notifyStateSub?.cancel();

    if (_peripheralStarted) {
      try {
        await _peripheral.stopAdvertising();
        await _peripheral.removeAllServices();
      } catch (_) {}
      _peripheralStarted = false;
    }

    if (!_incomingController.isClosed) await _incomingController.close();
    if (!_errorController.isClosed) await _errorController.close();
  }

  // ─── Peripheral-Rolle: GATT-Server + Advertising ──────────────────────────

  Future<void> _startPeripheral() async {
    if (_stopped) return;
    try {
      // CCCD-Descriptor (Client Characteristic Configuration Descriptor)
      // Pflicht für NOTIFY-Property; Centrals schreiben hier 0x0100 um zu subscriben.
      final cccd = GATTDescriptor.mutable(
        uuid: UUID.fromString(kCccdUuidStr),
        permissions: [
          GATTCharacteristicPermission.read,
          GATTCharacteristicPermission.write,
        ],
      );

      // Mutable Characteristic mit Write + WriteWithoutResponse + Notify.
      final char = GATTCharacteristic.mutable(
        uuid: UUID.fromString(kStageSyncCharUuidStr),
        properties: [
          GATTCharacteristicProperty.write,
          GATTCharacteristicProperty.writeWithoutResponse,
          GATTCharacteristicProperty.notify,
        ],
        permissions: [
          GATTCharacteristicPermission.read,
          GATTCharacteristicPermission.write,
        ],
        descriptors: [cccd],
      );
      _mutableChar = char;

      // Service aufbauen.
      final service = GATTService(
        uuid: UUID.fromString(kStageSyncServiceUuidStr),
        isPrimary: true,
        includedServices: [],
        characteristics: [char],
      );

      await _peripheral.removeAllServices();
      await _peripheral.addService(service);

      // Callbacks für Write-Anfragen und Notify-Subscriptions registrieren.
      _subscribePeripheralEvents(char);

      // Advertising starten.
      await _peripheral.startAdvertising(Advertisement(
        name: kWindowsStageSyncDeviceName,
        serviceUUIDs: [UUID.fromString(kStageSyncServiceUuidStr)],
      ));

      _peripheralStarted = true;
      _peripheralRetryCount = 0;
      _emitStatus(
        'Windows-Peripheral gestartet – Gerät ist auffindbar als "$kWindowsStageSyncDeviceName".',
      );
    } catch (e) {
      _peripheralStarted = false;
      _reportError(
        'BLE Peripheral-Start fehlgeschlagen '
        '(Versuch ${_peripheralRetryCount + 1}): $e',
      );
      _schedulePeripheralRetry();
    }
  }

  /// Exponentieller Backoff für Peripheral-Neustart.
  void _schedulePeripheralRetry() {
    if (_stopped || _peripheralRetryCount >= 5) {
      if (_peripheralRetryCount >= 5) {
        _reportError(
          'Windows BLE Advertising dauerhaft fehlgeschlagen. '
          'Gerät ist für andere nicht auffindbar. WebSocket-Routing aktiv.',
        );
      }
      return;
    }
    final delay = kWindowsPeripheralRetryDelay * (1 << _peripheralRetryCount);
    _peripheralRetryCount++;
    _peripheralRetryTimer?.cancel();
    _peripheralRetryTimer = Timer(delay, _startPeripheral);
  }

  /// Abonniert Write-Anfragen vom GATT-Client (mobile → Windows).
  void _subscribePeripheralEvents(GATTCharacteristic char) {
    _writeReqSub?.cancel();
    _writeReqSub =
        _peripheral.characteristicWriteRequested.listen((args) async {
      // Nur unsere Characteristic verarbeiten.
      if (args.characteristic.uuid != char.uuid) return;

      final encryptedBytes = args.request.value;
      final centralUuid = args.central.uuid.toString();

      // Immer auf Write reagieren (auch ohne Response-Write).
      try {
        await _peripheral.respondWriteRequest(args.request);
      } catch (_) {}

      // Peer registrieren und Paket entschlüsseln.
      _peers.touchPeer(
        deviceId: centralUuid,
        deviceShortId: shortIdFromString(centralUuid),
        rssi: -70,
      );

      await _onRawBytesReceived(centralUuid, encryptedBytes);
    });

    // Notify-Subscription-Änderungen verfolgen.
    _notifyStateSub?.cancel();
    _notifyStateSub =
        _peripheral.characteristicNotifyStateChanged.listen((args) {
      if (args.characteristic.uuid != char.uuid) return;
      final centralUuid = args.central.uuid.toString();
      if (args.state) {
        _notifySubscribers[centralUuid] = args.central;
        _emitStatus(
          'Central $centralUuid hat NOTIFY auf StageSync-Char abonniert.',
        );
      } else {
        _notifySubscribers.remove(centralUuid);
      }
    });
  }

  // ─── Central-Rolle: Scan + GATT-Verbindung ────────────────────────────────

  Future<void> _startScan() async {
    if (_stopped) return;
    try {
      await _central.stopDiscovery();
    } catch (_) {}

    _discoverySub?.cancel();
    _discoverySub = _central.discovered.listen(_onDeviceDiscovered);

    try {
      await _central.startDiscovery(
        serviceUUIDs: [UUID.fromString(kStageSyncServiceUuidStr)],
      );
      _isScanning = true;
    } catch (e) {
      _isScanning = false;
      _reportError('BLE-Scan fehlgeschlagen: $e');
    }
  }

  void _scheduleScanRestart() {
    _scanRestartTimer?.cancel();
    _scanRestartTimer = Timer.periodic(
      Duration(milliseconds: kWindowsScanRestartIntervalMs),
      (_) async {
        if (_stopped) return;
        _peers.evictStale();
        await _startScan();
      },
    );
  }

  void _onDeviceDiscovered(DiscoveredEventArgs args) {
    if (_stopped) return;

    final peer = args.peripheral;
    final peerUuid = peer.uuid.toString();

    _discovered[peerUuid] = peer;
    _peers.touchPeer(
      deviceId: peerUuid,
      deviceShortId: shortIdFromString(peerUuid),
      rssi: args.rssi,
    );

    // Verbindung aufbauen falls noch nicht verbunden.
    if (!_connectedChars.containsKey(peerUuid) &&
        !_connectingSet.contains(peerUuid) &&
        _connectedChars.length < kMaxGattConnections) {
      _connectToPeer(peer).ignore();
    }
  }

  void _subscribeConnectionEvents() {
    _connStateSub?.cancel();
    _connStateSub = _central.connectionStateChanged.listen((args) {
      final uuid = args.peripheral.uuid.toString();
      if (args.state == ConnectionState.disconnected) {
        _onPeerDisconnected(uuid);
      }
    });
  }

  void _subscribeNotifyEvents() {
    _notifySub?.cancel();
    _notifySub = _central.characteristicNotified.listen((args) async {
      // Eingehende NOTIFY von einem entdeckten Mobile-Peer.
      final peerUuid = args.peripheral.uuid.toString();
      await _onRawBytesReceived(peerUuid, args.value);
    });
  }

  Future<void> _connectToPeer(Peripheral peer) async {
    final peerUuid = peer.uuid.toString();
    if (_stopped ||
        _connectedChars.containsKey(peerUuid) ||
        _connectingSet.contains(peerUuid)) {
      return;
    }

    _connectingSet.add(peerUuid);
    try {
      await _central.connect(peer).timeout(kGattConnectTimeout);

      // GATT-Services und Characteristics ermitteln.
      final services = await _central.discoverGATT(peer);
      final GATTCharacteristic? targetChar =
          _findStageSyncChar(services, peerUuid);

      if (targetChar == null) {
        _reportError(
          'Peer $peerUuid: StageSync-Characteristic nicht gefunden. '
          'Trenne Verbindung.',
        );
        await _central.disconnect(peer);
        return;
      }

      _connectedChars[peerUuid] = targetChar;
      _emitStatus(
        'GATT-Verbindung zu $peerUuid hergestellt. '
        '(${_connectedChars.length} aktive Verbindung(en))',
      );

      // NOTIFY auf der Peer-Charakteristik abonnieren, damit Mobile → Windows
      // Pakete senden kann (Mobile ruft notifyCharacteristic auf).
      if (targetChar.properties.contains(GATTCharacteristicProperty.notify)) {
        try {
          await _central.setCharacteristicNotifyState(
            peer,
            targetChar,
            state: true,
          );
        } catch (e) {
          _reportError('NOTIFY-Subscription auf $peerUuid fehlgeschlagen: $e');
        }
      }
    } on TimeoutException {
      _reportError('GATT-Verbindung zu $peerUuid timeout.');
    } catch (e) {
      _reportError('GATT-Verbindungsfehler zu $peerUuid: $e');
    } finally {
      _connectingSet.remove(peerUuid);
    }
  }

  /// Sucht die StageSync-Charakteristik in einer GATT-Service-Liste.
  GATTCharacteristic? _findStageSyncChar(
      List<GATTService> services, String peerUuid) {
    final targetServiceUuid = UUID.fromString(kStageSyncServiceUuidStr);
    final targetCharUuid = UUID.fromString(kStageSyncCharUuidStr);

    for (final svc in services) {
      if (svc.uuid != targetServiceUuid) continue;
      for (final ch in svc.characteristics) {
        if (ch.uuid == targetCharUuid) return ch;
      }
    }
    return null;
  }

  void _onPeerDisconnected(String peerUuid) {
    _connectedChars.remove(peerUuid);
    _connectingSet.remove(peerUuid);
    _emitStatus(
      'Peer $peerUuid getrennt. '
      '(${_connectedChars.length} Verbindung(en) verbleiben)',
    );
    // Sofortiger Reconnect-Versuch falls Peer noch in _discovered.
    final peer = _discovered[peerUuid];
    if (peer != null && !_stopped) {
      Future.delayed(
        const Duration(seconds: 3),
        () => _connectToPeer(peer).ignore(),
      );
    }
  }

  // ─── Send: Windows → Mobile ──────────────────────────────────────────────

  @override
  Future<void> sendPacket(
      String targetDeviceId, Uint8List plainPacketBytes) async {
    final encrypted = await _crypto.encrypt(plainPacketBytes);
    await _sendEncryptedToDevice(targetDeviceId, encrypted);
  }

  @override
  Future<void> sendRawEncryptedPacket(
      String targetDeviceId, Uint8List alreadyEncryptedBytes) async {
    await _sendEncryptedToDevice(targetDeviceId, alreadyEncryptedBytes);
  }

  Future<void> _sendEncryptedToDevice(
      String peerUuid, Uint8List encryptedBytes) async {
    // Weg 1: Als Central via GATT-Write auf dem Peer.
    final char = _connectedChars[peerUuid];
    if (char != null) {
      final peer = _discovered[peerUuid];
      if (peer != null) {
        try {
          await _central.writeCharacteristic(
            peer,
            char,
            value: encryptedBytes,
            type: GATTCharacteristicWriteType.withResponse,
          );
          return;
        } catch (e) {
          _reportError('GATT-Write an $peerUuid fehlgeschlagen: $e');
          _onPeerDisconnected(peerUuid);
        }
      }
    }

    // Weg 2: Als Peripheral via NOTIFY an subscribed Central.
    final subscribedCentral = _notifySubscribers[peerUuid];
    final mutableChar = _mutableChar;
    if (subscribedCentral != null && mutableChar != null) {
      try {
        await _peripheral.notifyCharacteristic(
          subscribedCentral,
          mutableChar,
          value: encryptedBytes,
        );
        return;
      } catch (e) {
        _reportError('NOTIFY an $peerUuid fehlgeschlagen: $e');
      }
    }

    // Keine Verbindung → Reconnect versuchen.
    final peer = _discovered[peerUuid];
    if (peer != null && !_connectingSet.contains(peerUuid)) {
      _connectToPeer(peer).ignore();
    }
  }

  // ─── Receive: Entschlüsseln + Parsen ─────────────────────────────────────

  Future<void> _onRawBytesReceived(
      String senderDeviceId, Uint8List encrypted) async {
    try {
      final plainBytes = await _crypto.decrypt(encrypted);
      final packet = parseBlePacket(plainBytes);
      _incomingController.add(
        IncomingBlePacket(senderDeviceId: senderDeviceId, packet: packet),
      );
    } on FormatException {
      // Malformed packet → verwerfen.
    } catch (_) {
      // Authentifizierungsfehler oder unbekannter Fehler → verwerfen.
    }
  }

  // ─── Diagnostik ───────────────────────────────────────────────────────────

  /// Sendet [alreadyEncryptedBytes] als NOTIFY an alle subscribed Centrals.
  ///
  /// Wird vom GossipEngine nach jedem originierten/weitergeleiteten Paket
  /// aufgerufen, damit mobile Geräte, die als Centrals auf unseren Peripheral
  /// subscribed sind, die Daten direkt erhalten.
  @override
  Future<void> broadcastToSubscribers(Uint8List alreadyEncryptedBytes) async {
    final mutableChar = _mutableChar;
    if (mutableChar == null || _notifySubscribers.isEmpty) return;

    for (final entry in List.of(_notifySubscribers.entries)) {
      try {
        await _peripheral.notifyCharacteristic(
          entry.value,
          mutableChar,
          value: alreadyEncryptedBytes,
        );
      } catch (e) {
        _reportError(
          'broadcastToSubscribers NOTIFY an ${entry.key} fehlgeschlagen: $e',
        );
        _notifySubscribers.remove(entry.key);
      }
    }
  }

  void _reportError(String message) {
    if (!_errorController.isClosed) _errorController.add(message);
  }

  void _emitStatus(String message) {
    // Status-Meldungen werden über denselben Stream geleitet;
    // der Weaver konvertiert sie zu BleStatusEvent.
    if (!_errorController.isClosed) _errorController.add(message);
  }
}
