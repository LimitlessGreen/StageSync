// This is a generated file - do not edit.
//
// Generated from stagesync/v1/talkback.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Init-Frame: erstes Frame eines StreamTalkback-Calls.
class TalkbackInitFrame extends $pb.GeneratedMessage {
  factory TalkbackInitFrame({
    $core.String? sessionId,
    $core.String? token,
    $core.String? clientId,
    $core.String? displayName,
    $core.Iterable<$core.String>? targetBusIds,
    $core.int? sampleRate,
    $core.int? channels,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (clientId != null) result.clientId = clientId;
    if (displayName != null) result.displayName = displayName;
    if (targetBusIds != null) result.targetBusIds.addAll(targetBusIds);
    if (sampleRate != null) result.sampleRate = sampleRate;
    if (channels != null) result.channels = channels;
    return result;
  }

  TalkbackInitFrame._();

  factory TalkbackInitFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TalkbackInitFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TalkbackInitFrame',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'clientId')
    ..aOS(4, _omitFieldNames ? '' : 'displayName')
    ..pPS(5, _omitFieldNames ? '' : 'targetBusIds')
    ..aI(6, _omitFieldNames ? '' : 'sampleRate')
    ..aI(7, _omitFieldNames ? '' : 'channels')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TalkbackInitFrame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TalkbackInitFrame copyWith(void Function(TalkbackInitFrame) updates) =>
      super.copyWith((message) => updates(message as TalkbackInitFrame))
          as TalkbackInitFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TalkbackInitFrame create() => TalkbackInitFrame._();
  @$core.override
  TalkbackInitFrame createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TalkbackInitFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TalkbackInitFrame>(create);
  static TalkbackInitFrame? _defaultInstance;

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
  $core.String get clientId => $_getSZ(2);
  @$pb.TagNumber(3)
  set clientId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClientId() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayName() => $_clearField(4);

  /// Routing: leer = alle Buses vom Typ TALKBACK aus der PatchConfig.
  /// Explizit: nur die genannten Bus-IDs.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get targetBusIds => $_getList(4);

  /// Audio-Format des Streams (Opus erwartet)
  @$pb.TagNumber(6)
  $core.int get sampleRate => $_getIZ(5);
  @$pb.TagNumber(6)
  set sampleRate($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSampleRate() => $_has(5);
  @$pb.TagNumber(6)
  void clearSampleRate() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get channels => $_getIZ(6);
  @$pb.TagNumber(7)
  set channels($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasChannels() => $_has(6);
  @$pb.TagNumber(7)
  void clearChannels() => $_clearField(7);
}

/// Ein Opus-codiertes Audio-Frame.
class AudioChunk extends $pb.GeneratedMessage {
  factory AudioChunk({
    $core.List<$core.int>? opusData,
    $fixnum.Int64? timestampMs,
    $core.int? sequence,
  }) {
    final result = create();
    if (opusData != null) result.opusData = opusData;
    if (timestampMs != null) result.timestampMs = timestampMs;
    if (sequence != null) result.sequence = sequence;
    return result;
  }

  AudioChunk._();

  factory AudioChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioChunk',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'opusData', $pb.PbFieldType.OY)
    ..aInt64(2, _omitFieldNames ? '' : 'timestampMs')
    ..aI(3, _omitFieldNames ? '' : 'sequence', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioChunk copyWith(void Function(AudioChunk) updates) =>
      super.copyWith((message) => updates(message as AudioChunk)) as AudioChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioChunk create() => AudioChunk._();
  @$core.override
  AudioChunk createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioChunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioChunk>(create);
  static AudioChunk? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get opusData => $_getN(0);
  @$pb.TagNumber(1)
  set opusData($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOpusData() => $_has(0);
  @$pb.TagNumber(1)
  void clearOpusData() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestampMs => $_getI64(1);
  @$pb.TagNumber(2)
  set timestampMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimestampMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestampMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sequence => $_getIZ(2);
  @$pb.TagNumber(3)
  set sequence($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearSequence() => $_clearField(3);
}

enum TalkbackFrame_Payload { init, audio, notSet }

/// Multiplexed Frame-Typ (Init oder Audio).
class TalkbackFrame extends $pb.GeneratedMessage {
  factory TalkbackFrame({
    TalkbackInitFrame? init,
    AudioChunk? audio,
  }) {
    final result = create();
    if (init != null) result.init = init;
    if (audio != null) result.audio = audio;
    return result;
  }

  TalkbackFrame._();

  factory TalkbackFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TalkbackFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, TalkbackFrame_Payload>
      _TalkbackFrame_PayloadByTag = {
    1: TalkbackFrame_Payload.init,
    2: TalkbackFrame_Payload.audio,
    0: TalkbackFrame_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TalkbackFrame',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<TalkbackInitFrame>(1, _omitFieldNames ? '' : 'init',
        subBuilder: TalkbackInitFrame.create)
    ..aOM<AudioChunk>(2, _omitFieldNames ? '' : 'audio',
        subBuilder: AudioChunk.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TalkbackFrame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TalkbackFrame copyWith(void Function(TalkbackFrame) updates) =>
      super.copyWith((message) => updates(message as TalkbackFrame))
          as TalkbackFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TalkbackFrame create() => TalkbackFrame._();
  @$core.override
  TalkbackFrame createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TalkbackFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TalkbackFrame>(create);
  static TalkbackFrame? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  TalkbackFrame_Payload whichPayload() =>
      _TalkbackFrame_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  TalkbackInitFrame get init => $_getN(0);
  @$pb.TagNumber(1)
  set init(TalkbackInitFrame value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInit() => $_has(0);
  @$pb.TagNumber(1)
  void clearInit() => $_clearField(1);
  @$pb.TagNumber(1)
  TalkbackInitFrame ensureInit() => $_ensure(0);

  @$pb.TagNumber(2)
  AudioChunk get audio => $_getN(1);
  @$pb.TagNumber(2)
  set audio(AudioChunk value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAudio() => $_has(1);
  @$pb.TagNumber(2)
  void clearAudio() => $_clearField(2);
  @$pb.TagNumber(2)
  AudioChunk ensureAudio() => $_ensure(1);
}

/// Status-Update vom Server an den sendenden Client.
class TalkbackStatus extends $pb.GeneratedMessage {
  factory TalkbackStatus({
    $core.bool? active,
    $core.Iterable<ActiveTalker>? activeTalkers,
    $core.String? errorMsg,
  }) {
    final result = create();
    if (active != null) result.active = active;
    if (activeTalkers != null) result.activeTalkers.addAll(activeTalkers);
    if (errorMsg != null) result.errorMsg = errorMsg;
    return result;
  }

  TalkbackStatus._();

  factory TalkbackStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TalkbackStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TalkbackStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'active')
    ..pPM<ActiveTalker>(2, _omitFieldNames ? '' : 'activeTalkers',
        subBuilder: ActiveTalker.create)
    ..aOS(3, _omitFieldNames ? '' : 'errorMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TalkbackStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TalkbackStatus copyWith(void Function(TalkbackStatus) updates) =>
      super.copyWith((message) => updates(message as TalkbackStatus))
          as TalkbackStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TalkbackStatus create() => TalkbackStatus._();
  @$core.override
  TalkbackStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TalkbackStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TalkbackStatus>(create);
  static TalkbackStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get active => $_getBF(0);
  @$pb.TagNumber(1)
  set active($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasActive() => $_has(0);
  @$pb.TagNumber(1)
  void clearActive() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ActiveTalker> get activeTalkers => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get errorMsg => $_getSZ(2);
  @$pb.TagNumber(3)
  set errorMsg($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrorMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrorMsg() => $_clearField(3);
}

/// Ein aktiver Sprecher in der Session.
class ActiveTalker extends $pb.GeneratedMessage {
  factory ActiveTalker({
    $core.String? clientId,
    $core.String? displayName,
    $fixnum.Int64? latencyMs,
    $core.Iterable<$core.String>? busIds,
  }) {
    final result = create();
    if (clientId != null) result.clientId = clientId;
    if (displayName != null) result.displayName = displayName;
    if (latencyMs != null) result.latencyMs = latencyMs;
    if (busIds != null) result.busIds.addAll(busIds);
    return result;
  }

  ActiveTalker._();

  factory ActiveTalker.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActiveTalker.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActiveTalker',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'clientId')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aInt64(3, _omitFieldNames ? '' : 'latencyMs')
    ..pPS(4, _omitFieldNames ? '' : 'busIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveTalker clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveTalker copyWith(void Function(ActiveTalker) updates) =>
      super.copyWith((message) => updates(message as ActiveTalker))
          as ActiveTalker;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActiveTalker create() => ActiveTalker._();
  @$core.override
  ActiveTalker createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ActiveTalker getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActiveTalker>(create);
  static ActiveTalker? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get latencyMs => $_getI64(2);
  @$pb.TagNumber(3)
  set latencyMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLatencyMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearLatencyMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get busIds => $_getList(3);
}

class ListActiveTalkersRequest extends $pb.GeneratedMessage {
  factory ListActiveTalkersRequest({
    $core.String? sessionId,
    $core.String? token,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    return result;
  }

  ListActiveTalkersRequest._();

  factory ListActiveTalkersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListActiveTalkersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListActiveTalkersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveTalkersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveTalkersRequest copyWith(
          void Function(ListActiveTalkersRequest) updates) =>
      super.copyWith((message) => updates(message as ListActiveTalkersRequest))
          as ListActiveTalkersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListActiveTalkersRequest create() => ListActiveTalkersRequest._();
  @$core.override
  ListActiveTalkersRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListActiveTalkersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListActiveTalkersRequest>(create);
  static ListActiveTalkersRequest? _defaultInstance;

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

class ListActiveTalkersResponse extends $pb.GeneratedMessage {
  factory ListActiveTalkersResponse({
    $core.Iterable<ActiveTalker>? talkers,
  }) {
    final result = create();
    if (talkers != null) result.talkers.addAll(talkers);
    return result;
  }

  ListActiveTalkersResponse._();

  factory ListActiveTalkersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListActiveTalkersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListActiveTalkersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..pPM<ActiveTalker>(1, _omitFieldNames ? '' : 'talkers',
        subBuilder: ActiveTalker.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveTalkersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveTalkersResponse copyWith(
          void Function(ListActiveTalkersResponse) updates) =>
      super.copyWith((message) => updates(message as ListActiveTalkersResponse))
          as ListActiveTalkersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListActiveTalkersResponse create() => ListActiveTalkersResponse._();
  @$core.override
  ListActiveTalkersResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListActiveTalkersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListActiveTalkersResponse>(create);
  static ListActiveTalkersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ActiveTalker> get talkers => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
