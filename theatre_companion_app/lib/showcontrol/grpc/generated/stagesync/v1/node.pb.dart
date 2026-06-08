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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pb.dart' as $2;
import 'node.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'node.pbenum.dart';

class AudioDeviceInfo extends $pb.GeneratedMessage {
  factory AudioDeviceInfo({
    $core.int? index,
    $core.String? name,
    $core.bool? isDefault,
    $core.String? backend,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (name != null) result.name = name;
    if (isDefault != null) result.isDefault = isDefault;
    if (backend != null) result.backend = backend;
    return result;
  }

  AudioDeviceInfo._();

  factory AudioDeviceInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioDeviceInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioDeviceInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOB(3, _omitFieldNames ? '' : 'isDefault')
    ..aOS(4, _omitFieldNames ? '' : 'backend')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioDeviceInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioDeviceInfo copyWith(void Function(AudioDeviceInfo) updates) =>
      super.copyWith((message) => updates(message as AudioDeviceInfo))
          as AudioDeviceInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioDeviceInfo create() => AudioDeviceInfo._();
  @$core.override
  AudioDeviceInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioDeviceInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioDeviceInfo>(create);
  static AudioDeviceInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isDefault => $_getBF(2);
  @$pb.TagNumber(3)
  set isDefault($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsDefault() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsDefault() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get backend => $_getSZ(3);
  @$pb.TagNumber(4)
  set backend($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBackend() => $_has(3);
  @$pb.TagNumber(4)
  void clearBackend() => $_clearField(4);
}

class AudioCapabilities extends $pb.GeneratedMessage {
  factory AudioCapabilities({
    $core.Iterable<$core.String>? outputDevices,
    $core.Iterable<$core.String>? supportedFormats,
    $core.int? maxSimultaneous,
    $core.String? mediaServerUrl,
    $core.Iterable<AudioDeviceInfo>? availableDevices,
    $core.int? selectedDevice,
    $core.String? activeBackend,
    $core.Iterable<$core.String>? backendPriority,
    $core.int? sampleRate,
    $core.int? channels,
  }) {
    final result = create();
    if (outputDevices != null) result.outputDevices.addAll(outputDevices);
    if (supportedFormats != null)
      result.supportedFormats.addAll(supportedFormats);
    if (maxSimultaneous != null) result.maxSimultaneous = maxSimultaneous;
    if (mediaServerUrl != null) result.mediaServerUrl = mediaServerUrl;
    if (availableDevices != null)
      result.availableDevices.addAll(availableDevices);
    if (selectedDevice != null) result.selectedDevice = selectedDevice;
    if (activeBackend != null) result.activeBackend = activeBackend;
    if (backendPriority != null) result.backendPriority.addAll(backendPriority);
    if (sampleRate != null) result.sampleRate = sampleRate;
    if (channels != null) result.channels = channels;
    return result;
  }

  AudioCapabilities._();

  factory AudioCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioCapabilities',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'outputDevices')
    ..pPS(2, _omitFieldNames ? '' : 'supportedFormats')
    ..aI(3, _omitFieldNames ? '' : 'maxSimultaneous')
    ..aOS(4, _omitFieldNames ? '' : 'mediaServerUrl')
    ..pPM<AudioDeviceInfo>(5, _omitFieldNames ? '' : 'availableDevices',
        subBuilder: AudioDeviceInfo.create)
    ..aI(6, _omitFieldNames ? '' : 'selectedDevice')
    ..aOS(7, _omitFieldNames ? '' : 'activeBackend')
    ..pPS(8, _omitFieldNames ? '' : 'backendPriority')
    ..aI(9, _omitFieldNames ? '' : 'sampleRate', fieldType: $pb.PbFieldType.OU3)
    ..aI(10, _omitFieldNames ? '' : 'channels', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioCapabilities copyWith(void Function(AudioCapabilities) updates) =>
      super.copyWith((message) => updates(message as AudioCapabilities))
          as AudioCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioCapabilities create() => AudioCapabilities._();
  @$core.override
  AudioCapabilities createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioCapabilities getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioCapabilities>(create);
  static AudioCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get outputDevices => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get supportedFormats => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get maxSimultaneous => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxSimultaneous($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxSimultaneous() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxSimultaneous() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get mediaServerUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set mediaServerUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMediaServerUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearMediaServerUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<AudioDeviceInfo> get availableDevices => $_getList(4);

  @$pb.TagNumber(6)
  $core.int get selectedDevice => $_getIZ(5);
  @$pb.TagNumber(6)
  set selectedDevice($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSelectedDevice() => $_has(5);
  @$pb.TagNumber(6)
  void clearSelectedDevice() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get activeBackend => $_getSZ(6);
  @$pb.TagNumber(7)
  set activeBackend($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasActiveBackend() => $_has(6);
  @$pb.TagNumber(7)
  void clearActiveBackend() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get backendPriority => $_getList(7);

  @$pb.TagNumber(9)
  $core.int get sampleRate => $_getIZ(8);
  @$pb.TagNumber(9)
  set sampleRate($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSampleRate() => $_has(8);
  @$pb.TagNumber(9)
  void clearSampleRate() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get channels => $_getIZ(9);
  @$pb.TagNumber(10)
  set channels($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasChannels() => $_has(9);
  @$pb.TagNumber(10)
  void clearChannels() => $_clearField(10);
}

class MediaFileInfo extends $pb.GeneratedMessage {
  factory MediaFileInfo({
    $core.String? filename,
    $fixnum.Int64? sizeBytes,
    $core.String? format,
    $fixnum.Int64? durationMs,
    $2.Timestamp? modifiedAt,
  }) {
    final result = create();
    if (filename != null) result.filename = filename;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (format != null) result.format = format;
    if (durationMs != null) result.durationMs = durationMs;
    if (modifiedAt != null) result.modifiedAt = modifiedAt;
    return result;
  }

  MediaFileInfo._();

  factory MediaFileInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MediaFileInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MediaFileInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'filename')
    ..aInt64(2, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(3, _omitFieldNames ? '' : 'format')
    ..aInt64(4, _omitFieldNames ? '' : 'durationMs')
    ..aOM<$2.Timestamp>(5, _omitFieldNames ? '' : 'modifiedAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaFileInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaFileInfo copyWith(void Function(MediaFileInfo) updates) =>
      super.copyWith((message) => updates(message as MediaFileInfo))
          as MediaFileInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MediaFileInfo create() => MediaFileInfo._();
  @$core.override
  MediaFileInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MediaFileInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MediaFileInfo>(create);
  static MediaFileInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get filename => $_getSZ(0);
  @$pb.TagNumber(1)
  set filename($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilename() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilename() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sizeBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSizeBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearSizeBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get format => $_getSZ(2);
  @$pb.TagNumber(3)
  set format($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFormat() => $_has(2);
  @$pb.TagNumber(3)
  void clearFormat() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get durationMs => $_getI64(3);
  @$pb.TagNumber(4)
  set durationMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDurationMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearDurationMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.Timestamp get modifiedAt => $_getN(4);
  @$pb.TagNumber(5)
  set modifiedAt($2.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasModifiedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearModifiedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Timestamp ensureModifiedAt() => $_ensure(4);
}

class MaCapabilities extends $pb.GeneratedMessage {
  factory MaCapabilities({
    $core.String? grandmaVersion,
    $core.String? grandmaAddress,
    $core.int? grandmaOscPort,
    $core.bool? oscEnabled,
    $core.bool? telnetEnabled,
  }) {
    final result = create();
    if (grandmaVersion != null) result.grandmaVersion = grandmaVersion;
    if (grandmaAddress != null) result.grandmaAddress = grandmaAddress;
    if (grandmaOscPort != null) result.grandmaOscPort = grandmaOscPort;
    if (oscEnabled != null) result.oscEnabled = oscEnabled;
    if (telnetEnabled != null) result.telnetEnabled = telnetEnabled;
    return result;
  }

  MaCapabilities._();

  factory MaCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MaCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MaCapabilities',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'grandmaVersion')
    ..aOS(2, _omitFieldNames ? '' : 'grandmaAddress')
    ..aI(3, _omitFieldNames ? '' : 'grandmaOscPort')
    ..aOB(4, _omitFieldNames ? '' : 'oscEnabled')
    ..aOB(5, _omitFieldNames ? '' : 'telnetEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MaCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MaCapabilities copyWith(void Function(MaCapabilities) updates) =>
      super.copyWith((message) => updates(message as MaCapabilities))
          as MaCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MaCapabilities create() => MaCapabilities._();
  @$core.override
  MaCapabilities createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MaCapabilities getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MaCapabilities>(create);
  static MaCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get grandmaVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set grandmaVersion($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGrandmaVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearGrandmaVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get grandmaAddress => $_getSZ(1);
  @$pb.TagNumber(2)
  set grandmaAddress($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGrandmaAddress() => $_has(1);
  @$pb.TagNumber(2)
  void clearGrandmaAddress() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get grandmaOscPort => $_getIZ(2);
  @$pb.TagNumber(3)
  set grandmaOscPort($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGrandmaOscPort() => $_has(2);
  @$pb.TagNumber(3)
  void clearGrandmaOscPort() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get oscEnabled => $_getBF(3);
  @$pb.TagNumber(4)
  set oscEnabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOscEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearOscEnabled() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get telnetEnabled => $_getBF(4);
  @$pb.TagNumber(5)
  set telnetEnabled($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTelnetEnabled() => $_has(4);
  @$pb.TagNumber(5)
  void clearTelnetEnabled() => $_clearField(5);
}

class NodeCapabilities extends $pb.GeneratedMessage {
  factory NodeCapabilities({
    AudioCapabilities? audio,
    MaCapabilities? ma,
    $core.bool? auditionSupported,
    $core.String? auditionDevice,
  }) {
    final result = create();
    if (audio != null) result.audio = audio;
    if (ma != null) result.ma = ma;
    if (auditionSupported != null) result.auditionSupported = auditionSupported;
    if (auditionDevice != null) result.auditionDevice = auditionDevice;
    return result;
  }

  NodeCapabilities._();

  factory NodeCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeCapabilities',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOM<AudioCapabilities>(1, _omitFieldNames ? '' : 'audio',
        subBuilder: AudioCapabilities.create)
    ..aOM<MaCapabilities>(2, _omitFieldNames ? '' : 'ma',
        subBuilder: MaCapabilities.create)
    ..aOB(3, _omitFieldNames ? '' : 'auditionSupported')
    ..aOS(4, _omitFieldNames ? '' : 'auditionDevice')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeCapabilities copyWith(void Function(NodeCapabilities) updates) =>
      super.copyWith((message) => updates(message as NodeCapabilities))
          as NodeCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeCapabilities create() => NodeCapabilities._();
  @$core.override
  NodeCapabilities createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeCapabilities getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeCapabilities>(create);
  static NodeCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  AudioCapabilities get audio => $_getN(0);
  @$pb.TagNumber(1)
  set audio(AudioCapabilities value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAudio() => $_has(0);
  @$pb.TagNumber(1)
  void clearAudio() => $_clearField(1);
  @$pb.TagNumber(1)
  AudioCapabilities ensureAudio() => $_ensure(0);

  @$pb.TagNumber(2)
  MaCapabilities get ma => $_getN(1);
  @$pb.TagNumber(2)
  set ma(MaCapabilities value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMa() => $_has(1);
  @$pb.TagNumber(2)
  void clearMa() => $_clearField(2);
  @$pb.TagNumber(2)
  MaCapabilities ensureMa() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get auditionSupported => $_getBF(2);
  @$pb.TagNumber(3)
  set auditionSupported($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAuditionSupported() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuditionSupported() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get auditionDevice => $_getSZ(3);
  @$pb.TagNumber(4)
  set auditionDevice($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAuditionDevice() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuditionDevice() => $_clearField(4);
}

class RegisterNodeRequest extends $pb.GeneratedMessage {
  factory RegisterNodeRequest({
    $core.String? sessionId,
    $core.String? token,
    $2.NodeInfo? node,
    NodeCapabilities? capabilities,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (node != null) result.node = node;
    if (capabilities != null) result.capabilities = capabilities;
    return result;
  }

  RegisterNodeRequest._();

  factory RegisterNodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterNodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterNodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOM<$2.NodeInfo>(3, _omitFieldNames ? '' : 'node',
        subBuilder: $2.NodeInfo.create)
    ..aOM<NodeCapabilities>(4, _omitFieldNames ? '' : 'capabilities',
        subBuilder: NodeCapabilities.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterNodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterNodeRequest copyWith(void Function(RegisterNodeRequest) updates) =>
      super.copyWith((message) => updates(message as RegisterNodeRequest))
          as RegisterNodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterNodeRequest create() => RegisterNodeRequest._();
  @$core.override
  RegisterNodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterNodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterNodeRequest>(create);
  static RegisterNodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);

  @$pb.TagNumber(3)
  $2.NodeInfo get node => $_getN(2);
  @$pb.TagNumber(3)
  set node($2.NodeInfo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNode() => $_has(2);
  @$pb.TagNumber(3)
  void clearNode() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.NodeInfo ensureNode() => $_ensure(2);

  @$pb.TagNumber(4)
  NodeCapabilities get capabilities => $_getN(3);
  @$pb.TagNumber(4)
  set capabilities(NodeCapabilities value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCapabilities() => $_has(3);
  @$pb.TagNumber(4)
  void clearCapabilities() => $_clearField(4);
  @$pb.TagNumber(4)
  NodeCapabilities ensureCapabilities() => $_ensure(3);
}

class NodeResponse extends $pb.GeneratedMessage {
  factory NodeResponse({
    $2.NodeInfo? node,
    $core.String? token,
  }) {
    final result = create();
    if (node != null) result.node = node;
    if (token != null) result.token = token;
    return result;
  }

  NodeResponse._();

  factory NodeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOM<$2.NodeInfo>(1, _omitFieldNames ? '' : 'node',
        subBuilder: $2.NodeInfo.create)
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeResponse copyWith(void Function(NodeResponse) updates) =>
      super.copyWith((message) => updates(message as NodeResponse))
          as NodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeResponse create() => NodeResponse._();
  @$core.override
  NodeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeResponse>(create);
  static NodeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $2.NodeInfo get node => $_getN(0);
  @$pb.TagNumber(1)
  set node($2.NodeInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNode() => $_has(0);
  @$pb.TagNumber(1)
  void clearNode() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.NodeInfo ensureNode() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);
}

class UnregisterNodeRequest extends $pb.GeneratedMessage {
  factory UnregisterNodeRequest({
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

  UnregisterNodeRequest._();

  factory UnregisterNodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnregisterNodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnregisterNodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'nodeId')
    ..aOS(3, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnregisterNodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnregisterNodeRequest copyWith(
          void Function(UnregisterNodeRequest) updates) =>
      super.copyWith((message) => updates(message as UnregisterNodeRequest))
          as UnregisterNodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnregisterNodeRequest create() => UnregisterNodeRequest._();
  @$core.override
  UnregisterNodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnregisterNodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnregisterNodeRequest>(create);
  static UnregisterNodeRequest? _defaultInstance;

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

class ListNodesRequest extends $pb.GeneratedMessage {
  factory ListNodesRequest({
    $core.String? sessionId,
    $core.String? token,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    return result;
  }

  ListNodesRequest._();

  factory ListNodesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListNodesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListNodesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesRequest copyWith(void Function(ListNodesRequest) updates) =>
      super.copyWith((message) => updates(message as ListNodesRequest))
          as ListNodesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListNodesRequest create() => ListNodesRequest._();
  @$core.override
  ListNodesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListNodesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListNodesRequest>(create);
  static ListNodesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);
}

class ListNodesResponse extends $pb.GeneratedMessage {
  factory ListNodesResponse({
    $core.Iterable<$2.NodeInfo>? nodes,
  }) {
    final result = create();
    if (nodes != null) result.nodes.addAll(nodes);
    return result;
  }

  ListNodesResponse._();

  factory ListNodesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListNodesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListNodesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..pPM<$2.NodeInfo>(1, _omitFieldNames ? '' : 'nodes',
        subBuilder: $2.NodeInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesResponse copyWith(void Function(ListNodesResponse) updates) =>
      super.copyWith((message) => updates(message as ListNodesResponse))
          as ListNodesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListNodesResponse create() => ListNodesResponse._();
  @$core.override
  ListNodesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListNodesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListNodesResponse>(create);
  static ListNodesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$2.NodeInfo> get nodes => $_getList(0);
}

class WatchNodesRequest extends $pb.GeneratedMessage {
  factory WatchNodesRequest({
    $core.String? sessionId,
    $core.String? token,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    return result;
  }

  WatchNodesRequest._();

  factory WatchNodesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchNodesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchNodesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchNodesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchNodesRequest copyWith(void Function(WatchNodesRequest) updates) =>
      super.copyWith((message) => updates(message as WatchNodesRequest))
          as WatchNodesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchNodesRequest create() => WatchNodesRequest._();
  @$core.override
  WatchNodesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchNodesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchNodesRequest>(create);
  static WatchNodesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);
}

class NodeEvent extends $pb.GeneratedMessage {
  factory NodeEvent({
    NodeEvent_Type? type,
    $2.NodeInfo? node,
    $2.Timestamp? occurredAt,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (node != null) result.node = node;
    if (occurredAt != null) result.occurredAt = occurredAt;
    return result;
  }

  NodeEvent._();

  factory NodeEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aE<NodeEvent_Type>(1, _omitFieldNames ? '' : 'type',
        enumValues: NodeEvent_Type.values)
    ..aOM<$2.NodeInfo>(2, _omitFieldNames ? '' : 'node',
        subBuilder: $2.NodeInfo.create)
    ..aOM<$2.Timestamp>(3, _omitFieldNames ? '' : 'occurredAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeEvent copyWith(void Function(NodeEvent) updates) =>
      super.copyWith((message) => updates(message as NodeEvent)) as NodeEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeEvent create() => NodeEvent._();
  @$core.override
  NodeEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NodeEvent>(create);
  static NodeEvent? _defaultInstance;

  @$pb.TagNumber(1)
  NodeEvent_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(NodeEvent_Type value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $2.NodeInfo get node => $_getN(1);
  @$pb.TagNumber(2)
  set node($2.NodeInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNode() => $_has(1);
  @$pb.TagNumber(2)
  void clearNode() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.NodeInfo ensureNode() => $_ensure(1);

  @$pb.TagNumber(3)
  $2.Timestamp get occurredAt => $_getN(2);
  @$pb.TagNumber(3)
  set occurredAt($2.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOccurredAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearOccurredAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.Timestamp ensureOccurredAt() => $_ensure(2);
}

class UpdateCapabilitiesRequest extends $pb.GeneratedMessage {
  factory UpdateCapabilitiesRequest({
    $core.String? sessionId,
    $core.String? nodeId,
    $core.String? token,
    NodeCapabilities? capabilities,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (nodeId != null) result.nodeId = nodeId;
    if (token != null) result.token = token;
    if (capabilities != null) result.capabilities = capabilities;
    return result;
  }

  UpdateCapabilitiesRequest._();

  factory UpdateCapabilitiesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateCapabilitiesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateCapabilitiesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'nodeId')
    ..aOS(3, _omitFieldNames ? '' : 'token')
    ..aOM<NodeCapabilities>(4, _omitFieldNames ? '' : 'capabilities',
        subBuilder: NodeCapabilities.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCapabilitiesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCapabilitiesRequest copyWith(
          void Function(UpdateCapabilitiesRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateCapabilitiesRequest))
          as UpdateCapabilitiesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateCapabilitiesRequest create() => UpdateCapabilitiesRequest._();
  @$core.override
  UpdateCapabilitiesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateCapabilitiesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateCapabilitiesRequest>(create);
  static UpdateCapabilitiesRequest? _defaultInstance;

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
  NodeCapabilities get capabilities => $_getN(3);
  @$pb.TagNumber(4)
  set capabilities(NodeCapabilities value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCapabilities() => $_has(3);
  @$pb.TagNumber(4)
  void clearCapabilities() => $_clearField(4);
  @$pb.TagNumber(4)
  NodeCapabilities ensureCapabilities() => $_ensure(3);
}

/// StreamNodeCommandsRequest: Node öffnet den Command-Stream
class StreamNodeCommandsRequest extends $pb.GeneratedMessage {
  factory StreamNodeCommandsRequest({
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

  StreamNodeCommandsRequest._();

  factory StreamNodeCommandsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamNodeCommandsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamNodeCommandsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'nodeId')
    ..aOS(3, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamNodeCommandsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamNodeCommandsRequest copyWith(
          void Function(StreamNodeCommandsRequest) updates) =>
      super.copyWith((message) => updates(message as StreamNodeCommandsRequest))
          as StreamNodeCommandsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamNodeCommandsRequest create() => StreamNodeCommandsRequest._();
  @$core.override
  StreamNodeCommandsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamNodeCommandsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamNodeCommandsRequest>(create);
  static StreamNodeCommandsRequest? _defaultInstance;

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

enum NodeCommandRequest_Command {
  audioPreload,
  audioPlay,
  audioStop,
  maOsc,
  audioPause,
  audioResume,
  audioTest,
  nodeConfig,
  audioFade,
  audioTalkback,
  audioTalkbackCtrl,
  midiSend,
  ledFeedback,
  notSet
}

/// NodeCommandRequest: wird über den Stream an den Node gepusht
class NodeCommandRequest extends $pb.GeneratedMessage {
  factory NodeCommandRequest({
    $core.String? sessionId,
    $core.String? commandId,
    $core.String? targetNodeId,
    AudioPreloadCommand? audioPreload,
    AudioPlayCommand? audioPlay,
    AudioStopCommand? audioStop,
    MaOscCommand? maOsc,
    $2.NodeTask? targetTask,
    AudioPauseCommand? audioPause,
    AudioResumeCommand? audioResume,
    AudioTestSignalCommand? audioTest,
    NodeConfigCommand? nodeConfig,
    AudioFadeCommand? audioFade,
    AudioTalkbackChunkCommand? audioTalkback,
    AudioTalkbackControlCommand? audioTalkbackCtrl,
    MidiSendCommand? midiSend,
    LedFeedbackCommand? ledFeedback,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (commandId != null) result.commandId = commandId;
    if (targetNodeId != null) result.targetNodeId = targetNodeId;
    if (audioPreload != null) result.audioPreload = audioPreload;
    if (audioPlay != null) result.audioPlay = audioPlay;
    if (audioStop != null) result.audioStop = audioStop;
    if (maOsc != null) result.maOsc = maOsc;
    if (targetTask != null) result.targetTask = targetTask;
    if (audioPause != null) result.audioPause = audioPause;
    if (audioResume != null) result.audioResume = audioResume;
    if (audioTest != null) result.audioTest = audioTest;
    if (nodeConfig != null) result.nodeConfig = nodeConfig;
    if (audioFade != null) result.audioFade = audioFade;
    if (audioTalkback != null) result.audioTalkback = audioTalkback;
    if (audioTalkbackCtrl != null) result.audioTalkbackCtrl = audioTalkbackCtrl;
    if (midiSend != null) result.midiSend = midiSend;
    if (ledFeedback != null) result.ledFeedback = ledFeedback;
    return result;
  }

  NodeCommandRequest._();

  factory NodeCommandRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeCommandRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, NodeCommandRequest_Command>
      _NodeCommandRequest_CommandByTag = {
    4: NodeCommandRequest_Command.audioPreload,
    5: NodeCommandRequest_Command.audioPlay,
    6: NodeCommandRequest_Command.audioStop,
    7: NodeCommandRequest_Command.maOsc,
    9: NodeCommandRequest_Command.audioPause,
    10: NodeCommandRequest_Command.audioResume,
    11: NodeCommandRequest_Command.audioTest,
    12: NodeCommandRequest_Command.nodeConfig,
    13: NodeCommandRequest_Command.audioFade,
    14: NodeCommandRequest_Command.audioTalkback,
    15: NodeCommandRequest_Command.audioTalkbackCtrl,
    16: NodeCommandRequest_Command.midiSend,
    17: NodeCommandRequest_Command.ledFeedback,
    0: NodeCommandRequest_Command.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeCommandRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..oo(0, [4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17])
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'commandId')
    ..aOS(3, _omitFieldNames ? '' : 'targetNodeId')
    ..aOM<AudioPreloadCommand>(4, _omitFieldNames ? '' : 'audioPreload',
        subBuilder: AudioPreloadCommand.create)
    ..aOM<AudioPlayCommand>(5, _omitFieldNames ? '' : 'audioPlay',
        subBuilder: AudioPlayCommand.create)
    ..aOM<AudioStopCommand>(6, _omitFieldNames ? '' : 'audioStop',
        subBuilder: AudioStopCommand.create)
    ..aOM<MaOscCommand>(7, _omitFieldNames ? '' : 'maOsc',
        subBuilder: MaOscCommand.create)
    ..aE<$2.NodeTask>(8, _omitFieldNames ? '' : 'targetTask',
        enumValues: $2.NodeTask.values)
    ..aOM<AudioPauseCommand>(9, _omitFieldNames ? '' : 'audioPause',
        subBuilder: AudioPauseCommand.create)
    ..aOM<AudioResumeCommand>(10, _omitFieldNames ? '' : 'audioResume',
        subBuilder: AudioResumeCommand.create)
    ..aOM<AudioTestSignalCommand>(11, _omitFieldNames ? '' : 'audioTest',
        subBuilder: AudioTestSignalCommand.create)
    ..aOM<NodeConfigCommand>(12, _omitFieldNames ? '' : 'nodeConfig',
        subBuilder: NodeConfigCommand.create)
    ..aOM<AudioFadeCommand>(13, _omitFieldNames ? '' : 'audioFade',
        subBuilder: AudioFadeCommand.create)
    ..aOM<AudioTalkbackChunkCommand>(14, _omitFieldNames ? '' : 'audioTalkback',
        subBuilder: AudioTalkbackChunkCommand.create)
    ..aOM<AudioTalkbackControlCommand>(
        15, _omitFieldNames ? '' : 'audioTalkbackCtrl',
        subBuilder: AudioTalkbackControlCommand.create)
    ..aOM<MidiSendCommand>(16, _omitFieldNames ? '' : 'midiSend',
        subBuilder: MidiSendCommand.create)
    ..aOM<LedFeedbackCommand>(17, _omitFieldNames ? '' : 'ledFeedback',
        subBuilder: LedFeedbackCommand.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeCommandRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeCommandRequest copyWith(void Function(NodeCommandRequest) updates) =>
      super.copyWith((message) => updates(message as NodeCommandRequest))
          as NodeCommandRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeCommandRequest create() => NodeCommandRequest._();
  @$core.override
  NodeCommandRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeCommandRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeCommandRequest>(create);
  static NodeCommandRequest? _defaultInstance;

  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  NodeCommandRequest_Command whichCommand() =>
      _NodeCommandRequest_CommandByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  void clearCommand() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get commandId => $_getSZ(1);
  @$pb.TagNumber(2)
  set commandId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommandId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommandId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get targetNodeId => $_getSZ(2);
  @$pb.TagNumber(3)
  set targetNodeId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetNodeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetNodeId() => $_clearField(3);

  @$pb.TagNumber(4)
  AudioPreloadCommand get audioPreload => $_getN(3);
  @$pb.TagNumber(4)
  set audioPreload(AudioPreloadCommand value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAudioPreload() => $_has(3);
  @$pb.TagNumber(4)
  void clearAudioPreload() => $_clearField(4);
  @$pb.TagNumber(4)
  AudioPreloadCommand ensureAudioPreload() => $_ensure(3);

  @$pb.TagNumber(5)
  AudioPlayCommand get audioPlay => $_getN(4);
  @$pb.TagNumber(5)
  set audioPlay(AudioPlayCommand value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAudioPlay() => $_has(4);
  @$pb.TagNumber(5)
  void clearAudioPlay() => $_clearField(5);
  @$pb.TagNumber(5)
  AudioPlayCommand ensureAudioPlay() => $_ensure(4);

  @$pb.TagNumber(6)
  AudioStopCommand get audioStop => $_getN(5);
  @$pb.TagNumber(6)
  set audioStop(AudioStopCommand value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasAudioStop() => $_has(5);
  @$pb.TagNumber(6)
  void clearAudioStop() => $_clearField(6);
  @$pb.TagNumber(6)
  AudioStopCommand ensureAudioStop() => $_ensure(5);

  @$pb.TagNumber(7)
  MaOscCommand get maOsc => $_getN(6);
  @$pb.TagNumber(7)
  set maOsc(MaOscCommand value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMaOsc() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaOsc() => $_clearField(7);
  @$pb.TagNumber(7)
  MaOscCommand ensureMaOsc() => $_ensure(6);

  @$pb.TagNumber(8)
  $2.NodeTask get targetTask => $_getN(7);
  @$pb.TagNumber(8)
  set targetTask($2.NodeTask value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasTargetTask() => $_has(7);
  @$pb.TagNumber(8)
  void clearTargetTask() => $_clearField(8);

  @$pb.TagNumber(9)
  AudioPauseCommand get audioPause => $_getN(8);
  @$pb.TagNumber(9)
  set audioPause(AudioPauseCommand value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasAudioPause() => $_has(8);
  @$pb.TagNumber(9)
  void clearAudioPause() => $_clearField(9);
  @$pb.TagNumber(9)
  AudioPauseCommand ensureAudioPause() => $_ensure(8);

  @$pb.TagNumber(10)
  AudioResumeCommand get audioResume => $_getN(9);
  @$pb.TagNumber(10)
  set audioResume(AudioResumeCommand value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasAudioResume() => $_has(9);
  @$pb.TagNumber(10)
  void clearAudioResume() => $_clearField(10);
  @$pb.TagNumber(10)
  AudioResumeCommand ensureAudioResume() => $_ensure(9);

  @$pb.TagNumber(11)
  AudioTestSignalCommand get audioTest => $_getN(10);
  @$pb.TagNumber(11)
  set audioTest(AudioTestSignalCommand value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasAudioTest() => $_has(10);
  @$pb.TagNumber(11)
  void clearAudioTest() => $_clearField(11);
  @$pb.TagNumber(11)
  AudioTestSignalCommand ensureAudioTest() => $_ensure(10);

  @$pb.TagNumber(12)
  NodeConfigCommand get nodeConfig => $_getN(11);
  @$pb.TagNumber(12)
  set nodeConfig(NodeConfigCommand value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasNodeConfig() => $_has(11);
  @$pb.TagNumber(12)
  void clearNodeConfig() => $_clearField(12);
  @$pb.TagNumber(12)
  NodeConfigCommand ensureNodeConfig() => $_ensure(11);

  @$pb.TagNumber(13)
  AudioFadeCommand get audioFade => $_getN(12);
  @$pb.TagNumber(13)
  set audioFade(AudioFadeCommand value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasAudioFade() => $_has(12);
  @$pb.TagNumber(13)
  void clearAudioFade() => $_clearField(13);
  @$pb.TagNumber(13)
  AudioFadeCommand ensureAudioFade() => $_ensure(12);

  @$pb.TagNumber(14)
  AudioTalkbackChunkCommand get audioTalkback => $_getN(13);
  @$pb.TagNumber(14)
  set audioTalkback(AudioTalkbackChunkCommand value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasAudioTalkback() => $_has(13);
  @$pb.TagNumber(14)
  void clearAudioTalkback() => $_clearField(14);
  @$pb.TagNumber(14)
  AudioTalkbackChunkCommand ensureAudioTalkback() => $_ensure(13);

  @$pb.TagNumber(15)
  AudioTalkbackControlCommand get audioTalkbackCtrl => $_getN(14);
  @$pb.TagNumber(15)
  set audioTalkbackCtrl(AudioTalkbackControlCommand value) =>
      $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasAudioTalkbackCtrl() => $_has(14);
  @$pb.TagNumber(15)
  void clearAudioTalkbackCtrl() => $_clearField(15);
  @$pb.TagNumber(15)
  AudioTalkbackControlCommand ensureAudioTalkbackCtrl() => $_ensure(14);

  @$pb.TagNumber(16)
  MidiSendCommand get midiSend => $_getN(15);
  @$pb.TagNumber(16)
  set midiSend(MidiSendCommand value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasMidiSend() => $_has(15);
  @$pb.TagNumber(16)
  void clearMidiSend() => $_clearField(16);
  @$pb.TagNumber(16)
  MidiSendCommand ensureMidiSend() => $_ensure(15);

  @$pb.TagNumber(17)
  LedFeedbackCommand get ledFeedback => $_getN(16);
  @$pb.TagNumber(17)
  set ledFeedback(LedFeedbackCommand value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasLedFeedback() => $_has(16);
  @$pb.TagNumber(17)
  void clearLedFeedback() => $_clearField(17);
  @$pb.TagNumber(17)
  LedFeedbackCommand ensureLedFeedback() => $_ensure(16);
}

/// Sendet rohe MIDI-Bytes an einen ausgehenden MIDI-Port des Nodes.
class MidiSendCommand extends $pb.GeneratedMessage {
  factory MidiSendCommand({
    $core.int? channel,
    $core.int? command,
    $core.int? data1,
    $core.int? data2,
  }) {
    final result = create();
    if (channel != null) result.channel = channel;
    if (command != null) result.command = command;
    if (data1 != null) result.data1 = data1;
    if (data2 != null) result.data2 = data2;
    return result;
  }

  MidiSendCommand._();

  factory MidiSendCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MidiSendCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MidiSendCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'channel')
    ..aI(2, _omitFieldNames ? '' : 'command')
    ..aI(3, _omitFieldNames ? '' : 'data1')
    ..aI(4, _omitFieldNames ? '' : 'data2')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MidiSendCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MidiSendCommand copyWith(void Function(MidiSendCommand) updates) =>
      super.copyWith((message) => updates(message as MidiSendCommand))
          as MidiSendCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MidiSendCommand create() => MidiSendCommand._();
  @$core.override
  MidiSendCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MidiSendCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MidiSendCommand>(create);
  static MidiSendCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get channel => $_getIZ(0);
  @$pb.TagNumber(1)
  set channel($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannel() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get command => $_getIZ(1);
  @$pb.TagNumber(2)
  set command($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommand() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommand() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get data1 => $_getIZ(2);
  @$pb.TagNumber(3)
  set data1($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasData1() => $_has(2);
  @$pb.TagNumber(3)
  void clearData1() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get data2 => $_getIZ(3);
  @$pb.TagNumber(4)
  set data2($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasData2() => $_has(3);
  @$pb.TagNumber(4)
  void clearData2() => $_clearField(4);
}

/// Setzt die LED eines Controller-Pads. Der MIDI-Node übersetzt (track,scene)
/// bzw. note + color in das gerätespezifische Protokoll (z.B. APC Mini Velocity).
class LedFeedbackCommand extends $pb.GeneratedMessage {
  factory LedFeedbackCommand({
    $core.int? trackIndex,
    $core.int? sceneIndex,
    LedFeedbackCommand_Color? color,
  }) {
    final result = create();
    if (trackIndex != null) result.trackIndex = trackIndex;
    if (sceneIndex != null) result.sceneIndex = sceneIndex;
    if (color != null) result.color = color;
    return result;
  }

  LedFeedbackCommand._();

  factory LedFeedbackCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LedFeedbackCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LedFeedbackCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'trackIndex')
    ..aI(2, _omitFieldNames ? '' : 'sceneIndex')
    ..aE<LedFeedbackCommand_Color>(3, _omitFieldNames ? '' : 'color',
        enumValues: LedFeedbackCommand_Color.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LedFeedbackCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LedFeedbackCommand copyWith(void Function(LedFeedbackCommand) updates) =>
      super.copyWith((message) => updates(message as LedFeedbackCommand))
          as LedFeedbackCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LedFeedbackCommand create() => LedFeedbackCommand._();
  @$core.override
  LedFeedbackCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LedFeedbackCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LedFeedbackCommand>(create);
  static LedFeedbackCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get trackIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set trackIndex($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTrackIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearTrackIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get sceneIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set sceneIndex($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSceneIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearSceneIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  LedFeedbackCommand_Color get color => $_getN(2);
  @$pb.TagNumber(3)
  set color(LedFeedbackCommand_Color value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearColor() => $_clearField(3);
}

/// Konfigurationsbefehl vom Master an einen Node.
/// Ermöglicht Remote-Verwaltung ohne Node neu starten zu müssen.
class NodeConfigCommand extends $pb.GeneratedMessage {
  factory NodeConfigCommand({
    $core.int? audioDeviceIndex,
    $core.String? audioDeviceName,
    $core.String? networkInterfaceAddress,
    $core.Iterable<$2.NodeTask>? tasks,
    $core.String? audioBackend,
    $core.Iterable<$core.String>? audioBackendPriority,
    $core.int? sampleRate,
    $core.int? channels,
  }) {
    final result = create();
    if (audioDeviceIndex != null) result.audioDeviceIndex = audioDeviceIndex;
    if (audioDeviceName != null) result.audioDeviceName = audioDeviceName;
    if (networkInterfaceAddress != null)
      result.networkInterfaceAddress = networkInterfaceAddress;
    if (tasks != null) result.tasks.addAll(tasks);
    if (audioBackend != null) result.audioBackend = audioBackend;
    if (audioBackendPriority != null)
      result.audioBackendPriority.addAll(audioBackendPriority);
    if (sampleRate != null) result.sampleRate = sampleRate;
    if (channels != null) result.channels = channels;
    return result;
  }

  NodeConfigCommand._();

  factory NodeConfigCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeConfigCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeConfigCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'audioDeviceIndex')
    ..aOS(2, _omitFieldNames ? '' : 'audioDeviceName')
    ..aOS(3, _omitFieldNames ? '' : 'networkInterfaceAddress')
    ..pc<$2.NodeTask>(4, _omitFieldNames ? '' : 'tasks', $pb.PbFieldType.KE,
        valueOf: $2.NodeTask.valueOf,
        enumValues: $2.NodeTask.values,
        defaultEnumValue: $2.NodeTask.NODE_TASK_UNSPECIFIED)
    ..aOS(5, _omitFieldNames ? '' : 'audioBackend')
    ..pPS(6, _omitFieldNames ? '' : 'audioBackendPriority')
    ..aI(7, _omitFieldNames ? '' : 'sampleRate', fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'channels', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeConfigCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeConfigCommand copyWith(void Function(NodeConfigCommand) updates) =>
      super.copyWith((message) => updates(message as NodeConfigCommand))
          as NodeConfigCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeConfigCommand create() => NodeConfigCommand._();
  @$core.override
  NodeConfigCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeConfigCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeConfigCommand>(create);
  static NodeConfigCommand? _defaultInstance;

  /// Audio-Ausgabegerät setzen. -1 = System-Default.
  @$pb.TagNumber(1)
  $core.int get audioDeviceIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set audioDeviceIndex($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAudioDeviceIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearAudioDeviceIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get audioDeviceName => $_getSZ(1);
  @$pb.TagNumber(2)
  set audioDeviceName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAudioDeviceName() => $_has(1);
  @$pb.TagNumber(2)
  void clearAudioDeviceName() => $_clearField(2);

  /// Netzwerk-Interface des Media-Servers setzen (IP-Adresse).
  /// Leer = keine Änderung.
  @$pb.TagNumber(3)
  $core.String get networkInterfaceAddress => $_getSZ(2);
  @$pb.TagNumber(3)
  set networkInterfaceAddress($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNetworkInterfaceAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearNetworkInterfaceAddress() => $_clearField(3);

  /// Tasks (Rollen) des Nodes neu setzen. Leer = keine Änderung.
  /// Master sendet dies; Server aktualisiert NodeInfo in der Session-Registry
  /// und broadcastet ein TYPE_CAPS_UPDATED NodeEvent.
  @$pb.TagNumber(4)
  $pb.PbList<$2.NodeTask> get tasks => $_getList(3);

  /// Audio-Backend setzen (z.B. "jack"/"jack2", "alsa", "pulseaudio").
  /// Leer = keine Änderung.
  @$pb.TagNumber(5)
  $core.String get audioBackend => $_getSZ(4);
  @$pb.TagNumber(5)
  set audioBackend($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAudioBackend() => $_has(4);
  @$pb.TagNumber(5)
  void clearAudioBackend() => $_clearField(5);

  /// Backend-Fallback-Reihenfolge setzen (erste Position = Präferenz).
  /// Beispiel Linux DAW-Setup: ["jack", "alsa", "pulseaudio"].
  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get audioBackendPriority => $_getList(5);

  /// Laufzeit-Audioformat setzen (0 = keine Änderung).
  @$pb.TagNumber(7)
  $core.int get sampleRate => $_getIZ(6);
  @$pb.TagNumber(7)
  set sampleRate($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSampleRate() => $_has(6);
  @$pb.TagNumber(7)
  void clearSampleRate() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get channels => $_getIZ(7);
  @$pb.TagNumber(8)
  set channels($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasChannels() => $_has(7);
  @$pb.TagNumber(8)
  void clearChannels() => $_clearField(8);
}

/// SendNodeCommandRequest: Master/Client sendet Command an einen Node
class SendNodeCommandRequest extends $pb.GeneratedMessage {
  factory SendNodeCommandRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? targetNodeId,
    NodeCommandRequest? command,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (targetNodeId != null) result.targetNodeId = targetNodeId;
    if (command != null) result.command = command;
    return result;
  }

  SendNodeCommandRequest._();

  factory SendNodeCommandRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendNodeCommandRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendNodeCommandRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'targetNodeId')
    ..aOM<NodeCommandRequest>(4, _omitFieldNames ? '' : 'command',
        subBuilder: NodeCommandRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendNodeCommandRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendNodeCommandRequest copyWith(
          void Function(SendNodeCommandRequest) updates) =>
      super.copyWith((message) => updates(message as SendNodeCommandRequest))
          as SendNodeCommandRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendNodeCommandRequest create() => SendNodeCommandRequest._();
  @$core.override
  SendNodeCommandRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SendNodeCommandRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendNodeCommandRequest>(create);
  static SendNodeCommandRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get targetNodeId => $_getSZ(2);
  @$pb.TagNumber(3)
  set targetNodeId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetNodeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetNodeId() => $_clearField(3);

  @$pb.TagNumber(4)
  NodeCommandRequest get command => $_getN(3);
  @$pb.TagNumber(4)
  set command(NodeCommandRequest value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCommand() => $_has(3);
  @$pb.TagNumber(4)
  void clearCommand() => $_clearField(4);
  @$pb.TagNumber(4)
  NodeCommandRequest ensureCommand() => $_ensure(3);
}

class AudioPreloadCommand extends $pb.GeneratedMessage {
  factory AudioPreloadCommand({
    $core.String? cueId,
    $core.String? filePath,
    $core.String? assetId,
  }) {
    final result = create();
    if (cueId != null) result.cueId = cueId;
    if (filePath != null) result.filePath = filePath;
    if (assetId != null) result.assetId = assetId;
    return result;
  }

  AudioPreloadCommand._();

  factory AudioPreloadCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioPreloadCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioPreloadCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cueId')
    ..aOS(2, _omitFieldNames ? '' : 'filePath')
    ..aOS(3, _omitFieldNames ? '' : 'assetId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPreloadCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPreloadCommand copyWith(void Function(AudioPreloadCommand) updates) =>
      super.copyWith((message) => updates(message as AudioPreloadCommand))
          as AudioPreloadCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioPreloadCommand create() => AudioPreloadCommand._();
  @$core.override
  AudioPreloadCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioPreloadCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioPreloadCommand>(create);
  static AudioPreloadCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get filePath => $_getSZ(1);
  @$pb.TagNumber(2)
  set filePath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFilePath() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilePath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get assetId => $_getSZ(2);
  @$pb.TagNumber(3)
  set assetId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAssetId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAssetId() => $_clearField(3);
}

class AudioPlayCommand extends $pb.GeneratedMessage {
  factory AudioPlayCommand({
    $core.String? cueId,
    $fixnum.Int64? startUnixMillis,
    $core.double? volumeDb,
    $core.double? fadeInMs,
    $core.double? fadeOutMs,
    $core.bool? loop,
    $core.double? startTimeMs,
    $core.double? endTimeMs,
  }) {
    final result = create();
    if (cueId != null) result.cueId = cueId;
    if (startUnixMillis != null) result.startUnixMillis = startUnixMillis;
    if (volumeDb != null) result.volumeDb = volumeDb;
    if (fadeInMs != null) result.fadeInMs = fadeInMs;
    if (fadeOutMs != null) result.fadeOutMs = fadeOutMs;
    if (loop != null) result.loop = loop;
    if (startTimeMs != null) result.startTimeMs = startTimeMs;
    if (endTimeMs != null) result.endTimeMs = endTimeMs;
    return result;
  }

  AudioPlayCommand._();

  factory AudioPlayCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioPlayCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioPlayCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cueId')
    ..aInt64(2, _omitFieldNames ? '' : 'startUnixMillis')
    ..aD(3, _omitFieldNames ? '' : 'volumeDb')
    ..aD(4, _omitFieldNames ? '' : 'fadeInMs')
    ..aD(5, _omitFieldNames ? '' : 'fadeOutMs')
    ..aOB(6, _omitFieldNames ? '' : 'loop')
    ..aD(7, _omitFieldNames ? '' : 'startTimeMs')
    ..aD(8, _omitFieldNames ? '' : 'endTimeMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPlayCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPlayCommand copyWith(void Function(AudioPlayCommand) updates) =>
      super.copyWith((message) => updates(message as AudioPlayCommand))
          as AudioPlayCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioPlayCommand create() => AudioPlayCommand._();
  @$core.override
  AudioPlayCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioPlayCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioPlayCommand>(create);
  static AudioPlayCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get startUnixMillis => $_getI64(1);
  @$pb.TagNumber(2)
  set startUnixMillis($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStartUnixMillis() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartUnixMillis() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get volumeDb => $_getN(2);
  @$pb.TagNumber(3)
  set volumeDb($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVolumeDb() => $_has(2);
  @$pb.TagNumber(3)
  void clearVolumeDb() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get fadeInMs => $_getN(3);
  @$pb.TagNumber(4)
  set fadeInMs($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFadeInMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearFadeInMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get fadeOutMs => $_getN(4);
  @$pb.TagNumber(5)
  set fadeOutMs($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFadeOutMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearFadeOutMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get loop => $_getBF(5);
  @$pb.TagNumber(6)
  set loop($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLoop() => $_has(5);
  @$pb.TagNumber(6)
  void clearLoop() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get startTimeMs => $_getN(6);
  @$pb.TagNumber(7)
  set startTimeMs($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStartTimeMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearStartTimeMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get endTimeMs => $_getN(7);
  @$pb.TagNumber(8)
  set endTimeMs($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEndTimeMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearEndTimeMs() => $_clearField(8);
}

class AudioStopCommand extends $pb.GeneratedMessage {
  factory AudioStopCommand({
    $core.String? cueId,
    $core.double? fadeOutMs,
  }) {
    final result = create();
    if (cueId != null) result.cueId = cueId;
    if (fadeOutMs != null) result.fadeOutMs = fadeOutMs;
    return result;
  }

  AudioStopCommand._();

  factory AudioStopCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioStopCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioStopCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cueId')
    ..aD(2, _omitFieldNames ? '' : 'fadeOutMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioStopCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioStopCommand copyWith(void Function(AudioStopCommand) updates) =>
      super.copyWith((message) => updates(message as AudioStopCommand))
          as AudioStopCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioStopCommand create() => AudioStopCommand._();
  @$core.override
  AudioStopCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioStopCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioStopCommand>(create);
  static AudioStopCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get fadeOutMs => $_getN(1);
  @$pb.TagNumber(2)
  set fadeOutMs($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFadeOutMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearFadeOutMs() => $_clearField(2);
}

/// Hält die laufende Voice an (Playhead bleibt stehen). cue_id leer = alle.
class AudioPauseCommand extends $pb.GeneratedMessage {
  factory AudioPauseCommand({
    $core.String? cueId,
    $core.double? fadeOutMs,
  }) {
    final result = create();
    if (cueId != null) result.cueId = cueId;
    if (fadeOutMs != null) result.fadeOutMs = fadeOutMs;
    return result;
  }

  AudioPauseCommand._();

  factory AudioPauseCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioPauseCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioPauseCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cueId')
    ..aD(2, _omitFieldNames ? '' : 'fadeOutMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPauseCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPauseCommand copyWith(void Function(AudioPauseCommand) updates) =>
      super.copyWith((message) => updates(message as AudioPauseCommand))
          as AudioPauseCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioPauseCommand create() => AudioPauseCommand._();
  @$core.override
  AudioPauseCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioPauseCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioPauseCommand>(create);
  static AudioPauseCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get fadeOutMs => $_getN(1);
  @$pb.TagNumber(2)
  set fadeOutMs($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFadeOutMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearFadeOutMs() => $_clearField(2);
}

/// Setzt eine angehaltene Voice fort. cue_id leer = alle.
class AudioResumeCommand extends $pb.GeneratedMessage {
  factory AudioResumeCommand({
    $core.String? cueId,
    $core.double? fadeInMs,
  }) {
    final result = create();
    if (cueId != null) result.cueId = cueId;
    if (fadeInMs != null) result.fadeInMs = fadeInMs;
    return result;
  }

  AudioResumeCommand._();

  factory AudioResumeCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioResumeCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioResumeCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cueId')
    ..aD(2, _omitFieldNames ? '' : 'fadeInMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioResumeCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioResumeCommand copyWith(void Function(AudioResumeCommand) updates) =>
      super.copyWith((message) => updates(message as AudioResumeCommand))
          as AudioResumeCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioResumeCommand create() => AudioResumeCommand._();
  @$core.override
  AudioResumeCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioResumeCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioResumeCommand>(create);
  static AudioResumeCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get fadeInMs => $_getN(1);
  @$pb.TagNumber(2)
  set fadeInMs($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFadeInMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearFadeInMs() => $_clearField(2);
}

/// Anweisung an den Node, ein Testsignal SELBST zu generieren und abzuspielen
/// (es wird kein Audio über das Netz übertragen).
/// Blendet eine laufende Cue auf eine Ziel-Lautstärke um.
/// Kann optional die Cue danach stoppen oder pausieren.
class AudioFadeCommand extends $pb.GeneratedMessage {
  factory AudioFadeCommand({
    $core.String? cueId,
    $core.double? targetVolumeDb,
    $core.double? durationMs,
    $core.bool? stopWhenDone,
    $core.bool? pauseWhenDone,
  }) {
    final result = create();
    if (cueId != null) result.cueId = cueId;
    if (targetVolumeDb != null) result.targetVolumeDb = targetVolumeDb;
    if (durationMs != null) result.durationMs = durationMs;
    if (stopWhenDone != null) result.stopWhenDone = stopWhenDone;
    if (pauseWhenDone != null) result.pauseWhenDone = pauseWhenDone;
    return result;
  }

  AudioFadeCommand._();

  factory AudioFadeCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioFadeCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioFadeCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cueId')
    ..aD(2, _omitFieldNames ? '' : 'targetVolumeDb')
    ..aD(3, _omitFieldNames ? '' : 'durationMs')
    ..aOB(4, _omitFieldNames ? '' : 'stopWhenDone')
    ..aOB(5, _omitFieldNames ? '' : 'pauseWhenDone')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioFadeCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioFadeCommand copyWith(void Function(AudioFadeCommand) updates) =>
      super.copyWith((message) => updates(message as AudioFadeCommand))
          as AudioFadeCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioFadeCommand create() => AudioFadeCommand._();
  @$core.override
  AudioFadeCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioFadeCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioFadeCommand>(create);
  static AudioFadeCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get targetVolumeDb => $_getN(1);
  @$pb.TagNumber(2)
  set targetVolumeDb($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTargetVolumeDb() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetVolumeDb() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get durationMs => $_getN(2);
  @$pb.TagNumber(3)
  set durationMs($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDurationMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearDurationMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get stopWhenDone => $_getBF(3);
  @$pb.TagNumber(4)
  set stopWhenDone($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStopWhenDone() => $_has(3);
  @$pb.TagNumber(4)
  void clearStopWhenDone() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get pauseWhenDone => $_getBF(4);
  @$pb.TagNumber(5)
  set pauseWhenDone($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPauseWhenDone() => $_has(4);
  @$pb.TagNumber(5)
  void clearPauseWhenDone() => $_clearField(5);
}

class AudioTestSignalCommand extends $pb.GeneratedMessage {
  factory AudioTestSignalCommand({
    $core.String? cueId,
    AudioTestSignalCommand_Kind? kind,
    $core.double? startHz,
    $core.double? endHz,
    $core.double? frequencyHz,
    $core.double? durationMs,
    $core.double? amplitude,
  }) {
    final result = create();
    if (cueId != null) result.cueId = cueId;
    if (kind != null) result.kind = kind;
    if (startHz != null) result.startHz = startHz;
    if (endHz != null) result.endHz = endHz;
    if (frequencyHz != null) result.frequencyHz = frequencyHz;
    if (durationMs != null) result.durationMs = durationMs;
    if (amplitude != null) result.amplitude = amplitude;
    return result;
  }

  AudioTestSignalCommand._();

  factory AudioTestSignalCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioTestSignalCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioTestSignalCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cueId')
    ..aE<AudioTestSignalCommand_Kind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: AudioTestSignalCommand_Kind.values)
    ..aD(3, _omitFieldNames ? '' : 'startHz')
    ..aD(4, _omitFieldNames ? '' : 'endHz')
    ..aD(5, _omitFieldNames ? '' : 'frequencyHz')
    ..aD(6, _omitFieldNames ? '' : 'durationMs')
    ..aD(7, _omitFieldNames ? '' : 'amplitude')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioTestSignalCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioTestSignalCommand copyWith(
          void Function(AudioTestSignalCommand) updates) =>
      super.copyWith((message) => updates(message as AudioTestSignalCommand))
          as AudioTestSignalCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioTestSignalCommand create() => AudioTestSignalCommand._();
  @$core.override
  AudioTestSignalCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioTestSignalCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioTestSignalCommand>(create);
  static AudioTestSignalCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueId() => $_clearField(1);

  @$pb.TagNumber(2)
  AudioTestSignalCommand_Kind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(AudioTestSignalCommand_Kind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get startHz => $_getN(2);
  @$pb.TagNumber(3)
  set startHz($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStartHz() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartHz() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get endHz => $_getN(3);
  @$pb.TagNumber(4)
  set endHz($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEndHz() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndHz() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get frequencyHz => $_getN(4);
  @$pb.TagNumber(5)
  set frequencyHz($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFrequencyHz() => $_has(4);
  @$pb.TagNumber(5)
  void clearFrequencyHz() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get durationMs => $_getN(5);
  @$pb.TagNumber(6)
  set durationMs($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDurationMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearDurationMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get amplitude => $_getN(6);
  @$pb.TagNumber(7)
  set amplitude($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAmplitude() => $_has(6);
  @$pb.TagNumber(7)
  void clearAmplitude() => $_clearField(7);
}

class MaOscCommand extends $pb.GeneratedMessage {
  factory MaOscCommand({
    $core.String? oscAddress,
    $core.String? oscArgument,
  }) {
    final result = create();
    if (oscAddress != null) result.oscAddress = oscAddress;
    if (oscArgument != null) result.oscArgument = oscArgument;
    return result;
  }

  MaOscCommand._();

  factory MaOscCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MaOscCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MaOscCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'oscAddress')
    ..aOS(2, _omitFieldNames ? '' : 'oscArgument')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MaOscCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MaOscCommand copyWith(void Function(MaOscCommand) updates) =>
      super.copyWith((message) => updates(message as MaOscCommand))
          as MaOscCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MaOscCommand create() => MaOscCommand._();
  @$core.override
  MaOscCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MaOscCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MaOscCommand>(create);
  static MaOscCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get oscAddress => $_getSZ(0);
  @$pb.TagNumber(1)
  set oscAddress($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOscAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearOscAddress() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get oscArgument => $_getSZ(1);
  @$pb.TagNumber(2)
  set oscArgument($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOscArgument() => $_has(1);
  @$pb.TagNumber(2)
  void clearOscArgument() => $_clearField(2);
}

class NodeCommandResponse extends $pb.GeneratedMessage {
  factory NodeCommandResponse({
    $core.bool? success,
    $core.String? errorMsg,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (errorMsg != null) result.errorMsg = errorMsg;
    return result;
  }

  NodeCommandResponse._();

  factory NodeCommandResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeCommandResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeCommandResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'errorMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeCommandResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeCommandResponse copyWith(void Function(NodeCommandResponse) updates) =>
      super.copyWith((message) => updates(message as NodeCommandResponse))
          as NodeCommandResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeCommandResponse create() => NodeCommandResponse._();
  @$core.override
  NodeCommandResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeCommandResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeCommandResponse>(create);
  static NodeCommandResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errorMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errorMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrorMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrorMsg() => $_clearField(2);
}

/// Ein Talkback-Audio-Chunk: Opus-codiert, vom Server an den Node relayed.
/// Der Node dekodiert Opus → PCM und mischt es in die Audio-Engine.
class AudioTalkbackChunkCommand extends $pb.GeneratedMessage {
  factory AudioTalkbackChunkCommand({
    $core.String? clientId,
    $core.List<$core.int>? opusData,
    $fixnum.Int64? timestampMs,
    $core.int? sequence,
    $core.double? levelDb,
  }) {
    final result = create();
    if (clientId != null) result.clientId = clientId;
    if (opusData != null) result.opusData = opusData;
    if (timestampMs != null) result.timestampMs = timestampMs;
    if (sequence != null) result.sequence = sequence;
    if (levelDb != null) result.levelDb = levelDb;
    return result;
  }

  AudioTalkbackChunkCommand._();

  factory AudioTalkbackChunkCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioTalkbackChunkCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioTalkbackChunkCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'clientId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'opusData', $pb.PbFieldType.OY)
    ..aInt64(3, _omitFieldNames ? '' : 'timestampMs')
    ..aI(4, _omitFieldNames ? '' : 'sequence', fieldType: $pb.PbFieldType.OU3)
    ..aD(5, _omitFieldNames ? '' : 'levelDb', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioTalkbackChunkCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioTalkbackChunkCommand copyWith(
          void Function(AudioTalkbackChunkCommand) updates) =>
      super.copyWith((message) => updates(message as AudioTalkbackChunkCommand))
          as AudioTalkbackChunkCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioTalkbackChunkCommand create() => AudioTalkbackChunkCommand._();
  @$core.override
  AudioTalkbackChunkCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioTalkbackChunkCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioTalkbackChunkCommand>(create);
  static AudioTalkbackChunkCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get opusData => $_getN(1);
  @$pb.TagNumber(2)
  set opusData($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOpusData() => $_has(1);
  @$pb.TagNumber(2)
  void clearOpusData() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timestampMs => $_getI64(2);
  @$pb.TagNumber(3)
  set timestampMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimestampMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestampMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get sequence => $_getIZ(3);
  @$pb.TagNumber(4)
  set sequence($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSequence() => $_has(3);
  @$pb.TagNumber(4)
  void clearSequence() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get levelDb => $_getN(4);
  @$pb.TagNumber(5)
  set levelDb($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLevelDb() => $_has(4);
  @$pb.TagNumber(5)
  void clearLevelDb() => $_clearField(5);
}

/// Talkback-Steuerung: Start/Stop/Duck eines Talkback-Streams auf dem Node.
class AudioTalkbackControlCommand extends $pb.GeneratedMessage {
  factory AudioTalkbackControlCommand({
    AudioTalkbackControlCommand_Action? action,
    $core.String? clientId,
    $core.double? duckDb,
    $core.int? duckMs,
  }) {
    final result = create();
    if (action != null) result.action = action;
    if (clientId != null) result.clientId = clientId;
    if (duckDb != null) result.duckDb = duckDb;
    if (duckMs != null) result.duckMs = duckMs;
    return result;
  }

  AudioTalkbackControlCommand._();

  factory AudioTalkbackControlCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioTalkbackControlCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioTalkbackControlCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aE<AudioTalkbackControlCommand_Action>(1, _omitFieldNames ? '' : 'action',
        enumValues: AudioTalkbackControlCommand_Action.values)
    ..aOS(2, _omitFieldNames ? '' : 'clientId')
    ..aD(3, _omitFieldNames ? '' : 'duckDb', fieldType: $pb.PbFieldType.OF)
    ..aI(4, _omitFieldNames ? '' : 'duckMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioTalkbackControlCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioTalkbackControlCommand copyWith(
          void Function(AudioTalkbackControlCommand) updates) =>
      super.copyWith(
              (message) => updates(message as AudioTalkbackControlCommand))
          as AudioTalkbackControlCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioTalkbackControlCommand create() =>
      AudioTalkbackControlCommand._();
  @$core.override
  AudioTalkbackControlCommand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioTalkbackControlCommand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioTalkbackControlCommand>(create);
  static AudioTalkbackControlCommand? _defaultInstance;

  @$pb.TagNumber(1)
  AudioTalkbackControlCommand_Action get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(AudioTalkbackControlCommand_Action value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get clientId => $_getSZ(1);
  @$pb.TagNumber(2)
  set clientId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClientId() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get duckDb => $_getN(2);
  @$pb.TagNumber(3)
  set duckDb($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDuckDb() => $_has(2);
  @$pb.TagNumber(3)
  void clearDuckDb() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get duckMs => $_getIZ(3);
  @$pb.TagNumber(4)
  set duckMs($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDuckMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearDuckMs() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
