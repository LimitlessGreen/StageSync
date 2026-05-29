/// permission_service.dart
/// ────────────────────────
/// Zentrales Laufzeit-Permission-Management für StageSync.
///
/// Muss **vor** dem Start des Netzwerk-Isolates aufgerufen werden, da Plattform-
/// kanäle (permission_handler) nur vom Main-Isolate aus nutzbar sind.
///
/// ## Platform-Matrix
///
/// ┌──────────────────────────────────┬─────────────────────────────────────────────────────────┐
/// │ Benötigte Berechtigung           │ Plattform / Bedingung                                   │
/// ├──────────────────────────────────┼─────────────────────────────────────────────────────────┤
/// │ BLUETOOTH_SCAN                   │ Android 12+ (API ≥ 31)                                  │
/// │ BLUETOOTH_CONNECT                │ Android 12+ (API ≥ 31)                                  │
/// │ BLUETOOTH_ADVERTISE              │ Android 12+ (API ≥ 31)                                  │
/// │ ACCESS_FINE_LOCATION             │ Android 6–11 (API 23–30) – BLE-Scan benötigt Standort  │
/// │ NSBluetoothAlwaysUsageDescription│ iOS – nur PLIST-Key, kein Runtime-Dialog nötig          │
/// │ NSMotionUsageDescription         │ iOS – nur PLIST-Key, sensor_plus löst Dialog aus        │
/// └──────────────────────────────────┴─────────────────────────────────────────────────────────┘
///
/// ## Aufrufebene
/// ```dart
/// // In network_state_provider.dart, bevor der Isolate startet:
/// final result = await PermissionService.requestAll();
/// if (!result.bleMeshGranted) {
///   // Zeige dem User eine Erklärung und ggf. Settings-Link
/// }
/// ```
library permission_service;

import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ergebnis-Objekt
// ─────────────────────────────────────────────────────────────────────────────

/// Zusammenfassung des Permission-Ergebnisses nach [PermissionService.requestAll].
class PermissionResult {
  /// Sind alle benötigten BLE-Berechtigungen gewährt?
  /// Wenn false, kann BleMeshService NICHT gestartet werden.
  final bool bleMeshGranted;

  /// Ist die Standort-Berechtigung gewährt (nur relevant auf Android ≤ 11)?
  final bool locationGranted;

  /// Wurde eine Berechtigung permanent verweigert?
  /// In diesem Fall muss [openAppSettings] aufgerufen werden.
  final bool isPermanentlyDenied;

  /// Liste der verweigerten Berechtigungen (für Debug-/UI-Ausgabe).
  final List<String> deniedPermissionNames;

  const PermissionResult({
    required this.bleMeshGranted,
    required this.locationGranted,
    required this.isPermanentlyDenied,
    required this.deniedPermissionNames,
  });

  /// BLE ist vollständig nutzbar.
  bool get isFullyGranted => bleMeshGranted;

  /// Öffnet die App-Einstellungen (wenn Berechtigung permanent verweigert).
  Future<bool> openSettings() => openAppSettings();

  @override
  String toString() =>
      'PermissionResult(ble=$bleMeshGranted, loc=$locationGranted, '
      'denied=$deniedPermissionNames)';
}

// ─────────────────────────────────────────────────────────────────────────────
// PermissionService
// ─────────────────────────────────────────────────────────────────────────────

class PermissionService {
  // Privater Konstruktor – nur statische Methoden.
  PermissionService._();

  // ─── Hauptfunktion ────────────────────────────────────────────────────────

