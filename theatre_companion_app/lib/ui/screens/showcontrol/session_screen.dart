import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../showcontrol/discovery/mdns_discovery.dart';
import '../../../showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import '../../../showcontrol/grpc/generated/stagesync/v1/session.pb.dart';
import '../../../showcontrol/grpc/stage_sync_client.dart';
import '../../../showcontrol/nodes/audio_node/media_server.dart';
import '../../../showcontrol/providers/audio_node_provider.dart';
import '../../../showcontrol/providers/ma_node_provider.dart';
import '../../../showcontrol/providers/session_provider.dart';
import '../../../showcontrol/session/session_service.dart';
import '../../../showcontrol/ui/shell/sc_adaptive_shell.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final _hostCtrl = TextEditingController(text: '192.168.1.100');
  final _portCtrl = TextEditingController(text: '50051');
  final _sessionNameCtrl = TextEditingController(text: 'Aufführung 1');
  final _showNameCtrl = TextEditingController(text: 'Meine Show');
  final _passwordCtrl = TextEditingController();
  final _sessionIdCtrl = TextEditingController();
  final _deviceNameCtrl = TextEditingController(text: 'Mein Gerät');
  final _maHostCtrl = TextEditingController(text: '192.168.1.200');
  final _maPortCtrl = TextEditingController(text: '8000');

  final Set<NodeTask> _selectedTasks = {NodeTask.NODE_TASK_VIEWER};
  bool _isCreating = true;
  bool _isPersistent = false;
  bool _scanning = false;
  List<StageSyncServer> _discovered = [];
  List<Session> _availableSessions = [];
  Session? _selectedSession;
  bool _loadingSessions = false;
  String? _sessionLoadError;
  List<NetworkInterfaceInfo> _availableInterfaces = [];
  NetworkInterfaceInfo? _selectedInterface;

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _sessionNameCtrl.dispose();
    _showNameCtrl.dispose();
    _passwordCtrl.dispose();
    _sessionIdCtrl.dispose();
    _deviceNameCtrl.dispose();
    _maHostCtrl.dispose();
    _maPortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);

    // Bereits in Session → GO-Screen
    if (sessionState.isLoading && !sessionState.isInSession) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verbinde…', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    if (sessionState.isInSession) {
      return const ScAdaptiveShell();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('StageSync')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Server-Verbindung ────────────────────────────────────────────
            _SectionHeader('Server'),
            _ServerDiscoveryWidget(
              hostCtrl: _hostCtrl,
              portCtrl: _portCtrl,
              scanning: _scanning,
              discovered: _discovered,
              onScan: _scanForServers,
              onSelect: (server) => setState(() {
                _hostCtrl.text = server.host;
                _portCtrl.text = server.port.toString();
              }),
            ),

            const SizedBox(height: 24),

            // ── Modus ────────────────────────────────────────────────────────
            _SectionHeader('Modus'),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Session erstellen')),
                ButtonSegment(value: false, label: Text('Session beitreten')),
              ],
              selected: {_isCreating},
              onSelectionChanged: (s) => setState(() {
                _isCreating = s.first;
                _availableSessions = [];
                _selectedSession = null;
                _sessionLoadError = null;
              }),
            ),

            const SizedBox(height: 24),

            if (_isCreating) ...[
              _Field('Session-Name', _sessionNameCtrl),
              _Field('Show-Name', _showNameCtrl),
              _Field('Passwort (optional)', _passwordCtrl, obscure: true),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isPersistent,
                onChanged: (v) => setState(() => _isPersistent = v),
                title: const Text('Session dauerhaft speichern'),
                subtitle: const Text(
                    'Übersteht einen Neustart des Sync-Servers (sonst temporär).'),
              ),
            ] else ...[
              _SessionPickerWidget(
                sessions: _availableSessions,
                selected: _selectedSession,
                isLoading: _loadingSessions,
                error: _sessionLoadError,
                onRefresh: _loadSessions,
                onSelect: (s) => setState(() => _selectedSession = s),
              ),
              if (_selectedSession?.passwordProtected == true)
                _Field('Passwort', _passwordCtrl, obscure: true),
            ],

            const SizedBox(height: 24),

            // ── Gerät ────────────────────────────────────────────────────────
            _SectionHeader('Dieses Gerät'),
            _Field('Gerätename', _deviceNameCtrl),
            const SizedBox(height: 12),
            _NodeTaskSelector(
              selected: _selectedTasks,
              onChanged: (tasks) async {
                setState(() {
                  _selectedTasks.clear();
                  _selectedTasks.addAll(tasks);
                });
                if (tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT) && _availableInterfaces.isEmpty) {
                  final ifaces = await MediaServer.listInterfaces();
                  if (mounted) {
                    setState(() {
                      _availableInterfaces = ifaces;
                      _selectedInterface ??= ifaces.isNotEmpty ? ifaces.first : null;
                    });
                  }
                }
              },
            ),

            // Netzwerk-Interface (nur wenn Audio-Task gewählt)
            if (_selectedTasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT) &&
                _availableInterfaces.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Netzwerk-Interface (MediaServer)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 4),
              DropdownButtonFormField<NetworkInterfaceInfo>(
                value: _selectedInterface,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _availableInterfaces.map((iface) => DropdownMenuItem(
                  value: iface,
                  child: Text('${iface.name}  ${iface.address}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                )).toList(),
                onChanged: (iface) => setState(() => _selectedInterface = iface),
              ),
            ],

            // GrandMA-Verbindung (nur wenn MA-Task gewählt)
            if (_selectedTasks.contains(NodeTask.NODE_TASK_MA_OSC)) ...[
              const SizedBox(height: 16),
              _SectionHeader('GrandMA2/3-Konsole'),
              Row(children: [
                Expanded(flex: 3, child: _Field('IP-Adresse (MA)', _maHostCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _Field('OSC-Port', _maPortCtrl,
                    keyboardType: TextInputType.number)),
              ]),
            ],

            const SizedBox(height: 32),

            if (sessionState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  sessionState.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

            FilledButton(
              onPressed: sessionState.isLoading ||
                      (!_isCreating && _selectedSession == null)
                  ? null
                  : _submit,
              child: sessionState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isCreating ? 'Session erstellen' : 'Beitreten'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSessions() async {
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 50051;
    setState(() {
      _loadingSessions = true;
      _sessionLoadError = null;
      _availableSessions = [];
      _selectedSession = null;
    });
    try {
      await StageSyncClient.instance.connect(host, port);
      final sessions = await SessionService().listSessions();
      if (!mounted) return;
      setState(() {
        _availableSessions = sessions;
        _loadingSessions = false;
        if (sessions.length == 1) _selectedSession = sessions.first;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSessions = false;
        _sessionLoadError = 'Fehler: $e';
      });
    }
  }

  Future<void> _scanForServers() async {
    setState(() { _scanning = true; _discovered = []; });
    final found = await MdnsDiscovery.discover();
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _discovered = found;
      if (found.length == 1) {
        // Einzigen gefundenen Server direkt übernehmen
        _hostCtrl.text = found.first.host;
        _portCtrl.text = found.first.port.toString();
      }
    });
  }

  Future<void> _submit() async {
    final notifier = ref.read(sessionProvider.notifier);
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 50051;
    final tasks = _selectedTasks.toList();
    // Leite NodeType aus Tasks ab (für Server-Kompatibilität)
    final nodeType = _selectedTasks.contains(NodeTask.NODE_TASK_MASTER)
        ? NodeType.NODE_TYPE_MASTER
        : _selectedTasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)
            ? NodeType.NODE_TYPE_AUDIO
            : _selectedTasks.contains(NodeTask.NODE_TASK_MA_OSC)
                ? NodeType.NODE_TYPE_MA
                : NodeType.NODE_TYPE_VIEWER;

    if (_isCreating) {
      await notifier.createSession(
        host: host,
        port: port,
        sessionName: _sessionNameCtrl.text.trim(),
        showName: _showNameCtrl.text.trim(),
        deviceName: _deviceNameCtrl.text.trim(),
        nodeType: nodeType,
        tasks: tasks,
        password: _passwordCtrl.text,
        persistent: _isPersistent,
      );
    } else {
      final sessionId = _selectedSession?.sessionId ?? _sessionIdCtrl.text.trim();
      if (sessionId.isEmpty) return;
      await notifier.joinSession(
        host: host,
        port: port,
        sessionId: sessionId,
        deviceName: _deviceNameCtrl.text.trim(),
        nodeType: nodeType,
        tasks: tasks,
        password: _passwordCtrl.text,
      );
    }

    // Nach erfolgreichem Join: Node-Services starten
    if (!mounted) return;
    final session = ref.read(sessionProvider);
    if (!session.isInSession) return;

    if (_selectedTasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) {
      if (_selectedInterface != null) {
        await ref.read(audioNodeProvider.notifier).selectInterface(_selectedInterface!);
      }
      await ref.read(audioNodeProvider.notifier).startAudioNode();
    }
    if (_selectedTasks.contains(NodeTask.NODE_TASK_MA_OSC)) {
      final maHost = _maHostCtrl.text.trim();
      final maPort = int.tryParse(_maPortCtrl.text.trim()) ?? 8000;
      await ref.read(maNodeProvider.notifier).startMaNode(
            maHost: maHost,
            maPort: maPort,
          );
    }
  }
}

// ── Helper-Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;

  const _Field(this.label, this.controller,
      {this.keyboardType, this.obscure = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          keyboardType: keyboardType,
          obscureText: obscure,
        ),
      );
}

