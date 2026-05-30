// This is a generated file - do not edit.
//
// Generated from stagesync/v1/media.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ManifestEvent_EventType extends $pb.ProtobufEnum {
  static const ManifestEvent_EventType MANIFEST_SNAPSHOT =
      ManifestEvent_EventType._(0, _omitEnumNames ? '' : 'MANIFEST_SNAPSHOT');
  static const ManifestEvent_EventType ASSET_ADDED =
      ManifestEvent_EventType._(1, _omitEnumNames ? '' : 'ASSET_ADDED');
  static const ManifestEvent_EventType ASSET_REMOVED =
      ManifestEvent_EventType._(2, _omitEnumNames ? '' : 'ASSET_REMOVED');
  static const ManifestEvent_EventType ASSET_UPDATED =
      ManifestEvent_EventType._(3, _omitEnumNames ? '' : 'ASSET_UPDATED');

  static const $core.List<ManifestEvent_EventType> values =
      <ManifestEvent_EventType>[
    MANIFEST_SNAPSHOT,
    ASSET_ADDED,
    ASSET_REMOVED,
    ASSET_UPDATED,
  ];

  static final $core.List<ManifestEvent_EventType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ManifestEvent_EventType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ManifestEvent_EventType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
