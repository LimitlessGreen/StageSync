import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import '../../../showcontrol/grpc/generated/stagesync/v1/showcontrol.pb.dart';
import '../../../showcontrol/providers/session_provider.dart';
import '../../../showcontrol/providers/show_control_provider.dart';
import 'cue_inspector_panel.dart';

/// Desktop-CueList-Editor: Linke Spalte = Cue-Liste, Rechte Spalte = Inspector.
class CueListEditorScreen extends ConsumerStatefulWidget {
  const CueListEditorScreen({super.key});

  @override
  ConsumerState<CueListEditorScreen> createState() => _CueListEditorScreenState();
}

class _CueListEditorScreenState extends ConsumerState<CueListEditorScreen> {
  String? _selectedCueId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showControlProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final show = ref.watch(showControlProvider);
    final session = ref.watch(sessionProvider);
    final connectedNodes = session.session?.nodes.toList() ?? <NodeInfo>[];
    final audioNodes = connectedNodes.where((n) =>
        n.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT) &&
        n.mediaServerUrl.isNotEmpty).toList();
    final cues = List<Cue>.from(show.cueList?.cues ?? []);
    final selected = _selectedCue(cues);

    return Scaffold(
      appBar: AppBar(
        title: Text(show.cueList?.name ?? 'CueList-Editor'),
        actions: [
          if (audioNodes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cloud_sync),
              tooltip: 'Show Deploy — Dateien auf alle Nodes',
              onPressed: () => _showDeployDialog(context, cues, audioNodes),
            ),
          // ── GO / STOP ───────────────────────────────────────────────────
          _GoStopBar(),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // ── Linke Spalte: Cue-Liste ──────────────────────────────────────
          SizedBox(
            width: 380,
            child: Column(
              children: [
                _CueListToolbar(onAddCue: () => _showAddCueDialog(context, cues.length)),
                Expanded(
                  child: _CueListView(
                    cues: cues,
                    selectedCueId: _selectedCueId,
                    activeCueId: show.activeCue?.cueId,
                    onSelect: (id) => setState(() => _selectedCueId = id),
                    onReorder: _handleReorder,
                    onDelete: _handleDelete,
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // ── Rechte Spalte: Inspector ─────────────────────────────────────
          Expanded(
            child: selected != null
                ? CueInspectorPanel(
                    cue: selected,
                    onSave: _handleSaveCue,
                    connectedNodes: connectedNodes,
                  )
                : const _EmptyInspector(),
          ),
        ],
      ),
    );
  }

  Cue? _selectedCue(List<Cue> cues) {
    if (_selectedCueId == null) return null;
    for (final c in cues) {
      if (c.cueId == _selectedCueId) return c;
    }
    return null;
  }

  Future<void> _showAddCueDialog(BuildContext context, int currentCount) async {
    final type = await showDialog<CueType>(
      context: context,
      builder: (_) => const _CueTypeDialog(),
    );
    if (type == null || !mounted) return;

    final newCue = Cue()
      ..cueId = _generateId()
      ..number = (currentCount + 1).toString()
      ..label = _defaultLabel(type)
      ..cueType = type;

    await ref.read(showControlProvider.notifier).upsertCue(newCue);
    setState(() => _selectedCueId = newCue.cueId);
  }

  Future<void> _handleSaveCue(Cue updated) async {
    await ref.read(showControlProvider.notifier).upsertCue(updated);
  }

  Future<void> _handleDelete(String cueId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cue löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(showControlProvider.notifier).deleteCue(cueId);
    if (_selectedCueId == cueId) setState(() => _selectedCueId = null);
  }

  Future<void> _handleReorder(List<Cue> reordered) async {
    final updated = ref.read(showControlProvider).cueList;
    if (updated == null) return;
    final newList = CueList()
      ..cueListId = updated.cueListId
      ..name = updated.name
      ..cues.addAll(reordered);
    await ref.read(showControlProvider.notifier).updateCueList(newList);
  }

  Future<void> _showDeployDialog(
      BuildContext context, List<Cue> cues, List<NodeInfo> audioNodes) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ShowDeployDialog(cues: cues, audioNodes: audioNodes),
    );
  }

  String _generateId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final us = DateTime.now().microsecond;
    return ms.toRadixString(36) + us.toRadixString(36);
  }

  String _defaultLabel(CueType type) => switch (type) {
        CueType.CUE_TYPE_AUDIO => 'Audio',
        CueType.CUE_TYPE_MA_OSC => 'GrandMA',
        CueType.CUE_TYPE_WAIT => 'Warten',
        CueType.CUE_TYPE_GROUP => 'Gruppe',
        CueType.CUE_TYPE_GOTO => 'Goto',
        _ => 'Cue',
      };
}

