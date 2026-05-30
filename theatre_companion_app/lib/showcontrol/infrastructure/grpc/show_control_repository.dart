import 'package:path/path.dart' as p;

import '../../grpc/generated/stagesync/v1/showcontrol.pb.dart' as pb;
import '../../grpc/generated/stagesync/v1/common.pb.dart' as pb_common;
import '../../domain/show.dart';
import '../../domain/cue_params.dart';
import '../../domain/node_status.dart';
import '../../domain/patch_config.dart';

/// Maps protobuf transport types to immutable domain models.
///
/// Infrastructure layer — only this file imports proto-generated code.
/// Domain and UI layers must not import proto types directly.
class ShowControlRepository {
  ShowControlRepository._();

  // ── CueList ───────────────────────────────────────────────────────────────

  static CueList cueListFromProto(pb.CueList proto) {
    return CueList(
      id: proto.cueListId,
      name: proto.name,
      cues: proto.cues.map(cueFromProto).toList(),
    );
  }

  // ── Cue ───────────────────────────────────────────────────────────────────

  static Cue cueFromProto(pb.Cue proto) {
    final params = _paramsFromProto(proto);
    return Cue(
      id: proto.cueId,
      number: proto.number,
      label: proto.label,
      params: params,
      timing: CueTiming(
        preWaitMs: proto.preWaitMs,
        postWaitMs: proto.postWaitMs,
        autoContinue: proto.autoContinue,
        durationMs: _durationMs(proto),
      ),
      // logical_output_id bevorzugt; targetNodeId als Fallback für ältere Cues.
      logicalOutputId: proto.logicalOutputId.isNotEmpty
          ? proto.logicalOutputId
          : (proto.targetNodeId.isNotEmpty ? proto.targetNodeId : null),
    );
  }

  static CueParams _paramsFromProto(pb.Cue proto) {
    return switch (proto.whichParams()) {
      pb.Cue_Params.audio => AudioParams(
          // asset_id (SHA-256) bevorzugt; fallback auf basename(file_path) für
          // Cues die noch ohne asset_id gespeichert wurden.
          assetId: proto.audio.assetId.isNotEmpty
              ? proto.audio.assetId
              : p.basename(proto.audio.filePath),
          volumeDb: proto.audio.volumeDb,
          fadeInMs: proto.audio.fadeInMs,
          fadeOutMs: proto.audio.fadeOutMs,
          loop: proto.audio.loop,
          startTimeMs: proto.audio.startTimeMs,
          endTimeMs: proto.audio.endTimeMs,
          declaredDurationMs: proto.audio.declaredDurationMs > 0
              ? proto.audio.declaredDurationMs
              : null,
        ),
      pb.Cue_Params.wait => WaitParams(
          durationMs: proto.wait.durationMs,
        ),
      pb.Cue_Params.maOsc => MaOscParams(
          oscAddress: proto.maOsc.oscAddress,
          oscArgument: proto.maOsc.oscArgument,
          executorPage: proto.maOsc.executorPage,
          executorNo: proto.maOsc.executorNo,
          command: _maCommand(proto.maOsc.command),
          gotoCue: proto.maOsc.gotoCue.toDouble(),
        ),
      pb.Cue_Params.gotoP => GotoParams(
          targetCueId: proto.gotoP.targetCueId,
          targetNumber: proto.gotoP.targetNumber,
        ),
      pb.Cue_Params.group => GroupParams(
          childCueIds: proto.group.childCueIds.toList(),
          sequential: proto.group.sequential,
        ),
      pb.Cue_Params.notSet => const ScriptParams(script: ''),
    };
  }

  static double? _durationMs(pb.Cue proto) {
    if (proto.whichParams() == pb.Cue_Params.wait) {
      return proto.wait.durationMs;
    }
    if (proto.whichParams() == pb.Cue_Params.audio) {
      final end = proto.audio.endTimeMs;
      final start = proto.audio.startTimeMs;
      if (end > start && end > 0) return end - start;
    }
    return null;
  }

  static MaOscCommand _maCommand(pb.MaOscCueParams_MaCommand cmd) =>
      switch (cmd.value) {
        1 => MaOscCommand.go,
        2 => MaOscCommand.off,
        3 => MaOscCommand.pause,
        4 => MaOscCommand.gotoP,
        _ => MaOscCommand.unspecified,
      };

  // ── NodeStatus ────────────────────────────────────────────────────────────

