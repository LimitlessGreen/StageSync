/// ble_mesh_service.dart
/// ──────────────────────
/// Einheitlicher BLE-Mesh-Service für alle nativen Plattformen
/// (Android, iOS, Windows, macOS) via `bluetooth_low_energy` v6.x.
///
/// ## Wichtige Fixes gegenüber initialem Entwurf
///
///   1. **authorize()** – Muss auf Android VOR startDiscovery() aufgerufen
///      werden. Ohne authorize() bleibt state = unauthorized und der Scan
///      findet stumm nichts.
///
///   2. **State-Management** – CentralManager/PeripheralManager können den
///      State `poweredOff` oder `unknown` haben wenn der Service startet.
///      Wir subscriben auf stateChanged und starten Scan/Advertising erst
///      wenn `poweredOn` signalisiert wird.
///
///   3. **Fallback-Scan** – Einige Android-Versionen filtern 128-bit UUIDs
///      im BLE-Scan falsch. Nach 15 Sekunden ohne Peers wechseln wir auf
///      einen ungefilterten Scan mit Dart-seitigem Filter (Name oder UUID).
///
/// ## GATT-Profil (identisch auf allen Plattformen)
///   Service UUID:        kStageSyncServiceUuid
///   Characteristic UUID: kStageSyncCharUuid
///     Properties: WRITE, WRITE_WITHOUT_RESPONSE, NOTIFY
library;
import 'dart:async';
import 'dart:typed_data';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import '../crypto/aes_gcm_service.dart';
import '../models/ble_packet.dart';
import '../platform/abstract_ble_service.dart';
import '../routing/peer_registry.dart';
export '../platform/abstract_ble_service.dart' show IncomingBlePacket;
// ─── UUID-Konstanten ──────────────────────────────────────────────────────────
const String kStageSyncServiceUuid = '4a4d4553-482d-0000-0000-535441474553';
const String kStageSyncCharUuid    = '4a4d4553-482d-0001-0000-535441474553';
const String kStageSyncCccdUuid    = '00002902-0000-1000-8000-00805f9b34fb';
const String kStageSyncDeviceName  = 'StageSync';
const int      kMaxGattConnections        = 7;
const int      kScanRestartIntervalMs     = 10000;
const Duration kGattConnectTimeout        = Duration(seconds: 12);
const Duration kPeripheralRetryBaseDelay  = Duration(seconds: 15);
const int      kMaxPeripheralRetries      = 5;
/// Wartezeit bis Fallback-Scan (ohne UUID-Filter) aktiviert wird.
const Duration kFallbackScanDelay         = Duration(seconds: 15);
// ─────────────────────────────────────────────────────────────────────────────
class BleMeshService implements AbstractBleService {
  final PeerRegistry  _peers;
  final AesGcmService _crypto;
  final CentralManager    _central    = CentralManager();
  final PeripheralManager _peripheral = PeripheralManager();
  final StreamController<String>            _errorController    = StreamController<String>.broadcast();
  final StreamController<IncomingBlePacket> _incomingController = StreamController<IncomingBlePacket>.broadcast();
  @override Stream<String>            get onBleError      => _errorController.stream;
  @override Stream<IncomingBlePacket> get onPacketReceived => _incomingController.stream;
  // ── Central-Zustand ────────────────────────────────────────────────────────
  final Map<String, Peripheral>        _discovered     = {};
  final Map<String, GATTCharacteristic> _connectedChars = {};
  final Set<String>                    _connectingSet  = {};
  bool   _isScanning         = false;
  bool   _isFallbackScanMode = false;
  Timer? _scanRestartTimer;
  Timer? _fallbackScanTimer;
  // ── Peripheral-Zustand ─────────────────────────────────────────────────────
  bool   _peripheralStarted   = false;
  int    _peripheralRetryCount = 0;
  Timer? _peripheralRetryTimer;
  GATTCharacteristic?        _mutableChar;
  final Map<String, Central> _notifySubscribers = {};
  // ── Lifecycle Guard ────────────────────────────────────────────────────────
  bool _stopped = false;
  // ── BLE-State Subscriptions ────────────────────────────────────────────────
  StreamSubscription<BluetoothLowEnergyStateChangedEventArgs>? _centralStateSub;
  StreamSubscription<BluetoothLowEnergyStateChangedEventArgs>? _peripheralStateSub;
  // ── Event Subscriptions ────────────────────────────────────────────────────
  StreamSubscription<DiscoveredEventArgs>?                           _discoverySub;
  StreamSubscription<PeripheralConnectionStateChangedEventArgs>?     _connStateSub;
  StreamSubscription<GATTCharacteristicNotifiedEventArgs>?           _notifySub;
  StreamSubscription<GATTCharacteristicWriteRequestedEventArgs>?     _writeReqSub;
  StreamSubscription<GATTCharacteristicNotifyStateChangedEventArgs>? _notifyStateSub;
  BleMeshService({required PeerRegistry peers, required AesGcmService crypto})
      : _peers = peers, _crypto = crypto;
  // ─── Status-Getter ────────────────────────────────────────────────────────
  @override bool get isAdvertising        => _peripheralStarted;
  @override bool get isScanning           => _isScanning;
  @override bool get isFallbackScanMode   => _isFallbackScanMode;
  @override int  get activeConnectionCount => _connectedChars.length;
  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  Future<void> start() async {
    _stopped = false;
    // 1. State-Änderungen abonnieren (VOR authorize/start).
    _centralStateSub =
        _central.stateChanged.listen(_onCentralStateChanged);
    _peripheralStateSub =
        _peripheral.stateChanged.listen(_onPeripheralStateChanged);

    // 2. Nicht-blockierende BLE-Initialisierung starten.
    //    WICHTIG: Kein `await` – start() muss sofort zurückkehren damit init()
    //    nicht hängt. BLE-Operationen laufen asynchron weiter.
    _initBleAsync();
  }

