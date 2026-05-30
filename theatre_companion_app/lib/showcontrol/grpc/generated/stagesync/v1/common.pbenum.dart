// This is a generated file - do not edit.
//
// Generated from stagesync/v1/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// NodeType: Primäre Gerätekategorie (für Routing, backward-compat).
/// Für Capability-Auswahl: siehe NodeTask.
class NodeType extends $pb.ProtobufEnum {
  static const NodeType NODE_TYPE_UNSPECIFIED =
      NodeType._(0, _omitEnumNames ? '' : 'NODE_TYPE_UNSPECIFIED');
  static const NodeType NODE_TYPE_MASTER =
      NodeType._(1, _omitEnumNames ? '' : 'NODE_TYPE_MASTER');
  static const NodeType NODE_TYPE_AUDIO =
      NodeType._(2, _omitEnumNames ? '' : 'NODE_TYPE_AUDIO');
  static const NodeType NODE_TYPE_VIEWER =
      NodeType._(3, _omitEnumNames ? '' : 'NODE_TYPE_VIEWER');
  static const NodeType NODE_TYPE_MA =
      NodeType._(4, _omitEnumNames ? '' : 'NODE_TYPE_MA');
  static const NodeType NODE_TYPE_LIGHTING =
      NodeType._(5, _omitEnumNames ? '' : 'NODE_TYPE_LIGHTING');

  static const $core.List<NodeType> values = <NodeType>[
    NODE_TYPE_UNSPECIFIED,
    NODE_TYPE_MASTER,
    NODE_TYPE_AUDIO,
    NODE_TYPE_VIEWER,
    NODE_TYPE_MA,
    NODE_TYPE_LIGHTING,
  ];

  static final $core.List<NodeType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static NodeType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeType._(super.value, super.name);
}

class NodeRole extends $pb.ProtobufEnum {
  static const NodeRole NODE_ROLE_UNSPECIFIED =
      NodeRole._(0, _omitEnumNames ? '' : 'NODE_ROLE_UNSPECIFIED');
  static const NodeRole NODE_ROLE_MASTER =
      NodeRole._(1, _omitEnumNames ? '' : 'NODE_ROLE_MASTER');
  static const NodeRole NODE_ROLE_BACKUP =
      NodeRole._(2, _omitEnumNames ? '' : 'NODE_ROLE_BACKUP');
  static const NodeRole NODE_ROLE_CLIENT =
      NodeRole._(3, _omitEnumNames ? '' : 'NODE_ROLE_CLIENT');
  static const NodeRole NODE_ROLE_VIEWER =
      NodeRole._(4, _omitEnumNames ? '' : 'NODE_ROLE_VIEWER');

  static const $core.List<NodeRole> values = <NodeRole>[
    NODE_ROLE_UNSPECIFIED,
    NODE_ROLE_MASTER,
    NODE_ROLE_BACKUP,
    NODE_ROLE_CLIENT,
    NODE_ROLE_VIEWER,
  ];

  static final $core.List<NodeRole?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static NodeRole? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeRole._(super.value, super.name);
}

/// NodeTask: Aufgaben, die ein Node gleichzeitig übernehmen kann.
/// Ein Gerät kann z.B. MASTER + AUDIO_OUTPUT + EDITOR gleichzeitig sein.
class NodeTask extends $pb.ProtobufEnum {
  static const NodeTask NODE_TASK_UNSPECIFIED =
      NodeTask._(0, _omitEnumNames ? '' : 'NODE_TASK_UNSPECIFIED');
  static const NodeTask NODE_TASK_MASTER =
      NodeTask._(1, _omitEnumNames ? '' : 'NODE_TASK_MASTER');
  static const NodeTask NODE_TASK_AUDIO_OUTPUT =
      NodeTask._(2, _omitEnumNames ? '' : 'NODE_TASK_AUDIO_OUTPUT');
  static const NodeTask NODE_TASK_EDITOR =
      NodeTask._(3, _omitEnumNames ? '' : 'NODE_TASK_EDITOR');
  static const NodeTask NODE_TASK_VIEWER =
      NodeTask._(4, _omitEnumNames ? '' : 'NODE_TASK_VIEWER');
  static const NodeTask NODE_TASK_MA_OSC =
      NodeTask._(5, _omitEnumNames ? '' : 'NODE_TASK_MA_OSC');