  /// Converts a session's node list to domain [NodeStatus] objects.
  static List<NodeStatus> nodeStatusesFromNodes(
    List<pb_common.NodeInfo> nodes,
    bool sessionConnected,
  ) {
    return nodes.map((node) {
      final tasks = tasksFromProto(node.tasks.toList());
      final health = sessionConnected
          ? (node.online ? NodeHealthPhase.online : NodeHealthPhase.offline)
          : NodeHealthPhase.reconnecting;

      return NodeStatus(
        nodeId: node.nodeId,
        name: node.name,
        tasks: tasks,
        health: health,
      );
    }).toList();
  }

  static List<String> tasksFromProto(List<pb_common.NodeTask> tasks) {
    return tasks.map((t) => switch (t.value) {
          1 => 'master',
          2 => 'audio',
          3 => 'editor',
          4 => 'viewer',
          5 => 'ma_osc',
          _ => 'unknown',
        }).toList();
  }

  // ── PatchConfig ───────────────────────────────────────────────────────────

  static PatchConfig patchConfigFromProto(pb.PatchConfig proto) {
    return PatchConfig(
      logicalOutputs: proto.logicalOutputs
          .map((o) => LogicalOutput(id: o.id, name: o.name))
          .toList(),
      nodePatches: proto.nodeAssigns
          .map((a) => NodePatch(
                logicalOutputId: a.logicalOutputId,
                nodeIds: a.nodeIds.toList(),
              ))
          .toList(),
      devicePatches: proto.deviceAssigns
          .map((a) => DevicePatch(
                logicalOutputId: a.logicalOutputId,
                nodeId: a.nodeId,
                deviceIndex: a.deviceIndex,
                deviceName: a.deviceName,
              ))
          .toList(),
    );
  }

  static pb.PatchConfig patchConfigToProto(PatchConfig domain) {
    return pb.PatchConfig(
      logicalOutputs: domain.logicalOutputs
          .map((o) => pb.PatchLogicalOutput(id: o.id, name: o.name))
          .toList(),
      nodeAssigns: domain.nodePatches
          .map((p) => pb.PatchNodeAssign(
                logicalOutputId: p.logicalOutputId,
                nodeIds: p.nodeIds,
              ))
          .toList(),
      deviceAssigns: domain.devicePatches
          .map((p) => pb.PatchDeviceAssign(
                logicalOutputId: p.logicalOutputId,
                nodeId: p.nodeId,
                deviceIndex: p.deviceIndex,
                deviceName: p.deviceName,
              ))
          .toList(),
    );
  }

  // ── Domain → Proto (write path from Inspector) ────────────────────────────

  /// Converts a domain [Cue] back to a protobuf [pb.Cue] for server updates.
  static pb.Cue cueToProto(Cue domain) {
    final proto = pb.Cue()
      ..cueId = domain.id
      ..number = domain.number
      ..label = domain.label
      ..preWaitMs = domain.timing.preWaitMs
      ..postWaitMs = domain.timing.postWaitMs
      ..autoContinue = domain.timing.autoContinue;

    if (domain.logicalOutputId != null) {
      proto.logicalOutputId = domain.logicalOutputId!;
    }

    switch (domain.params) {
      case AudioParams ap:
        proto.cueType = pb_common.CueType.CUE_TYPE_AUDIO;
        proto.audio = pb.AudioCueParams()
          ..assetId = ap.assetId
          ..filePath = ''           // filePath nicht mit SHA-256 befüllen (würde Preload-Lookup brechen)
          ..volumeDb = ap.volumeDb
          ..fadeInMs = ap.fadeInMs
          ..fadeOutMs = ap.fadeOutMs
          ..loop = ap.loop
          ..startTimeMs = ap.startTimeMs
          ..endTimeMs = ap.endTimeMs
          ..declaredDurationMs = ap.declaredDurationMs ?? 0;
      case WaitParams wp:
        proto.cueType = pb_common.CueType.CUE_TYPE_WAIT;
        proto.wait = pb.WaitCueParams()..durationMs = wp.durationMs;
      case MaOscParams mp:
        proto.cueType = pb_common.CueType.CUE_TYPE_MA_OSC;
        proto.maOsc = pb.MaOscCueParams()
          ..oscAddress = mp.oscAddress
          ..oscArgument = mp.oscArgument
          ..executorPage = mp.executorPage
          ..executorNo = mp.executorNo
          ..gotoCue = mp.gotoCue.toInt();
      case GotoParams gp:
        proto.cueType = pb_common.CueType.CUE_TYPE_GOTO;
        proto.gotoP = pb.GotoCueParams()
          ..targetCueId = gp.targetCueId
          ..targetNumber = gp.targetNumber;
      default:
        break;
    }

    return proto;
  }
}
