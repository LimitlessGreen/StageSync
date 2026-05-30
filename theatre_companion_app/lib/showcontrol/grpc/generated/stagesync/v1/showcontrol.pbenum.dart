// This is a generated file - do not edit.
//
// Generated from stagesync/v1/showcontrol.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// ── Pause / Resume Verhalten ──────────────────────────────────────────────
class AudioCueParams_PauseBehavior extends $pb.ProtobufEnum {
  static const AudioCueParams_PauseBehavior PAUSE_HARD =
      AudioCueParams_PauseBehavior._(0, _omitEnumNames ? '' : 'PAUSE_HARD');
  static const AudioCueParams_PauseBehavior PAUSE_FADE_OUT =
      AudioCueParams_PauseBehavior._(1, _omitEnumNames ? '' : 'PAUSE_FADE_OUT');

  static const $core.List<AudioCueParams_PauseBehavior> values =
      <AudioCueParams_PauseBehavior>[
    PAUSE_HARD,
    PAUSE_FADE_OUT,
  ];

  static final $core.List<AudioCueParams_PauseBehavior?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static AudioCueParams_PauseBehavior? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AudioCueParams_PauseBehavior._(super.value, super.name);
}

class AudioCueParams_ResumeBehavior extends $pb.ProtobufEnum {
  static const AudioCueParams_ResumeBehavior RESUME_CONTINUE =
      AudioCueParams_ResumeBehavior._(
          0, _omitEnumNames ? '' : 'RESUME_CONTINUE');
  static const AudioCueParams_ResumeBehavior RESUME_FADE_IN =
      AudioCueParams_ResumeBehavior._(
          1, _omitEnumNames ? '' : 'RESUME_FADE_IN');
  static const AudioCueParams_ResumeBehavior RESUME_FROM_START =
      AudioCueParams_ResumeBehavior._(
          2, _omitEnumNames ? '' : 'RESUME_FROM_START');

  static const $core.List<AudioCueParams_ResumeBehavior> values =
      <AudioCueParams_ResumeBehavior>[
    RESUME_CONTINUE,
    RESUME_FADE_IN,
    RESUME_FROM_START,
  ];

  static final $core.List<AudioCueParams_ResumeBehavior?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static AudioCueParams_ResumeBehavior? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AudioCueParams_ResumeBehavior._(super.value, super.name);
}

class MaOscCueParams_MaCommand extends $pb.ProtobufEnum {
  static const MaOscCueParams_MaCommand MA_CMD_UNSPECIFIED =
      MaOscCueParams_MaCommand._(0, _omitEnumNames ? '' : 'MA_CMD_UNSPECIFIED');
  static const MaOscCueParams_MaCommand MA_CMD_GO =
      MaOscCueParams_MaCommand._(1, _omitEnumNames ? '' : 'MA_CMD_GO');
  static const MaOscCueParams_MaCommand MA_CMD_OFF =
      MaOscCueParams_MaCommand._(2, _omitEnumNames ? '' : 'MA_CMD_OFF');
  static const MaOscCueParams_MaCommand MA_CMD_PAUSE =
      MaOscCueParams_MaCommand._(3, _omitEnumNames ? '' : 'MA_CMD_PAUSE');
  static const MaOscCueParams_MaCommand MA_CMD_GOTO =
      MaOscCueParams_MaCommand._(4, _omitEnumNames ? '' : 'MA_CMD_GOTO');

  static const $core.List<MaOscCueParams_MaCommand> values =
      <MaOscCueParams_MaCommand>[
    MA_CMD_UNSPECIFIED,
    MA_CMD_GO,
    MA_CMD_OFF,
    MA_CMD_PAUSE,
    MA_CMD_GOTO,
  ];

  static final $core.List<MaOscCueParams_MaCommand?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static MaOscCueParams_MaCommand? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MaOscCueParams_MaCommand._(super.value, super.name);
}

