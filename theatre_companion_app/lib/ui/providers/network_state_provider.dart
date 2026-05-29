/// network_state_provider.dart
/// ─────────────────────────────
/// Riverpod providers that expose the [NetworkIsolateManager] and its event
/// stream to the entire widget tree.
///
/// ## How to use from a widget
///
/// ```dart
/// // Read the live network status:
/// final status = ref.watch(networkStatusProvider);
///
/// // Watch all item updates:
/// ref.listen(itemUpdatedProvider, (prev, next) { … });
///
/// // Send a command (e.g. from a scan button):
/// ref.read(networkIsolateManagerProvider.notifier).send(
///   ScanItemCommand(itemId: id, statusId: 1, timestampMs: now),
/// );
/// ```
library network_state_provider;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../network/isolate/isolate_messages.dart';
import '../../network/isolate/network_isolate_manager.dart';
import '../../network/network_facade.dart';
import '../../network/platform/permission_service.dart';
import '../../network/platform/platform_capabilities.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1.  Device ID provider
//     Einmalig generierte UUID, die in SharedPreferences gespeichert wird.
//     Alle Geräte im Mesh benötigen eine eindeutige ID – der frühere Hardcode
//     ('device-0000-default') ließ alle Geräte identisch aussehen und brach
//     die gesamte Leader-Election und CRDT-Logik.
// ─────────────────────────────────────────────────────────────────────────────

const _kDeviceIdKey = 'stagesync_device_id';

/// Persistent unique device identifier.
/// Wird beim ersten Start generiert (UUIDv4) und dauerhaft gespeichert.
final deviceIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString(_kDeviceIdKey);
  if (id == null || id.isEmpty) {
    id = const Uuid().v4();
    await prefs.setString(_kDeviceIdKey, id);
  }
  return id;
});

// ─────────────────────────────────────────────────────────────────────────────
// 2.  Permission provider  (nur lesend – für UI-Feedback nach dem Start)
// ─────────────────────────────────────────────────────────────────────────────

/// Das Ergebnis des Permission-Requests beim letzten App-Start.
/// Die UI kann diesen Provider beobachten, um eine Erklärung anzuzeigen, falls
/// Berechtigungen fehlen.
final permissionResultProvider = FutureProvider<PermissionResult>((ref) async {
  // Berechtigungen einmalig anfordern. Wird vor dem Netzwerk-Isolate-Start
  // aufgerufen, weil permission_handler den Main-Isolate benötigt.
  return PermissionService.requestAll();
});

// ─────────────────────────────────────────────────────────────────────────────
// 3.  NetworkIsolateManager  (async – initialisiert Background-Isolate)
//     Wartet zuerst auf deviceId + Permissions, dann erst auf Isolate-Start.
// ─────────────────────────────────────────────────────────────────────────────

const _kCloudServerUrl = 'cloud_server_url';
const _kCloudUserId = 'cloud_user_id';
const _kCloudUserName = 'cloud_user_name';
const _kCloudSecret = 'cloud_secret';
const _kCloudShowId = 'cloud_show_id';
const _kCloudAutoConnect = 'cloud_auto_connect';

final networkIsolateManagerProvider =
    FutureProvider<NetworkIsolateManager>((ref) async {
  // ── Schritt 1: Gerätespezifische UUID ────────────────────────────────────
  final deviceId = await ref.watch(deviceIdProvider.future);

  // ── Schritt 2: Laufzeit-Berechtigungen anfragen ──────────────────────────
  // Muss vom Main-Isolate BEVOR der Netzwerk-Isolate startet erfolgen.
  // Bei verweigerten BLE-Permissions läuft die App im WebSocket-only-Modus
  // (BleMeshService → StubBleService-Fallback via PlatformCapabilities).
  final permissions = await ref.watch(permissionResultProvider.future);

  // Das Ergebnis wird auch im permissionResultProvider gecacht; hier nur
  // für die Log-Ausgabe / Debugging verwendet.
  assert(() {
    if (!permissions.bleMeshGranted) {
      // ignore: avoid_print
      print('[StageSync] BLE-Berechtigungen nicht gewährt: '
          '${permissions.deniedPermissionNames}. '
          'App läuft im WebSocket-only-Modus.');
    }
    return true;
  }());

  // ── Schritt 3: Netzwerk-Isolate starten ──────────────────────────────────
  final manager = NetworkIsolateManager();
  await manager.init(deviceId: deviceId);

  // ── Schritt 4: Auto-Connect Cloud (falls aktiviert) ───────────────────────
  final prefs = await SharedPreferences.getInstance();
  final autoConnect = prefs.getBool(_kCloudAutoConnect) ?? false;
  if (autoConnect) {
    final serverUrl = prefs.getString(_kCloudServerUrl) ?? '';
    final userId = prefs.getString(_kCloudUserId) ?? '';
    final secret = prefs.getString(_kCloudSecret) ?? '';
    if (serverUrl.isNotEmpty && userId.isNotEmpty && secret.isNotEmpty) {
      // Kurze Verzögerung damit der Isolate vollständig gestartet ist
      Future.delayed(const Duration(seconds: 2), () {
        manager.send(CloudConnectCommand(
          serverUrl: serverUrl,
          userId: userId,
          userName: prefs.getString(_kCloudUserName) ?? userId,
          secret: secret,
          showId: prefs.getString(_kCloudShowId),
        ));
      });
    }
  }

  // Graceful Teardown wenn ProviderScope zerstört wird (z.B. App-Lifecycle).
  ref.onDispose(manager.dispose);

  return manager;
});

