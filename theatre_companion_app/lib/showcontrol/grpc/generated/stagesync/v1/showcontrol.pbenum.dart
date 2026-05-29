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

class ShowStateEvent_Type extends $pb.ProtobufEnum {
  static const ShowStateEvent_Type TYPE_UNSPECIFIED =
      ShowStateEvent_Type._(0, _omitEnumNames ? '' : 'TYPE_UNSPECIFIED');
  static const ShowStateEvent_Type TYPE_CUE_STARTED =
      ShowStateEvent_Type._(1, _omitEnumNames ? '' : 'TYPE_CUE_STARTED');
  static const ShowStateEvent_Type TYPE_CUE_STOPPED =
      ShowStateEvent_Type._(2, _omitEnumNames ? '' : 'TYPE_CUE_STOPPED');
  static const ShowStateEvent_Type TYPE_CUE_PAUSED =
      ShowStateEvent_Type._(3, _omitEnumNames ? '' : 'TYPE_CUE_PAUSED');
  static const ShowStateEvent_Type TYPE_CUE_DONE =
      ShowStateEvent_Type._(4, _omitEnumNames ? '' : 'TYPE_CUE_DONE');
  static const ShowStateEvent_Type TYPE_CUE_ERROR =
      ShowStateEvent_Type._(5, _omitEnumNames ? '' : 'TYPE_CUE_ERROR');
  static const ShowStateEvent_Type TYPE_LIST_UPDATED =
      ShowStateEvent_Type._(6, _omitEnumNames ? '' : 'TYPE_LIST_UPDATED');
  static const ShowStateEvent_Type TYPE_POSITION_CHANGED =
      ShowStateEvent_Type._(7, _omitEnumNames ? '' : 'TYPE_POSITION_CHANGED');

  static const $core.List<ShowStateEvent_Type> values = <ShowStateEvent_Type>[
    TYPE_UNSPECIFIED,
    TYPE_CUE_STARTED,
    TYPE_CUE_STOPPED,
    TYPE_CUE_PAUSED,
    TYPE_CUE_DONE,
    TYPE_CUE_ERROR,
    TYPE_LIST_UPDATED,
    TYPE_POSITION_CHANGED,
  ];

  static final $core.List<ShowStateEvent_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static ShowStateEvent_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ShowStateEvent_Type._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