// ── GO/STOP-Bar ───────────────────────────────────────────────────────────────

class _GoStopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
          icon: const Icon(Icons.play_arrow),
          label: const Text('GO'),
          onPressed: () => ref.read(showControlProvider.notifier).go(),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.stop, color: Colors.red),
          label: const Text('STOP'),
          onPressed: () => ref.read(showControlProvider.notifier).stop(),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.pause),
          label: const Text('PAUSE'),
          onPressed: () => ref.read(showControlProvider.notifier).pause(),
        ),
      ],
    );
  }
}

// ── Cue-Liste Toolbar ─────────────────────────────────────────────────────────

class _CueListToolbar extends StatelessWidget {
  final VoidCallback onAddCue;
  const _CueListToolbar({required this.onAddCue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text('Cues', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          FilledButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Hinzufügen'),
            onPressed: onAddCue,
          ),
        ],
      ),
    );
  }
}

// ── Cue-Liste View (reorderable) ──────────────────────────────────────────────

class _CueListView extends StatelessWidget {
  final List<Cue> cues;
  final String? selectedCueId;
  final String? activeCueId;
  final ValueChanged<String> onSelect;
  final ValueChanged<List<Cue>> onReorder;
  final ValueChanged<String> onDelete;

  const _CueListView({
    required this.cues,
    required this.selectedCueId,
    required this.activeCueId,
    required this.onSelect,
    required this.onReorder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (cues.isEmpty) {
      return const Center(
        child: Text('Keine Cues.\nKlicke auf "Hinzufügen".', textAlign: TextAlign.center),
      );
    }

    return ReorderableListView.builder(
      itemCount: cues.length,
      onReorder: (oldIdx, newIdx) {
        final reordered = List<Cue>.from(cues);
        if (newIdx > oldIdx) newIdx--;
        final item = reordered.removeAt(oldIdx);
        reordered.insert(newIdx, item);
        onReorder(reordered);
      },
      itemBuilder: (context, i) {
        final cue = cues[i];
        final isSelected = cue.cueId == selectedCueId;
        final isActive = cue.cueId == activeCueId;

        return _CueRow(
          key: ValueKey(cue.cueId),
          cue: cue,
          isSelected: isSelected,
          isActive: isActive,
          onTap: () => onSelect(cue.cueId),
          onDelete: () => onDelete(cue.cueId),
        );
      },
    );
  }
}

class _CueRow extends StatelessWidget {
  final Cue cue;
  final bool isSelected;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CueRow({
    super.key,
    required this.cue,
    required this.isSelected,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      selected: isSelected,
      selectedTileColor: cs.primaryContainer,
      tileColor: isActive ? const Color(0xFF00C853).withValues(alpha: 0.08) : null,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(cue.number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF00C853) : null,
              )),
        ],
      ),
      title: Text(cue.label),
      subtitle: Text(_typeLabel(cue.cueType), style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CueTypeChip(type: cue.cueType),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            color: cs.error,
          ),
          ReorderableDragStartListener(
            index: 0,
            child: const Icon(Icons.drag_handle),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _typeLabel(CueType t) => switch (t) {
        CueType.CUE_TYPE_AUDIO => 'Audio-Cue',
        CueType.CUE_TYPE_MA_OSC => 'GrandMA-OSC',
        CueType.CUE_TYPE_WAIT => 'Warten',
        CueType.CUE_TYPE_GROUP => 'Gruppe',
        CueType.CUE_TYPE_GOTO => 'Goto',
        _ => 'Unbekannt',
      };
}

class _CueTypeChip extends StatelessWidget {
  final CueType type;
  const _CueTypeChip({required this.type});

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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Cue-Typ Dialog ────────────────────────────────────────────────────────────

class _CueTypeDialog extends StatelessWidget {
  const _CueTypeDialog();

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Cue-Typ wählen'),
      children: [
        _CueTypeOption(
          icon: Icons.volume_up,
          label: 'Audio-Cue',
          subtitle: 'WAV, MP3, FLAC abspielen',
          color: Colors.blue,
          type: CueType.CUE_TYPE_AUDIO,
        ),
        _CueTypeOption(
          icon: Icons.light_mode,
          label: 'GrandMA-OSC',
          subtitle: 'Executor Go/Off/Pause via OSC',
          color: Colors.orange,
          type: CueType.CUE_TYPE_MA_OSC,
        ),
        _CueTypeOption(
          icon: Icons.timer_outlined,
          label: 'Warten',
          subtitle: 'Zeitverzögerung',
          color: Colors.purple,
          type: CueType.CUE_TYPE_WAIT,
        ),
        _CueTypeOption(
          icon: Icons.redo,
          label: 'Goto',
          subtitle: 'Zu einer anderen Cue springen',
          color: Colors.teal,
          type: CueType.CUE_TYPE_GOTO,
        ),
      ],
    );
  }
}

