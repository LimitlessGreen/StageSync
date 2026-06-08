import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _kDeviceId = 'stagesync_device_id';
const _kConnectHost = 'stagesync_connect_host';
const _kConnectPort = 'stagesync_connect_port';
const _kDeviceName = 'stagesync_device_name';
const _kPreferredAudioDevice = 'stagesync_preferred_audio_device';
const _kAudioSetupDone = 'stagesync_audio_setup_done';

const _defaultHost = '127.0.0.1';
const _defaultPort = 50051;

/// Persistente gerätespezifische Einstellungen (SharedPreferences).
class DevicePreferences {
  static final _uuid = Uuid();

  /// Eindeutige, dauerhaft gespeicherte Geräte-ID (UUID v4).
  /// Wird beim ersten Aufruf generiert und danach nie mehr geändert.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuid.v4();
    await prefs.setString(_kDeviceId, id);
    return id;
  }

  static Future<ConnectDefaults> loadConnectDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    return ConnectDefaults(
      host: prefs.getString(_kConnectHost) ?? _defaultHost,
      port: prefs.getInt(_kConnectPort) ?? _defaultPort,
      deviceName: prefs.getString(_kDeviceName) ?? '',
    );
  }

  static Future<void> saveConnectDefaults({
    required String host,
    required int port,
    required String deviceName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kConnectHost, host);
    await prefs.setInt(_kConnectPort, port);
    await prefs.setString(_kDeviceName, deviceName);
  }

  static Future<String?> getPreferredAudioDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPreferredAudioDevice);
  }

  static Future<void> savePreferredAudioDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPreferredAudioDevice, name);
  }

  static Future<bool> isAudioSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAudioSetupDone) ?? false;
  }

  static Future<void> markAudioSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAudioSetupDone, true);
  }
}

class ConnectDefaults {
  final String host;
  final int port;
  final String deviceName;

  const ConnectDefaults({
    required this.host,
    required this.port,
    required this.deviceName,
  });
}
