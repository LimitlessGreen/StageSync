// cloud_settings_screen.dart
// ─────────────────────────────
// Einstellungsscreen für die Cloud-Verbindung zum StageSync Realtime-Server.
//
// Der Nutzer kann hier:
//   • Server-URL eingeben (automatisch oder manuell)
//   • Konto-ID und Anzeigenamen festlegen
//   • HMAC-Geheimnis des Servers eingeben
//   • Optional: Vorstellungs-ID (Show-Raum) angeben
//   • Auto-Verbindung beim Starten aktivieren
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../network/isolate/isolate_messages.dart';
import '../providers/network_state_provider.dart';
import 'qr_scan_screen.dart'; // ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences Schlüssel
// ─────────────────────────────────────────────────────────────────────────────

const _kCloudServerUrl = 'cloud_server_url';
const _kCloudUserId = 'cloud_user_id';
const _kCloudUserName = 'cloud_user_name';
const _kCloudSecret = 'cloud_secret';
const _kCloudShowId = 'cloud_show_id';
const _kCloudAutoConnect = 'cloud_auto_connect';

// ─────────────────────────────────────────────────────────────────────────────
// CloudSettingsScreen
// ─────────────────────────────────────────────────────────────────────────────

class CloudSettingsScreen extends ConsumerStatefulWidget {
  const CloudSettingsScreen({super.key});

  @override
  ConsumerState<CloudSettingsScreen> createState() =>
      _CloudSettingsScreenState();
}

