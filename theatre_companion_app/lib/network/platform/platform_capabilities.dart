/// platform_capabilities.dart
/// ───────────────────────────
/// Erkennt zur Laufzeit welche Netzwerkfunktionen auf der aktuellen Plattform
/// verfügbar sind und stellt diese Informationen der UI bereit.
///
/// Plattform-Matrix:
/// ┌───────────────┬─────────┬───────┬─────────┬──────────────────────────────┐
/// │ Feature       │ Android │  iOS  │ Windows │ Web                          │
/// ├───────────────┼─────────┼───────┼─────────┼──────────────────────────────┤
/// │ BLE Central   │    ✅   │  ✅   │   ✅   │ ⚠️ Chrome/Edge only          │
/// │ BLE Peripheral│    ✅   │  ⚠️† │   ✅   │ ❌                           │
/// │ WebSocket     │    ✅   │  ✅   │   ✅   │ ✅                           │
/// │ Hintergrund   │    ✅   │  ⚠️‡ │   ✅   │ ⚠️ Web Worker                │
/// │ Persistenz    │ SQLite  │ SQLite│ SQLite  │ IndexedDB (erfordert Setup)   │
/// └───────────────┴─────────┴───────┴─────────┴──────────────────────────────┘
/// * bluetooth_low_energy v6.x: CentralManager + PeripheralManager auf allen nativen Plattformen
/// † iOS: BLE Peripheral nur im Vordergrund (CBPeripheralManager-Einschränkung)
/// ‡ iOS: Background-App-Refresh muss aktiviert sein
library platform_capabilities;

import 'package:flutter/foundation.dart';

/// Beschreibt den Unterstützungsgrad eines Features auf der aktuellen Plattform.
enum FeatureSupport {
  /// Vollständig unterstützt.
  full,

  /// Teilweise unterstützt (z.B. nur im Vordergrund, nur bestimmte Browser).
  partial,

  /// Nicht verfügbar – Graceful Degradation aktiv.
  unavailable,
}

/// Snapshot der Platformfähigkeiten zur Laufzeit.
class PlatformCapabilities {
  /// Kann das Gerät BLE-Pakete senden und empfangen?
  final FeatureSupport bleMesh;

  /// Steht eine WebSocket-Verbindung zum Server zur Verfügung?
  final FeatureSupport webSocket;

  /// Läuft der Netzwerk-Stack in einem echten Hintergrund-Isolate?
  final FeatureSupport backgroundIsolate;

  /// Ist die lokale SQLite-Datenbank verfügbar?
  final FeatureSupport localStorage;

  /// Lesbare Beschreibung der Plattform.
  final String platformName;

  /// Hinweistext für die UI (z.B. Browser-Einschränkungen).
  final String? hint;

  const PlatformCapabilities({
    required this.bleMesh,
    required this.webSocket,
    required this.backgroundIsolate,
    required this.localStorage,
    required this.platformName,
    this.hint,
  });

  // ─── Factory: erkennt die aktuelle Plattform ────────────────────────────

  factory PlatformCapabilities.detect() {
    if (kIsWeb) {
      return const PlatformCapabilities(
        platformName: 'Web Browser',
        bleMesh: FeatureSupport.partial,
        webSocket: FeatureSupport.full,
        backgroundIsolate: FeatureSupport.partial,
        localStorage: FeatureSupport.partial,
        hint: 'BLE nur in Chromium-Browsern (Chrome/Edge). '
            'iOS Safari & Firefox: WebSocket-only-Modus. '
            'Persistenz erfordert IndexedDB-Setup.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const PlatformCapabilities(
          platformName: 'Android',
          bleMesh: FeatureSupport.full,
          webSocket: FeatureSupport.full,
          backgroundIsolate: FeatureSupport.full,
          localStorage: FeatureSupport.full,
          hint: 'Android 12+: BLUETOOTH_SCAN/CONNECT/ADVERTISE-Permissions '
              'werden zur Laufzeit angefragt.',
        );

      case TargetPlatform.iOS:
        return const PlatformCapabilities(
          platformName: 'iOS',
          bleMesh: FeatureSupport.partial,
          webSocket: FeatureSupport.full,
          backgroundIsolate: FeatureSupport.full,
          localStorage: FeatureSupport.full,
          hint: 'BLE-Peripheral-Modus (Advertising) nur im Vordergrund '
              '(CBPeripheralManager-Einschränkung von Apple). '
              'Leader-Score bekommt -80 Malus wenn App im Hintergrund.',
        );

      case TargetPlatform.windows:
        return const PlatformCapabilities(
          platformName: 'Windows',
          bleMesh: FeatureSupport.partial,
          webSocket: FeatureSupport.full,
          backgroundIsolate: FeatureSupport.full,
          localStorage: FeatureSupport.full,
          hint: 'BLE-Mesh via WinRT (bluetooth_low_energy): '
              'Central-Rolle (Scan+Connect+Write) vollständig, '
              'Peripheral-Rolle (Advertising+GATT-Server) unterstützt. '
              'Advertising erfordert Windows 10 Build 16299+ und BLE-Adapter.',
        );

      case TargetPlatform.macOS:
        return const PlatformCapabilities(
          platformName: 'macOS',
          bleMesh: FeatureSupport.unavailable,
          webSocket: FeatureSupport.full,
          backgroundIsolate: FeatureSupport.full,
          localStorage: FeatureSupport.full,
          hint: 'BLE-Mesh deaktiviert auf macOS. WebSocket-only-Modus.',
        );

      case TargetPlatform.linux:
        return const PlatformCapabilities(
          platformName: 'Linux',
          bleMesh: FeatureSupport.unavailable,
          webSocket: FeatureSupport.full,
          backgroundIsolate: FeatureSupport.full,
          localStorage: FeatureSupport.full,
          hint: 'BLE-Mesh deaktiviert auf Linux. WebSocket-only-Modus.',
        );

      default:
        return const PlatformCapabilities(
          platformName: 'Unbekannte Plattform',
          bleMesh: FeatureSupport.unavailable,
          webSocket: FeatureSupport.partial,
          backgroundIsolate: FeatureSupport.unavailable,
          localStorage: FeatureSupport.unavailable,
        );
    }
  }

  // ─── Convenience-Getter ────────────────────────────────────────────────

  bool get hasBle => bleMesh != FeatureSupport.unavailable;
  bool get hasFullBle => bleMesh == FeatureSupport.full;
  bool get isWebSocketOnly => !hasBle;
}