  /// Führt die eigentliche BLE-Initialisierung NICHT-BLOCKIEREND durch.
  /// Wird als Fire-and-Forget aus [start()] gerufen.
  void _initBleAsync() async {
    // Auf Android: authorize() muss VOR startDiscovery() aufgerufen werden.
    // Mit 8-Sekunden-Timeout damit es nicht hängt, wenn der Activity-Result
    // nie zurückkommt (tritt auf, wenn permission_handler und
    // bluetooth_low_energy beide Activity-Results nutzen).
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final centralOk = await _central
            .authorize()
            .timeout(const Duration(seconds: 8), onTimeout: () => false);
        final peripheralOk = await _peripheral
            .authorize()
            .timeout(const Duration(seconds: 8), onTimeout: () => false);
        _emitStatus(
          'BLE authorize(): Central=$centralOk, Peripheral=$peripheralOk',
        );
      } catch (e) {
        _reportError('authorize() fehlgeschlagen: $e');
      }
    }

    if (_stopped) return;

    // Aktuellen State lesen und sofort starten falls bereits poweredOn.
    final centralState    = _central.state;
    final peripheralState = _peripheral.state;
    _emitStatus(
      'BLE-Adapter-State: Central=${centralState.name}, '
      'Peripheral=${peripheralState.name}',
    );
    if (centralState == BluetoothLowEnergyState.poweredOn) {
      _subscribeConnectionEvents();
      _subscribeNotifyEvents();
      _startScan().ignore();        // fire-and-forget – kein await
      _scheduleScanRestart();
      _scheduleFallbackScan();
    }
    if (peripheralState == BluetoothLowEnergyState.poweredOn) {
      _startPeripheral().ignore();  // fire-and-forget – kein await
    }
  }
  @override
  Future<void> stop() async {
    _stopped = true;
    _isScanning         = false;
    _isFallbackScanMode = false;
    _scanRestartTimer?.cancel();
    _fallbackScanTimer?.cancel();
    _peripheralRetryTimer?.cancel();
    await _centralStateSub?.cancel();
    await _peripheralStateSub?.cancel();
    await _discoverySub?.cancel();
    await _connStateSub?.cancel();
    await _notifySub?.cancel();
    try {
      await _central.stopDiscovery()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    } catch (_) {}
    for (final peer in List.of(_discovered.values)) {
      try {
        await _central.disconnect(peer)
            .timeout(const Duration(seconds: 3), onTimeout: () {});
      } catch (_) {}
    }
    await _writeReqSub?.cancel();
    await _notifyStateSub?.cancel();
    if (_peripheralStarted) {
      try {
        await _peripheral.stopAdvertising()
            .timeout(const Duration(seconds: 5), onTimeout: () {});
        await _peripheral.removeAllServices()
            .timeout(const Duration(seconds: 5), onTimeout: () {});
      } catch (_) {}
      _peripheralStarted = false;
    }
    if (!_incomingController.isClosed) await _incomingController.close();
    if (!_errorController.isClosed)    await _errorController.close();
  }
  // ─── BLE-State Callbacks ──────────────────────────────────────────────────
  void _onCentralStateChanged(BluetoothLowEnergyStateChangedEventArgs args) {
    _emitStatus('Central-State: ${args.state.name}');
    if (_stopped) return;
    if (args.state == BluetoothLowEnergyState.poweredOn) {
      _subscribeConnectionEvents();
      _subscribeNotifyEvents();
      _startScan().ignore();
      _scheduleScanRestart();
      _scheduleFallbackScan();
    } else {
      _isScanning = false;
      _isFallbackScanMode = false;
      _scanRestartTimer?.cancel();
      _fallbackScanTimer?.cancel();
    }
  }
  void _onPeripheralStateChanged(
      BluetoothLowEnergyStateChangedEventArgs args) {
    _emitStatus('Peripheral-State: ${args.state.name}');
    if (_stopped) return;
    if (args.state == BluetoothLowEnergyState.poweredOn) {
      _startPeripheral().ignore();
    } else {
      _peripheralStarted = false;
    }
  }
  // ─── Peripheral-Rolle ────────────────────────────────────────────────────
  Future<void> _startPeripheral() async {
    if (_stopped) return;
    try {
      final cccd = GATTDescriptor.mutable(
        uuid: UUID.fromString(kStageSyncCccdUuid),
        permissions: [
          GATTCharacteristicPermission.read,
          GATTCharacteristicPermission.write,
        ],
      );
      final char = GATTCharacteristic.mutable(
        uuid: UUID.fromString(kStageSyncCharUuid),
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
      final service = GATTService(
        uuid: UUID.fromString(kStageSyncServiceUuid),
        isPrimary: true,
        includedServices: [],
        characteristics: [char],
      );
      await _peripheral.removeAllServices()
          .timeout(const Duration(seconds: 8), onTimeout: () {});
      await _peripheral.addService(service)
          .timeout(const Duration(seconds: 8), onTimeout: () {
        throw TimeoutException('addService() timeout');
      });
      _subscribePeripheralEvents(char);
      await _peripheral.startAdvertising(Advertisement(
        name: kStageSyncDeviceName,
        serviceUUIDs: [UUID.fromString(kStageSyncServiceUuid)],
      )).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('startAdvertising() timeout');
      });
      _peripheralStarted    = true;
      _peripheralRetryCount = 0;
      _emitStatus('Peripheral gestartet – sichtbar als "$kStageSyncDeviceName".');
    } catch (e) {
      _peripheralStarted = false;
      _reportError(
        'Peripheral-Start fehlgeschlagen '
        '(Versuch ${_peripheralRetryCount + 1}): $e',
      );
      _schedulePeripheralRetry();
    }
  }
  void _schedulePeripheralRetry() {
    if (_stopped || _peripheralRetryCount >= kMaxPeripheralRetries) {
      if (_peripheralRetryCount >= kMaxPeripheralRetries) {
        _reportError(
          'Advertising dauerhaft fehlgeschlagen (${kMaxPeripheralRetries}x). '
          'Central-only-Modus aktiv.',
        );
      }
      return;
    }
    final delay = kPeripheralRetryBaseDelay * (1 << _peripheralRetryCount);
    _peripheralRetryCount++;
    _peripheralRetryTimer?.cancel();
    _peripheralRetryTimer = Timer(delay, _startPeripheral);
  }
  void _subscribePeripheralEvents(GATTCharacteristic char) {
    _writeReqSub?.cancel();
    _writeReqSub = _peripheral.characteristicWriteRequested.listen((args) async {
      if (args.characteristic.uuid != char.uuid) return;
      final centralUuid    = args.central.uuid.toString();
      final encryptedBytes = args.request.value;
      try { await _peripheral.respondWriteRequest(args.request); } catch (_) {}
      _peers.touchPeer(
        deviceId: centralUuid,
        deviceShortId: shortIdFromString(centralUuid),
        rssi: -70,
      );
      await _onRawBytesReceived(centralUuid, encryptedBytes);
    });
    _notifyStateSub?.cancel();
    _notifyStateSub =
        _peripheral.characteristicNotifyStateChanged.listen((args) {
      if (args.characteristic.uuid != char.uuid) return;
      final centralUuid = args.central.uuid.toString();
      if (args.state) {
        _notifySubscribers[centralUuid] = args.central;
        _emitStatus('Central $centralUuid hat NOTIFY abonniert.');
      } else {
        _notifySubscribers.remove(centralUuid);
      }
    });
  }
  // ─── Central-Rolle: Scan ──────────────────────────────────────────────────
  /// Primärer Scan: filtert nach Service-UUID (effizient, batterieschonend).
  Future<void> _startScan() async {
    if (_stopped) return;
    try {
      await _central.stopDiscovery()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    } catch (_) {}
    _isFallbackScanMode = false;
    _discoverySub?.cancel();
    _discoverySub = _central.discovered.listen(_onDeviceDiscovered);
    try {
      await _central.startDiscovery(
        serviceUUIDs: [UUID.fromString(kStageSyncServiceUuid)],
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        _reportError('UUID-gefilterter Scan: startDiscovery() Timeout.');
      });
      _isScanning = true;
      _emitStatus('UUID-gefilterter Scan gestartet.');
    } catch (e) {
      _isScanning = false;
      _reportError('UUID-gefilterter Scan fehlgeschlagen: $e');
      // Direkt auf Fallback wechseln
      _startScanNoFilter().ignore();
    }
  }

  /// Fallback-Scan ohne UUID-Filter + Dart-seitige Filterung.
  /// Nötig auf Android-Versionen die 128-bit-UUID-Filter falsch implementieren.
  Future<void> _startScanNoFilter() async {
    if (_stopped) return;
    try {
      await _central.stopDiscovery()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    } catch (_) {}
    _isFallbackScanMode = true;
    _discoverySub?.cancel();
    _discoverySub = _central.discovered.listen(_onDeviceDiscoveredUnfiltered);
    try {
      await _central.startDiscovery() // kein serviceUUIDs-Filter
          .timeout(const Duration(seconds: 10), onTimeout: () {
        _reportError('Fallback-Scan: startDiscovery() Timeout.');
      });
      _isScanning = true;
      _emitStatus(
        'Ungefilterter Fallback-Scan gestartet. '
        'Filtere nach Name "$kStageSyncDeviceName" oder Service-UUID.',
      );
    } catch (e) {
      _isScanning = false;
      _reportError('Fallback-Scan fehlgeschlagen: $e');
    }
  }
  void _scheduleScanRestart() {
    _scanRestartTimer?.cancel();
    _scanRestartTimer = Timer.periodic(
      Duration(milliseconds: kScanRestartIntervalMs),
      (_) async {
        if (_stopped) return;
        _peers.evictStale();
        if (_isFallbackScanMode) {
          await _startScanNoFilter();
        } else {
          await _startScan();
        }
      },
    );
  }
  /// Plant Wechsel auf Fallback-Scan wenn nach [kFallbackScanDelay] kein Peer
  /// gefunden wurde.
  void _scheduleFallbackScan() {
    _fallbackScanTimer?.cancel();
    _fallbackScanTimer = Timer(kFallbackScanDelay, () {
      if (_stopped || _isFallbackScanMode) return;
      if (_peers.aliveCount == 0) {
        _emitStatus(
          'Keine Peers nach ${kFallbackScanDelay.inSeconds}s. '
          'Aktiviere Fallback-Scan (kein UUID-Filter).',
        );
        _startScanNoFilter().ignore();
      }
    });
  }
  void _onDeviceDiscovered(DiscoveredEventArgs args) {
    if (_stopped) return;
    _fallbackScanTimer?.cancel(); // Peer gefunden → kein Fallback nötig
    _connectOrUpdate(args.peripheral, args.rssi);
  }
  /// Callback für ungefilterten Scan – filtert manuell nach Name oder UUID.
  void _onDeviceDiscoveredUnfiltered(DiscoveredEventArgs args) {
    if (_stopped) return;
    final name = args.advertisement.name;
    final uuids = args.advertisement.serviceUUIDs;
    final targetUuid = UUID.fromString(kStageSyncServiceUuid);
    final matchesName = name == kStageSyncDeviceName;
    // UUID-Vergleich: toString() normalisieren
    final matchesUuid = uuids.any(
      (u) => u.toString().toLowerCase() == kStageSyncServiceUuid.toLowerCase(),
    );
    // Auch prüfen mit direktem Gleichheitsvergleich
    final matchesUuidDirect = uuids.contains(targetUuid);
    if (matchesName || matchesUuid || matchesUuidDirect) {
      _connectOrUpdate(args.peripheral, args.rssi);
    }
  }
  void _connectOrUpdate(Peripheral peer, int rssi) {
    final peerUuid = peer.uuid.toString();
    _discovered[peerUuid] = peer;
    _peers.touchPeer(
      deviceId: peerUuid,
      deviceShortId: shortIdFromString(peerUuid),
      rssi: rssi,
    );
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
      final services  = await _central.discoverGATT(peer);
      final targetChar = _findStageSyncChar(services);
      if (targetChar == null) {
        _reportError(
          'Peer $peerUuid: StageSync-Char nicht gefunden nach GATT-Discovery. '
          'Trenne Verbindung.',
        );
        await _central.disconnect(peer);
        return;
      }
      _connectedChars[peerUuid] = targetChar;
      _emitStatus(
        'GATT-Verbindung zu ${_shortUuid(peerUuid)} hergestellt. '
        '(${_connectedChars.length} aktiv)',
      );
      // NOTIFY abonnieren → Mobile-Peers können uns per NOTIFY Daten senden.
      if (targetChar.properties.contains(GATTCharacteristicProperty.notify)) {
        try {
          await _central.setCharacteristicNotifyState(
            peer, targetChar, state: true,
          );
        } catch (e) {
          _reportError('NOTIFY-Subscription auf $peerUuid fehlgeschlagen: $e');
        }
      }
    } on TimeoutException {
      _reportError(
        'GATT-Verbindung zu ${_shortUuid(peerUuid)} timeout.',
      );
    } catch (e) {
      _reportError('GATT-Fehler bei ${_shortUuid(peerUuid)}: $e');
    } finally {
      _connectingSet.remove(peerUuid);
    }
  }
  GATTCharacteristic? _findStageSyncChar(List<GATTService> services) {
    final svcUuid  = UUID.fromString(kStageSyncServiceUuid);
    final charUuid = UUID.fromString(kStageSyncCharUuid);
    for (final svc in services) {
      if (svc.uuid != svcUuid) continue;
      for (final ch in svc.characteristics) {
        if (ch.uuid == charUuid) return ch;
      }
    }
    return null;
  }
  void _onPeerDisconnected(String peerUuid) {
    _connectedChars.remove(peerUuid);
    _connectingSet.remove(peerUuid);
    _emitStatus(
      'Peer ${_shortUuid(peerUuid)} getrennt '
      '(${_connectedChars.length} verbleiben).',
    );
    final peer = _discovered[peerUuid];
    if (peer != null && !_stopped) {
      Future.delayed(
        const Duration(seconds: 3),
        () => _connectToPeer(peer).ignore(),
      );
    }
  }
  // ─── Send ─────────────────────────────────────────────────────────────────
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
    // Weg 1: Als Central via GATT-Write.
    final char = _connectedChars[peerUuid];
    final peer = _discovered[peerUuid];
    if (char != null && peer != null) {
      try {
        await _central.writeCharacteristic(
          peer, char,
          value: encryptedBytes,
          type: GATTCharacteristicWriteType.withResponse,
        );
        return;
      } catch (e) {
        _reportError(
          'GATT-Write an ${_shortUuid(peerUuid)} fehlgeschlagen: $e',
        );
        _onPeerDisconnected(peerUuid);
      }
    }
    // Weg 2: Als Peripheral via NOTIFY an subscribed Central.
    final subscribedCentral = _notifySubscribers[peerUuid];
    final mutableChar       = _mutableChar;
    if (subscribedCentral != null && mutableChar != null) {
      try {
        await _peripheral.notifyCharacteristic(
          subscribedCentral, mutableChar,
          value: encryptedBytes,
        );
        return;
      } catch (e) {
        _reportError('NOTIFY an ${_shortUuid(peerUuid)} fehlgeschlagen: $e');
      }
    }
    // Keine Verbindung → Reconnect.
    if (peer != null && !_connectingSet.contains(peerUuid)) {
      _connectToPeer(peer).ignore();
    }
  }
  @override
  Future<void> broadcastToSubscribers(Uint8List alreadyEncryptedBytes) async {
    final mutableChar = _mutableChar;
    if (mutableChar == null || _notifySubscribers.isEmpty) return;
    for (final entry in List.of(_notifySubscribers.entries)) {
      try {
        await _peripheral.notifyCharacteristic(
          entry.value, mutableChar,
          value: alreadyEncryptedBytes,
        );
      } catch (e) {
        _reportError(
          'broadcastToSubscribers NOTIFY an ${_shortUuid(entry.key)} fehlgeschlagen: $e',
        );
        _notifySubscribers.remove(entry.key);
      }
    }
  }
  // ─── Receive ──────────────────────────────────────────────────────────────
  Future<void> _onRawBytesReceived(
      String senderDeviceId, Uint8List encrypted) async {
    try {
      final plainBytes = await _crypto.decrypt(encrypted);
      final packet     = parseBlePacket(plainBytes);
      _incomingController.add(
        IncomingBlePacket(senderDeviceId: senderDeviceId, packet: packet),
      );
    } on FormatException { /* malformed → verwerfen */ }
    catch (_) { /* Authentifizierungsfehler → verwerfen */ }
  }
  // ─── Diagnostik ───────────────────────────────────────────────────────────
  void _reportError(String message) {
    if (!_errorController.isClosed) _errorController.add(message);
  }
  void _emitStatus(String message) {
    if (!_errorController.isClosed) _errorController.add(message);
  }
  String _shortUuid(String uuid) =>
      uuid.length > 8 ? '...${uuid.substring(uuid.length - 8)}' : uuid;
}