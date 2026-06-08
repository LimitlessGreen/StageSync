import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../showcontrol/domain/patch_config.dart';
import '../../showcontrol/domain/node_status.dart';
import '../../showcontrol/providers/show_control_domain_provider.dart';
import '../../showcontrol/providers/show_control_provider.dart';

/// Bottom-Sheet zur Verwaltung der Audio-Buses.
///
/// Zeigt alle Buses aus der PatchConfig und erlaubt:
///   • Lautstärke-Fader pro Bus
///   • Mute/Unmute
///   • Bus-Typ-Anzeige (Chip)
///   • "Bus hinzufügen" → einfacher Talkback-Bus-Creator
///
/// Aufruf: showBusConfigSheet(context, ref)
Future<void> showBusConfigSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF181818),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _BusConfigSheet(ref: ref),
  );
}

class _BusConfigSheet extends ConsumerStatefulWidget {
  const _BusConfigSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_BusConfigSheet> createState() => _BusConfigSheetState();
}

class _BusConfigSheetState extends ConsumerState<_BusConfigSheet> {
  @override
  Widget build(BuildContext context) {
    final domain = ref.watch(showControlDomainProvider);
    final buses = domain.patchConfig.buses;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'AUDIO BUSES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddBusDialog(context),
                  icon:
                      const Icon(Icons.add, size: 18, color: Color(0xFF64B5F6)),
                  label: const Text('Bus hinzufügen',
                      style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF333333), height: 1),

