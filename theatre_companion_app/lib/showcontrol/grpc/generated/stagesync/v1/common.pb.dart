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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'common.pbenum.dart';

class Timestamp extends $pb.GeneratedMessage {
  factory Timestamp({
    $fixnum.Int64? unixMillis,
  }) {
    final result = create();
    if (unixMillis != null) result.unixMillis = unixMillis;
    return result;
  }

  Timestamp._();

  factory Timestamp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Timestamp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Timestamp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'unixMillis')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Timestamp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Timestamp copyWith(void Function(Timestamp) updates) =>
      super.copyWith((message) => updates(message as Timestamp)) as Timestamp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Timestamp create() => Timestamp._();
  @$core.override
  Timestamp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Timestamp getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Timestamp>(create);
  static Timestamp? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get unixMillis => $_getI64(0);
  @$pb.TagNumber(1)
  set unixMillis($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUnixMillis() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnixMillis() => $_clearField(1);
}

class NodeInfo extends $pb.GeneratedMessage {
  factory NodeInfo({
    $core.String? nodeId,
    $core.String? name,
    NodeType? nodeType,
    NodeRole? nodeRole,
    $core.String? address,
    $core.bool? online,
    $core.Iterable<NodeTask>? tasks,
    $core.String? mediaServerUrl,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (name != null) result.name = name;
    if (nodeType != null) result.nodeType = nodeType;
    if (nodeRole != null) result.nodeRole = nodeRole;
    if (address != null) result.address = address;
    if (online != null) result.online = online;
    if (tasks != null) result.tasks.addAll(tasks);
    if (mediaServerUrl != null) result.mediaServerUrl = mediaServerUrl;
    return result;
  }

  NodeInfo._();

  factory NodeInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<NodeType>(3, _omitFieldNames ? '' : 'nodeType',
        enumValues: NodeType.values)
    ..aE<NodeRole>(4, _omitFieldNames ? '' : 'nodeRole',
        enumValues: NodeRole.values)
    ..aOS(5, _omitFieldNames ? '' : 'address')
    ..aOB(6, _omitFieldNames ? '' : 'online')
    ..pc<NodeTask>(7, _omitFieldNames ? '' : 'tasks', $pb.PbFieldType.KE,
        valueOf: NodeTask.valueOf,
        enumValues: NodeTask.values,
        defaultEnumValue: NodeTask.NODE_TASK_UNSPECIFIED)
    ..aOS(8, _omitFieldNames ? '' : 'mediaServerUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeInfo copyWith(void Function(NodeInfo) updates) =>
      super.copyWith((message) => updates(message as NodeInfo)) as NodeInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeInfo create() => NodeInfo._();
  @$core.override
  NodeInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NodeInfo>(create);
  static NodeInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  NodeType get nodeType => $_getN(2);
  @$pb.TagNumber(3)
  set nodeType(NodeType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNodeType() => $_has(2);
  @$pb.TagNumber(3)
  void clearNodeType() => $_clearField(3);

  @$pb.TagNumber(4)
  NodeRole get nodeRole => $_getN(3);
  @$pb.TagNumber(4)
  set nodeRole(NodeRole value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasNodeRole() => $_has(3);
  @$pb.TagNumber(4)
  void clearNodeRole() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get address => $_getSZ(4);
  @$pb.TagNumber(5)
  set address($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAddress() => $_has(4);
  @$pb.TagNumber(5)
  void clearAddress() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get online => $_getBF(5);
  @$pb.TagNumber(6)
  set online($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOnline() => $_has(5);
  @$pb.TagNumber(6)
  void clearOnline() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<NodeTask> get tasks => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get mediaServerUrl => $_getSZ(7);
  @$pb.TagNumber(8)
  set mediaServerUrl($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMediaServerUrl() => $_has(7);
  @$pb.TagNumber(8)
  void clearMediaServerUrl() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