// ─────────────────────────────────────────────────────────────────────────────
// 4.  Raw event stream from the network isolate
// ─────────────────────────────────────────────────────────────────────────────

final networkEventStreamProvider = StreamProvider<NetworkEvent>((ref) async* {
  // Wait for the manager to be initialised.
  final managerAsync = await ref.watch(
    networkIsolateManagerProvider.future,
  );
  yield* managerAsync.events;
});

// ─────────────────────────────────────────────────────────────────────────────
// 5.  Derived providers for specific event types
// ─────────────────────────────────────────────────────────────────────────────

/// Latest [NetworkStatusEvent] – updated roughly every 5 seconds.
/// The UI can use this to show peer count, sync status, and leader badge.
final networkStatusProvider = Provider<NetworkStatusEvent?>((ref) {
  final stream = ref.watch(networkEventStreamProvider);
  return stream.whenData((event) {
    if (event is NetworkStatusEvent) return event;
    return null;
  }).value;
});

/// Latest [LeaderChangedEvent].
final leaderChangedProvider = Provider<LeaderChangedEvent?>((ref) {
  final stream = ref.watch(networkEventStreamProvider);
  return stream.whenData((event) {
    if (event is LeaderChangedEvent) return event;
    return null;
  }).value;
});

/// Stream of [ItemUpdatedEvent]s for live inventory updates.
final itemUpdateStreamProvider = StreamProvider<ItemUpdatedEvent>((ref) {
  final ctrl = StreamController<ItemUpdatedEvent>.broadcast();
  final sub = ref.listen<AsyncValue<NetworkEvent>>(
    networkEventStreamProvider,
    (_, next) => next.whenData((e) {
      if (e is ItemUpdatedEvent) ctrl.add(e);
    }),
  );
  ref.onDispose(() {
    sub.close();
    ctrl.close();
  });
  return ctrl.stream;
});

/// Stream of [ChatMessageReceivedEvent]s for the chat screen.
final chatEventStreamProvider =
    StreamProvider<ChatMessageReceivedEvent>((ref) {
  final ctrl = StreamController<ChatMessageReceivedEvent>.broadcast();
  final sub = ref.listen<AsyncValue<NetworkEvent>>(
    networkEventStreamProvider,
    (_, next) => next.whenData((e) {
      if (e is ChatMessageReceivedEvent) ctrl.add(e);
    }),
  );
  ref.onDispose(() {
    sub.close();
    ctrl.close();
  });
  return ctrl.stream;
});

/// Derived live peer list from the latest [NetworkStatusEvent].
final peerListProvider = Provider<List<PeerStatusInfo>>((ref) {
  return ref.watch(networkStatusProvider)?.peers ?? const [];
});

/// Erkennt die Plattform-Fähigkeiten einmalig beim App-Start.
final platformCapabilitiesProvider = Provider<PlatformCapabilities>((ref) {
  return PlatformCapabilities.detect();
});

/// Convenience: Is BLE available on the current platform?
final hasBleProvider = Provider<bool>((ref) {
  return ref.watch(platformCapabilitiesProvider).hasBle;
});

/// Latest score breakdown from the latest [NetworkStatusEvent].
final scoreBreakdownProvider = Provider<NetworkScoreBreakdown>((ref) {
  return ref.watch(networkStatusProvider)?.scoreBreakdown ??
      NetworkScoreBreakdown.zero;
});

/// Convenience derived state: has the network isolate been initialised?
final isNetworkReadyProvider = Provider<bool>((ref) {
  return ref.watch(networkIsolateManagerProvider).hasValue;
});

/// True, wenn dieses Gerät aktuell der Leader ist.
final isLeaderProvider = Provider<bool>((ref) {
  return ref.watch(leaderChangedProvider)?.isThisDeviceLeader ?? false;
});

// ─────────────────────────────────────────────────────────────────────────────
// Cloud-Verbindungsstatus (akkumulierend – nicht resetted bei anderen Events)
// ─────────────────────────────────────────────────────────────────────────────

/// Hält den aktuellen Cloud-Verbindungsstatus dauerhaft (kein Reset bei anderen Events).
class _CloudConnectionNotifier extends StateNotifier<bool> {
  _CloudConnectionNotifier(Ref ref) : super(false) {
    ref.listen<AsyncValue<NetworkEvent>>(
      networkEventStreamProvider,
      (_, next) {
        next.whenData((event) {
          if (event is CloudConnectionChangedEvent) {
            state = event.isConnected;
          }
        });
      },
    );
  }
}

