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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pb.dart' as $2;
import 'showcontrol.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'showcontrol.pbenum.dart';

enum Cue_Params { audio, maOsc, wait, gotoP, notSet }

class Cue extends $pb.GeneratedMessage {
  factory Cue({
    $core.String? cueId,
    $core.String? number,
    $core.String? label,
    $2.CueType? cueType,
    $2.CueState? state,
    $core.String? targetNodeId,
    $core.bool? autoContinue,
    $core.double? preWaitMs,
    $core.double? postWaitMs,
    AudioCueParams? audio,
    MaOscCueParams? maOsc,
    WaitCueParams? wait,
    GotoCueParams? gotoP,
    $2.Timestamp? createdAt,
    $2.Timestamp? updatedAt,
    $fixnum.Int64? version,
  }) {
    final result = create();
    if (cueId != null) result.cueId = cueId;
    if (number != null) result.number = number;
    if (label != null) result.label = label;
    if (cueType != null) result.cueType = cueType;
    if (state != null) result.state = state;
    if (targetNodeId != null) result.targetNodeId = targetNodeId;
    if (autoContinue != null) result.autoContinue = autoContinue;
    if (preWaitMs != null) result.preWaitMs = preWaitMs;
    if (postWaitMs != null) result.postWaitMs = postWaitMs;
    if (audio != null) result.audio = audio;
    if (maOsc != null) result.maOsc = maOsc;
    if (wait != null) result.wait = wait;
    if (gotoP != null) result.gotoP = gotoP;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (version != null) result.version = version;
    return result;
  }

  Cue._();

