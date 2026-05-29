import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../showcontrol/grpc/generated/stagesync/v1/showcontrol.pb.dart';
import '../../../showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import '../../../showcontrol/media/server_media_client.dart';

/// Inspector-Panel für eine Cue — zeigt typspezifische Parameter.
/// Änderungen werden erst auf "Speichern" via [onSave] gemeldet.
class CueInspectorPanel extends StatefulWidget {
  final Cue cue;
  final ValueChanged<Cue> onSave;
  /// Alle verbundenen Nodes (für Target-Picker und Medienbrowser).
  final List<NodeInfo> connectedNodes;

  const CueInspectorPanel({
    super.key,
    required this.cue,
    required this.onSave,
    this.connectedNodes = const [],
  });

  @override
  State<CueInspectorPanel> createState() => _CueInspectorPanelState();
}

class _CueInspectorPanelState extends State<CueInspectorPanel> {
  late Cue _working;
  bool _dirty = false;

  // Gemeinsame Controller
  late TextEditingController _numberCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _targetNodeCtrl;
  late TextEditingController _preWaitCtrl;
  late TextEditingController _postWaitCtrl;

  @override
  void initState() {
    super.initState();
    _initFrom(widget.cue);
  }

  @override
  void didUpdateWidget(CueInspectorPanel old) {
    super.didUpdateWidget(old);
    if (old.cue.cueId != widget.cue.cueId) {
      _disposeControllers();
      _initFrom(widget.cue);
    }
  }

  void _initFrom(Cue cue) {
    _working = cue.deepCopy();
    _dirty = false;
    _numberCtrl = TextEditingController(text: cue.number);
    _labelCtrl = TextEditingController(text: cue.label);
    _targetNodeCtrl = TextEditingController(text: cue.targetNodeId);
    _preWaitCtrl = TextEditingController(text: cue.preWaitMs.toString());
    _postWaitCtrl = TextEditingController(text: cue.postWaitMs.toString());
  }

