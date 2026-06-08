// This is a generated file - do not edit.
//
// Generated from stagesync/v1/grid.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class LaunchMode extends $pb.ProtobufEnum {
  static const LaunchMode LAUNCH_TRIGGER =
      LaunchMode._(0, _omitEnumNames ? '' : 'LAUNCH_TRIGGER');
  static const LaunchMode LAUNCH_GATE =
      LaunchMode._(1, _omitEnumNames ? '' : 'LAUNCH_GATE');
  static const LaunchMode LAUNCH_TOGGLE =
      LaunchMode._(2, _omitEnumNames ? '' : 'LAUNCH_TOGGLE');

  static const $core.List<LaunchMode> values = <LaunchMode>[
    LAUNCH_TRIGGER,
    LAUNCH_GATE,
    LAUNCH_TOGGLE,
  ];

  static final $core.List<LaunchMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static LaunchMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LaunchMode._(super.value, super.name);
}

class FollowAction extends $pb.ProtobufEnum {
  static const FollowAction FOLLOW_NONE =
      FollowAction._(0, _omitEnumNames ? '' : 'FOLLOW_NONE');
  static const FollowAction FOLLOW_NEXT_CLIP =
      FollowAction._(1, _omitEnumNames ? '' : 'FOLLOW_NEXT_CLIP');
  static const FollowAction FOLLOW_NEXT_SCENE =
      FollowAction._(2, _omitEnumNames ? '' : 'FOLLOW_NEXT_SCENE');
  static const FollowAction FOLLOW_STOP =
      FollowAction._(3, _omitEnumNames ? '' : 'FOLLOW_STOP');

  static const $core.List<FollowAction> values = <FollowAction>[
    FOLLOW_NONE,
    FOLLOW_NEXT_CLIP,
    FOLLOW_NEXT_SCENE,
    FOLLOW_STOP,
  ];

  static final $core.List<FollowAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static FollowAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FollowAction._(super.value, super.name);
}

class GridQuantize extends $pb.ProtobufEnum {
  static const GridQuantize QUANTIZE_OFF =
      GridQuantize._(0, _omitEnumNames ? '' : 'QUANTIZE_OFF');
  static const GridQuantize QUANTIZE_ON =
      GridQuantize._(1, _omitEnumNames ? '' : 'QUANTIZE_ON');

  static const $core.List<GridQuantize> values = <GridQuantize>[
    QUANTIZE_OFF,
    QUANTIZE_ON,
  ];

  static final $core.List<GridQuantize?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static GridQuantize? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GridQuantize._(super.value, super.name);
}

class GridExecutionEvent_Type extends $pb.ProtobufEnum {
  static const GridExecutionEvent_Type GRID_SNAPSHOT =
      GridExecutionEvent_Type._(0, _omitEnumNames ? '' : 'GRID_SNAPSHOT');
  static const GridExecutionEvent_Type CLIP_LAUNCHED =
      GridExecutionEvent_Type._(1, _omitEnumNames ? '' : 'CLIP_LAUNCHED');
  static const GridExecutionEvent_Type CLIP_PLAYING =
      GridExecutionEvent_Type._(2, _omitEnumNames ? '' : 'CLIP_PLAYING');
  static const GridExecutionEvent_Type CLIP_STOPPED =
      GridExecutionEvent_Type._(3, _omitEnumNames ? '' : 'CLIP_STOPPED');
  static const GridExecutionEvent_Type CLIP_DONE =
      GridExecutionEvent_Type._(4, _omitEnumNames ? '' : 'CLIP_DONE');
  static const GridExecutionEvent_Type CLIP_ERROR =
      GridExecutionEvent_Type._(5, _omitEnumNames ? '' : 'CLIP_ERROR');

  static const $core.List<GridExecutionEvent_Type> values =
      <GridExecutionEvent_Type>[
    GRID_SNAPSHOT,
    CLIP_LAUNCHED,
    CLIP_PLAYING,
    CLIP_STOPPED,
    CLIP_DONE,
    CLIP_ERROR,
  ];

  static final $core.List<GridExecutionEvent_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static GridExecutionEvent_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GridExecutionEvent_Type._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