          // ── Bus-Liste ───────────────────────────────────────────────────────
          Expanded(
            child: buses.isEmpty
                ? _EmptyBusHint(onAdd: () => _showAddBusDialog(context))
                : ListView.builder(
                    controller: scroll,
                    itemCount: buses.length,
                    itemBuilder: (_, i) => _BusTile(
                      bus: buses[i],
                      onChanged: (updated) => _updateBus(buses, i, updated),
                      onDelete: () => _deleteBus(buses, i),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _updateBus(List<AudioBus> buses, int index, AudioBus updated) {
    final newBuses = List<AudioBus>.from(buses);
    newBuses[index] = updated;
    _saveBuses(newBuses);
  }

  void _deleteBus(List<AudioBus> buses, int index) {
    final newBuses = List<AudioBus>.from(buses)..removeAt(index);
    _saveBuses(newBuses);
  }

  void _saveBuses(List<AudioBus> newBuses) {
    final domain = ref.read(showControlDomainProvider);
    final newPatch = domain.patchConfig.copyWith(buses: newBuses);
    ref.read(showControlProvider.notifier).updatePatchConfig(newPatch);
  }

  void _showAddBusDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    AudioBusType selectedType = AudioBusType.talkback;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Bus hinzufügen',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Color(0xFF888888)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF444444))),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButton<AudioBusType>(
                value: selectedType,
                dropdownColor: const Color(0xFF2C2C2C),
                isExpanded: true,
                items: AudioBusType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_busTypeName(t),
                              style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (t) {
                  if (t != null) setDlg(() => selectedType = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Color(0xFF888888))),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final newBus = AudioBus(
                  id: 'bus_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  type: selectedType,
                );
                final buses =
                    ref.read(showControlDomainProvider).patchConfig.buses;
                _saveBuses([...buses, newBus]);
                Navigator.pop(ctx);
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bus-Tile ──────────────────────────────────────────────────────────────────

class _BusTile extends ConsumerWidget {
  const _BusTile({
    required this.bus,
    required this.onChanged,
    required this.onDelete,
  });

  final AudioBus bus;
  final void Function(AudioBus) onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioNodes = ref
        .watch(showControlDomainProvider)
        .nodes
        .where((n) => n.isAudio && n.isOnline)
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + Typ + Mute + Delete ───────────────────────────────────
          Row(
            children: [
              _BusTypeChip(type: bus.type),
              const SizedBox(width: 8),
              Expanded(
                child: Text(bus.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: Icon(
                  bus.muted ? Icons.volume_off : Icons.volume_up,
                  color: bus.muted
                      ? const Color(0xFFFF5252)
                      : const Color(0xFF64B5F6),
                  size: 20,
                ),
                onPressed: () => onChanged(_copyBus(muted: !bus.muted)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFF666666), size: 20),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),

          // ── Fader ────────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.tune, size: 14, color: Color(0xFF666666)),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF64B5F6),
                    inactiveTrackColor: const Color(0xFF333333),
                    thumbColor: Colors.white,
                    overlayColor: Colors.transparent,
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: bus.outputLevelDb.clamp(-60.0, 10.0),
                    min: -60,
                    max: 10,
                    onChanged: (v) => onChanged(_copyBus(outputLevelDb: v)),
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '${bus.outputLevelDb.toStringAsFixed(1)} dB',
                  style:
                      const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          // ── Node-Patch ───────────────────────────────────────────────────
          const Divider(color: Color(0xFF333333), height: 16),
          Row(
            children: [
              const Icon(Icons.settings_input_hdmi,
                  size: 13, color: Color(0xFF666666)),
              const SizedBox(width: 6),
              const Text('NODE-PATCH',
                  style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 10,
                      letterSpacing: 0.8)),
              const Spacer(),
              if (audioNodes.isNotEmpty)
                GestureDetector(
                  onTap: () => _showAddNodeDialog(context, audioNodes),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Color(0xFF64B5F6)),
                      SizedBox(width: 2),
                      Text('Node hinzufügen',
                          style: TextStyle(
                              color: Color(0xFF64B5F6), fontSize: 11)),
                    ],
                  ),
                )
              else
                const Text('Keine Audio-Nodes online',
                    style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),

          if (bus.patch.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'Kein Node zugewiesen — Fallback auf alle Online-Nodes',
                style: TextStyle(color: Color(0xFF555555), fontSize: 11),
              ),
            )
          else
            ...bus.patch.map((assign) {
              final node = audioNodes.cast<NodeStatus?>().firstWhere(
                  (n) => n?.nodeId == assign.nodeId,
                  orElse: () => null);
              final nodeName = node?.name ?? assign.nodeId.substring(0, 8);
              final devName = assign.deviceName.isNotEmpty
                  ? assign.deviceName
                  : 'Gerät ${assign.deviceIndex}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Color(0xFF64B5F6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$nodeName — $devName',
                        style: const TextStyle(
                            color: Color(0xFFCCCCCC), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 14, color: Color(0xFF666666)),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () {
                        final newPatch = bus.patch
                            .where((a) => !(a.nodeId == assign.nodeId &&
                                a.deviceIndex == assign.deviceIndex))
                            .toList();
                        onChanged(_copyBus(patch: newPatch));
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  AudioBus _copyBus({
    double? outputLevelDb,
    bool? muted,
    List<BusNodeAssign>? patch,
  }) =>
      AudioBus(
        id: bus.id,
        name: bus.name,
        type: bus.type,
        outputLevelDb: outputLevelDb ?? bus.outputLevelDb,
        muted: muted ?? bus.muted,
        patch: patch ?? bus.patch,
      );

  void _showAddNodeDialog(BuildContext context, List<NodeStatus> audioNodes) {
    NodeStatus? selectedNode = audioNodes.first;
    int selectedDeviceIndex = audioNodes.first.availableDevices.isNotEmpty
        ? audioNodes.first.availableDevices.first.index
        : 0;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final devices = selectedNode?.availableDevices ?? [];
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Node zum Patch hinzufügen',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Audio-Node',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButton<NodeStatus>(
                  value: selectedNode,
                  dropdownColor: const Color(0xFF2C2C2C),
                  isExpanded: true,
                  items: audioNodes
                      .map((n) => DropdownMenuItem(
                            value: n,
                            child: Text(n.name,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (n) => setDlg(() {
                    selectedNode = n;
                    selectedDeviceIndex = n?.availableDevices.isNotEmpty == true
                        ? n!.availableDevices.first.index
                        : 0;
                  }),
                ),
                const SizedBox(height: 12),
                const Text('Ausgabegerät',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                const SizedBox(height: 4),
                if (devices.isEmpty)
                  const Text('System Default',
                      style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13))
                else
                  DropdownButton<int>(
                    value: selectedDeviceIndex,
                    dropdownColor: const Color(0xFF2C2C2C),
                    isExpanded: true,
                    items: devices
                        .map((d) => DropdownMenuItem(
                              value: d.index,
                              child: Text(
                                '[${d.index}] ${d.name}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (i) =>
                        setDlg(() => selectedDeviceIndex = i ?? 0),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen',
                    style: TextStyle(color: Color(0xFF888888))),
              ),
              FilledButton(
                onPressed: () {
                  if (selectedNode == null) return;
                  final devName = selectedNode!.availableDevices
                          .where((d) => d.index == selectedDeviceIndex)
                          .map((d) => d.name)
                          .firstOrNull ??
                      '';
                  final newAssign = BusNodeAssign(
                    nodeId: selectedNode!.nodeId,
                    deviceIndex: selectedDeviceIndex,
                    deviceName: devName,
                  );
                  final exists = bus.patch.any((a) =>
                      a.nodeId == newAssign.nodeId &&
                      a.deviceIndex == newAssign.deviceIndex);
                  if (!exists) {
                    onChanged(_copyBus(patch: [...bus.patch, newAssign]));
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Hinzufügen'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text('Bus löschen?', style: TextStyle(color: Colors.white)),
        content: Text('"${bus.name}" wird aus der PatchConfig entfernt.',
            style: const TextStyle(color: Color(0xFFAAAAAA))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

class _BusTypeChip extends StatelessWidget {
  const _BusTypeChip({required this.type});
  final AudioBusType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _busTypeColor(type).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _busTypeColor(type)),
      ),
      child: Text(
        _busTypeName(type),
        style: TextStyle(
          color: _busTypeColor(type),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _EmptyBusHint extends StatelessWidget {
  const _EmptyBusHint({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speaker_group_outlined,
              size: 48, color: Color(0xFF444444)),
          const SizedBox(height: 12),
          const Text('Noch keine Buses konfiguriert',
              style: TextStyle(color: Color(0xFF666666))),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Talkback-Bus erstellen'),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _busTypeName(AudioBusType t) => switch (t) {
      AudioBusType.main => 'MAIN',
      AudioBusType.monitor => 'MONITOR',
      AudioBusType.talkback => 'TALKBACK',
      AudioBusType.aux => 'AUX',
      AudioBusType.iem => 'IEM',
    };

Color _busTypeColor(AudioBusType t) => switch (t) {
      AudioBusType.main => const Color(0xFF64B5F6),
      AudioBusType.monitor => const Color(0xFF81C784),
      AudioBusType.talkback => const Color(0xFFFF8A65),
      AudioBusType.aux => const Color(0xFFCE93D8),
      AudioBusType.iem => const Color(0xFF4DD0E1),
    };