class FadeCueParams_FadeAction extends $pb.ProtobufEnum {
  static const FadeCueParams_FadeAction FADE_ACTION_VOLUME =
      FadeCueParams_FadeAction._(0, _omitEnumNames ? '' : 'FADE_ACTION_VOLUME');
  static const FadeCueParams_FadeAction FADE_ACTION_STOP =
      FadeCueParams_FadeAction._(1, _omitEnumNames ? '' : 'FADE_ACTION_STOP');
  static const FadeCueParams_FadeAction FADE_ACTION_PAUSE =
      FadeCueParams_FadeAction._(2, _omitEnumNames ? '' : 'FADE_ACTION_PAUSE');
  static const FadeCueParams_FadeAction FADE_ACTION_RESUME =
      FadeCueParams_FadeAction._(3, _omitEnumNames ? '' : 'FADE_ACTION_RESUME');

  static const $core.List<FadeCueParams_FadeAction> values =
      <FadeCueParams_FadeAction>[
    FADE_ACTION_VOLUME,
    FADE_ACTION_STOP,
    FADE_ACTION_PAUSE,
    FADE_ACTION_RESUME,
  ];

  static final $core.List<FadeCueParams_FadeAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static FadeCueParams_FadeAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FadeCueParams_FadeAction._(super.value, super.name);
}

class ShowDefinitionEvent_DefinitionEventType extends $pb.ProtobufEnum {
  static const ShowDefinitionEvent_DefinitionEventType DEFINITION_SNAPSHOT =
      ShowDefinitionEvent_DefinitionEventType._(
          0, _omitEnumNames ? '' : 'DEFINITION_SNAPSHOT');
  static const ShowDefinitionEvent_DefinitionEventType CUE_LIST_CHANGED =
      ShowDefinitionEvent_DefinitionEventType._(
          1, _omitEnumNames ? '' : 'CUE_LIST_CHANGED');
  static const ShowDefinitionEvent_DefinitionEventType PATCH_CONFIG_CHANGED =
      ShowDefinitionEvent_DefinitionEventType._(
          2, _omitEnumNames ? '' : 'PATCH_CONFIG_CHANGED');

  static const $core.List<ShowDefinitionEvent_DefinitionEventType> values =
      <ShowDefinitionEvent_DefinitionEventType>[
    DEFINITION_SNAPSHOT,
    CUE_LIST_CHANGED,
    PATCH_CONFIG_CHANGED,
  ];

  static final $core.List<ShowDefinitionEvent_DefinitionEventType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ShowDefinitionEvent_DefinitionEventType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ShowDefinitionEvent_DefinitionEventType._(super.value, super.name);
}

class ShowExecutionEvent_ExecutionEventType extends $pb.ProtobufEnum {
  static const ShowExecutionEvent_ExecutionEventType EXECUTION_SNAPSHOT =
      ShowExecutionEvent_ExecutionEventType._(
          0, _omitEnumNames ? '' : 'EXECUTION_SNAPSHOT');
  static const ShowExecutionEvent_ExecutionEventType CUE_STARTED =
      ShowExecutionEvent_ExecutionEventType._(
          1, _omitEnumNames ? '' : 'CUE_STARTED');
  static const ShowExecutionEvent_ExecutionEventType CUE_PAUSED =
      ShowExecutionEvent_ExecutionEventType._(
          2, _omitEnumNames ? '' : 'CUE_PAUSED');
  static const ShowExecutionEvent_ExecutionEventType CUE_RESUMED =
      ShowExecutionEvent_ExecutionEventType._(
          3, _omitEnumNames ? '' : 'CUE_RESUMED');
  static const ShowExecutionEvent_ExecutionEventType CUE_STOPPED =
      ShowExecutionEvent_ExecutionEventType._(
          4, _omitEnumNames ? '' : 'CUE_STOPPED');
  static const ShowExecutionEvent_ExecutionEventType CUE_DONE =
      ShowExecutionEvent_ExecutionEventType._(
          5, _omitEnumNames ? '' : 'CUE_DONE');
  static const ShowExecutionEvent_ExecutionEventType CUE_ERROR =
      ShowExecutionEvent_ExecutionEventType._(
          6, _omitEnumNames ? '' : 'CUE_ERROR');