  static const $core.List<NodeTask> values = <NodeTask>[
    NODE_TASK_UNSPECIFIED,
    NODE_TASK_MASTER,
    NODE_TASK_AUDIO_OUTPUT,
    NODE_TASK_EDITOR,
    NODE_TASK_VIEWER,
    NODE_TASK_MA_OSC,
  ];

  static final $core.List<NodeTask?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static NodeTask? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeTask._(super.value, super.name);
}

class CueType extends $pb.ProtobufEnum {
  static const CueType CUE_TYPE_UNSPECIFIED =
      CueType._(0, _omitEnumNames ? '' : 'CUE_TYPE_UNSPECIFIED');
  static const CueType CUE_TYPE_AUDIO =
      CueType._(1, _omitEnumNames ? '' : 'CUE_TYPE_AUDIO');
  static const CueType CUE_TYPE_MA_OSC =
      CueType._(2, _omitEnumNames ? '' : 'CUE_TYPE_MA_OSC');
  static const CueType CUE_TYPE_WAIT =
      CueType._(3, _omitEnumNames ? '' : 'CUE_TYPE_WAIT');
  static const CueType CUE_TYPE_GROUP =
      CueType._(4, _omitEnumNames ? '' : 'CUE_TYPE_GROUP');
  static const CueType CUE_TYPE_GOTO =
      CueType._(5, _omitEnumNames ? '' : 'CUE_TYPE_GOTO');
  static const CueType CUE_TYPE_NOTE =
      CueType._(6, _omitEnumNames ? '' : 'CUE_TYPE_NOTE');
  static const CueType CUE_TYPE_FADE =
      CueType._(7, _omitEnumNames ? '' : 'CUE_TYPE_FADE');

  static const $core.List<CueType> values = <CueType>[
    CUE_TYPE_UNSPECIFIED,
    CUE_TYPE_AUDIO,
    CUE_TYPE_MA_OSC,
    CUE_TYPE_WAIT,
    CUE_TYPE_GROUP,
    CUE_TYPE_GOTO,
    CUE_TYPE_NOTE,
    CUE_TYPE_FADE,
  ];

  static final $core.List<CueType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static CueType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CueType._(super.value, super.name);
}

class CueState extends $pb.ProtobufEnum {
  static const CueState CUE_STATE_UNSPECIFIED =
      CueState._(0, _omitEnumNames ? '' : 'CUE_STATE_UNSPECIFIED');
  static const CueState CUE_STATE_IDLE =
      CueState._(1, _omitEnumNames ? '' : 'CUE_STATE_IDLE');
  static const CueState CUE_STATE_ARMED =
      CueState._(2, _omitEnumNames ? '' : 'CUE_STATE_ARMED');
  static const CueState CUE_STATE_PLAYING =
      CueState._(3, _omitEnumNames ? '' : 'CUE_STATE_PLAYING');
  static const CueState CUE_STATE_PAUSED =
      CueState._(4, _omitEnumNames ? '' : 'CUE_STATE_PAUSED');
  static const CueState CUE_STATE_DONE =
      CueState._(5, _omitEnumNames ? '' : 'CUE_STATE_DONE');
  static const CueState CUE_STATE_ERROR =
      CueState._(6, _omitEnumNames ? '' : 'CUE_STATE_ERROR');

  static const $core.List<CueState> values = <CueState>[
    CUE_STATE_UNSPECIFIED,
    CUE_STATE_IDLE,
    CUE_STATE_ARMED,
    CUE_STATE_PLAYING,
    CUE_STATE_PAUSED,
    CUE_STATE_DONE,
    CUE_STATE_ERROR,
  ];

  static final $core.List<CueState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static CueState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CueState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