  factory Cue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Cue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Cue_Params> _Cue_ParamsByTag = {
    10: Cue_Params.audio,
    11: Cue_Params.maOsc,
    12: Cue_Params.wait,
    13: Cue_Params.gotoP,
    0: Cue_Params.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Cue',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13])
    ..aOS(1, _omitFieldNames ? '' : 'cueId')
    ..aOS(2, _omitFieldNames ? '' : 'number')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aE<$2.CueType>(4, _omitFieldNames ? '' : 'cueType',
        enumValues: $2.CueType.values)
    ..aE<$2.CueState>(5, _omitFieldNames ? '' : 'state',
        enumValues: $2.CueState.values)
    ..aOS(6, _omitFieldNames ? '' : 'targetNodeId')
    ..aOB(7, _omitFieldNames ? '' : 'autoContinue')
    ..aD(8, _omitFieldNames ? '' : 'preWaitMs')
    ..aD(9, _omitFieldNames ? '' : 'postWaitMs')
    ..aOM<AudioCueParams>(10, _omitFieldNames ? '' : 'audio',
        subBuilder: AudioCueParams.create)
    ..aOM<MaOscCueParams>(11, _omitFieldNames ? '' : 'maOsc',
        subBuilder: MaOscCueParams.create)
    ..aOM<WaitCueParams>(12, _omitFieldNames ? '' : 'wait',
        subBuilder: WaitCueParams.create)
    ..aOM<GotoCueParams>(13, _omitFieldNames ? '' : 'gotoP',
        subBuilder: GotoCueParams.create)
    ..aOM<$2.Timestamp>(14, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(15, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $2.Timestamp.create)
    ..aInt64(16, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Cue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Cue copyWith(void Function(Cue) updates) =>
      super.copyWith((message) => updates(message as Cue)) as Cue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Cue create() => Cue._();
  @$core.override
  Cue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Cue getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Cue>(create);
  static Cue? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  Cue_Params whichParams() => _Cue_ParamsByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  void clearParams() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get cueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get number => $_getSZ(1);
  @$pb.TagNumber(2)
  set number($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumber() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $2.CueType get cueType => $_getN(3);
  @$pb.TagNumber(4)
  set cueType($2.CueType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCueType() => $_has(3);
  @$pb.TagNumber(4)
  void clearCueType() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.CueState get state => $_getN(4);
  @$pb.TagNumber(5)
  set state($2.CueState value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasState() => $_has(4);
  @$pb.TagNumber(5)
  void clearState() => $_clearField(5);

  /// Welcher Node führt diese Cue aus
  @$pb.TagNumber(6)
  $core.String get targetNodeId => $_getSZ(5);
  @$pb.TagNumber(6)
  set targetNodeId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTargetNodeId() => $_has(5);
  @$pb.TagNumber(6)
  void clearTargetNodeId() => $_clearField(6);

  /// Leer = nächste Cue automatisch, sonst wartet die Engine auf GO
  @$pb.TagNumber(7)
  $core.bool get autoContinue => $_getBF(6);
  @$pb.TagNumber(7)
  set autoContinue($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAutoContinue() => $_has(6);
  @$pb.TagNumber(7)
  void clearAutoContinue() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get preWaitMs => $_getN(7);
  @$pb.TagNumber(8)
  set preWaitMs($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPreWaitMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearPreWaitMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get postWaitMs => $_getN(8);
  @$pb.TagNumber(9)
  set postWaitMs($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPostWaitMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearPostWaitMs() => $_clearField(9);

  @$pb.TagNumber(10)
  AudioCueParams get audio => $_getN(9);
  @$pb.TagNumber(10)
  set audio(AudioCueParams value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasAudio() => $_has(9);
  @$pb.TagNumber(10)
  void clearAudio() => $_clearField(10);
  @$pb.TagNumber(10)
  AudioCueParams ensureAudio() => $_ensure(9);

  @$pb.TagNumber(11)
  MaOscCueParams get maOsc => $_getN(10);
  @$pb.TagNumber(11)
  set maOsc(MaOscCueParams value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasMaOsc() => $_has(10);
  @$pb.TagNumber(11)
  void clearMaOsc() => $_clearField(11);
  @$pb.TagNumber(11)
  MaOscCueParams ensureMaOsc() => $_ensure(10);

  @$pb.TagNumber(12)
  WaitCueParams get wait => $_getN(11);
  @$pb.TagNumber(12)
  set wait(WaitCueParams value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasWait() => $_has(11);
  @$pb.TagNumber(12)
  void clearWait() => $_clearField(12);
  @$pb.TagNumber(12)
  WaitCueParams ensureWait() => $_ensure(11);

  @$pb.TagNumber(13)
  GotoCueParams get gotoP => $_getN(12);
  @$pb.TagNumber(13)
  set gotoP(GotoCueParams value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasGotoP() => $_has(12);
  @$pb.TagNumber(13)
  void clearGotoP() => $_clearField(13);
  @$pb.TagNumber(13)
  GotoCueParams ensureGotoP() => $_ensure(12);

  @$pb.TagNumber(14)
  $2.Timestamp get createdAt => $_getN(13);
  @$pb.TagNumber(14)
  set createdAt($2.Timestamp value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasCreatedAt() => $_has(13);
  @$pb.TagNumber(14)
  void clearCreatedAt() => $_clearField(14);
  @$pb.TagNumber(14)
  $2.Timestamp ensureCreatedAt() => $_ensure(13);

  @$pb.TagNumber(15)
  $2.Timestamp get updatedAt => $_getN(14);
  @$pb.TagNumber(15)
  set updatedAt($2.Timestamp value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasUpdatedAt() => $_has(14);
  @$pb.TagNumber(15)
  void clearUpdatedAt() => $_clearField(15);
  @$pb.TagNumber(15)
  $2.Timestamp ensureUpdatedAt() => $_ensure(14);

  @$pb.TagNumber(16)
  $fixnum.Int64 get version => $_getI64(15);
  @$pb.TagNumber(16)
  set version($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasVersion() => $_has(15);
  @$pb.TagNumber(16)
  void clearVersion() => $_clearField(16);
}

class AudioCueParams extends $pb.GeneratedMessage {
  factory AudioCueParams({
    $core.String? filePath,
    $core.double? volumeDb,
    $core.double? fadeInMs,
    $core.double? fadeOutMs,
    $core.bool? loop,
    $core.double? startTimeMs,
    $core.double? endTimeMs,
    $core.String? outputDevice,
  }) {
    final result = create();
    if (filePath != null) result.filePath = filePath;
    if (volumeDb != null) result.volumeDb = volumeDb;
    if (fadeInMs != null) result.fadeInMs = fadeInMs;
    if (fadeOutMs != null) result.fadeOutMs = fadeOutMs;
    if (loop != null) result.loop = loop;
    if (startTimeMs != null) result.startTimeMs = startTimeMs;
    if (endTimeMs != null) result.endTimeMs = endTimeMs;
    if (outputDevice != null) result.outputDevice = outputDevice;
    return result;
  }

  AudioCueParams._();

  factory AudioCueParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioCueParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioCueParams',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'filePath')
    ..aD(2, _omitFieldNames ? '' : 'volumeDb')
    ..aD(3, _omitFieldNames ? '' : 'fadeInMs')
    ..aD(4, _omitFieldNames ? '' : 'fadeOutMs')
    ..aOB(5, _omitFieldNames ? '' : 'loop')
    ..aD(6, _omitFieldNames ? '' : 'startTimeMs')
    ..aD(7, _omitFieldNames ? '' : 'endTimeMs')
    ..aOS(8, _omitFieldNames ? '' : 'outputDevice')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioCueParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioCueParams copyWith(void Function(AudioCueParams) updates) =>
      super.copyWith((message) => updates(message as AudioCueParams))
          as AudioCueParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioCueParams create() => AudioCueParams._();
  @$core.override
  AudioCueParams createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioCueParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioCueParams>(create);
  static AudioCueParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get filePath => $_getSZ(0);
  @$pb.TagNumber(1)
  set filePath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilePath() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilePath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get volumeDb => $_getN(1);
  @$pb.TagNumber(2)
  set volumeDb($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVolumeDb() => $_has(1);
  @$pb.TagNumber(2)
  void clearVolumeDb() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get fadeInMs => $_getN(2);
  @$pb.TagNumber(3)
  set fadeInMs($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFadeInMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearFadeInMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get fadeOutMs => $_getN(3);
  @$pb.TagNumber(4)
  set fadeOutMs($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFadeOutMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearFadeOutMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get loop => $_getBF(4);
  @$pb.TagNumber(5)
  set loop($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLoop() => $_has(4);
  @$pb.TagNumber(5)
  void clearLoop() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get startTimeMs => $_getN(5);
  @$pb.TagNumber(6)
  set startTimeMs($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasStartTimeMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearStartTimeMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get endTimeMs => $_getN(6);
  @$pb.TagNumber(7)
  set endTimeMs($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEndTimeMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearEndTimeMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get outputDevice => $_getSZ(7);
  @$pb.TagNumber(8)
  set outputDevice($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasOutputDevice() => $_has(7);
  @$pb.TagNumber(8)
  void clearOutputDevice() => $_clearField(8);
}

class MaOscCueParams extends $pb.GeneratedMessage {
  factory MaOscCueParams({
    $core.String? oscAddress,
    $core.String? oscArgument,
    $core.int? executorPage,
    $core.int? executorNo,
    MaOscCueParams_MaCommand? command,
    $core.int? gotoCue,
  }) {
    final result = create();
    if (oscAddress != null) result.oscAddress = oscAddress;
    if (oscArgument != null) result.oscArgument = oscArgument;
    if (executorPage != null) result.executorPage = executorPage;
    if (executorNo != null) result.executorNo = executorNo;
    if (command != null) result.command = command;
    if (gotoCue != null) result.gotoCue = gotoCue;
    return result;
  }

  MaOscCueParams._();

  factory MaOscCueParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MaOscCueParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MaOscCueParams',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'oscAddress')
    ..aOS(2, _omitFieldNames ? '' : 'oscArgument')
    ..aI(3, _omitFieldNames ? '' : 'executorPage')
    ..aI(4, _omitFieldNames ? '' : 'executorNo')
    ..aE<MaOscCueParams_MaCommand>(5, _omitFieldNames ? '' : 'command',
        enumValues: MaOscCueParams_MaCommand.values)
    ..aI(6, _omitFieldNames ? '' : 'gotoCue')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MaOscCueParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MaOscCueParams copyWith(void Function(MaOscCueParams) updates) =>
      super.copyWith((message) => updates(message as MaOscCueParams))
          as MaOscCueParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MaOscCueParams create() => MaOscCueParams._();
  @$core.override
  MaOscCueParams createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MaOscCueParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MaOscCueParams>(create);
  static MaOscCueParams? _defaultInstance;

  /// OSC-Adresse, die an GrandMA gesendet wird
  /// z.B. "/gma3/cmd" mit Argument "Executor 1 Go"
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

  /// Alternativ: direkte GrandMA-Executor-Steuerung
  @$pb.TagNumber(3)
  $core.int get executorPage => $_getIZ(2);
  @$pb.TagNumber(3)
  set executorPage($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExecutorPage() => $_has(2);
  @$pb.TagNumber(3)
  void clearExecutorPage() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get executorNo => $_getIZ(3);
  @$pb.TagNumber(4)
  set executorNo($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExecutorNo() => $_has(3);
  @$pb.TagNumber(4)
  void clearExecutorNo() => $_clearField(4);

  @$pb.TagNumber(5)
  MaOscCueParams_MaCommand get command => $_getN(4);
  @$pb.TagNumber(5)
  set command(MaOscCueParams_MaCommand value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCommand() => $_has(4);
  @$pb.TagNumber(5)
  void clearCommand() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get gotoCue => $_getIZ(5);
  @$pb.TagNumber(6)
  set gotoCue($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGotoCue() => $_has(5);
  @$pb.TagNumber(6)
  void clearGotoCue() => $_clearField(6);
}

class WaitCueParams extends $pb.GeneratedMessage {
  factory WaitCueParams({
    $core.double? durationMs,
  }) {
    final result = create();
    if (durationMs != null) result.durationMs = durationMs;
    return result;
  }

  WaitCueParams._();

  factory WaitCueParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WaitCueParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WaitCueParams',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'durationMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WaitCueParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WaitCueParams copyWith(void Function(WaitCueParams) updates) =>
      super.copyWith((message) => updates(message as WaitCueParams))
          as WaitCueParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WaitCueParams create() => WaitCueParams._();
  @$core.override
  WaitCueParams createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WaitCueParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WaitCueParams>(create);
  static WaitCueParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get durationMs => $_getN(0);
  @$pb.TagNumber(1)
  set durationMs($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDurationMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearDurationMs() => $_clearField(1);
}

class GotoCueParams extends $pb.GeneratedMessage {
  factory GotoCueParams({
    $core.String? targetCueId,
    $core.String? targetNumber,
  }) {
    final result = create();
    if (targetCueId != null) result.targetCueId = targetCueId;
    if (targetNumber != null) result.targetNumber = targetNumber;
    return result;
  }

  GotoCueParams._();

  factory GotoCueParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GotoCueParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GotoCueParams',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'targetCueId')
    ..aOS(2, _omitFieldNames ? '' : 'targetNumber')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GotoCueParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GotoCueParams copyWith(void Function(GotoCueParams) updates) =>
      super.copyWith((message) => updates(message as GotoCueParams))
          as GotoCueParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GotoCueParams create() => GotoCueParams._();
  @$core.override
  GotoCueParams createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GotoCueParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GotoCueParams>(create);
  static GotoCueParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get targetCueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set targetCueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTargetCueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTargetCueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get targetNumber => $_getSZ(1);
  @$pb.TagNumber(2)
  set targetNumber($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTargetNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetNumber() => $_clearField(2);
}

class CueList extends $pb.GeneratedMessage {
  factory CueList({
    $core.String? cueListId,
    $core.String? name,
    $core.Iterable<Cue>? cues,
    $core.String? activeCueId,
    $core.String? nextCueId,
    $fixnum.Int64? version,
    $2.Timestamp? updatedAt,
  }) {
    final result = create();
    if (cueListId != null) result.cueListId = cueListId;
    if (name != null) result.name = name;
    if (cues != null) result.cues.addAll(cues);
    if (activeCueId != null) result.activeCueId = activeCueId;
    if (nextCueId != null) result.nextCueId = nextCueId;
    if (version != null) result.version = version;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  CueList._();

  factory CueList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CueList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CueList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cueListId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pPM<Cue>(3, _omitFieldNames ? '' : 'cues', subBuilder: Cue.create)
    ..aOS(4, _omitFieldNames ? '' : 'activeCueId')
    ..aOS(5, _omitFieldNames ? '' : 'nextCueId')
    ..aInt64(6, _omitFieldNames ? '' : 'version')
    ..aOM<$2.Timestamp>(7, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CueList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CueList copyWith(void Function(CueList) updates) =>
      super.copyWith((message) => updates(message as CueList)) as CueList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CueList create() => CueList._();
  @$core.override
  CueList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CueList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CueList>(create);
  static CueList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cueListId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cueListId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCueListId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueListId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Cue> get cues => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get activeCueId => $_getSZ(3);
  @$pb.TagNumber(4)
  set activeCueId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasActiveCueId() => $_has(3);
  @$pb.TagNumber(4)
  void clearActiveCueId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get nextCueId => $_getSZ(4);
  @$pb.TagNumber(5)
  set nextCueId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNextCueId() => $_has(4);
  @$pb.TagNumber(5)
  void clearNextCueId() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get version => $_getI64(5);
  @$pb.TagNumber(6)
  set version($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearVersion() => $_clearField(6);

  @$pb.TagNumber(7)
  $2.Timestamp get updatedAt => $_getN(6);
  @$pb.TagNumber(7)
  set updatedAt($2.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.Timestamp ensureUpdatedAt() => $_ensure(6);
}

class GetCueListRequest extends $pb.GeneratedMessage {
  factory GetCueListRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? cueListId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (cueListId != null) result.cueListId = cueListId;
    return result;
  }

  GetCueListRequest._();

  factory GetCueListRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetCueListRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCueListRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'cueListId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCueListRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCueListRequest copyWith(void Function(GetCueListRequest) updates) =>
      super.copyWith((message) => updates(message as GetCueListRequest))
          as GetCueListRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetCueListRequest create() => GetCueListRequest._();
  @$core.override
  GetCueListRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetCueListRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetCueListRequest>(create);
  static GetCueListRequest? _defaultInstance;

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
  $core.String get cueListId => $_getSZ(2);
  @$pb.TagNumber(3)
  set cueListId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCueListId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCueListId() => $_clearField(3);
}

class UpdateCueListRequest extends $pb.GeneratedMessage {
  factory UpdateCueListRequest({
    $core.String? sessionId,
    $core.String? token,
    CueList? cueList,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (cueList != null) result.cueList = cueList;
    return result;
  }

  UpdateCueListRequest._();

  factory UpdateCueListRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateCueListRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateCueListRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOM<CueList>(3, _omitFieldNames ? '' : 'cueList',
        subBuilder: CueList.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCueListRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCueListRequest copyWith(void Function(UpdateCueListRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateCueListRequest))
          as UpdateCueListRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateCueListRequest create() => UpdateCueListRequest._();
  @$core.override
  UpdateCueListRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateCueListRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateCueListRequest>(create);
  static UpdateCueListRequest? _defaultInstance;

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
  CueList get cueList => $_getN(2);
  @$pb.TagNumber(3)
  set cueList(CueList value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCueList() => $_has(2);
  @$pb.TagNumber(3)
  void clearCueList() => $_clearField(3);
  @$pb.TagNumber(3)
  CueList ensureCueList() => $_ensure(2);
}

class CueListResponse extends $pb.GeneratedMessage {
  factory CueListResponse({
    CueList? cueList,
  }) {
    final result = create();
    if (cueList != null) result.cueList = cueList;
    return result;
  }

  CueListResponse._();

  factory CueListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CueListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CueListResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOM<CueList>(1, _omitFieldNames ? '' : 'cueList',
        subBuilder: CueList.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CueListResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CueListResponse copyWith(void Function(CueListResponse) updates) =>
      super.copyWith((message) => updates(message as CueListResponse))
          as CueListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CueListResponse create() => CueListResponse._();
  @$core.override
  CueListResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CueListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CueListResponse>(create);
  static CueListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  CueList get cueList => $_getN(0);
  @$pb.TagNumber(1)
  set cueList(CueList value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCueList() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueList() => $_clearField(1);
  @$pb.TagNumber(1)
  CueList ensureCueList() => $_ensure(0);
}

class UpsertCueRequest extends $pb.GeneratedMessage {
  factory UpsertCueRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? cueListId,
    Cue? cue,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (cueListId != null) result.cueListId = cueListId;
    if (cue != null) result.cue = cue;
    return result;
  }

  UpsertCueRequest._();

  factory UpsertCueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpsertCueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpsertCueRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'cueListId')
    ..aOM<Cue>(4, _omitFieldNames ? '' : 'cue', subBuilder: Cue.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpsertCueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpsertCueRequest copyWith(void Function(UpsertCueRequest) updates) =>
      super.copyWith((message) => updates(message as UpsertCueRequest))
          as UpsertCueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpsertCueRequest create() => UpsertCueRequest._();
  @$core.override
  UpsertCueRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpsertCueRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpsertCueRequest>(create);
  static UpsertCueRequest? _defaultInstance;

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
  $core.String get cueListId => $_getSZ(2);
  @$pb.TagNumber(3)
  set cueListId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCueListId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCueListId() => $_clearField(3);

  @$pb.TagNumber(4)
  Cue get cue => $_getN(3);
  @$pb.TagNumber(4)
  set cue(Cue value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCue() => $_has(3);
  @$pb.TagNumber(4)
  void clearCue() => $_clearField(4);
  @$pb.TagNumber(4)
  Cue ensureCue() => $_ensure(3);
}

class CueResponse extends $pb.GeneratedMessage {
  factory CueResponse({
    Cue? cue,
  }) {
    final result = create();
    if (cue != null) result.cue = cue;
    return result;
  }

  CueResponse._();

  factory CueResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CueResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CueResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOM<Cue>(1, _omitFieldNames ? '' : 'cue', subBuilder: Cue.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CueResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CueResponse copyWith(void Function(CueResponse) updates) =>
      super.copyWith((message) => updates(message as CueResponse))
          as CueResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CueResponse create() => CueResponse._();
  @$core.override
  CueResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CueResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CueResponse>(create);
  static CueResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Cue get cue => $_getN(0);
  @$pb.TagNumber(1)
  set cue(Cue value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCue() => $_has(0);
  @$pb.TagNumber(1)
  void clearCue() => $_clearField(1);
  @$pb.TagNumber(1)
  Cue ensureCue() => $_ensure(0);
}

class DeleteCueRequest extends $pb.GeneratedMessage {
  factory DeleteCueRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? cueListId,
    $core.String? cueId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (cueListId != null) result.cueListId = cueListId;
    if (cueId != null) result.cueId = cueId;
    return result;
  }

  DeleteCueRequest._();

  factory DeleteCueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteCueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteCueRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'cueListId')
    ..aOS(4, _omitFieldNames ? '' : 'cueId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteCueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteCueRequest copyWith(void Function(DeleteCueRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteCueRequest))
          as DeleteCueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteCueRequest create() => DeleteCueRequest._();
  @$core.override
  DeleteCueRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteCueRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteCueRequest>(create);
  static DeleteCueRequest? _defaultInstance;

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
  $core.String get cueListId => $_getSZ(2);
  @$pb.TagNumber(3)
  set cueListId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCueListId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCueListId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get cueId => $_getSZ(3);
  @$pb.TagNumber(4)
  set cueId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCueId() => $_has(3);
  @$pb.TagNumber(4)
  void clearCueId() => $_clearField(4);
}

class GoRequest extends $pb.GeneratedMessage {
  factory GoRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? cueId,
    $core.String? commandId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (cueId != null) result.cueId = cueId;
    if (commandId != null) result.commandId = commandId;
    return result;
  }

  GoRequest._();

  factory GoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GoRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'cueId')
    ..aOS(4, _omitFieldNames ? '' : 'commandId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoRequest copyWith(void Function(GoRequest) updates) =>
      super.copyWith((message) => updates(message as GoRequest)) as GoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GoRequest create() => GoRequest._();
  @$core.override
  GoRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GoRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GoRequest>(create);
  static GoRequest? _defaultInstance;

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
  $core.String get cueId => $_getSZ(2);
  @$pb.TagNumber(3)
  set cueId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCueId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCueId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get commandId => $_getSZ(3);
  @$pb.TagNumber(4)
  set commandId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCommandId() => $_has(3);
  @$pb.TagNumber(4)
  void clearCommandId() => $_clearField(4);
}

class GoResponse extends $pb.GeneratedMessage {
  factory GoResponse({
    Cue? executingCue,
    Cue? nextCue,
  }) {
    final result = create();
    if (executingCue != null) result.executingCue = executingCue;
    if (nextCue != null) result.nextCue = nextCue;
    return result;
  }

  GoResponse._();

  factory GoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOM<Cue>(1, _omitFieldNames ? '' : 'executingCue', subBuilder: Cue.create)
    ..aOM<Cue>(2, _omitFieldNames ? '' : 'nextCue', subBuilder: Cue.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoResponse copyWith(void Function(GoResponse) updates) =>
      super.copyWith((message) => updates(message as GoResponse)) as GoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GoResponse create() => GoResponse._();
  @$core.override
  GoResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GoResponse>(create);
  static GoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Cue get executingCue => $_getN(0);
  @$pb.TagNumber(1)
  set executingCue(Cue value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasExecutingCue() => $_has(0);
  @$pb.TagNumber(1)
  void clearExecutingCue() => $_clearField(1);
  @$pb.TagNumber(1)
  Cue ensureExecutingCue() => $_ensure(0);

  @$pb.TagNumber(2)
  Cue get nextCue => $_getN(1);
  @$pb.TagNumber(2)
  set nextCue(Cue value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNextCue() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextCue() => $_clearField(2);
  @$pb.TagNumber(2)
  Cue ensureNextCue() => $_ensure(1);
}

class StopRequest extends $pb.GeneratedMessage {
  factory StopRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? commandId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (commandId != null) result.commandId = commandId;
    return result;
  }

  StopRequest._();

  factory StopRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StopRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'commandId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopRequest copyWith(void Function(StopRequest) updates) =>
      super.copyWith((message) => updates(message as StopRequest))
          as StopRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StopRequest create() => StopRequest._();
  @$core.override
  StopRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StopRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopRequest>(create);
  static StopRequest? _defaultInstance;

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
  $core.String get commandId => $_getSZ(2);
  @$pb.TagNumber(3)
  set commandId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommandId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommandId() => $_clearField(3);
}

class PauseRequest extends $pb.GeneratedMessage {
  factory PauseRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? commandId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (commandId != null) result.commandId = commandId;
    return result;
  }

  PauseRequest._();

  factory PauseRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PauseRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PauseRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'commandId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PauseRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PauseRequest copyWith(void Function(PauseRequest) updates) =>
      super.copyWith((message) => updates(message as PauseRequest))
          as PauseRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PauseRequest create() => PauseRequest._();
  @$core.override
  PauseRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PauseRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PauseRequest>(create);
  static PauseRequest? _defaultInstance;

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
  $core.String get commandId => $_getSZ(2);
  @$pb.TagNumber(3)
  set commandId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommandId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommandId() => $_clearField(3);
}

class ResumeRequest extends $pb.GeneratedMessage {
  factory ResumeRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? commandId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (commandId != null) result.commandId = commandId;
    return result;
  }

  ResumeRequest._();

  factory ResumeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResumeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResumeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'commandId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResumeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResumeRequest copyWith(void Function(ResumeRequest) updates) =>
      super.copyWith((message) => updates(message as ResumeRequest))
          as ResumeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResumeRequest create() => ResumeRequest._();
  @$core.override
  ResumeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResumeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResumeRequest>(create);
  static ResumeRequest? _defaultInstance;

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
  $core.String get commandId => $_getSZ(2);
  @$pb.TagNumber(3)
  set commandId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommandId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommandId() => $_clearField(3);
}

class WatchShowStateRequest extends $pb.GeneratedMessage {
  factory WatchShowStateRequest({
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

  WatchShowStateRequest._();

  factory WatchShowStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchShowStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchShowStateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'nodeId')
    ..aOS(3, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchShowStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchShowStateRequest copyWith(
          void Function(WatchShowStateRequest) updates) =>
      super.copyWith((message) => updates(message as WatchShowStateRequest))
          as WatchShowStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchShowStateRequest create() => WatchShowStateRequest._();
  @$core.override
  WatchShowStateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchShowStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchShowStateRequest>(create);
  static WatchShowStateRequest? _defaultInstance;

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

class ShowStateEvent extends $pb.GeneratedMessage {
  factory ShowStateEvent({
    ShowStateEvent_Type? type,
    CueList? cueList,
    Cue? affectedCue,
    $core.String? nodeId,
    $2.Timestamp? occurredAt,
    $core.String? errorMsg,
    $fixnum.Int64? seq,
    $core.bool? isPaused,
    $fixnum.Int64? cueStartedAtMs,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (cueList != null) result.cueList = cueList;
    if (affectedCue != null) result.affectedCue = affectedCue;
    if (nodeId != null) result.nodeId = nodeId;
    if (occurredAt != null) result.occurredAt = occurredAt;
    if (errorMsg != null) result.errorMsg = errorMsg;
    if (seq != null) result.seq = seq;
    if (isPaused != null) result.isPaused = isPaused;
    if (cueStartedAtMs != null) result.cueStartedAtMs = cueStartedAtMs;
    return result;
  }

  ShowStateEvent._();

  factory ShowStateEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ShowStateEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShowStateEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aE<ShowStateEvent_Type>(1, _omitFieldNames ? '' : 'type',
        enumValues: ShowStateEvent_Type.values)
    ..aOM<CueList>(2, _omitFieldNames ? '' : 'cueList',
        subBuilder: CueList.create)
    ..aOM<Cue>(3, _omitFieldNames ? '' : 'affectedCue', subBuilder: Cue.create)
    ..aOS(4, _omitFieldNames ? '' : 'nodeId')
    ..aOM<$2.Timestamp>(5, _omitFieldNames ? '' : 'occurredAt',
        subBuilder: $2.Timestamp.create)
    ..aOS(6, _omitFieldNames ? '' : 'errorMsg')
    ..aInt64(7, _omitFieldNames ? '' : 'seq')
    ..aOB(8, _omitFieldNames ? '' : 'isPaused')
    ..aInt64(9, _omitFieldNames ? '' : 'cueStartedAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShowStateEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShowStateEvent copyWith(void Function(ShowStateEvent) updates) =>
      super.copyWith((message) => updates(message as ShowStateEvent))
          as ShowStateEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ShowStateEvent create() => ShowStateEvent._();
  @$core.override
  ShowStateEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ShowStateEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShowStateEvent>(create);
  static ShowStateEvent? _defaultInstance;

  @$pb.TagNumber(1)
  ShowStateEvent_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(ShowStateEvent_Type value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  CueList get cueList => $_getN(1);
  @$pb.TagNumber(2)
  set cueList(CueList value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCueList() => $_has(1);
  @$pb.TagNumber(2)
  void clearCueList() => $_clearField(2);
  @$pb.TagNumber(2)
  CueList ensureCueList() => $_ensure(1);

  @$pb.TagNumber(3)
  Cue get affectedCue => $_getN(2);
  @$pb.TagNumber(3)
  set affectedCue(Cue value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAffectedCue() => $_has(2);
  @$pb.TagNumber(3)
  void clearAffectedCue() => $_clearField(3);
  @$pb.TagNumber(3)
  Cue ensureAffectedCue() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get nodeId => $_getSZ(3);
  @$pb.TagNumber(4)
  set nodeId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNodeId() => $_has(3);
  @$pb.TagNumber(4)
  void clearNodeId() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.Timestamp get occurredAt => $_getN(4);
  @$pb.TagNumber(5)
  set occurredAt($2.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasOccurredAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearOccurredAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Timestamp ensureOccurredAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get errorMsg => $_getSZ(5);
  @$pb.TagNumber(6)
  set errorMsg($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasErrorMsg() => $_has(5);
  @$pb.TagNumber(6)
  void clearErrorMsg() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get seq => $_getI64(6);
  @$pb.TagNumber(7)
  set seq($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSeq() => $_has(6);
  @$pb.TagNumber(7)
  void clearSeq() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isPaused => $_getBF(7);
  @$pb.TagNumber(8)
  set isPaused($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsPaused() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsPaused() => $_clearField(8);

  /// Explizite Startzeit der aktiven Cue in Server-Unix-Millis.
  /// Bei TYPE_CUE_STARTED und Snapshot-Events gesetzt.
  /// Clients nutzen diesen Wert + ClockSync für korrekte Elapsed-Berechnung.
  @$pb.TagNumber(9)
  $fixnum.Int64 get cueStartedAtMs => $_getI64(8);
  @$pb.TagNumber(9)
  set cueStartedAtMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCueStartedAtMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearCueStartedAtMs() => $_clearField(9);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