  static const $core.List<ShowExecutionEvent_ExecutionEventType> values =
      <ShowExecutionEvent_ExecutionEventType>[
    EXECUTION_SNAPSHOT,
    CUE_STARTED,
    CUE_PAUSED,
    CUE_RESUMED,
    CUE_STOPPED,
    CUE_DONE,
    CUE_ERROR,
  ];

  static final $core.List<ShowExecutionEvent_ExecutionEventType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static ShowExecutionEvent_ExecutionEventType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ShowExecutionEvent_ExecutionEventType._(super.value, super.name);
}

class NodeHealthEvent_HealthEventType extends $pb.ProtobufEnum {
  static const NodeHealthEvent_HealthEventType HEALTH_SNAPSHOT =
      NodeHealthEvent_HealthEventType._(
          0, _omitEnumNames ? '' : 'HEALTH_SNAPSHOT');
  static const NodeHealthEvent_HealthEventType NODE_ONLINE =
      NodeHealthEvent_HealthEventType._(1, _omitEnumNames ? '' : 'NODE_ONLINE');
  static const NodeHealthEvent_HealthEventType NODE_OFFLINE =
      NodeHealthEvent_HealthEventType._(
          2, _omitEnumNames ? '' : 'NODE_OFFLINE');
  static const NodeHealthEvent_HealthEventType NODE_DEGRADED =
      NodeHealthEvent_HealthEventType._(
          3, _omitEnumNames ? '' : 'NODE_DEGRADED');
  static const NodeHealthEvent_HealthEventType CLOCK_DELTA =
      NodeHealthEvent_HealthEventType._(4, _omitEnumNames ? '' : 'CLOCK_DELTA');

  static const $core.List<NodeHealthEvent_HealthEventType> values =
      <NodeHealthEvent_HealthEventType>[
    HEALTH_SNAPSHOT,
    NODE_ONLINE,
    NODE_OFFLINE,
    NODE_DEGRADED,
    CLOCK_DELTA,
  ];

  static final $core.List<NodeHealthEvent_HealthEventType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static NodeHealthEvent_HealthEventType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeHealthEvent_HealthEventType._(super.value, super.name);
}

class MediaSyncEvent_MediaEventType extends $pb.ProtobufEnum {
  static const MediaSyncEvent_MediaEventType MEDIA_SNAPSHOT =
      MediaSyncEvent_MediaEventType._(
          0, _omitEnumNames ? '' : 'MEDIA_SNAPSHOT');
  static const MediaSyncEvent_MediaEventType ASSET_ADDED =
      MediaSyncEvent_MediaEventType._(1, _omitEnumNames ? '' : 'ASSET_ADDED');
  static const MediaSyncEvent_MediaEventType ASSET_REMOVED =
      MediaSyncEvent_MediaEventType._(2, _omitEnumNames ? '' : 'ASSET_REMOVED');
  static const MediaSyncEvent_MediaEventType ASSET_UPDATED =
      MediaSyncEvent_MediaEventType._(3, _omitEnumNames ? '' : 'ASSET_UPDATED');

  static const $core.List<MediaSyncEvent_MediaEventType> values =
      <MediaSyncEvent_MediaEventType>[
    MEDIA_SNAPSHOT,
    ASSET_ADDED,
    ASSET_REMOVED,
    ASSET_UPDATED,
  ];

  static final $core.List<MediaSyncEvent_MediaEventType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static MediaSyncEvent_MediaEventType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MediaSyncEvent_MediaEventType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