class _ServerDiscoveryWidget extends StatelessWidget {
  final TextEditingController hostCtrl;
  final TextEditingController portCtrl;
  final bool scanning;
  final List<StageSyncServer> discovered;
  final VoidCallback onScan;
  final ValueChanged<StageSyncServer> onSelect;

  const _ServerDiscoveryWidget({
    required this.hostCtrl,
    required this.portCtrl,
    required this.scanning,
    required this.discovered,
    required this.onScan,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: hostCtrl,
                  decoration: const InputDecoration(
                    labelText: 'IP-Adresse',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: portCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          icon: scanning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search, size: 18),
          label: Text(scanning ? 'Suche läuft…' : 'Im Netz suchen (mDNS)'),
          onPressed: scanning ? null : onScan,
        ),
        if (!scanning && discovered.isEmpty && hostCtrl.text.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Kein Server gefunden — IP manuell eingeben.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        if (discovered.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Gefundene Server:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          ...discovered.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(s.name),
                  subtitle: Text('${s.host}:${s.port}'),
                  trailing: TextButton(
                    onPressed: () => onSelect(s),
                    child: const Text('Auswählen'),
                  ),
                ),
              )),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SessionPickerWidget extends StatelessWidget {
  final List<Session> sessions;
  final Session? selected;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final ValueChanged<Session> onSelect;

  const _SessionPickerWidget({
    required this.sessions,
    required this.selected,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Verfügbare Sessions',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(isLoading ? 'Lädt…' : 'Laden'),
              onPressed: isLoading ? null : onRefresh,
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 13)),
          )
        else if (!isLoading && sessions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Keine Sessions gefunden — zuerst IP eingeben und "Laden" drücken.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          ...sessions.map((s) {
            final isSelected = selected?.sessionId == s.sessionId;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: Icon(
                  s.passwordProtected ? Icons.lock_outline : Icons.meeting_room,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
                title: Text(s.name),
                subtitle: Text(s.showName),
                trailing: isSelected
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => onSelect(s),
              ),
            );
          }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _NodeTaskSelector extends StatelessWidget {
  final Set<NodeTask> selected;
  final ValueChanged<Set<NodeTask>> onChanged;

  const _NodeTaskSelector({required this.selected, required this.onChanged});

  static const _tasks = [
    (NodeTask.NODE_TASK_VIEWER,       'Viewer',   Icons.visibility),
    (NodeTask.NODE_TASK_AUDIO_OUTPUT, 'Audio',    Icons.volume_up),
    (NodeTask.NODE_TASK_MA_OSC,       'GrandMA',  Icons.light_mode),
    (NodeTask.NODE_TASK_MASTER,       'Master',   Icons.laptop),
    (NodeTask.NODE_TASK_EDITOR,       'Editor',   Icons.edit_note),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aufgaben dieses Geräts (Mehrfachauswahl)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _tasks.map((t) {
            final (task, label, icon) = t;
            final isSelected = selected.contains(task);
            return FilterChip(
              avatar: Icon(icon, size: 16),
              label: Text(label),
              selected: isSelected,
              onSelected: (val) {
                final next = Set<NodeTask>.from(selected);
                if (val) {
                  next.add(task);
                } else {
                  next.remove(task);
                  if (next.isEmpty) next.add(NodeTask.NODE_TASK_VIEWER);
                }
                onChanged(next);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
