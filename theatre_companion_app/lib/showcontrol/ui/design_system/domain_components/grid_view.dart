import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sc_colors.dart';
import '../sc_tick.dart';
import '../primitives/sc_grid_cell.dart';
import 'clip_inspector.dart';
import '../../../domain/grid_run_state.dart';
import '../../../providers/grid_provider.dart';
import '../../../providers/grid_midi_controller.dart';
import '../../../session/clock_sync.dart';
import '../../../grpc/generated/stagesync/v1/grid.pb.dart';

/// Session-View-Matrix: Spalten = Tracks, Reihen = Scenes. Rechts eine
/// Scene-Launch-Spalte. Desktop-orientiert.
class ScGridView extends ConsumerWidget {
  /// Wird beim Antippen einer Zelle mit deren Position aufgerufen (Editor öffnen).
  final void Function(int track, int scene)? onEditCell;

  /// Aktuell ausgewählte Zelle (für Editor-Highlight).
  final (int, int)? selected;

  const ScGridView({super.key, this.onEditCell, this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live-Fortschritt: an den geteilten vsync-Ticker andocken.
    ScTick.of(context);

    final state = ref.watch(gridProvider);
    final notifier = ref.read(gridProvider.notifier);
    final grid = state.grid;

    if (state.isLoading && grid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Fallback-Grid wenn kein Server erreichbar: 8×8 leeres Raster, damit
    // der Inspector trotzdem geöffnet und Clips vorbereitet werden können.
    final effectiveGrid = grid ?? _defaultGrid();

    final trackCount = effectiveGrid.tracks.length;
    final sceneCount = effectiveGrid.scenes.length;
    final nowMs = ClockSync.instance.serverNow();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            _trackHeaderRow(effectiveGrid, notifier),
            const SizedBox(height: 4),
            Expanded(
              child: Column(
                children: [
                  for (int scene = 0; scene < sceneCount; scene++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            for (int track = 0; track < trackCount; track++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: _cell(context, state, notifier, track,
                                      scene, nowMs),
                                ),
                              ),
                            _sceneLaunchButton(effectiveGrid, notifier, scene),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _bottomBar(context, ref, notifier),
          ],
        );
      },
    );
  }

  Widget _cell(BuildContext context, GridState state, GridNotifier notifier,
      int track, int scene, int nowMs) {
    final clip = state.clipAt(track, scene);
    final run = state.runStateAt(track, scene);
    final isSel =
        selected != null && selected!.$1 == track && selected!.$2 == scene;

    void openInspector() {
      if (onEditCell != null) {
        onEditCell!(track, scene);
      } else {
        showClipInspector(context,
            trackIndex: track, sceneIndex: scene, existing: clip);
      }
    }

    return ScGridCell(
      clip: clip,
      runState: run,
      progress: _progress(run, nowMs),
      selected: isSel,
      // Leere Zelle → Inspector öffnen; belegte Zelle → Clip starten.
      onTap: clip == null
          ? openInspector
          : () => notifier.launchClip(track, scene),
      onLongPress: openInspector,
    );
  }

  static Grid _defaultGrid() {
    const cols = 8;
    const rows = 8;
    return Grid(
      gridId: 'main',
      name: 'Grid',
      tracks: [
        for (var t = 0; t < cols; t++)
          GridTrack(trackId: 'T$t', name: 'T${t + 1}', exclusive: true)
      ],
      scenes: [
        for (var s = 0; s < rows; s++)
          GridScene(sceneId: 'S$s', name: 'S${s + 1}')
      ],
    );
  }

  double? _progress(GridClipRunState run, int nowMs) {
    if (run.lifecycle != ClipLifecycle.playing) return null;
    final start = run.startedServerMs;
    if (start == null || run.lengthMs <= 0) return null;
    final elapsed = (nowMs - start).toDouble();
    return (elapsed / run.lengthMs).clamp(0.0, 1.0);
  }

  Widget _trackHeaderRow(Grid grid, GridNotifier notifier) {
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          for (int t = 0; t < grid.tracks.length; t++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () => notifier.stopTrack(t),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ScColors.surface2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      grid.tracks[t].name.isEmpty
                          ? 'T${t + 1}'
                          : grid.tracks[t].name,
                      style: const TextStyle(
                          color: ScColors.textSecondary, fontSize: 10),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 44), // Platz über der Scene-Launch-Spalte
        ],
      ),
    );
  }

  Widget _sceneLaunchButton(Grid grid, GridNotifier notifier, int scene) {
    return SizedBox(
      width: 40,
      child: GestureDetector(
        onTap: () => notifier.launchScene(scene),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ScColors.surface2,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: ScColors.divider),
          ),
          child: const Icon(Icons.play_arrow, color: ScColors.active, size: 18),
        ),
      ),
    );
  }

  Widget _bottomBar(
      BuildContext context, WidgetRef ref, GridNotifier notifier) {
    final midi = ref.watch(gridMidiProvider);
    final midiLabel = midi.connected
        ? 'MIDI: ${midi.deviceName ?? "verbunden"}'
        : (midi.enabled ? 'MIDI: ${midi.error ?? "kein Gerät"}' : 'MIDI lokal');
    return Row(
      children: [
        // Lokaler MIDI-Pfad (APC Mini) ein/aus.
        FilterChip(
          label: Text(midiLabel, style: const TextStyle(fontSize: 11)),
          avatar: Icon(Icons.piano,
              size: 14,
              color: midi.connected ? ScColors.active : ScColors.textDim),
          selected: midi.enabled,
          selectedColor: ScColors.selected,
          backgroundColor: ScColors.surface2,
          onSelected: (v) => ref.read(gridMidiProvider.notifier).setEnabled(v),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: notifier.stopAll,
          icon: const Icon(Icons.stop, color: ScColors.error, size: 18),
          label:
              const Text('Stop All', style: TextStyle(color: ScColors.error)),
        ),
      ],
    );
  }
}
