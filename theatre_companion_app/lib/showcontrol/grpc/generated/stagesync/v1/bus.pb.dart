// This is a generated file - do not edit.
//
// Generated from stagesync/v1/bus.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'bus.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'bus.pbenum.dart';

/// Ein benannter Summenkanal.
class AudioBus extends $pb.GeneratedMessage {
  factory AudioBus({
    $core.String? id,
    $core.String? name,
    AudioBusType? type,
    $core.double? outputLevelDb,
    $core.bool? muted,
    $core.Iterable<BusNodeAssign>? patch,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (outputLevelDb != null) result.outputLevelDb = outputLevelDb;
    if (muted != null) result.muted = muted;
    if (patch != null) result.patch.addAll(patch);
    return result;
  }

  AudioBus._();

  factory AudioBus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioBus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioBus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<AudioBusType>(3, _omitFieldNames ? '' : 'type',
        enumValues: AudioBusType.values)
    ..aD(4, _omitFieldNames ? '' : 'outputLevelDb',
        fieldType: $pb.PbFieldType.OF)
    ..aOB(5, _omitFieldNames ? '' : 'muted')
    ..pPM<BusNodeAssign>(6, _omitFieldNames ? '' : 'patch',
        subBuilder: BusNodeAssign.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioBus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioBus copyWith(void Function(AudioBus) updates) =>
      super.copyWith((message) => updates(message as AudioBus)) as AudioBus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioBus create() => AudioBus._();
  @$core.override
  AudioBus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioBus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioBus>(create);
  static AudioBus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  AudioBusType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type(AudioBusType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get outputLevelDb => $_getN(3);
  @$pb.TagNumber(4)
  set outputLevelDb($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOutputLevelDb() => $_has(3);
  @$pb.TagNumber(4)
  void clearOutputLevelDb() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get muted => $_getBF(4);
  @$pb.TagNumber(5)
  set muted($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMuted() => $_has(4);
  @$pb.TagNumber(5)
  void clearMuted() => $_clearField(5);

  /// Bus → physische Ausgänge
  @$pb.TagNumber(6)
  $pb.PbList<BusNodeAssign> get patch => $_getList(5);
}

/// Zuordnung eines Buses zu einem Node + Device.
class BusNodeAssign extends $pb.GeneratedMessage {
  factory BusNodeAssign({
    $core.String? nodeId,
    $core.int? deviceIndex,
    $core.String? deviceName,
    $core.int? channelOffset,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (deviceIndex != null) result.deviceIndex = deviceIndex;
    if (deviceName != null) result.deviceName = deviceName;
    if (channelOffset != null) result.channelOffset = channelOffset;
    return result;
  }

  BusNodeAssign._();

  factory BusNodeAssign.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BusNodeAssign.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BusNodeAssign',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aI(2, _omitFieldNames ? '' : 'deviceIndex')
    ..aOS(3, _omitFieldNames ? '' : 'deviceName')
    ..aI(4, _omitFieldNames ? '' : 'channelOffset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BusNodeAssign clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BusNodeAssign copyWith(void Function(BusNodeAssign) updates) =>
      super.copyWith((message) => updates(message as BusNodeAssign))
          as BusNodeAssign;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BusNodeAssign create() => BusNodeAssign._();
  @$core.override
  BusNodeAssign createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BusNodeAssign getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BusNodeAssign>(create);
  static BusNodeAssign? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get deviceIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set deviceIndex($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get deviceName => $_getSZ(2);
  @$pb.TagNumber(3)
  set deviceName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get channelOffset => $_getIZ(3);
  @$pb.TagNumber(4)
  set channelOffset($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChannelOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearChannelOffset() => $_clearField(4);
}

/// Send-Zuweisung einer Source (Cue, Talkback) zu einem Bus.
class BusSend extends $pb.GeneratedMessage {
  factory BusSend({
    $core.String? busId,
    $core.double? sendLevelDb,
    $core.bool? enabled,
  }) {
    final result = create();
    if (busId != null) result.busId = busId;
    if (sendLevelDb != null) result.sendLevelDb = sendLevelDb;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  BusSend._();

  factory BusSend.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BusSend.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BusSend',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'busId')
    ..aD(2, _omitFieldNames ? '' : 'sendLevelDb', fieldType: $pb.PbFieldType.OF)
    ..aOB(3, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BusSend clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BusSend copyWith(void Function(BusSend) updates) =>
      super.copyWith((message) => updates(message as BusSend)) as BusSend;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BusSend create() => BusSend._();
  @$core.override
  BusSend createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BusSend getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BusSend>(create);
  static BusSend? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get busId => $_getSZ(0);
  @$pb.TagNumber(1)
  set busId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBusId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBusId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get sendLevelDb => $_getN(1);
  @$pb.TagNumber(2)
  set sendLevelDb($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSendLevelDb() => $_has(1);
  @$pb.TagNumber(2)
  void clearSendLevelDb() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get enabled => $_getBF(2);
  @$pb.TagNumber(3)
  set enabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnabled() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