class _CloudSettingsScreenState extends ConsumerState<CloudSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Textcontroller
  late final TextEditingController _urlCtrl;
  late final TextEditingController _userIdCtrl;
  late final TextEditingController _userNameCtrl;
  late final TextEditingController _secretCtrl;
  late final TextEditingController _showIdCtrl;

  bool _autoConnect = false;
  bool _secretObscured = true;
  bool _isBusy = false;
  bool _isCloudConnected = false;

  ProviderSubscription<AsyncValue<NetworkEvent>>? _eventSub;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
    _userIdCtrl = TextEditingController();
    _userNameCtrl = TextEditingController();
    _secretCtrl = TextEditingController();
    _showIdCtrl = TextEditingController();
    _loadSettings();
    _listenToEvents();
  }

  void _listenToEvents() {
    // Cloud-Verbindungsstatus aus dem Event-Stream beobachten
    _eventSub = ref.listenManual<AsyncValue<NetworkEvent>>(
      networkEventStreamProvider,
      (_, next) {
        next.whenData((event) {
          if (event is CloudConnectionChangedEvent) {
            if (mounted) {
              setState(() {
                _isCloudConnected = event.isConnected;
                _isBusy = false;
              });
            }
          }
        });
      },
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text = prefs.getString(_kCloudServerUrl) ?? '';
      _userIdCtrl.text = prefs.getString(_kCloudUserId) ?? '';
      _userNameCtrl.text = prefs.getString(_kCloudUserName) ?? '';
      _secretCtrl.text = prefs.getString(_kCloudSecret) ?? '';
      _showIdCtrl.text = prefs.getString(_kCloudShowId) ?? '';
      _autoConnect = prefs.getBool(_kCloudAutoConnect) ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCloudServerUrl, _urlCtrl.text.trim());
    await prefs.setString(_kCloudUserId, _userIdCtrl.text.trim());
    await prefs.setString(_kCloudUserName, _userNameCtrl.text.trim());
    await prefs.setString(_kCloudSecret, _secretCtrl.text.trim());
    await prefs.setString(_kCloudShowId, _showIdCtrl.text.trim());
    await prefs.setBool(_kCloudAutoConnect, _autoConnect);
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    await _saveSettings();

    setState(() => _isBusy = true);

    ref.read(networkIsolateManagerProvider).whenData((manager) {
      manager.send(CloudConnectCommand(
        serverUrl: _urlCtrl.text.trim(),
        userId: _userIdCtrl.text.trim(),
        userName: _userNameCtrl.text.trim().isNotEmpty
            ? _userNameCtrl.text.trim()
            : _userIdCtrl.text.trim(),
        secret: _secretCtrl.text.trim(),
        showId:
            _showIdCtrl.text.trim().isNotEmpty ? _showIdCtrl.text.trim() : null,
      ));
    });

    // Timeout: falls kein CloudConnectionChangedEvent kommt
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isBusy) {
        setState(() => _isBusy = false);
      }
    });
  }

  void _disconnect() {
    ref.read(networkIsolateManagerProvider).whenData((manager) {
      manager.send(CloudDisconnectCommand());
    });
    setState(() => _isCloudConnected = false);
  }

  /// Öffnet den QR-Scanner und befüllt die Felder aus dem gescannten Payload.
  ///
  /// Erwartetes JSON-Format (von dev-Server generiert):
  /// ```json
  /// { "v": 1, "url": "http://192.168.1.x:4001", "secret": "..." }
  /// ```
  /// `userId` ist optional – fehlt er, wird die persistente Geräte-UUID verwendet,
  /// damit mehrere Geräte denselben QR-Code scannen können.
  Future<void> _scanQrCode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(
          title: 'Server-QR scannen',
          hint: 'QR-Code des StageSync Dev-Servers scannen',
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final map = jsonDecode(result) as Map<String, dynamic>;
      final version = map['v'] as int? ?? 0;
      if (version < 1)
        throw FormatException('Unbekannte Payload-Version: $version');

      // URL und Secret direkt übernehmen
      if (map['url'] is String) _urlCtrl.text = map['url'] as String;
      if (map['secret'] is String) _secretCtrl.text = map['secret'] as String;
      if (map['showId'] is String) _showIdCtrl.text = map['showId'] as String;

      // userId: aus QR übernehmen – oder Geräte-UUID verwenden (mehrere Geräte!)
      if (map['userId'] is String && (map['userId'] as String).isNotEmpty) {
        _userIdCtrl.text = map['userId'] as String;
      } else if (_userIdCtrl.text.isEmpty) {
        // Geräte-eigene UUID aus SharedPreferences (wird einmal generiert + gespeichert)
        final deviceId = await ref.read(deviceIdProvider.future);
        if (mounted) _userIdCtrl.text = deviceId;
      }

      // Anzeigename: aus QR oder leer lassen
      if (map['userName'] is String)
        _userNameCtrl.text = map['userName'] as String;

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Server-Daten importiert – bereit zum Verbinden'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ungültiger QR-Code: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('QR-Code konnte nicht verarbeitet werden'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _eventSub?.close();
    _urlCtrl.dispose();
    _userIdCtrl.dispose();
    _userNameCtrl.dispose();
    _secretCtrl.dispose();
    _showIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud-Verbindung'),
        actions: [
          // QR-Scan Button in AppBar (schneller Zugriff)
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Server-QR scannen',
            onPressed: _scanQrCode,
          ),
          // Status-Chip in der AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _StatusChip(isConnected: _isCloudConnected),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Infokarte ──────────────────────────────────────────────────
            Card(
              color: colors.secondaryContainer.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: colors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Im Dev-Modus zeigt der Server beim Start automatisch '
                        'einen QR-Code im Terminal an – einfach scannen, fertig. '
                        'Mehrere Geräte können denselben Code scannen.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── QR-Code Schnelleinrichtung ─────────────────────────────────
            OutlinedButton.icon(
              onPressed: _scanQrCode,
              icon: const Icon(Icons.qr_code_scanner, size: 22),
              label: const Text('Server-QR-Code scannen'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: BorderSide(color: colors.primary),
                foregroundColor: colors.primary,
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'oder manuell eingeben',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),

            // ── Server URL ─────────────────────────────────────────────────
            Text('Server', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Server-URL',
                hintText:
                    'https://theater.example.com  oder  http://192.168.1.10:4001',
                prefixIcon: Icon(Icons.cloud_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'URL ist erforderlich';
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.hasScheme) return 'Ungültige URL';
                if (!uri.scheme.startsWith('http'))
                  return 'Nur http/https erlaubt';
                return null;
              },
            ),
            const SizedBox(height: 8),

            // ── Netzwerk-Erkennung Hinweis ─────────────────────────────────
            _NetworkScanHint(onIpSelected: (ip) {
              _urlCtrl.text = 'http://$ip:4001';
            }),

            const SizedBox(height: 20),

            // ── Konto ──────────────────────────────────────────────────────
            Text('Konto', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _userIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Konto-ID (userId)',
                hintText: 'Theater-Konto-ID vom Admin',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Konto-ID erforderlich'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _userNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Anzeigename (optional)',
                hintText: 'z. B. "Max Mustermann"',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Sicherheit ─────────────────────────────────────────────────
            Text('Authentifizierung',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _secretCtrl,
              obscureText: _secretObscured,
              decoration: InputDecoration(
                labelText: 'HMAC-Geheimnis',
                hintText: 'Vom Server-Admin (REALTIME_HANDSHAKE_SECRET)',
                prefixIcon: const Icon(Icons.key_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _secretObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _secretObscured = !_secretObscured),
                ),
              ),
              autocorrect: false,
              enableSuggestions: false,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Geheimnis erforderlich'
                  : null,
            ),
            const SizedBox(height: 20),

            // ── Vorstellung ────────────────────────────────────────────────
            Text('Vorstellung (optional)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _showIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Vorstellungs-ID',
                hintText: 'z. B. "show-2025-hamlet-01"',
                prefixIcon: Icon(Icons.theater_comedy_outlined),
                border: OutlineInputBorder(),
                helperText: 'Tritt dem show_xxx Raum auf dem Server bei',
              ),
              autocorrect: false,
            ),
            const SizedBox(height: 16),

            // ── Auto-Connect ───────────────────────────────────────────────
            SwitchListTile(
              value: _autoConnect,
              onChanged: (v) => setState(() => _autoConnect = v),
              title: const Text('Beim Start automatisch verbinden'),
              subtitle: const Text('Benötigt gespeicherte Einstellungen'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
              ),
            ),
            const SizedBox(height: 24),

            // ── Aktions-Buttons ────────────────────────────────────────────
            if (_isCloudConnected)
              FilledButton.tonalIcon(
                onPressed: _disconnect,
                icon: const Icon(Icons.cloud_off),
                label: const Text('Verbindung trennen'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.errorContainer,
                  foregroundColor: colors.onErrorContainer,
                  minimumSize: const Size(double.infinity, 48),
                ),
              )
            else
              FilledButton.icon(
                onPressed: _isBusy ? null : _connect,
                icon: _isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isBusy ? 'Verbinde…' : 'Verbinden'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Einstellungen speichern'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hilfwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isConnected;
  const _StatusChip({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        isConnected ? Icons.cloud_done : Icons.cloud_off,
        size: 16,
        color: isConnected ? Colors.green : Colors.grey,
      ),
      label: Text(
        isConnected ? 'Verbunden' : 'Getrennt',
        style: const TextStyle(fontSize: 12),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Scannt das lokale Netzwerk nach StageSync-Server-IPs (simple Ping auf Port 4001).
class _NetworkScanHint extends StatefulWidget {
  final void Function(String ip) onIpSelected;
  const _NetworkScanHint({required this.onIpSelected});

  @override
  State<_NetworkScanHint> createState() => _NetworkScanHintState();
}

class _NetworkScanHintState extends State<_NetworkScanHint> {
  bool _scanning = false;
  List<String> _found = [];

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _found = [];
    });

    // Einfacher Scan: testet typische lokale IPs auf Port 4001
    // Ermittelt das Subnetz aus der Loopback-Annahme (192.168.1.x)
    // Eine robustere Variante würde multicast-DNS (mDNS) nutzen.
    final candidates = <String>[];
    for (final subnet in ['192.168.1', '192.168.0', '10.0.0', '10.0.1']) {
      for (final host in [1, 100, 101, 102, 110, 200, 254]) {
        candidates.add('$subnet.$host');
      }
    }

    final futures = candidates.map((ip) => _checkPort(ip, 4001));
    final results = await Future.wait(futures);

    final found = <String>[];
    for (var i = 0; i < candidates.length; i++) {
      if (results[i]) found.add(candidates[i]);
    }

    if (mounted) {
      setState(() {
        _scanning = false;
        _found = found;
      });
    }
  }

  Future<bool> _checkPort(String host, int port) async {
    try {
      // Schneller TCP-Verbindungsversuch via dart:io Socket
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 300),
      );
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: _scanning ? null : _scan,
              icon: _scanning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search, size: 16),
              label: Text(
                _scanning ? 'Suche…' : 'Im Netzwerk suchen',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        if (_found.isNotEmpty)
          Wrap(
            spacing: 8,
            children: _found.map((ip) {
              return ActionChip(
                label: Text(ip),
                avatar: const Icon(Icons.router, size: 14),
                onPressed: () => widget.onIpSelected(ip),
              );
            }).toList(),
          ),
        if (!_scanning && _found.isEmpty && _scanning == false)
          const SizedBox.shrink(),
      ],
    );
  }
}