  void _disposeControllers() {
    _numberCtrl.dispose();
    _labelCtrl.dispose();
    _targetNodeCtrl.dispose();
    _preWaitCtrl.dispose();
    _postWaitCtrl.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _mark() => setState(() => _dirty = true);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text('Cue ${_working.number}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              _TypeBadge(type: _working.cueType),
              const Spacer(),
              if (_dirty)
                FilledButton.icon(
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Speichern'),
                  onPressed: _save,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── Formular ────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section('Allgemein', [
                  Row(children: [
                    SizedBox(
                      width: 80,
                      child: _Field('Nr.', _numberCtrl,
                          onChanged: (v) { _working.number = v; _mark(); }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field('Bezeichnung', _labelCtrl,
                          onChanged: (v) { _working.label = v; _mark(); }),
                    ),
                  ]),
                  _NodePicker(
                    currentId: _working.targetNodeId,
                    nodes: widget.connectedNodes,
                    onChanged: (id) {
                      setState(() {
                        _working.targetNodeId = id;
                        _targetNodeCtrl.text = id;
                        _dirty = true;
                      });
                    },
                  ),
                  Row(children: [
                    Expanded(child: _Field('Pre-Wait (ms)', _preWaitCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (v) { _working.preWaitMs = double.tryParse(v) ?? 0; _mark(); })),
                    const SizedBox(width: 12),
                    Expanded(child: _Field('Post-Wait (ms)', _postWaitCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (v) { _working.postWaitMs = double.tryParse(v) ?? 0; _mark(); })),
                  ]),
                  SwitchListTile(
                    title: const Text('Auto-Continue'),
                    subtitle: const Text('Nächste Cue automatisch starten'),
                    value: _working.autoContinue,
                    onChanged: (v) { setState(() { _working.autoContinue = v; _dirty = true; }); },
                  ),
                ]),
                const SizedBox(height: 16),
                // Typ-spezifische Parameter
                _buildTypeParams(widget.connectedNodes.where((n) =>
            n.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT) &&
            n.mediaServerUrl.isNotEmpty).toList()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeParams(List<NodeInfo> audioNodes) {
    return switch (_working.cueType) {
      CueType.CUE_TYPE_AUDIO => _AudioParams(
          params: _working.hasAudio() ? _working.audio : AudioCueParams(),
          onChanged: (p) { setState(() { _working.audio = p; _dirty = true; }); },
          audioNodes: audioNodes,
        ),
      CueType.CUE_TYPE_MA_OSC => _MaOscParams(
          params: _working.hasMaOsc() ? _working.maOsc : MaOscCueParams(),
          onChanged: (p) { setState(() { _working.maOsc = p; _dirty = true; }); },
        ),
      CueType.CUE_TYPE_WAIT => _WaitParams(
          params: _working.hasWait() ? _working.wait : WaitCueParams(),
          onChanged: (p) { setState(() { _working.wait = p; _dirty = true; }); },
        ),
      CueType.CUE_TYPE_GOTO => _GotoParams(
          params: _working.hasGotoP() ? _working.gotoP : GotoCueParams(),
          onChanged: (p) { setState(() { _working.gotoP = p; _dirty = true; }); },
        ),
      _ => const SizedBox.shrink(),
    };
  }

  void _save() {
    widget.onSave(_working.deepCopy());
    setState(() => _dirty = false);
  }
}

// ── Audio-Parameter ───────────────────────────────────────────────────────────

class _AudioParams extends StatefulWidget {
  final AudioCueParams params;
  final ValueChanged<AudioCueParams> onChanged;
  final List<NodeInfo> audioNodes;

  const _AudioParams({
    required this.params,
    required this.onChanged,
    required this.audioNodes,
  });

  @override
  State<_AudioParams> createState() => _AudioParamsState();
}

class _AudioParamsState extends State<_AudioParams> {
  late AudioCueParams _p;
  late TextEditingController _fileCtrl;
  late TextEditingController _fadeInCtrl;
  late TextEditingController _fadeOutCtrl;
  bool _uploading = false;
  String? _uploadStatus;

  @override
  void initState() {
    super.initState();
    _p = widget.params.deepCopy();
    _fileCtrl = TextEditingController(text: _p.filePath);
    _fadeInCtrl = TextEditingController(text: _p.fadeInMs.toString());
    _fadeOutCtrl = TextEditingController(text: _p.fadeOutMs.toString());
  }

  @override
  void dispose() {
    _fileCtrl.dispose();
    _fadeInCtrl.dispose();
    _fadeOutCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_p.deepCopy());

  @override
  Widget build(BuildContext context) {
    return _Section('Audio-Parameter', [
      // Datei-Zeile mit Upload-Status
      Row(children: [
        Expanded(child: _Field('Datei', _fileCtrl, onChanged: (v) { _p.filePath = v; _emit(); })),
        const SizedBox(width: 8),
        if (_uploading)
          const SizedBox(width: 36, height: 36,
              child: CircularProgressIndicator(strokeWidth: 2))
        else ...[
          IconButton.filled(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Lokale Datei wählen & auf alle Nodes hochladen',
            onPressed: widget.audioNodes.isEmpty ? null : _pickAndUpload,
          ),
          if (widget.audioNodes.isNotEmpty) ...[
            const SizedBox(width: 4),
            IconButton.outlined(
              icon: const Icon(Icons.cloud_download_outlined),
              tooltip: 'AudioNode-Bibliothek durchsuchen',
              onPressed: () => _openMediaBrowser(context),
            ),
          ],
        ],
      ]),
      if (_uploadStatus != null)
        Text(_uploadStatus!,
            style: TextStyle(
                fontSize: 11,
                color: _uploadStatus!.startsWith('✓')
                    ? Colors.green
                    : _uploadStatus!.startsWith('✗')
                        ? Colors.red
                        : Colors.orange)),
      if (widget.audioNodes.isEmpty)
        const Text(
          'Kein Audio-Node verbunden. Verbinde zuerst einen Node mit Audio-Task.',
          style: TextStyle(color: Colors.orange, fontSize: 11),
        ),
      _VolumeSlider(
        volumeDb: _p.volumeDb,
        onChanged: (v) { setState(() { _p.volumeDb = v; _emit(); }); },
      ),
      Row(children: [
        Expanded(child: _Field('Fade-In (ms)', _fadeInCtrl,
            keyboardType: TextInputType.number,
            onChanged: (v) { _p.fadeInMs = double.tryParse(v) ?? 0; _emit(); })),
        const SizedBox(width: 12),
        Expanded(child: _Field('Fade-Out (ms)', _fadeOutCtrl,
            keyboardType: TextInputType.number,
            onChanged: (v) { _p.fadeOutMs = double.tryParse(v) ?? 0; _emit(); })),
      ]),
      SwitchListTile(
        title: const Text('Loop'),
        value: _p.loop,
        onChanged: (v) { setState(() { _p.loop = v; _emit(); }); },
      ),
    ]);
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result == null) return;
    final file = result.files.single;
    final filename = p.basename(file.name);
    Uint8List bytes;
    if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else if (file.bytes != null) {
      // Web/memory: PlatformFile liefert Bytes direkt (kein readAsBytes())
      bytes = file.bytes!;
    } else {
      return; // Keine Bytes verfügbar (sollte nicht vorkommen)
    }

    setState(() { _uploading = true; _uploadStatus = 'Lade auf Server hoch…'; });

    // Medien liegen IMMER auf dem Sync-Server. Ein einziger Upload genügt;
    // die Audio-Nodes spiegeln die Datei selbstständig.
    final client = ServerMediaClient.fromConnection();
    if (client == null) {
      setState(() { _uploading = false; _uploadStatus = '✗ Keine Server-Verbindung'; });
      return;
    }
    try {
      await client.upload(filename, bytes);
      setState(() {
        _uploading = false;
        _uploadStatus = '✓ "$filename" auf Server hochgeladen';
        _p.filePath = filename;
        _fileCtrl.text = filename;
        _emit();
      });
    } catch (e) {
      setState(() { _uploading = false; _uploadStatus = '✗ Upload-Fehler: $e'; });
    }
  }

  Future<void> _openMediaBrowser(BuildContext context) async {
    // Medienbibliothek liegt auf dem Server. Vorhören passiert auf einem
    // Audio-Node (der die Datei gespiegelt hat) — falls einer verbunden ist.
    final previewUrl = widget.audioNodes
        .map((n) => n.mediaServerUrl)
        .firstWhere((u) => u.isNotEmpty, orElse: () => '');

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _MediaBrowserDialog(
        previewBaseUrl: previewUrl.isEmpty ? null : previewUrl,
      ),
    );
    if (selected != null) {
      setState(() {
        _p.filePath = selected;
        _fileCtrl.text = selected;
      });
      _emit();
    }
  }
}

// ── Lautstärke-Slider ─────────────────────────────────────────────────────────

class _VolumeSlider extends StatelessWidget {
  final double volumeDb;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({required this.volumeDb, required this.onChanged});

  String _label(double db) {
    if (db <= -60) return '−∞ dB';
    if (db == 0) return '0 dB';
    return '${db > 0 ? '+' : ''}${db.toStringAsFixed(1)} dB';
  }

  Color _color(double db) {
    if (db > 3) return Colors.red;
    if (db > 0) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final clamped = volumeDb.clamp(-60.0, 6.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Text('Lautstärke',
              style: TextStyle(fontSize: 13, color: Colors.black87)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _color(clamped).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _color(clamped).withValues(alpha: 0.4)),
            ),
            child: Text(
              _label(clamped),
              style: TextStyle(
                color: _color(clamped),
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Text('−∞', style: TextStyle(fontSize: 10, color: Colors.grey)),
          Expanded(
            child: Slider(
              value: clamped,
              min: -60,
              max: 6,
              divisions: 66,   // 1 dB Schritte
              onChanged: onChanged,
              activeColor: _color(clamped),
            ),
          ),
          const Text('+6', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
        // Markierungen
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('−60', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('−40', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('−20', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('0',   style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('+6',  style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── MA-OSC-Parameter ──────────────────────────────────────────────────────────

class _MaOscParams extends StatefulWidget {
  final MaOscCueParams params;
  final ValueChanged<MaOscCueParams> onChanged;

  const _MaOscParams({required this.params, required this.onChanged});

  @override
  State<_MaOscParams> createState() => _MaOscParamsState();
}

class _MaOscParamsState extends State<_MaOscParams> {
  late MaOscCueParams _p;
  late TextEditingController _addrCtrl;
  late TextEditingController _argCtrl;
  late TextEditingController _pageCtrl;
  late TextEditingController _execCtrl;

  @override
  void initState() {
    super.initState();
    _p = widget.params.deepCopy();
    _addrCtrl = TextEditingController(text: _p.oscAddress);
    _argCtrl = TextEditingController(text: _p.oscArgument);
    _pageCtrl = TextEditingController(text: _p.executorPage.toString());
    _execCtrl = TextEditingController(text: _p.executorNo.toString());
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _argCtrl.dispose();
    _pageCtrl.dispose();
    _execCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_p.deepCopy());

  @override
  Widget build(BuildContext context) {
    return _Section('GrandMA-OSC-Parameter', [
      const Text('Direkte OSC-Nachricht:', style: TextStyle(fontWeight: FontWeight.w500)),
      _Field('/gma3/cmd', _addrCtrl, onChanged: (v) { _p.oscAddress = v; _emit(); }),
      _Field('Argument (z.B. "Executor 1 Go")', _argCtrl,
          onChanged: (v) { _p.oscArgument = v; _emit(); }),
      const Divider(),
      const Text('Executor-Steuerung:', style: TextStyle(fontWeight: FontWeight.w500)),
      Row(children: [
        Expanded(child: _Field('Page', _pageCtrl,
            keyboardType: TextInputType.number,
            onChanged: (v) { _p.executorPage = int.tryParse(v) ?? 0; _emit(); })),
        const SizedBox(width: 12),
        Expanded(child: _Field('Executor', _execCtrl,
            keyboardType: TextInputType.number,
            onChanged: (v) { _p.executorNo = int.tryParse(v) ?? 0; _emit(); })),
      ]),
      DropdownButtonFormField<MaOscCueParams_MaCommand>(
        decoration: const InputDecoration(labelText: 'Befehl', border: OutlineInputBorder()),
        initialValue: _p.command,
        items: const [
          DropdownMenuItem(value: MaOscCueParams_MaCommand.MA_CMD_GO, child: Text('Go')),
          DropdownMenuItem(value: MaOscCueParams_MaCommand.MA_CMD_OFF, child: Text('Off')),
          DropdownMenuItem(value: MaOscCueParams_MaCommand.MA_CMD_PAUSE, child: Text('Pause')),
          DropdownMenuItem(value: MaOscCueParams_MaCommand.MA_CMD_GOTO, child: Text('Goto Cue')),
        ],
        onChanged: (v) { if (v != null) { setState(() { _p.command = v; _emit(); }); } },
      ),
    ]);
  }
}

// ── Wait-Parameter ────────────────────────────────────────────────────────────

class _WaitParams extends StatefulWidget {
  final WaitCueParams params;
  final ValueChanged<WaitCueParams> onChanged;

  const _WaitParams({required this.params, required this.onChanged});

  @override
  State<_WaitParams> createState() => _WaitParamsState();
}

class _WaitParamsState extends State<_WaitParams> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.params.durationMs.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Section('Warte-Parameter', [
      _Field('Dauer (ms)', _ctrl,
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final p = WaitCueParams()..durationMs = double.tryParse(v) ?? 0;
            widget.onChanged(p);
          }),
      Text('${(double.tryParse(_ctrl.text) ?? 0) / 1000} Sekunden',
          style: const TextStyle(color: Colors.grey)),
    ]);
  }
}

// ── Goto-Parameter ────────────────────────────────────────────────────────────

class _GotoParams extends StatefulWidget {
  final GotoCueParams params;
  final ValueChanged<GotoCueParams> onChanged;

  const _GotoParams({required this.params, required this.onChanged});

  @override
  State<_GotoParams> createState() => _GotoParamsState();
}

class _GotoParamsState extends State<_GotoParams> {
  late TextEditingController _numCtrl;

  @override
  void initState() {
    super.initState();
    _numCtrl = TextEditingController(text: widget.params.targetNumber);
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Section('Goto-Parameter', [
      _Field('Ziel-Cue-Nummer', _numCtrl,
          onChanged: (v) {
            final p = GotoCueParams()..targetNumber = v;
            widget.onChanged(p);
          }),
    ]);
  }
}

// ── Media Browser Dialog ──────────────────────────────────────────────────────

class _MediaBrowserDialog extends StatefulWidget {
  /// Basis-URL eines Audio-Nodes für die Vorschau (null = keine Vorschau).
  final String? previewBaseUrl;
  const _MediaBrowserDialog({this.previewBaseUrl});

  @override
  State<_MediaBrowserDialog> createState() => _MediaBrowserDialogState();
}

class _MediaBrowserDialogState extends State<_MediaBrowserDialog> {
  final ServerMediaClient? _client = ServerMediaClient.fromConnection();
  List<MediaFile> _files = [];
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String? _previewing;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final client = _client;
    if (client == null) {
      setState(() { _loading = false; _error = 'Keine Server-Verbindung'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final files = await client.list();
      setState(() { _files = files; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _uploadFile() async {
    final client = _client;
    if (client == null) return;
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result == null || result.files.single.path == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(result.files.single.path!);
      final filename = result.files.single.name;
      final bytes = await file.readAsBytes();
      await client.upload(filename, bytes);
      await _loadFiles();
    } catch (e) {
      setState(() => _error = 'Upload-Fehler: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteFile(String filename) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.delete(filename);
    } catch (e) {
      setState(() => _error = 'Löschen fehlgeschlagen: $e');
    }
    if (_previewing == filename) setState(() => _previewing = null);
    await _loadFiles();
  }

  Future<void> _preview(String filename) async {
    final base = widget.previewBaseUrl;
    if (base == null) return;
    setState(() => _previewing = filename);
    try {
      await http.get(Uri.parse(
          '$base/media/preview/${Uri.encodeComponent(filename)}'));
    } catch (e) {
      if (mounted) setState(() => _error = 'Vorhören fehlgeschlagen: $e');
    }
  }

  Future<void> _stopPreview() async {
    final base = widget.previewBaseUrl;
    if (base != null) {
      try {
        await http.delete(Uri.parse('$base/media/preview'));
      } catch (_) {}
    }
    if (mounted) setState(() => _previewing = null);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _stopPreview().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Server-Medienbibliothek')),
          if (_uploading)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Datei hochladen',
              onPressed: _uploadFile,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
            onPressed: _loadFiles,
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 440,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  Expanded(
                    child: _files.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.audio_file_outlined,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('Keine Audiodateien vorhanden',
                                    style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Erste Datei hochladen'),
                                  onPressed: _uploading ? null : _uploadFile,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _files.length,
                            itemBuilder: (ctx, i) {
                              final f = _files[i];
                              final name = f.name;
                              final size = _formatSize(f.sizeBytes);
                              final ext = name.contains('.')
                                  ? name.split('.').last.toLowerCase()
                                  : '';
                              final isPreviewing = _previewing == name;
                              return ListTile(
                                leading: Icon(
                                  isPreviewing ? Icons.volume_up : Icons.audio_file,
                                  color: isPreviewing ? Colors.green : null,
                                ),
                                title: Text(name, overflow: TextOverflow.ellipsis),
                                subtitle: Text('$size · $ext'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.previewBaseUrl != null)
                                      IconButton(
                                        icon: Icon(isPreviewing
                                            ? Icons.stop
                                            : Icons.play_arrow),
                                        tooltip: isPreviewing ? 'Stoppen' : 'Vorhören',
                                        onPressed: isPreviewing
                                            ? _stopPreview
                                            : () => _preview(name),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.check,
                                          color: Colors.green),
                                      tooltip: 'Auswählen',
                                      onPressed: () =>
                                          Navigator.of(context).pop(name),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                      tooltip: 'Löschen',
                                      onPressed: () => _confirmDelete(ctx, name),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        if (_previewing != null)
          TextButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Vorhören stoppen'),
            onPressed: _stopPreview,
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, String filename) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Datei löschen?'),
        content: Text('"$filename" wird vom Server gelöscht (alle Nodes entfernen sie beim Sync).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true) await _deleteFile(filename);
  }
}

// ── Shared Helpers ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 12),
        ...children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _Field(this.label, this.controller, {this.keyboardType, this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );
}

// ── Node-Picker ───────────────────────────────────────────────────────────────

class _NodePicker extends StatelessWidget {
  final String currentId;
  final List<NodeInfo> nodes;
  final ValueChanged<String> onChanged;

  const _NodePicker({
    required this.currentId,
    required this.nodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Wenn keine Nodes bekannt: normales Textfeld als Fallback
    if (nodes.isEmpty) {
      return TextField(
        controller: TextEditingController(text: currentId),
        decoration: const InputDecoration(
          labelText: 'Target-Node (kein Node verbunden)',
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      );
    }

    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('— Automatisch (Task-Routing) —')),
      ...nodes.map((n) => DropdownMenuItem(
            value: n.nodeId,
            child: Row(
              children: [
                Icon(_nodeIcon(n), size: 16, color: n.online ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    n.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: n.online ? null : Colors.grey),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _nodeTypeLabel(n),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          )),
    ];

    final selectedId = nodes.any((n) => n.nodeId == currentId) ? currentId : '';

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Target-Node',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          items: items,
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ),
    );
  }

  IconData _nodeIcon(NodeInfo n) {
    if (n.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) return Icons.volume_up;
    if (n.tasks.contains(NodeTask.NODE_TASK_MA_OSC)) return Icons.light_mode;
    if (n.tasks.contains(NodeTask.NODE_TASK_MASTER)) return Icons.laptop;
    return switch (n.nodeType) {
      NodeType.NODE_TYPE_AUDIO => Icons.volume_up,
      NodeType.NODE_TYPE_MA => Icons.light_mode,
      NodeType.NODE_TYPE_MASTER => Icons.laptop,
      _ => Icons.devices,
    };
  }

  String _nodeTypeLabel(NodeInfo n) {
    if (n.tasks.isNotEmpty) {
      return n.tasks
          .where((t) => t != NodeTask.NODE_TASK_UNSPECIFIED)
          .map((t) => switch (t) {
                NodeTask.NODE_TASK_AUDIO_OUTPUT => 'Audio',
                NodeTask.NODE_TASK_MA_OSC => 'MA',
                NodeTask.NODE_TASK_MASTER => 'Master',
                NodeTask.NODE_TASK_EDITOR => 'Editor',
                NodeTask.NODE_TASK_VIEWER => 'Viewer',
                _ => '',
              })
          .where((s) => s.isNotEmpty)
          .join('+');
    }
    return switch (n.nodeType) {
      NodeType.NODE_TYPE_AUDIO => 'Audio',
      NodeType.NODE_TYPE_MA => 'MA',
      NodeType.NODE_TYPE_MASTER => 'Master',
      _ => 'Viewer',
    };
  }
}

class _TypeBadge extends StatelessWidget {
  final CueType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      CueType.CUE_TYPE_AUDIO => ('AUDIO', Colors.blue),
      CueType.CUE_TYPE_MA_OSC => ('MA', Colors.orange),
      CueType.CUE_TYPE_WAIT => ('WAIT', Colors.purple),
      CueType.CUE_TYPE_GOTO => ('GOTO', Colors.teal),
      _ => ('?', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
