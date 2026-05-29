// This is a generated file - do not edit.
//
// Generated from stagesync/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SessionEvent_Type extends $pb.ProtobufEnum {
  static const SessionEvent_Type TYPE_UNSPECIFIED =
      SessionEvent_Type._(0, _omitEnumNames ? '' : 'TYPE_UNSPECIFIED');
  static const SessionEvent_Type TYPE_NODE_JOINED =
      SessionEvent_Type._(1, _omitEnumNames ? '' : 'TYPE_NODE_JOINED');
  static const SessionEvent_Type TYPE_NODE_LEFT =
      SessionEvent_Type._(2, _omitEnumNames ? '' : 'TYPE_NODE_LEFT');
  static const SessionEvent_Type TYPE_NODE_OFFLINE =
      SessionEvent_Type._(3, _omitEnumNames ? '' : 'TYPE_NODE_OFFLINE');
  static const SessionEvent_Type TYPE_MASTER_CHANGED =
      SessionEvent_Type._(4, _omitEnumNames ? '' : 'TYPE_MASTER_CHANGED');
  static const SessionEvent_Type TYPE_SESSION_CLOSED =
      SessionEvent_Type._(5, _omitEnumNames ? '' : 'TYPE_SESSION_CLOSED');

  static const $core.List<SessionEvent_Type> values = <SessionEvent_Type>[
    TYPE_UNSPECIFIED,
    TYPE_NODE_JOINED,
    TYPE_NODE_LEFT,
    TYPE_NODE_OFFLINE,
    TYPE_MASTER_CHANGED,
    TYPE_SESSION_CLOSED,
  ];

  static final $core.List<SessionEvent_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static SessionEvent_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SessionEvent_Type._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