class _CueTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final CueType type;

  const _CueTypeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, type),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyInspector extends StatelessWidget {
  const _EmptyInspector();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text(
          'Cue auswählen um Parameter zu bearbeiten.',
          style: TextStyle(color: Colors.grey),
        ),
      );
}

// ── Show Deploy Dialog ────────────────────────────────────────────────────────

class _ShowDeployDialog extends StatefulWidget {
  final List<Cue> cues;
  final List<NodeInfo> audioNodes;

  const _ShowDeployDialog({required this.cues, required this.audioNodes});

  @override
  State<_ShowDeployDialog> createState() => _ShowDeployDialogState();
}

class _ShowDeployDialogState extends State<_ShowDeployDialog> {
  bool _running = false;
  final List<_DeployEntry> _log = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _deploy());
  }

  Future<void> _deploy() async {
    setState(() { _running = true; _log.clear(); });

    // Alle Audio-Dateinamen aus der CueList sammeln
    final files = <String>{};
    for (final cue in widget.cues) {
      if (cue.cueType == CueType.CUE_TYPE_AUDIO && cue.hasAudio()) {
        final fp = cue.audio.filePath;
        if (fp.isNotEmpty) files.add(fp);
      }
    }

    if (files.isEmpty) {
      _addLog('Keine Audio-Cues in der CueList.', ok: true);
      setState(() => _running = false);
      return;
    }

    _addLog('${files.length} Datei(en) gefunden, prüfe auf ${widget.audioNodes.length} Node(s)…');

    for (final node in widget.audioNodes) {
      _addLog('Node: ${node.name} (${node.mediaServerUrl})');

      // Vorhandene Dateien abfragen
      Set<String> existing = {};
      try {
        final resp = await http.get(Uri.parse('${node.mediaServerUrl}/media'))
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final list = (jsonDecode(resp.body) as List)
              .map((e) => e['filename'] as String)
              .toSet();
          existing = list;
        }
      } catch (e) {
        _addLog('  ✗ Verbindung fehlgeschlagen: $e', ok: false);
        continue;
      }

      // Fehlende Dateien von einem anderen Node downloaden und hochladen
      for (final filename in files) {
        if (existing.contains(filename)) {
          _addLog('  ✓ "$filename" bereits vorhanden', ok: true);
          continue;
        }

        // Quelle: erster anderer Node der die Datei hat
        NodeInfo? source;
        List<int>? bytes;
        for (final other in widget.audioNodes) {
          if (other.nodeId == node.nodeId) continue;
          try {
            final dlResp = await http.get(
                Uri.parse('${other.mediaServerUrl}/media/download/$filename'))
                .timeout(const Duration(seconds: 15));
            if (dlResp.statusCode == 200) {
              source = other;
              bytes = dlResp.bodyBytes;
              break;
            }
          } catch (_) {}
        }

        if (bytes == null) {
          _addLog('  ✗ "$filename" — auf keinem Node gefunden!', ok: false);
          continue;
        }

        _addLog('  ↑ Lade "$filename" von ${source!.name} → ${node.name}…');
        try {
          final req = http.MultipartRequest(
              'POST', Uri.parse('${node.mediaServerUrl}/media/upload'))
            ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
          final uploadResp = await req.send().timeout(const Duration(seconds: 30));
          if (uploadResp.statusCode == 200) {
            _addLog('  ✓ "$filename" hochgeladen', ok: true);
          } else {
            _addLog('  ✗ "$filename" — Upload HTTP ${uploadResp.statusCode}', ok: false);
          }
        } catch (e) {
          _addLog('  ✗ "$filename" — Upload-Fehler: $e', ok: false);
        }
      }
    }

    _addLog('Deploy abgeschlossen.', ok: true);
    setState(() => _running = false);
  }

  void _addLog(String msg, {bool? ok}) {
    setState(() => _log.add(_DeployEntry(msg, ok)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.cloud_sync),
        const SizedBox(width: 8),
        const Text('Show Deploy'),
        if (_running) ...[
          const SizedBox(width: 12),
          const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ]),
      content: SizedBox(
        width: 500,
        height: 360,
        child: ListView.builder(
          itemCount: _log.length,
          itemBuilder: (ctx, i) {
            final e = _log[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(e.msg,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: e.ok == null
                        ? null
                        : e.ok!
                            ? Colors.green
                            : Colors.red,
                  )),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _running ? null : () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
        if (!_running)
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Nochmal'),
            onPressed: _deploy,
          ),
      ],
    );
  }
}

class _DeployEntry {
  final String msg;
  final bool? ok;
  const _DeployEntry(this.msg, this.ok);
}
