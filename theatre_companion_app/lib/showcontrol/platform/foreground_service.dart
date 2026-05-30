import 'dart:io';
import 'package:flutter/services.dart';

/// Steuert den Android Foreground Service und die Batterieoptimierung.
/// Auf nicht-Android-Plattformen sind alle Methoden No-ops.
class ForegroundService {
  ForegroundService._();

  static const _channel =
      MethodChannel('com.example.theatre_companion_app/foreground');

  /// Startet den Foreground Service mit sichtbarer Notification.
  /// [sessionName] und [role] erscheinen im Notification-Text.
  static Future<void> start({
    required String sessionName,
    String role = '',
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startService', {
        'sessionName': sessionName,
        'role': role,
      });
    } on PlatformException catch (_) {}
  }

  /// Stoppt den Foreground Service und entfernt die Notification.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (_) {}
  }

  /// Gibt zurück ob die App von der Batterieoptimierung ausgenommen ist.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod('isIgnoringBatteryOptimizations') as bool;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Öffnet den Android-Dialog zum Deaktivieren der Batterieoptimierung.
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } on PlatformException catch (_) {}
  }
}