/// True, wenn aktuell eine Cloud-Verbindung (Socket.IO Realtime-Server) besteht.
final isCloudConnectedProvider =
    StateNotifierProvider<_CloudConnectionNotifier, bool>((ref) {
  return _CloudConnectionNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// Cloud-Peer-Liste (Companion-App-Geräte auf dem Server)
// ─────────────────────────────────────────────────────────────────────────────

class _CloudPeersNotifier
    extends StateNotifier<(List<CloudPeerInfo>, int)> {
  _CloudPeersNotifier(Ref ref) : super((const [], 0)) {
    ref.listen<AsyncValue<NetworkEvent>>(
      networkEventStreamProvider,
      (_, next) {
        next.whenData((event) {
          if (event is CloudPeersUpdatedEvent) {
            state = (event.peers, event.totalOnline);
          }
        });
      },
    );
  }
}

final _cloudPeersNotifierProvider =
    StateNotifierProvider<_CloudPeersNotifier, (List<CloudPeerInfo>, int)>(
        (ref) => _CloudPeersNotifier(ref));

/// Aktuell sichtbare Cloud-Peers (andere StageSync-Geräte im Companion-Raum).
final cloudPeersProvider = Provider<List<CloudPeerInfo>>((ref) {
  return ref.watch(_cloudPeersNotifierProvider).$1;
});

/// Gesamtzahl verbundener Sockets auf dem Cloud-Server (inkl. Web-Clients).
final cloudTotalOnlineProvider = Provider<int>((ref) {
  return ref.watch(_cloudPeersNotifierProvider).$2;
});

// ─────────────────────────────────────────────────────────────────────────────
// NetworkFacade  (High-Level API für die UI)
// ─────────────────────────────────────────────────────────────────────────────

/// Gibt Zugriff auf [NetworkFacade] – die hochsprachliche API des Netzwerk-Stacks.
///
/// Die App sollte bevorzugt diese Facade nutzen statt direkt
/// [networkIsolateManagerProvider] + `send(ScanItemCommand(...))` zu verwenden.
///
/// ```dart
/// // Scan:
/// ref.read(networkFacadeProvider)?.scanItem(itemId: id, statusId: 1);
///
/// // Großer Transfer:
/// ref.read(networkFacadeProvider)?.announceTransfer(estimatedBytes: pdf.length);
/// ```
///
/// Null solange der Stack noch nicht initialisiert ist.
final networkFacadeProvider = Provider<NetworkFacade?>((ref) {
  final managerValue = ref.watch(networkIsolateManagerProvider);
  return managerValue.valueOrNull != null
      ? NetworkFacade(managerValue.value!)
      : null;
});

// ─────────────────────────────────────────────────────────────────────────────
// BLE-Status (Diagnose)
// ─────────────────────────────────────────────────────────────────────────────

/// Akkumuliert den letzten [BleStatusEvent] (BLE-Layer-Diagnose).
/// Zeigt z.B. ob Advertising läuft, ob Fallback-Scan aktiv ist, oder
/// ob ein BLE-Fehler aufgetreten ist.
class _BleStatusNotifier extends StateNotifier<BleStatusEvent?> {
  _BleStatusNotifier(Ref ref) : super(null) {
    ref.listen<AsyncValue<NetworkEvent>>(
      networkEventStreamProvider,
      (_, next) {
        next.whenData((event) {
          if (event is BleStatusEvent) state = event;
        });
      },
    );
  }
}

final bleStatusProvider =
    StateNotifierProvider<_BleStatusNotifier, BleStatusEvent?>((ref) {
  return _BleStatusNotifier(ref);
});

/// Convenience: Permission-Warnung für die UI.
/// Nur relevant wenn BLE-Permissions verweigert wurden.
final permissionWarningProvider = Provider<String?>((ref) {
  final result = ref.watch(permissionResultProvider);
  return result.when(
    loading: () => null,
    error: (_, __) => 'Berechtigungsprüfung fehlgeschlagen',
    data: (r) => r.bleMeshGranted
        ? null
        : 'BLE-Berechtigungen fehlen: ${r.deniedPermissionNames.join(', ')}. '
            '${r.isPermanentlyDenied ? 'Bitte in den App-Einstellungen aktivieren.' : ''}',
  );
});

/// Stream aller BLE-Status-Meldungen (für BLE Debug Screen Raw-Log).
/// Schließt ALLE BleStatusEvent-Nachrichten ein, nicht nur Fehler.
final bleRawLogStreamProvider = StreamProvider<BleStatusEvent>((ref) {
  final ctrl = StreamController<BleStatusEvent>.broadcast();
  final sub = ref.listen<AsyncValue<NetworkEvent>>(
    networkEventStreamProvider,
    (_, next) => next.whenData((e) {
      if (e is BleStatusEvent) ctrl.add(e);
    }),
  );
  ref.onDispose(() {
    sub.close();
    ctrl.close();
  });
  return ctrl.stream;
});








