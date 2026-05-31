import 'package:meta/meta.dart';

// ── Audio Bus System ──────────────────────────────────────────────────────────

enum AudioBusType { main, monitor, talkback, aux, iem }

@immutable
class BusNodeAssign {
  final String nodeId;
  final int deviceIndex;
  final String deviceName;

  const BusNodeAssign({
    required this.nodeId,
    required this.deviceIndex,
    this.deviceName = '',
  });
}

@immutable
class AudioBus {
  final String id;
  final String name;
  final AudioBusType type;
  final double outputLevelDb;
  final bool muted;
  final List<BusNodeAssign> patch;

  const AudioBus({
    required this.id,
    required this.name,
    this.type = AudioBusType.main,
    this.outputLevelDb = 0.0,
    this.muted = false,
    this.patch = const [],
  });
}

/// Layer 1: A named logical audio output that cues reference.
/// Cues store [LogicalOutput.id] in [Cue.logicalOutputId] — never a node ID.
@immutable
class LogicalOutput {
  final String id;
  final String name; // e.g. "Main L/R", "Monitor", "Surround"

  const LogicalOutput({required this.id, required this.name});
}

/// Layer 2: Maps a logical output to one or more node IDs.
/// Multiple nodes = redundancy or multi-room output.
@immutable
class NodePatch {
  final String logicalOutputId;
  final List<String> nodeIds;

  const NodePatch({
    required this.logicalOutputId,
    required this.nodeIds,
  });
}

/// Layer 3: Node-local device assignment.
/// Maps a logical output to a physical device/channel on a specific node.
/// Reported by the node after [RegisterNode]; server stores it in [PatchConfig].
@immutable
class DevicePatch {
  final String logicalOutputId;
  final String nodeId;
  final int deviceIndex;
  final String deviceName; // human-readable, e.g. "ASIO Out 1-2"

  const DevicePatch({
    required this.logicalOutputId,
    required this.nodeId,
    required this.deviceIndex,
    required this.deviceName,
  });
}

/// Layer 4: Node-local audition/preview output.
/// NOT part of the authoritative show state — never sent to server.
/// Each node declares its own [AuditionBus] via [AuditionCapability].
@immutable
class AuditionBus {
  final String nodeId;
  final int deviceIndex;
  final String deviceName; // e.g. "Headphones"

  const AuditionBus({
    required this.nodeId,
    required this.deviceIndex,
    required this.deviceName,
  });
}

/// Complete patch configuration for a show.
/// Immutable — changes produce a new instance.
@immutable
class PatchConfig {
  final List<LogicalOutput> logicalOutputs; // Legacy Layer 1 definitions
  final List<NodePatch> nodePatches;         // Legacy Layer 2: bus → nodes
  final List<DevicePatch> devicePatches;     // Legacy Layer 3: bus → device on node
  final List<AuditionBus> auditionBuses;     // Layer 4: per-node preview
  final List<AudioBus> buses;               // Audio Bus System (neues Modell)

  const PatchConfig({
    this.logicalOutputs = const [],
    this.nodePatches = const [],
    this.devicePatches = const [],
    this.auditionBuses = const [],
    this.buses = const [],
  });

  static const PatchConfig empty = PatchConfig();

  /// Alle Buses vom Typ [type].
  List<AudioBus> busesOfType(AudioBusType type) =>
      buses.where((b) => b.type == type).toList();

  PatchConfig copyWith({
    List<LogicalOutput>? logicalOutputs,
    List<NodePatch>? nodePatches,
    List<DevicePatch>? devicePatches,
    List<AuditionBus>? auditionBuses,
    List<AudioBus>? buses,
  }) =>
      PatchConfig(
        logicalOutputs: logicalOutputs ?? this.logicalOutputs,
        nodePatches: nodePatches ?? this.nodePatches,
        devicePatches: devicePatches ?? this.devicePatches,
        auditionBuses: auditionBuses ?? this.auditionBuses,
        buses: buses ?? this.buses,
      );

  /// All node IDs that are routed to [logicalOutputId].
  List<String> nodesForOutput(String logicalOutputId) => nodePatches
      .where((p) => p.logicalOutputId == logicalOutputId)
      .expand((p) => p.nodeIds)
      .toList();

  /// Device patch for [nodeId] on [logicalOutputId], if configured.
  DevicePatch? devicePatchFor(String logicalOutputId, String nodeId) {
    for (final dp in devicePatches) {
      if (dp.logicalOutputId == logicalOutputId && dp.nodeId == nodeId) {
        return dp;
      }
    }
    return null;
  }

  /// Returns true if [logicalOutputId] is mapped to at least one online node.
  bool hasConflict(String logicalOutputId) {
    final nodes = nodesForOutput(logicalOutputId);
    if (nodes.length <= 1) return false;
    // Conflict = same physical device used by multiple logical outputs on the same node
    final seenDevices = <String>{};
    for (final dp in devicePatches.where((d) => nodes.contains(d.nodeId))) {
      final key = '${dp.nodeId}:${dp.deviceIndex}';
      if (!seenDevices.add(key)) return true;
    }
    return false;
  }
}
