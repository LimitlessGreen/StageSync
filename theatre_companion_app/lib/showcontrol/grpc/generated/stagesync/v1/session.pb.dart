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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pb.dart' as $2;
import 'session.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'session.pbenum.dart';

class Session extends $pb.GeneratedMessage {
  factory Session({
    $core.String? sessionId,
    $core.String? name,
    $core.String? showName,
    $core.bool? passwordProtected,
    $core.String? masterNodeId,
    $core.Iterable<$2.NodeInfo>? nodes,
    $2.Timestamp? createdAt,
    $core.bool? persistent,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (name != null) result.name = name;
    if (showName != null) result.showName = showName;
    if (passwordProtected != null) result.passwordProtected = passwordProtected;
    if (masterNodeId != null) result.masterNodeId = masterNodeId;
    if (nodes != null) result.nodes.addAll(nodes);
    if (createdAt != null) result.createdAt = createdAt;
    if (persistent != null) result.persistent = persistent;
    return result;
  }

  Session._();

  factory Session.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Session.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Session',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'showName')
    ..aOB(4, _omitFieldNames ? '' : 'passwordProtected')
    ..aOS(5, _omitFieldNames ? '' : 'masterNodeId')
    ..pPM<$2.NodeInfo>(6, _omitFieldNames ? '' : 'nodes',
        subBuilder: $2.NodeInfo.create)
    ..aOM<$2.Timestamp>(7, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..aOB(8, _omitFieldNames ? '' : 'persistent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Session clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Session copyWith(void Function(Session) updates) =>
      super.copyWith((message) => updates(message as Session)) as Session;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Session create() => Session._();
  @$core.override
  Session createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Session getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Session>(create);
  static Session? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get showName => $_getSZ(2);
  @$pb.TagNumber(3)
  set showName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasShowName() => $_has(2);
  @$pb.TagNumber(3)
  void clearShowName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get passwordProtected => $_getBF(3);
  @$pb.TagNumber(4)
  set passwordProtected($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPasswordProtected() => $_has(3);
  @$pb.TagNumber(4)
  void clearPasswordProtected() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get masterNodeId => $_getSZ(4);
  @$pb.TagNumber(5)
  set masterNodeId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMasterNodeId() => $_has(4);
  @$pb.TagNumber(5)
  void clearMasterNodeId() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$2.NodeInfo> get nodes => $_getList(5);

  @$pb.TagNumber(7)
  $2.Timestamp get createdAt => $_getN(6);
  @$pb.TagNumber(7)
  set createdAt($2.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.Timestamp ensureCreatedAt() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.bool get persistent => $_getBF(7);
  @$pb.TagNumber(8)
  set persistent($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPersistent() => $_has(7);
  @$pb.TagNumber(8)
  void clearPersistent() => $_clearField(8);
}

class CreateSessionRequest extends $pb.GeneratedMessage {
  factory CreateSessionRequest({
    $core.String? sessionName,
    $core.String? showName,
    $core.String? password,
    $2.NodeInfo? myNode,
    $core.bool? persistent,
  }) {
    final result = create();
    if (sessionName != null) result.sessionName = sessionName;
    if (showName != null) result.showName = showName;
    if (password != null) result.password = password;
    if (myNode != null) result.myNode = myNode;
    if (persistent != null) result.persistent = persistent;
    return result;
  }

  CreateSessionRequest._();

  factory CreateSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionName')
    ..aOS(2, _omitFieldNames ? '' : 'showName')
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..aOM<$2.NodeInfo>(4, _omitFieldNames ? '' : 'myNode',
        subBuilder: $2.NodeInfo.create)
    ..aOB(5, _omitFieldNames ? '' : 'persistent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionRequest copyWith(void Function(CreateSessionRequest) updates) =>
      super.copyWith((message) => updates(message as CreateSessionRequest))
          as CreateSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateSessionRequest create() => CreateSessionRequest._();
  @$core.override
  CreateSessionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSessionRequest>(create);
  static CreateSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionName => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionName() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get showName => $_getSZ(1);
  @$pb.TagNumber(2)
  set showName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasShowName() => $_has(1);
  @$pb.TagNumber(2)
  void clearShowName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);

  @$pb.TagNumber(4)
  $2.NodeInfo get myNode => $_getN(3);
  @$pb.TagNumber(4)
  set myNode($2.NodeInfo value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMyNode() => $_has(3);
  @$pb.TagNumber(4)
  void clearMyNode() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.NodeInfo ensureMyNode() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get persistent => $_getBF(4);
  @$pb.TagNumber(5)
  set persistent($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPersistent() => $_has(4);
  @$pb.TagNumber(5)
  void clearPersistent() => $_clearField(5);
}

class JoinSessionRequest extends $pb.GeneratedMessage {
  factory JoinSessionRequest({
    $core.String? sessionId,
    $core.String? password,
    $2.NodeInfo? myNode,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (password != null) result.password = password;
    if (myNode != null) result.myNode = myNode;
    return result;
  }

  JoinSessionRequest._();

  factory JoinSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JoinSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JoinSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..aOM<$2.NodeInfo>(3, _omitFieldNames ? '' : 'myNode',
        subBuilder: $2.NodeInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinSessionRequest copyWith(void Function(JoinSessionRequest) updates) =>
      super.copyWith((message) => updates(message as JoinSessionRequest))
          as JoinSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JoinSessionRequest create() => JoinSessionRequest._();
  @$core.override
  JoinSessionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JoinSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JoinSessionRequest>(create);
  static JoinSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);

  @$pb.TagNumber(3)
  $2.NodeInfo get myNode => $_getN(2);
  @$pb.TagNumber(3)
  set myNode($2.NodeInfo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMyNode() => $_has(2);
  @$pb.TagNumber(3)
  void clearMyNode() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.NodeInfo ensureMyNode() => $_ensure(2);
}

class LeaveSessionRequest extends $pb.GeneratedMessage {
  factory LeaveSessionRequest({
    $core.String? sessionId,
    $core.String? nodeId,
    $core.String? token,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (nodeId != null) result.nodeId = nodeId;
    if (token != null) result.token = token;
    return result;
  }

  LeaveSessionRequest._();

  factory LeaveSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LeaveSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LeaveSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'nodeId')
    ..aOS(3, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveSessionRequest copyWith(void Function(LeaveSessionRequest) updates) =>
      super.copyWith((message) => updates(message as LeaveSessionRequest))
          as LeaveSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LeaveSessionRequest create() => LeaveSessionRequest._();
  @$core.override
  LeaveSessionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LeaveSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LeaveSessionRequest>(create);
  static LeaveSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get nodeId => $_getSZ(1);
  @$pb.TagNumber(2)
  set nodeId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNodeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNodeId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get token => $_getSZ(2);
  @$pb.TagNumber(3)
  set token($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearToken() => $_clearField(3);
}

class SessionResponse extends $pb.GeneratedMessage {
  factory SessionResponse({
    Session? session,
    $core.String? token,
    $2.NodeInfo? assignedNode,
  }) {
    final result = create();
    if (session != null) result.session = session;
    if (token != null) result.token = token;
    if (assignedNode != null) result.assignedNode = assignedNode;
    return result;
  }

  SessionResponse._();

  factory SessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.create)
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOM<$2.NodeInfo>(3, _omitFieldNames ? '' : 'assignedNode',
        subBuilder: $2.NodeInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionResponse copyWith(void Function(SessionResponse) updates) =>
      super.copyWith((message) => updates(message as SessionResponse))
          as SessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionResponse create() => SessionResponse._();
  @$core.override
  SessionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SessionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionResponse>(create);
  static SessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);

  @$pb.TagNumber(3)
  $2.NodeInfo get assignedNode => $_getN(2);
  @$pb.TagNumber(3)
  set assignedNode($2.NodeInfo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAssignedNode() => $_has(2);
  @$pb.TagNumber(3)
  void clearAssignedNode() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.NodeInfo ensureAssignedNode() => $_ensure(2);
}

class HeartbeatRequest extends $pb.GeneratedMessage {
  factory HeartbeatRequest({
    $core.String? sessionId,
    $core.String? nodeId,
    $core.String? token,
    $fixnum.Int64? unixMillis,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (nodeId != null) result.nodeId = nodeId;
    if (token != null) result.token = token;
    if (unixMillis != null) result.unixMillis = unixMillis;
    return result;
  }

  HeartbeatRequest._();

  factory HeartbeatRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HeartbeatRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeartbeatRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'nodeId')
    ..aOS(3, _omitFieldNames ? '' : 'token')
    ..aInt64(4, _omitFieldNames ? '' : 'unixMillis')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeartbeatRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeartbeatRequest copyWith(void Function(HeartbeatRequest) updates) =>
      super.copyWith((message) => updates(message as HeartbeatRequest))
          as HeartbeatRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeartbeatRequest create() => HeartbeatRequest._();
  @$core.override
  HeartbeatRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HeartbeatRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeartbeatRequest>(create);
  static HeartbeatRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get nodeId => $_getSZ(1);
  @$pb.TagNumber(2)
  set nodeId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNodeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNodeId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get token => $_getSZ(2);
  @$pb.TagNumber(3)
  set token($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearToken() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get unixMillis => $_getI64(3);
  @$pb.TagNumber(4)
  set unixMillis($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUnixMillis() => $_has(3);
  @$pb.TagNumber(4)
  void clearUnixMillis() => $_clearField(4);
}

class HeartbeatResponse extends $pb.GeneratedMessage {
  factory HeartbeatResponse({
    $fixnum.Int64? serverUnixMillis,
    $core.bool? sessionHealthy,
  }) {
    final result = create();
    if (serverUnixMillis != null) result.serverUnixMillis = serverUnixMillis;
    if (sessionHealthy != null) result.sessionHealthy = sessionHealthy;
    return result;
  }

  HeartbeatResponse._();

  factory HeartbeatResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HeartbeatResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeartbeatResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'serverUnixMillis')
    ..aOB(2, _omitFieldNames ? '' : 'sessionHealthy')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeartbeatResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeartbeatResponse copyWith(void Function(HeartbeatResponse) updates) =>
      super.copyWith((message) => updates(message as HeartbeatResponse))
          as HeartbeatResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeartbeatResponse create() => HeartbeatResponse._();
  @$core.override
  HeartbeatResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HeartbeatResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeartbeatResponse>(create);
  static HeartbeatResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get serverUnixMillis => $_getI64(0);
  @$pb.TagNumber(1)
  set serverUnixMillis($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerUnixMillis() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerUnixMillis() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get sessionHealthy => $_getBF(1);
  @$pb.TagNumber(2)
  set sessionHealthy($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionHealthy() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionHealthy() => $_clearField(2);
}

class WatchSessionRequest extends $pb.GeneratedMessage {
  factory WatchSessionRequest({
    $core.String? sessionId,
    $core.String? nodeId,
    $core.String? token,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (nodeId != null) result.nodeId = nodeId;
    if (token != null) result.token = token;
    return result;
  }

  WatchSessionRequest._();

  factory WatchSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'nodeId')
    ..aOS(3, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchSessionRequest copyWith(void Function(WatchSessionRequest) updates) =>
      super.copyWith((message) => updates(message as WatchSessionRequest))
          as WatchSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchSessionRequest create() => WatchSessionRequest._();
  @$core.override
  WatchSessionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchSessionRequest>(create);
  static WatchSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get nodeId => $_getSZ(1);
  @$pb.TagNumber(2)
  set nodeId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNodeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNodeId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get token => $_getSZ(2);
  @$pb.TagNumber(3)
  set token($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearToken() => $_clearField(3);
}

class SessionEvent extends $pb.GeneratedMessage {
  factory SessionEvent({
    SessionEvent_Type? type,
    Session? session,
    $2.NodeInfo? affectedNode,
    $2.Timestamp? occurredAt,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (session != null) result.session = session;
    if (affectedNode != null) result.affectedNode = affectedNode;
    if (occurredAt != null) result.occurredAt = occurredAt;
    return result;
  }

  SessionEvent._();

  factory SessionEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aE<SessionEvent_Type>(1, _omitFieldNames ? '' : 'type',
        enumValues: SessionEvent_Type.values)
    ..aOM<Session>(2, _omitFieldNames ? '' : 'session',
        subBuilder: Session.create)
    ..aOM<$2.NodeInfo>(3, _omitFieldNames ? '' : 'affectedNode',
        subBuilder: $2.NodeInfo.create)
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'occurredAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionEvent copyWith(void Function(SessionEvent) updates) =>
      super.copyWith((message) => updates(message as SessionEvent))
          as SessionEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionEvent create() => SessionEvent._();
  @$core.override
  SessionEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SessionEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionEvent>(create);
  static SessionEvent? _defaultInstance;

  @$pb.TagNumber(1)
  SessionEvent_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SessionEvent_Type value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  Session get session => $_getN(1);
  @$pb.TagNumber(2)
  set session(Session value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSession() => $_has(1);
  @$pb.TagNumber(2)
  void clearSession() => $_clearField(2);
  @$pb.TagNumber(2)
  Session ensureSession() => $_ensure(1);

  @$pb.TagNumber(3)
  $2.NodeInfo get affectedNode => $_getN(2);
  @$pb.TagNumber(3)
  set affectedNode($2.NodeInfo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAffectedNode() => $_has(2);
  @$pb.TagNumber(3)
  void clearAffectedNode() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.NodeInfo ensureAffectedNode() => $_ensure(2);

  @$pb.TagNumber(4)
  $2.Timestamp get occurredAt => $_getN(3);
  @$pb.TagNumber(4)
  set occurredAt($2.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOccurredAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearOccurredAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensureOccurredAt() => $_ensure(3);
}

class ListSessionsRequest extends $pb.GeneratedMessage {
  factory ListSessionsRequest() => create();

  ListSessionsRequest._();

  factory ListSessionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSessionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSessionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsRequest copyWith(void Function(ListSessionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListSessionsRequest))
          as ListSessionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSessionsRequest create() => ListSessionsRequest._();
  @$core.override
  ListSessionsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSessionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSessionsRequest>(create);
  static ListSessionsRequest? _defaultInstance;
}

class ListSessionsResponse extends $pb.GeneratedMessage {
  factory ListSessionsResponse({
    $core.Iterable<Session>? sessions,
  }) {
    final result = create();
    if (sessions != null) result.sessions.addAll(sessions);
    return result;
  }

  ListSessionsResponse._();

  factory ListSessionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSessionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSessionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..pPM<Session>(1, _omitFieldNames ? '' : 'sessions',
        subBuilder: Session.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsResponse copyWith(void Function(ListSessionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListSessionsResponse))
          as ListSessionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSessionsResponse create() => ListSessionsResponse._();
  @$core.override
  ListSessionsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSessionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSessionsResponse>(create);
  static ListSessionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Session> get sessions => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
