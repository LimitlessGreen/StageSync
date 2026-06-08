// This is a generated file - do not edit.
//
// Generated from stagesync/v1/node.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class NodeEvent_Type extends $pb.ProtobufEnum {
  static const NodeEvent_Type TYPE_UNSPECIFIED =
      NodeEvent_Type._(0, _omitEnumNames ? '' : 'TYPE_UNSPECIFIED');
  static const NodeEvent_Type TYPE_REGISTERED =
      NodeEvent_Type._(1, _omitEnumNames ? '' : 'TYPE_REGISTERED');
  static const NodeEvent_Type TYPE_UNREGISTERED =
      NodeEvent_Type._(2, _omitEnumNames ? '' : 'TYPE_UNREGISTERED');
  static const NodeEvent_Type TYPE_OFFLINE =
      NodeEvent_Type._(3, _omitEnumNames ? '' : 'TYPE_OFFLINE');
  static const NodeEvent_Type TYPE_ONLINE =
      NodeEvent_Type._(4, _omitEnumNames ? '' : 'TYPE_ONLINE');
  static const NodeEvent_Type TYPE_CAPS_UPDATED =
      NodeEvent_Type._(5, _omitEnumNames ? '' : 'TYPE_CAPS_UPDATED');

  static const $core.List<NodeEvent_Type> values = <NodeEvent_Type>[
    TYPE_UNSPECIFIED,
    TYPE_REGISTERED,
    TYPE_UNREGISTERED,
    TYPE_OFFLINE,
    TYPE_ONLINE,
    TYPE_CAPS_UPDATED,
  ];

  static final $core.List<NodeEvent_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static NodeEvent_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeEvent_Type._(super.value, super.name);
}

class LedFeedbackCommand_Color extends $pb.ProtobufEnum {
  static const LedFeedbackCommand_Color LED_OFF =
      LedFeedbackCommand_Color._(0, _omitEnumNames ? '' : 'LED_OFF');
  static const LedFeedbackCommand_Color LED_GREEN =
      LedFeedbackCommand_Color._(1, _omitEnumNames ? '' : 'LED_GREEN');
  static const LedFeedbackCommand_Color LED_GREEN_BLINK =
      LedFeedbackCommand_Color._(2, _omitEnumNames ? '' : 'LED_GREEN_BLINK');
  static const LedFeedbackCommand_Color LED_RED =
      LedFeedbackCommand_Color._(3, _omitEnumNames ? '' : 'LED_RED');
  static const LedFeedbackCommand_Color LED_RED_BLINK =
      LedFeedbackCommand_Color._(4, _omitEnumNames ? '' : 'LED_RED_BLINK');
  static const LedFeedbackCommand_Color LED_YELLOW =
      LedFeedbackCommand_Color._(5, _omitEnumNames ? '' : 'LED_YELLOW');
  static const LedFeedbackCommand_Color LED_YELLOW_BLINK =
      LedFeedbackCommand_Color._(6, _omitEnumNames ? '' : 'LED_YELLOW_BLINK');

  static const $core.List<LedFeedbackCommand_Color> values =
      <LedFeedbackCommand_Color>[
    LED_OFF,
    LED_GREEN,
    LED_GREEN_BLINK,
    LED_RED,
    LED_RED_BLINK,
    LED_YELLOW,
    LED_YELLOW_BLINK,
  ];

  static final $core.List<LedFeedbackCommand_Color?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static LedFeedbackCommand_Color? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LedFeedbackCommand_Color._(super.value, super.name);
}

class AudioTestSignalCommand_Kind extends $pb.ProtobufEnum {
  static const AudioTestSignalCommand_Kind KIND_TONE =
      AudioTestSignalCommand_Kind._(0, _omitEnumNames ? '' : 'KIND_TONE');
  static const AudioTestSignalCommand_Kind KIND_SWEEP =
      AudioTestSignalCommand_Kind._(1, _omitEnumNames ? '' : 'KIND_SWEEP');

  static const $core.List<AudioTestSignalCommand_Kind> values =
      <AudioTestSignalCommand_Kind>[
    KIND_TONE,
    KIND_SWEEP,
  ];

  static final $core.List<AudioTestSignalCommand_Kind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static AudioTestSignalCommand_Kind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AudioTestSignalCommand_Kind._(super.value, super.name);
}

class AudioTalkbackControlCommand_Action extends $pb.ProtobufEnum {
  static const AudioTalkbackControlCommand_Action ACTION_START =
      AudioTalkbackControlCommand_Action._(
          0, _omitEnumNames ? '' : 'ACTION_START');
  static const AudioTalkbackControlCommand_Action ACTION_STOP =
      AudioTalkbackControlCommand_Action._(
          1, _omitEnumNames ? '' : 'ACTION_STOP');
  static const AudioTalkbackControlCommand_Action ACTION_DUCK =
      AudioTalkbackControlCommand_Action._(
          2, _omitEnumNames ? '' : 'ACTION_DUCK');

  static const $core.List<AudioTalkbackControlCommand_Action> values =
      <AudioTalkbackControlCommand_Action>[
    ACTION_START,
    ACTION_STOP,
    ACTION_DUCK,
  ];

  static final $core.List<AudioTalkbackControlCommand_Action?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static AudioTalkbackControlCommand_Action? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AudioTalkbackControlCommand_Action._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
