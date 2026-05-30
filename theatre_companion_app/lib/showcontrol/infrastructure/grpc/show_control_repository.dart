import 'package:flutter/material.dart' show Color;
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
          pauseBehavior: _pauseBehavior(proto.audio.pauseBehavior),
          pauseFadeMs: proto.audio.pauseFadeMs,
          resumeBehavior: _resumeBehavior(proto.audio.resumeBehavior),
          resumeFadeMs: proto.audio.resumeFadeMs,
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
      pb.Cue_Params.note => NoteParams(
          text: proto.note.text,
          color: proto.note.colorHex.isNotEmpty
              ? Color(int.parse(
                  'FF${proto.note.colorHex.replaceAll("#", "")}',
                  radix: 16))
              : null,
        ),
      pb.Cue_Params.fade => FadeParams(
          targetCueId: proto.fade.targetCueId,
          targetCueNumber: proto.fade.targetCueNumber,
          action: _fadeAction(proto.fade.action),
          targetVolumeDb: proto.fade.targetVolumeDb,
          durationMs: proto.fade.durationMs,
          stopWhenDone: proto.fade.stopWhenDone,
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

  static pb.AudioCueParams_PauseBehavior _pauseBehaviorToProto(PauseBehavior v) =>
      switch (v) {
        PauseBehavior.fadeOut => pb.AudioCueParams_PauseBehavior.PAUSE_FADE_OUT,
        PauseBehavior.hard    => pb.AudioCueParams_PauseBehavior.PAUSE_HARD,
      };

  static pb.AudioCueParams_ResumeBehavior _resumeBehaviorToProto(ResumeBehavior v) =>
      switch (v) {
        ResumeBehavior.fadeIn          => pb.AudioCueParams_ResumeBehavior.RESUME_FADE_IN,
        ResumeBehavior.fromStart       => pb.AudioCueParams_ResumeBehavior.RESUME_FROM_START,
        ResumeBehavior.continuePlaying => pb.AudioCueParams_ResumeBehavior.RESUME_CONTINUE,
      };

  static pb.FadeCueParams_FadeAction _fadeActionToProto(FadeAction v) =>
      switch (v) {
        FadeAction.stop   => pb.FadeCueParams_FadeAction.FADE_ACTION_STOP,
        FadeAction.pause  => pb.FadeCueParams_FadeAction.FADE_ACTION_PAUSE,
        FadeAction.resume => pb.FadeCueParams_FadeAction.FADE_ACTION_RESUME,
        FadeAction.volume => pb.FadeCueParams_FadeAction.FADE_ACTION_VOLUME,
      };

  static PauseBehavior _pauseBehavior(pb.AudioCueParams_PauseBehavior v) =>
      switch (v.value) {
        1 => PauseBehavior.fadeOut,
        _ => PauseBehavior.hard,
      };

  static ResumeBehavior _resumeBehavior(pb.AudioCueParams_ResumeBehavior v) =>
      switch (v.value) {
        1 => ResumeBehavior.fadeIn,
        2 => ResumeBehavior.fromStart,
        _ => ResumeBehavior.continuePlaying,
      };

  static FadeAction _fadeAction(pb.FadeCueParams_FadeAction v) =>
      switch (v.value) {
        1 => FadeAction.stop,
        2 => FadeAction.pause,
        3 => FadeAction.resume,
        _ => FadeAction.volume,
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
          ..filePath = ''
          ..volumeDb = ap.volumeDb
          ..fadeInMs = ap.fadeInMs
          ..fadeOutMs = ap.fadeOutMs
          ..loop = ap.loop
          ..startTimeMs = ap.startTimeMs
          ..endTimeMs = ap.endTimeMs
          ..declaredDurationMs = ap.declaredDurationMs ?? 0
          ..pauseBehavior = _pauseBehaviorToProto(ap.pauseBehavior)
          ..pauseFadeMs = ap.pauseFadeMs
          ..resumeBehavior = _resumeBehaviorToProto(ap.resumeBehavior)
          ..resumeFadeMs = ap.resumeFadeMs;
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
      case GroupParams gp:
        proto.cueType = pb_common.CueType.CUE_TYPE_GROUP;
        proto.group = pb.GroupCueParams()
          ..childCueIds.addAll(gp.childCueIds)
          ..sequential = gp.sequential;
      case NoteParams np:
        proto.cueType = pb_common.CueType.CUE_TYPE_NOTE;
        proto.note = pb.NoteCueParams()
          ..text = np.text
          ..colorHex = np.color != null
              ? '#${np.color!.toARGB32().toRadixString(16).substring(2).toUpperCase()}'
              : '';
      case FadeParams fp:
        proto.cueType = pb_common.CueType.CUE_TYPE_FADE;
        proto.fade = pb.FadeCueParams()
          ..targetCueId = fp.targetCueId
          ..targetCueNumber = fp.targetCueNumber
          ..action = _fadeActionToProto(fp.action)
          ..targetVolumeDb = fp.targetVolumeDb
          ..durationMs = fp.durationMs
          ..stopWhenDone = fp.stopWhenDone;
      default:
        break;
    }

    return proto;
  }
}
