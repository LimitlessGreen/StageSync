import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/session_provider.dart';
import '../../../providers/embedded_server_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';

/// Zeigt Session-Einstellungen: Name, ID, Port, Netzwerk-Interfaces.
/// Erreichbar über den Header-Button "Session-Einstellungen".
class SessionSettingsPanel extends ConsumerStatefulWidget {
  const SessionSettingsPanel({super.key});

  @override
  ConsumerState<SessionSettingsPanel> createState() =>
      _SessionSettingsPanelState();
}

class _SessionSettingsPanelState extends ConsumerState<SessionSettingsPanel> {
  List<_IfaceInfo> _interfaces = [];
  bool _loadingIfaces = true;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _goLockCtrl;

  @override
  void initState() {
    super.initState();
    _loadInterfaces();
    final settings = ref.read(settingsProvider);
    _nameCtrl = TextEditingController(text: settings.sessionLocalName ?? '');
    _goLockCtrl =
        TextEditingController(text: settings.goLockDurationMs.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goLockCtrl.dispose();
    super.dispose();
  }

  void _saveName() {
    ref.read(settingsProvider.notifier)
        .setSessionLocalName(_nameCtrl.text.isEmpty ? null : _nameCtrl.text);
  }

  void _saveGoLock() {
    final ms = int.tryParse(_goLockCtrl.text);
    if (ms == null) return;
    ref.read(settingsProvider.notifier).setGoLockDurationMs(ms);
  }

  Future<void> _loadInterfaces() async {
    setState(() => _loadingIfaces = true);
    try {
      final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      final port = ref.read(embeddedPortProvider);
      setState(() {
        _interfaces = [
          for (final iface in ifaces)
            for (final addr in iface.addresses)
              _IfaceInfo(
                  name: iface.name,
                  ip: addr.address,
                  port: port,
              ),
        ];
        _loadingIfaces = false;
      });
    } catch (_) {
      setState(() => _loadingIfaces = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final s = session.session;
    final port = ref.watch(embeddedPortProvider);
    ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Toolbar ──────────────────────────────────────────────────────────
        Container(
          height: 36,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              Text('SESSION', style: ScText.panelTitle),
              const SizedBox(width: 10),
              if (session.isInSession)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: ScColors.active,
                    shape: BoxShape.circle,
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 14),
                color: ScColors.textDim,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Netzwerk-Interfaces neu laden',
                onPressed: _loadInterfaces,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Session-Info ─────────────────────────────────────────────
                _SectionHeader('INFO'),
                _EditRow(
                  label: 'Name',
                  controller: _nameCtrl,
                  hint: s?.name ?? '—',
                  onChanged: (_) => _saveName(),
                  onSave: _saveName,
                ),
                _InfoRow('Port', '$port'),
                if (s != null)
                  _CopyRow('Session-ID', s.sessionId),
                // ── Einstellungen ────────────────────────────────────────────
                const Divider(height: 1, color: ScColors.divider),
                _SectionHeader('EINSTELLUNGEN'),
                _EditRow(
                  label: 'GO-Sperre',
                  controller: _goLockCtrl,
                  hint: '1000',
                  suffix: 'ms',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _saveGoLock(),
                  onSave: _saveGoLock,
                ),
                // ── Dieses Gerät ─────────────────────────────────────────────
                if (session.myNode != null) ...[
                  const Divider(height: 1, color: ScColors.divider),
                  _SectionHeader('DIESES GERÄT'),
                  _InfoRow('Name', session.myNode!.name),
                  _InfoRow(
                    'Rollen',
                    session.myNode!.tasks.map(_taskLabel).join(' · '),
                  ),
                ],
                // ── Verbundene Geräte ─────────────────────────────────────────
                if (s != null && s.nodes.isNotEmpty) ...[
                  const Divider(height: 1, color: ScColors.divider),
                  _SectionHeader('VERBUNDENE GERÄTE (${s.nodes.length})'),
                  ...s.nodes.map((n) => _NodeRow(name: n.name, tasks: n.tasks)),
                ],
                // ── Netzwerk-Interfaces (für Freigabe) ───────────────────────
                const Divider(height: 1, color: ScColors.divider),
                _SectionHeader('NETZWERK-ADRESSEN'),
                if (_loadingIfaces)
                  const Padding(
                    padding: EdgeInsets.all(ScSpacing.panelPad),
                    child: SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: ScColors.active),
                    ),
                  )
                else if (_interfaces.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(ScSpacing.panelPad),
                    child: Text(
                      'Keine Netzwerkverbindung erkannt.',
                      style: ScText.label.copyWith(color: ScColors.textDim),
                    ),
                  )
                else
                  ..._interfaces.map((i) => _IfaceRow(iface: i)),
                const Divider(height: 1, color: ScColors.divider),
                Padding(
                  padding: const EdgeInsets.all(ScSpacing.panelPad),
                  child: Text(
                    'Andere Geräte finden diesen Server automatisch über mDNS '
                    '("Im Netz suchen" im Session-Screen).',
                    style: ScText.label.copyWith(color: ScColors.textDim),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _taskLabel(dynamic t) {
    final name = t.toString().toLowerCase();
    if (name.contains('master')) return 'Master';
    if (name.contains('audio')) return 'Audio';
    if (name.contains('editor')) return 'Editor';
    if (name.contains('ma_osc') || name.contains('ma osc')) return 'MA OSC';
    if (name.contains('viewer')) return 'Viewer';
    return name;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      alignment: Alignment.centerLeft,
      child: Text(title, style: ScText.panelTitle),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: ScText.label),
          ),
          Expanded(
            child: Text(
              value,
              style: ScText.label.copyWith(color: ScColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;
  const _CopyRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: ScText.label),
          ),
          Expanded(
            child: Text(
              value,
              style: ScText.label.copyWith(
                  color: ScColors.textPrimary, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            message: 'Kopieren',
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session-ID kopiert'),
                    duration: Duration(seconds: 2),
                    backgroundColor: ScColors.surface2,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.copy, size: 12, color: ScColors.textDim),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeRow extends StatelessWidget {
  final String name;
  final dynamic tasks;
  const _NodeRow({required this.name, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final taskLabels = (tasks as Iterable).map((t) {
      final s = t.toString().toLowerCase();
      if (s.contains('master')) return 'Master';
      if (s.contains('audio')) return 'Audio';
      if (s.contains('editor')) return 'Editor';
      if (s.contains('ma_osc') || s.contains('ma osc')) return 'MA';
      if (s.contains('viewer')) return 'Viewer';
      return s;
    }).join(' · ');
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
                color: ScColors.active, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(name,
                style: ScText.label.copyWith(color: ScColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
          Text(taskLabels,
              style: ScText.label.copyWith(color: ScColors.textDim,
                  fontSize: 10)),
        ],
      ),
    );
  }
}

class _IfaceRow extends StatelessWidget {
  final _IfaceInfo iface;
  const _IfaceRow({required this.iface});

  @override
  Widget build(BuildContext context) {
    final addr = '${iface.ip}:${iface.port}';
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          const Icon(Icons.lan_outlined, size: 12, color: ScColors.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addr,
                  style: ScText.label.copyWith(
                      color: ScColors.textPrimary, fontFamily: 'monospace'),
                ),
                Text(
                  iface.name,
                  style: ScText.statusSmall.copyWith(color: ScColors.textDim),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Adresse kopieren',
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: addr));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$addr kopiert'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: ScColors.surface2,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.copy, size: 12, color: ScColors.textDim),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? suffix;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _EditRow({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onSave,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: ScText.label),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: ScText.label.copyWith(color: ScColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: ScText.label.copyWith(color: ScColors.textDim),
                suffixText: suffix,
                suffixStyle: ScText.label.copyWith(color: ScColors.textDim),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                border: InputBorder.none,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: ScColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: ScColors.active),
                ),
              ),
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              onSubmitted: (_) => onSave(),
            ),
          ),
        ],
      ),
    );
  }
}

class _IfaceInfo {
  final String name;
  final String ip;
  final int port;
  const _IfaceInfo({required this.name, required this.ip, required this.port});
}