  /// Prüft und fordert alle für StageSync benötigten Berechtigungen an.
  ///
  /// Rufe diese Methode **einmal** beim App-Start vom Main-Isolate aus auf,
  /// bevor [NetworkIsolateManager.init()] aufgerufen wird.
  ///
  /// Auf Plattformen ohne BLE-Support (Windows, Web, macOS, Linux) gibt diese
  /// Methode sofort ein voll-gewährtes Ergebnis zurück, da kein BLE verwendet
  /// wird.
  static Future<PermissionResult> requestAll() async {
    // ── Plattformen ohne BLE geben sofort "granted" zurück ─────────────────
    if (kIsWeb) {
      return const PermissionResult(
        bleMeshGranted: true, // Web läuft ohne BLE-Adapter (Stub)
        locationGranted: true,
        isPermanentlyDenied: false,
        deniedPermissionNames: [],
      );
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      // Windows / macOS / Linux: StubBleService, keine Berechtigungen nötig.
      return const PermissionResult(
        bleMeshGranted: true,
        locationGranted: true,
        isPermanentlyDenied: false,
        deniedPermissionNames: [],
      );
    }

    if (Platform.isIOS) {
      return await _requestIos();
    }

    // Platform.isAndroid
    return await _requestAndroid();
  }

  // ─── Android ──────────────────────────────────────────────────────────────

  /// Anfragen für Android:
  ///   • API ≥ 31 (Android 12+): BLUETOOTH_SCAN | BLUETOOTH_CONNECT | BLUETOOTH_ADVERTISE
  ///     → Kein Standort nötig (BLUETOOTH_SCAN hat neverForLocation-Flag)
  ///   • API ≤ 30 (Android ≤ 11): ACCESS_FINE_LOCATION (BLE-Scan ohne neue BT-APIs)
  ///
  /// [permission_handler] erkennt die API-Version intern und gibt auf alten Geräten
  /// für BLUETOOTH_SCAN / CONNECT / ADVERTISE automatisch "granted" zurück (diese
  /// Berechtigungen existieren auf API < 31 nicht als Runtime-Permissions).
  static Future<PermissionResult> _requestAndroid() async {
    final denied = <String>[];
    bool anyPermanentlyDenied = false;

    // ── Android SDK-Version ermitteln ────────────────────────────────────────
    // Wichtig für die korrekte Permission-Logik:
    //   • API ≥ 31 (Android 12+): BLUETOOTH_SCAN hat neverForLocation → kein Standort nötig
    //   • API ≤ 30 (Android ≤ 11): kein BLUETOOTH_SCAN → ACCESS_FINE_LOCATION benötigt
    int sdkInt = 31; // konservativer Fallback: moderne API annehmen
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      sdkInt = info.version.sdkInt;
    } catch (_) {
      // DeviceInfo nicht verfügbar → Fallback
    }
    final isAndroid12Plus = sdkInt >= 31;

    // ── Schritt 1: Neue BT-Berechtigungen (Android 12+) ─────────────────────
    // Auf Android ≤ 11 gibt permission_handler für diese Permissions automatisch
    // `PermissionStatus.granted` zurück (werden über Declare-only-Manifest gewährt).
    final blePermissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ];
    final bleResults = await blePermissions.request();

    for (final entry in bleResults.entries) {
      if (!entry.value.isGranted) {
        denied.add(_permissionName(entry.key));
        if (entry.value.isPermanentlyDenied) anyPermanentlyDenied = true;
      }
    }

    // ── Schritt 2: Standort-Berechtigung (NUR Android ≤ 11 / API ≤ 30) ──────
    // Auf Android 12+ mit neverForLocation-Flag NICHT benötigt – niemals anfordern.
    // Das Anfordern würde auf Pixel 9 / Android 16 fälschlicherweise als fehlend
    // gezählt und das BLE-Mesh blockieren, obwohl es gar nicht nötig ist.
    bool locationGranted = true;
    if (!isAndroid12Plus) {
      final locStatus = await Permission.location.status;
      if (!locStatus.isGranted) {
        final locResult = await Permission.location.request();
        locationGranted = locResult.isGranted;
        if (!locationGranted) {
          denied.add('Standort (für BLE-Scan auf Android ≤11)');
          if (locResult.isPermanentlyDenied) anyPermanentlyDenied = true;
        }
      }
    }
    // Auf Android 12+ gilt locationGranted = true (nicht benötigt)

    // BLE ist vollständig nutzbar, wenn:
    //   • Android 12+: alle drei BT-Permissions granted (Location irrelevant)
    //   • Android ≤11: BT-Permissions granted UND Location granted
    final bleGranted = bleResults.values.every((s) => s.isGranted) &&
        (isAndroid12Plus || locationGranted);

    return PermissionResult(
      bleMeshGranted: bleGranted,
      locationGranted: locationGranted,
      isPermanentlyDenied: anyPermanentlyDenied,
      deniedPermissionNames: denied,
    );
  }

  // ─── iOS ──────────────────────────────────────────────────────────────────

  /// Auf iOS wird Bluetooth von CoreBluetooth automatisch angefragt, sobald
  /// der GATT-Scanner startet (Flutter Reactive BLE initialisiert CBCentralManager).
  ///
  /// Voraussetzung: `NSBluetoothAlwaysUsageDescription` muss in Info.plist
  /// eingetragen sein (sonst crasht die App beim ersten BLE-Zugriff).
  ///
  /// sensors_plus benötigt auf iOS keine explizite Runtime-Permission, aber
  /// `NSMotionUsageDescription` muss ebenfalls in Info.plist vorhanden sein,
  /// damit der System-Dialog korrekt erscheint.
  ///
  /// Diese Methode prüft den aktuellen Bluetooth-Status und gibt Feedback,
  /// damit die UI eine erklärende Meldung zeigen kann.
  static Future<PermissionResult> _requestIos() async {
    final denied = <String>[];
    bool anyPermanentlyDenied = false;

    // Bluetooth-Status prüfen (der Dialog wird von CoreBluetooth ausgelöst, nicht
    // von uns – wir können hier nur den Status abfragen).
    final bleStatus = await Permission.bluetooth.status;

    if (bleStatus.isDenied) {
      // Einmalige Anfrage auslösen; der iOS-Dialog erscheint beim nächsten
      // CBCentralManager-Zugriff automatisch.
      final result = await Permission.bluetooth.request();
      if (!result.isGranted) {
        denied.add('Bluetooth (Core Bluetooth)');
        if (result.isPermanentlyDenied) anyPermanentlyDenied = true;
      }
    } else if (bleStatus.isPermanentlyDenied) {
      denied.add('Bluetooth (permanent verweigert – Einstellungen öffnen)');
      anyPermanentlyDenied = true;
    }

    final bleGranted =
        denied.isEmpty || await Permission.bluetooth.status.then((s) => s.isGranted);

    return PermissionResult(
      bleMeshGranted: bleGranted,
      locationGranted: true, // iOS-BLE benötigt keine Standort-Berechtigung
      isPermanentlyDenied: anyPermanentlyDenied,
      deniedPermissionNames: denied,
    );
  }

  // ─── Hilfsfunktionen ──────────────────────────────────────────────────────

  /// Lesbare Bezeichnung für eine Permission (für Fehlermeldungen).
  static String _permissionName(Permission p) {
    if (p == Permission.bluetoothScan) return 'Bluetooth Scan';
    if (p == Permission.bluetoothConnect) return 'Bluetooth Connect';
    if (p == Permission.bluetoothAdvertise) return 'Bluetooth Advertise';
    if (p == Permission.location) return 'Standort';
    if (p == Permission.bluetooth) return 'Bluetooth';
    return p.toString();
  }

  // ─── Einzelne Checks für die UI ──────────────────────────────────────────

  /// Prüft ohne Dialog, ob alle BLE-Berechtigungen momentan gewährt sind.
  /// Kann synchron in UI-Buildern als Guard verwendet werden.
  static Future<bool> areBlePermissionsGranted() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;

    if (Platform.isAndroid) {
      // SDK-Version prüfen: auf API 31+ kein Location nötig
      int sdkInt = 31;
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        sdkInt = info.version.sdkInt;
      } catch (_) {}
      final isAndroid12Plus = sdkInt >= 31;

      final permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        if (!isAndroid12Plus) Permission.location,
      ];
      final statuses = await permissions.request();
      return statuses.values.every((s) => s.isGranted);
    }

    // iOS
    return await Permission.bluetooth.status.then((s) => s.isGranted);
  }
}

