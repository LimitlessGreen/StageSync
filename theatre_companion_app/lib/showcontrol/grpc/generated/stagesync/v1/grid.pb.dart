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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'bus.pb.dart' as $2;
import 'common.pb.dart' as $3;
import 'grid.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'grid.pbenum.dart';

class Grid extends $pb.GeneratedMessage {
  factory Grid({
    $core.String? gridId,
    $core.String? name,
    $core.Iterable<GridTrack>? tracks,
    $core.Iterable<GridScene>? scenes,
    $core.Iterable<GridClip>? clips,
    GridQuantize? quantize,
    $fixnum.Int64? version,
  }) {
    final result = create();
    if (gridId != null) result.gridId = gridId;
    if (name != null) result.name = name;
    if (tracks != null) result.tracks.addAll(tracks);
    if (scenes != null) result.scenes.addAll(scenes);
    if (clips != null) result.clips.addAll(clips);
    if (quantize != null) result.quantize = quantize;
    if (version != null) result.version = version;
    return result;
  }

  Grid._();

  factory Grid.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Grid.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Grid',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'gridId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pPM<GridTrack>(3, _omitFieldNames ? '' : 'tracks',
        subBuilder: GridTrack.create)
    ..pPM<GridScene>(4, _omitFieldNames ? '' : 'scenes',
        subBuilder: GridScene.create)
    ..pPM<GridClip>(5, _omitFieldNames ? '' : 'clips',
        subBuilder: GridClip.create)
    ..aE<GridQuantize>(6, _omitFieldNames ? '' : 'quantize',
        enumValues: GridQuantize.values)
    ..aInt64(7, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Grid clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Grid copyWith(void Function(Grid) updates) =>
      super.copyWith((message) => updates(message as Grid)) as Grid;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Grid create() => Grid._();
  @$core.override
  Grid createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Grid getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Grid>(create);
  static Grid? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<GridTrack> get tracks => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<GridScene> get scenes => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<GridClip> get clips => $_getList(4);

  @$pb.TagNumber(6)
  GridQuantize get quantize => $_getN(5);
  @$pb.TagNumber(6)
  set quantize(GridQuantize value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasQuantize() => $_has(5);
  @$pb.TagNumber(6)
  void clearQuantize() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get version => $_getI64(6);
  @$pb.TagNumber(7)
  set version($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasVersion() => $_has(6);
  @$pb.TagNumber(7)
  void clearVersion() => $_clearField(7);
}

/// Spalte: gruppiert auf einen Audio-Bus, optional exklusiv (nur 1 Clip live).
class GridTrack extends $pb.GeneratedMessage {
  factory GridTrack({
    $core.String? trackId,
    $core.String? name,
    $core.String? colorHex,
    $core.Iterable<$2.BusSend>? busSends,
    $core.bool? exclusive,
  }) {
    final result = create();
    if (trackId != null) result.trackId = trackId;
    if (name != null) result.name = name;
    if (colorHex != null) result.colorHex = colorHex;
    if (busSends != null) result.busSends.addAll(busSends);
    if (exclusive != null) result.exclusive = exclusive;
    return result;
  }

  GridTrack._();

  factory GridTrack.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GridTrack.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GridTrack',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'trackId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'colorHex')
    ..pPM<$2.BusSend>(4, _omitFieldNames ? '' : 'busSends',
        subBuilder: $2.BusSend.create)
    ..aOB(5, _omitFieldNames ? '' : 'exclusive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridTrack clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridTrack copyWith(void Function(GridTrack) updates) =>
      super.copyWith((message) => updates(message as GridTrack)) as GridTrack;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GridTrack create() => GridTrack._();
  @$core.override
  GridTrack createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GridTrack getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridTrack>(create);
  static GridTrack? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get trackId => $_getSZ(0);
  @$pb.TagNumber(1)
  set trackId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTrackId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTrackId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get colorHex => $_getSZ(2);
  @$pb.TagNumber(3)
  set colorHex($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasColorHex() => $_has(2);
  @$pb.TagNumber(3)
  void clearColorHex() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$2.BusSend> get busSends => $_getList(3);

  @$pb.TagNumber(5)
  $core.bool get exclusive => $_getBF(4);
  @$pb.TagNumber(5)
  set exclusive($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExclusive() => $_has(4);
  @$pb.TagNumber(5)
  void clearExclusive() => $_clearField(5);
}

/// Reihe: rein deklarativ; LaunchScene löst alle Clips der Reihe aus.
class GridScene extends $pb.GeneratedMessage {
  factory GridScene({
    $core.String? sceneId,
    $core.String? name,
    $core.String? colorHex,
  }) {
    final result = create();
    if (sceneId != null) result.sceneId = sceneId;
    if (name != null) result.name = name;
    if (colorHex != null) result.colorHex = colorHex;
    return result;
  }

  GridScene._();

  factory GridScene.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GridScene.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GridScene',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sceneId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'colorHex')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridScene clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridScene copyWith(void Function(GridScene) updates) =>
      super.copyWith((message) => updates(message as GridScene)) as GridScene;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GridScene create() => GridScene._();
  @$core.override
  GridScene createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GridScene getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridScene>(create);
  static GridScene? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sceneId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sceneId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSceneId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSceneId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get colorHex => $_getSZ(2);
  @$pb.TagNumber(3)
  set colorHex($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasColorHex() => $_has(2);
  @$pb.TagNumber(3)
  void clearColorHex() => $_clearField(3);
}

enum GridClip_Payload { audio, osc, midi, cueRef, notSet }

class GridClip extends $pb.GeneratedMessage {
  factory GridClip({
    $core.String? clipId,
    $core.int? trackIndex,
    $core.int? sceneIndex,
    $core.String? label,
    $core.String? colorHex,
    LaunchMode? launchMode,
    FollowAction? follow,
    AudioClipPayload? audio,
    OscClipPayload? osc,
    MidiClipPayload? midi,
    CueRefPayload? cueRef,
  }) {
    final result = create();
    if (clipId != null) result.clipId = clipId;
    if (trackIndex != null) result.trackIndex = trackIndex;
    if (sceneIndex != null) result.sceneIndex = sceneIndex;
    if (label != null) result.label = label;
    if (colorHex != null) result.colorHex = colorHex;
    if (launchMode != null) result.launchMode = launchMode;
    if (follow != null) result.follow = follow;
    if (audio != null) result.audio = audio;
    if (osc != null) result.osc = osc;
    if (midi != null) result.midi = midi;
    if (cueRef != null) result.cueRef = cueRef;
    return result;
  }

  GridClip._();

  factory GridClip.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GridClip.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GridClip_Payload> _GridClip_PayloadByTag = {
    10: GridClip_Payload.audio,
    11: GridClip_Payload.osc,
    12: GridClip_Payload.midi,
    13: GridClip_Payload.cueRef,
    0: GridClip_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GridClip',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13])
    ..aOS(1, _omitFieldNames ? '' : 'clipId')
    ..aI(2, _omitFieldNames ? '' : 'trackIndex')
    ..aI(3, _omitFieldNames ? '' : 'sceneIndex')
    ..aOS(4, _omitFieldNames ? '' : 'label')
    ..aOS(5, _omitFieldNames ? '' : 'colorHex')
    ..aE<LaunchMode>(6, _omitFieldNames ? '' : 'launchMode',
        enumValues: LaunchMode.values)
    ..aE<FollowAction>(7, _omitFieldNames ? '' : 'follow',
        enumValues: FollowAction.values)
    ..aOM<AudioClipPayload>(10, _omitFieldNames ? '' : 'audio',
        subBuilder: AudioClipPayload.create)
    ..aOM<OscClipPayload>(11, _omitFieldNames ? '' : 'osc',
        subBuilder: OscClipPayload.create)
    ..aOM<MidiClipPayload>(12, _omitFieldNames ? '' : 'midi',
        subBuilder: MidiClipPayload.create)
    ..aOM<CueRefPayload>(13, _omitFieldNames ? '' : 'cueRef',
        subBuilder: CueRefPayload.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridClip clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridClip copyWith(void Function(GridClip) updates) =>
      super.copyWith((message) => updates(message as GridClip)) as GridClip;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GridClip create() => GridClip._();
  @$core.override
  GridClip createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GridClip getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridClip>(create);
  static GridClip? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  GridClip_Payload whichPayload() => _GridClip_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get clipId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clipId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClipId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClipId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get trackIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set trackIndex($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTrackIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrackIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sceneIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set sceneIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSceneIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearSceneIndex() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get label => $_getSZ(3);
  @$pb.TagNumber(4)
  set label($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearLabel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get colorHex => $_getSZ(4);
  @$pb.TagNumber(5)
  set colorHex($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasColorHex() => $_has(4);
  @$pb.TagNumber(5)
  void clearColorHex() => $_clearField(5);

  @$pb.TagNumber(6)
  LaunchMode get launchMode => $_getN(5);
  @$pb.TagNumber(6)
  set launchMode(LaunchMode value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLaunchMode() => $_has(5);
  @$pb.TagNumber(6)
  void clearLaunchMode() => $_clearField(6);

  @$pb.TagNumber(7)
  FollowAction get follow => $_getN(6);
  @$pb.TagNumber(7)
  set follow(FollowAction value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasFollow() => $_has(6);
  @$pb.TagNumber(7)
  void clearFollow() => $_clearField(7);

  @$pb.TagNumber(10)
  AudioClipPayload get audio => $_getN(7);
  @$pb.TagNumber(10)
  set audio(AudioClipPayload value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasAudio() => $_has(7);
  @$pb.TagNumber(10)
  void clearAudio() => $_clearField(10);
  @$pb.TagNumber(10)
  AudioClipPayload ensureAudio() => $_ensure(7);

  @$pb.TagNumber(11)
  OscClipPayload get osc => $_getN(8);
  @$pb.TagNumber(11)
  set osc(OscClipPayload value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasOsc() => $_has(8);
  @$pb.TagNumber(11)
  void clearOsc() => $_clearField(11);
  @$pb.TagNumber(11)
  OscClipPayload ensureOsc() => $_ensure(8);

  @$pb.TagNumber(12)
  MidiClipPayload get midi => $_getN(9);
  @$pb.TagNumber(12)
  set midi(MidiClipPayload value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasMidi() => $_has(9);
  @$pb.TagNumber(12)
  void clearMidi() => $_clearField(12);
  @$pb.TagNumber(12)
  MidiClipPayload ensureMidi() => $_ensure(9);

  @$pb.TagNumber(13)
  CueRefPayload get cueRef => $_getN(10);
  @$pb.TagNumber(13)
  set cueRef(CueRefPayload value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasCueRef() => $_has(10);
  @$pb.TagNumber(13)
  void clearCueRef() => $_clearField(13);
  @$pb.TagNumber(13)
  CueRefPayload ensureCueRef() => $_ensure(10);
}

class AudioClipPayload extends $pb.GeneratedMessage {
  factory AudioClipPayload({
    $core.String? assetId,
    $core.double? volumeDb,
    $core.double? fadeInMs,
    $core.double? fadeOutMs,
    $core.bool? loop,
    $core.double? startTimeMs,
    $core.double? endTimeMs,
    $core.double? declaredDurationMs,
  }) {
    final result = create();
    if (assetId != null) result.assetId = assetId;
    if (volumeDb != null) result.volumeDb = volumeDb;
    if (fadeInMs != null) result.fadeInMs = fadeInMs;
    if (fadeOutMs != null) result.fadeOutMs = fadeOutMs;
    if (loop != null) result.loop = loop;
    if (startTimeMs != null) result.startTimeMs = startTimeMs;
    if (endTimeMs != null) result.endTimeMs = endTimeMs;
    if (declaredDurationMs != null)
      result.declaredDurationMs = declaredDurationMs;
    return result;
  }

  AudioClipPayload._();

  factory AudioClipPayload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioClipPayload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioClipPayload',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'assetId')
    ..aD(2, _omitFieldNames ? '' : 'volumeDb')
    ..aD(3, _omitFieldNames ? '' : 'fadeInMs')
    ..aD(4, _omitFieldNames ? '' : 'fadeOutMs')
    ..aOB(5, _omitFieldNames ? '' : 'loop')
    ..aD(6, _omitFieldNames ? '' : 'startTimeMs')
    ..aD(7, _omitFieldNames ? '' : 'endTimeMs')
    ..aD(8, _omitFieldNames ? '' : 'declaredDurationMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioClipPayload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioClipPayload copyWith(void Function(AudioClipPayload) updates) =>
      super.copyWith((message) => updates(message as AudioClipPayload))
          as AudioClipPayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioClipPayload create() => AudioClipPayload._();
  @$core.override
  AudioClipPayload createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioClipPayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioClipPayload>(create);
  static AudioClipPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get assetId => $_getSZ(0);
  @$pb.TagNumber(1)
  set assetId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAssetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAssetId() => $_clearField(1);

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
  $core.double get declaredDurationMs => $_getN(7);
  @$pb.TagNumber(8)
  set declaredDurationMs($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDeclaredDurationMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeclaredDurationMs() => $_clearField(8);
}

class OscClipPayload extends $pb.GeneratedMessage {
  factory OscClipPayload({
    $core.String? address,
    $core.Iterable<$core.String>? args,
    $core.String? targetNodeId,
  }) {
    final result = create();
    if (address != null) result.address = address;
    if (args != null) result.args.addAll(args);
    if (targetNodeId != null) result.targetNodeId = targetNodeId;
    return result;
  }

  OscClipPayload._();

  factory OscClipPayload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OscClipPayload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OscClipPayload',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'address')
    ..pPS(2, _omitFieldNames ? '' : 'args')
    ..aOS(3, _omitFieldNames ? '' : 'targetNodeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OscClipPayload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OscClipPayload copyWith(void Function(OscClipPayload) updates) =>
      super.copyWith((message) => updates(message as OscClipPayload))
          as OscClipPayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OscClipPayload create() => OscClipPayload._();
  @$core.override
  OscClipPayload createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OscClipPayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OscClipPayload>(create);
  static OscClipPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get address => $_getSZ(0);
  @$pb.TagNumber(1)
  set address($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddress() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get args => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get targetNodeId => $_getSZ(2);
  @$pb.TagNumber(3)
  set targetNodeId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetNodeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetNodeId() => $_clearField(3);
}

class MidiClipPayload extends $pb.GeneratedMessage {
  factory MidiClipPayload({
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

  MidiClipPayload._();

  factory MidiClipPayload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MidiClipPayload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MidiClipPayload',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'channel')
    ..aI(2, _omitFieldNames ? '' : 'command')
    ..aI(3, _omitFieldNames ? '' : 'data1')
    ..aI(4, _omitFieldNames ? '' : 'data2')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MidiClipPayload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MidiClipPayload copyWith(void Function(MidiClipPayload) updates) =>
      super.copyWith((message) => updates(message as MidiClipPayload))
          as MidiClipPayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MidiClipPayload create() => MidiClipPayload._();
  @$core.override
  MidiClipPayload createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MidiClipPayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MidiClipPayload>(create);
  static MidiClipPayload? _defaultInstance;

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

class CueRefPayload extends $pb.GeneratedMessage {
  factory CueRefPayload({
    $core.String? cueListId,
    $core.String? cueId,
  }) {
    final result = create();
    if (cueListId != null) result.cueListId = cueListId;
    if (cueId != null) result.cueId = cueId;
    return result;
  }

  CueRefPayload._();

  factory CueRefPayload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CueRefPayload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CueRefPayload',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cueListId')
    ..aOS(2, _omitFieldNames ? '' : 'cueId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CueRefPayload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CueRefPayload copyWith(void Function(CueRefPayload) updates) =>
      super.copyWith((message) => updates(message as CueRefPayload))
          as CueRefPayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CueRefPayload create() => CueRefPayload._();
  @$core.override
  CueRefPayload createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CueRefPayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CueRefPayload>(create);
  static CueRefPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cueListId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cueListId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCueListId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCueListId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get cueId => $_getSZ(1);
  @$pb.TagNumber(2)
  set cueId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCueId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCueId() => $_clearField(2);
}

class GetGridRequest extends $pb.GeneratedMessage {
  factory GetGridRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? gridId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (gridId != null) result.gridId = gridId;
    return result;
  }

  GetGridRequest._();

  factory GetGridRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetGridRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGridRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'gridId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGridRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGridRequest copyWith(void Function(GetGridRequest) updates) =>
      super.copyWith((message) => updates(message as GetGridRequest))
          as GetGridRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetGridRequest create() => GetGridRequest._();
  @$core.override
  GetGridRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetGridRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGridRequest>(create);
  static GetGridRequest? _defaultInstance;

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
  $core.String get gridId => $_getSZ(2);
  @$pb.TagNumber(3)
  set gridId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGridId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGridId() => $_clearField(3);
}

class GridResponse extends $pb.GeneratedMessage {
  factory GridResponse({
    Grid? grid,
  }) {
    final result = create();
    if (grid != null) result.grid = grid;
    return result;
  }

  GridResponse._();

  factory GridResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GridResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GridResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOM<Grid>(1, _omitFieldNames ? '' : 'grid', subBuilder: Grid.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridResponse copyWith(void Function(GridResponse) updates) =>
      super.copyWith((message) => updates(message as GridResponse))
          as GridResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GridResponse create() => GridResponse._();
  @$core.override
  GridResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GridResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GridResponse>(create);
  static GridResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Grid get grid => $_getN(0);
  @$pb.TagNumber(1)
  set grid(Grid value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasGrid() => $_has(0);
  @$pb.TagNumber(1)
  void clearGrid() => $_clearField(1);
  @$pb.TagNumber(1)
  Grid ensureGrid() => $_ensure(0);
}

class UpdateGridRequest extends $pb.GeneratedMessage {
  factory UpdateGridRequest({
    $core.String? sessionId,
    $core.String? token,
    Grid? grid,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (grid != null) result.grid = grid;
    return result;
  }

  UpdateGridRequest._();

  factory UpdateGridRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateGridRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateGridRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOM<Grid>(3, _omitFieldNames ? '' : 'grid', subBuilder: Grid.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateGridRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateGridRequest copyWith(void Function(UpdateGridRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateGridRequest))
          as UpdateGridRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateGridRequest create() => UpdateGridRequest._();
  @$core.override
  UpdateGridRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateGridRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateGridRequest>(create);
  static UpdateGridRequest? _defaultInstance;

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
  Grid get grid => $_getN(2);
  @$pb.TagNumber(3)
  set grid(Grid value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGrid() => $_has(2);
  @$pb.TagNumber(3)
  void clearGrid() => $_clearField(3);
  @$pb.TagNumber(3)
  Grid ensureGrid() => $_ensure(2);
}

class UpsertClipRequest extends $pb.GeneratedMessage {
  factory UpsertClipRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? gridId,
    GridClip? clip,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (gridId != null) result.gridId = gridId;
    if (clip != null) result.clip = clip;
    return result;
  }

  UpsertClipRequest._();

  factory UpsertClipRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpsertClipRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpsertClipRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'gridId')
    ..aOM<GridClip>(4, _omitFieldNames ? '' : 'clip',
        subBuilder: GridClip.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpsertClipRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpsertClipRequest copyWith(void Function(UpsertClipRequest) updates) =>
      super.copyWith((message) => updates(message as UpsertClipRequest))
          as UpsertClipRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpsertClipRequest create() => UpsertClipRequest._();
  @$core.override
  UpsertClipRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpsertClipRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpsertClipRequest>(create);
  static UpsertClipRequest? _defaultInstance;

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
  $core.String get gridId => $_getSZ(2);
  @$pb.TagNumber(3)
  set gridId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGridId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGridId() => $_clearField(3);

  @$pb.TagNumber(4)
  GridClip get clip => $_getN(3);
  @$pb.TagNumber(4)
  set clip(GridClip value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasClip() => $_has(3);
  @$pb.TagNumber(4)
  void clearClip() => $_clearField(4);
  @$pb.TagNumber(4)
  GridClip ensureClip() => $_ensure(3);
}

class ClipResponse extends $pb.GeneratedMessage {
  factory ClipResponse({
    GridClip? clip,
  }) {
    final result = create();
    if (clip != null) result.clip = clip;
    return result;
  }

  ClipResponse._();

  factory ClipResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClipResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClipResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOM<GridClip>(1, _omitFieldNames ? '' : 'clip',
        subBuilder: GridClip.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClipResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClipResponse copyWith(void Function(ClipResponse) updates) =>
      super.copyWith((message) => updates(message as ClipResponse))
          as ClipResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClipResponse create() => ClipResponse._();
  @$core.override
  ClipResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClipResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClipResponse>(create);
  static ClipResponse? _defaultInstance;

  @$pb.TagNumber(1)
  GridClip get clip => $_getN(0);
  @$pb.TagNumber(1)
  set clip(GridClip value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasClip() => $_has(0);
  @$pb.TagNumber(1)
  void clearClip() => $_clearField(1);
  @$pb.TagNumber(1)
  GridClip ensureClip() => $_ensure(0);
}

class DeleteClipRequest extends $pb.GeneratedMessage {
  factory DeleteClipRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? gridId,
    $core.String? clipId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (gridId != null) result.gridId = gridId;
    if (clipId != null) result.clipId = clipId;
    return result;
  }

  DeleteClipRequest._();

  factory DeleteClipRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteClipRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteClipRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'gridId')
    ..aOS(4, _omitFieldNames ? '' : 'clipId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteClipRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteClipRequest copyWith(void Function(DeleteClipRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteClipRequest))
          as DeleteClipRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteClipRequest create() => DeleteClipRequest._();
  @$core.override
  DeleteClipRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteClipRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteClipRequest>(create);
  static DeleteClipRequest? _defaultInstance;

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
  $core.String get gridId => $_getSZ(2);
  @$pb.TagNumber(3)
  set gridId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGridId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGridId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get clipId => $_getSZ(3);
  @$pb.TagNumber(4)
  set clipId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasClipId() => $_has(3);
  @$pb.TagNumber(4)
  void clearClipId() => $_clearField(4);
}

class LaunchClipRequest extends $pb.GeneratedMessage {
  factory LaunchClipRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? gridId,
    $core.int? trackIndex,
    $core.int? sceneIndex,
    $core.String? commandId,
    $core.bool? released,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (gridId != null) result.gridId = gridId;
    if (trackIndex != null) result.trackIndex = trackIndex;
    if (sceneIndex != null) result.sceneIndex = sceneIndex;
    if (commandId != null) result.commandId = commandId;
    if (released != null) result.released = released;
    return result;
  }

  LaunchClipRequest._();

  factory LaunchClipRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LaunchClipRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LaunchClipRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'gridId')
    ..aI(4, _omitFieldNames ? '' : 'trackIndex')
    ..aI(5, _omitFieldNames ? '' : 'sceneIndex')
    ..aOS(6, _omitFieldNames ? '' : 'commandId')
    ..aOB(7, _omitFieldNames ? '' : 'released')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LaunchClipRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LaunchClipRequest copyWith(void Function(LaunchClipRequest) updates) =>
      super.copyWith((message) => updates(message as LaunchClipRequest))
          as LaunchClipRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LaunchClipRequest create() => LaunchClipRequest._();
  @$core.override
  LaunchClipRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LaunchClipRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LaunchClipRequest>(create);
  static LaunchClipRequest? _defaultInstance;

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
  $core.String get gridId => $_getSZ(2);
  @$pb.TagNumber(3)
  set gridId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGridId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGridId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get trackIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set trackIndex($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTrackIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearTrackIndex() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get sceneIndex => $_getIZ(4);
  @$pb.TagNumber(5)
  set sceneIndex($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSceneIndex() => $_has(4);
  @$pb.TagNumber(5)
  void clearSceneIndex() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get commandId => $_getSZ(5);
  @$pb.TagNumber(6)
  set commandId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCommandId() => $_has(5);
  @$pb.TagNumber(6)
  void clearCommandId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get released => $_getBF(6);
  @$pb.TagNumber(7)
  set released($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReleased() => $_has(6);
  @$pb.TagNumber(7)
  void clearReleased() => $_clearField(7);
}

class LaunchSceneRequest extends $pb.GeneratedMessage {
  factory LaunchSceneRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? gridId,
    $core.int? sceneIndex,
    $core.String? commandId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (gridId != null) result.gridId = gridId;
    if (sceneIndex != null) result.sceneIndex = sceneIndex;
    if (commandId != null) result.commandId = commandId;
    return result;
  }

  LaunchSceneRequest._();

  factory LaunchSceneRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LaunchSceneRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LaunchSceneRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'gridId')
    ..aI(4, _omitFieldNames ? '' : 'sceneIndex')
    ..aOS(5, _omitFieldNames ? '' : 'commandId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LaunchSceneRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LaunchSceneRequest copyWith(void Function(LaunchSceneRequest) updates) =>
      super.copyWith((message) => updates(message as LaunchSceneRequest))
          as LaunchSceneRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LaunchSceneRequest create() => LaunchSceneRequest._();
  @$core.override
  LaunchSceneRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LaunchSceneRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LaunchSceneRequest>(create);
  static LaunchSceneRequest? _defaultInstance;

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
  $core.String get gridId => $_getSZ(2);
  @$pb.TagNumber(3)
  set gridId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGridId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGridId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get sceneIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set sceneIndex($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSceneIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearSceneIndex() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get commandId => $_getSZ(4);
  @$pb.TagNumber(5)
  set commandId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCommandId() => $_has(4);
  @$pb.TagNumber(5)
  void clearCommandId() => $_clearField(5);
}

class StopTrackRequest extends $pb.GeneratedMessage {
  factory StopTrackRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? gridId,
    $core.int? trackIndex,
    $core.String? commandId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (gridId != null) result.gridId = gridId;
    if (trackIndex != null) result.trackIndex = trackIndex;
    if (commandId != null) result.commandId = commandId;
    return result;
  }

  StopTrackRequest._();

  factory StopTrackRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StopTrackRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopTrackRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'gridId')
    ..aI(4, _omitFieldNames ? '' : 'trackIndex')
    ..aOS(5, _omitFieldNames ? '' : 'commandId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopTrackRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopTrackRequest copyWith(void Function(StopTrackRequest) updates) =>
      super.copyWith((message) => updates(message as StopTrackRequest))
          as StopTrackRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StopTrackRequest create() => StopTrackRequest._();
  @$core.override
  StopTrackRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StopTrackRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopTrackRequest>(create);
  static StopTrackRequest? _defaultInstance;

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
  $core.String get gridId => $_getSZ(2);
  @$pb.TagNumber(3)
  set gridId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGridId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGridId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get trackIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set trackIndex($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTrackIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearTrackIndex() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get commandId => $_getSZ(4);
  @$pb.TagNumber(5)
  set commandId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCommandId() => $_has(4);
  @$pb.TagNumber(5)
  void clearCommandId() => $_clearField(5);
}

class StopAllRequest extends $pb.GeneratedMessage {
  factory StopAllRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? gridId,
    $core.String? commandId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (gridId != null) result.gridId = gridId;
    if (commandId != null) result.commandId = commandId;
    return result;
  }

  StopAllRequest._();

  factory StopAllRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StopAllRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopAllRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'gridId')
    ..aOS(4, _omitFieldNames ? '' : 'commandId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopAllRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopAllRequest copyWith(void Function(StopAllRequest) updates) =>
      super.copyWith((message) => updates(message as StopAllRequest))
          as StopAllRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StopAllRequest create() => StopAllRequest._();
  @$core.override
  StopAllRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StopAllRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopAllRequest>(create);
  static StopAllRequest? _defaultInstance;

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
  $core.String get gridId => $_getSZ(2);
  @$pb.TagNumber(3)
  set gridId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGridId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGridId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get commandId => $_getSZ(3);
  @$pb.TagNumber(4)
  set commandId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCommandId() => $_has(3);
  @$pb.TagNumber(4)
  void clearCommandId() => $_clearField(4);
}

class WatchGridExecRequest extends $pb.GeneratedMessage {
  factory WatchGridExecRequest({
    $core.String? sessionId,
    $core.String? nodeId,
    $core.String? token,
    $core.String? gridId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (nodeId != null) result.nodeId = nodeId;
    if (token != null) result.token = token;
    if (gridId != null) result.gridId = gridId;
    return result;
  }

  WatchGridExecRequest._();

  factory WatchGridExecRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchGridExecRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchGridExecRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'nodeId')
    ..aOS(3, _omitFieldNames ? '' : 'token')
    ..aOS(4, _omitFieldNames ? '' : 'gridId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchGridExecRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchGridExecRequest copyWith(void Function(WatchGridExecRequest) updates) =>
      super.copyWith((message) => updates(message as WatchGridExecRequest))
          as WatchGridExecRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchGridExecRequest create() => WatchGridExecRequest._();
  @$core.override
  WatchGridExecRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchGridExecRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchGridExecRequest>(create);
  static WatchGridExecRequest? _defaultInstance;

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
  $core.String get gridId => $_getSZ(3);
  @$pb.TagNumber(4)
  set gridId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGridId() => $_has(3);
  @$pb.TagNumber(4)
  void clearGridId() => $_clearField(4);
}

class GridExecutionEvent extends $pb.GeneratedMessage {
  factory GridExecutionEvent({
    $fixnum.Int64? seq,
    GridExecutionEvent_Type? type,
    $3.Timestamp? occurredAt,
    $core.String? clipId,
    $core.int? trackIndex,
    $core.int? sceneIndex,
    $fixnum.Int64? startedAtMs,
    $core.double? clipLengthMs,
    $core.String? errorMsg,
    $core.Iterable<$core.String>? runningClipIds,
  }) {
    final result = create();
    if (seq != null) result.seq = seq;
    if (type != null) result.type = type;
    if (occurredAt != null) result.occurredAt = occurredAt;
    if (clipId != null) result.clipId = clipId;
    if (trackIndex != null) result.trackIndex = trackIndex;
    if (sceneIndex != null) result.sceneIndex = sceneIndex;
    if (startedAtMs != null) result.startedAtMs = startedAtMs;
    if (clipLengthMs != null) result.clipLengthMs = clipLengthMs;
    if (errorMsg != null) result.errorMsg = errorMsg;
    if (runningClipIds != null) result.runningClipIds.addAll(runningClipIds);
    return result;
  }

  GridExecutionEvent._();

  factory GridExecutionEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GridExecutionEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GridExecutionEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'seq')
    ..aE<GridExecutionEvent_Type>(2, _omitFieldNames ? '' : 'type',
        enumValues: GridExecutionEvent_Type.values)
    ..aOM<$3.Timestamp>(3, _omitFieldNames ? '' : 'occurredAt',
        subBuilder: $3.Timestamp.create)
    ..aOS(10, _omitFieldNames ? '' : 'clipId')
    ..aI(11, _omitFieldNames ? '' : 'trackIndex')
    ..aI(12, _omitFieldNames ? '' : 'sceneIndex')
    ..aInt64(13, _omitFieldNames ? '' : 'startedAtMs')
    ..aD(14, _omitFieldNames ? '' : 'clipLengthMs')
    ..aOS(15, _omitFieldNames ? '' : 'errorMsg')
    ..pPS(16, _omitFieldNames ? '' : 'runningClipIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridExecutionEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridExecutionEvent copyWith(void Function(GridExecutionEvent) updates) =>
      super.copyWith((message) => updates(message as GridExecutionEvent))
          as GridExecutionEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GridExecutionEvent create() => GridExecutionEvent._();
  @$core.override
  GridExecutionEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GridExecutionEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GridExecutionEvent>(create);
  static GridExecutionEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get seq => $_getI64(0);
  @$pb.TagNumber(1)
  set seq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeq() => $_clearField(1);

  @$pb.TagNumber(2)
  GridExecutionEvent_Type get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(GridExecutionEvent_Type value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $3.Timestamp get occurredAt => $_getN(2);
  @$pb.TagNumber(3)
  set occurredAt($3.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOccurredAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearOccurredAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $3.Timestamp ensureOccurredAt() => $_ensure(2);

  @$pb.TagNumber(10)
  $core.String get clipId => $_getSZ(3);
  @$pb.TagNumber(10)
  set clipId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(10)
  $core.bool hasClipId() => $_has(3);
  @$pb.TagNumber(10)
  void clearClipId() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get trackIndex => $_getIZ(4);
  @$pb.TagNumber(11)
  set trackIndex($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(11)
  $core.bool hasTrackIndex() => $_has(4);
  @$pb.TagNumber(11)
  void clearTrackIndex() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get sceneIndex => $_getIZ(5);
  @$pb.TagNumber(12)
  set sceneIndex($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(12)
  $core.bool hasSceneIndex() => $_has(5);
  @$pb.TagNumber(12)
  void clearSceneIndex() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get startedAtMs => $_getI64(6);
  @$pb.TagNumber(13)
  set startedAtMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(13)
  $core.bool hasStartedAtMs() => $_has(6);
  @$pb.TagNumber(13)
  void clearStartedAtMs() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.double get clipLengthMs => $_getN(7);
  @$pb.TagNumber(14)
  set clipLengthMs($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(14)
  $core.bool hasClipLengthMs() => $_has(7);
  @$pb.TagNumber(14)
  void clearClipLengthMs() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get errorMsg => $_getSZ(8);
  @$pb.TagNumber(15)
  set errorMsg($core.String value) => $_setString(8, value);
  @$pb.TagNumber(15)
  $core.bool hasErrorMsg() => $_has(8);
  @$pb.TagNumber(15)
  void clearErrorMsg() => $_clearField(15);

  /// Bei GRID_SNAPSHOT: alle aktuell laufenden Clip-IDs.
  @$pb.TagNumber(16)
  $pb.PbList<$core.String> get runningClipIds => $_getList(9);
}

class WaveformRequest extends $pb.GeneratedMessage {
  factory WaveformRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? assetId,
    $core.int? buckets,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (assetId != null) result.assetId = assetId;
    if (buckets != null) result.buckets = buckets;
    return result;
  }

  WaveformRequest._();

  factory WaveformRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WaveformRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WaveformRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'assetId')
    ..aI(4, _omitFieldNames ? '' : 'buckets')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WaveformRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WaveformRequest copyWith(void Function(WaveformRequest) updates) =>
      super.copyWith((message) => updates(message as WaveformRequest))
          as WaveformRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WaveformRequest create() => WaveformRequest._();
  @$core.override
  WaveformRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WaveformRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WaveformRequest>(create);
  static WaveformRequest? _defaultInstance;

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
  $core.String get assetId => $_getSZ(2);
  @$pb.TagNumber(3)
  set assetId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAssetId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAssetId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get buckets => $_getIZ(3);
  @$pb.TagNumber(4)
  set buckets($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBuckets() => $_has(3);
  @$pb.TagNumber(4)
  void clearBuckets() => $_clearField(4);
}

class WaveformChunk extends $pb.GeneratedMessage {
  factory WaveformChunk({
    $core.List<$core.int>? data,
    $core.int? totalBuckets,
    $core.int? channels,
    $core.int? sampleRate,
    $core.double? durationMs,
  }) {
    final result = create();
    if (data != null) result.data = data;
    if (totalBuckets != null) result.totalBuckets = totalBuckets;
    if (channels != null) result.channels = channels;
    if (sampleRate != null) result.sampleRate = sampleRate;
    if (durationMs != null) result.durationMs = durationMs;
    return result;
  }

  WaveformChunk._();

  factory WaveformChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WaveformChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WaveformChunk',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aI(2, _omitFieldNames ? '' : 'totalBuckets')
    ..aI(3, _omitFieldNames ? '' : 'channels', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'sampleRate', fieldType: $pb.PbFieldType.OU3)
    ..aD(5, _omitFieldNames ? '' : 'durationMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WaveformChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WaveformChunk copyWith(void Function(WaveformChunk) updates) =>
      super.copyWith((message) => updates(message as WaveformChunk))
          as WaveformChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WaveformChunk create() => WaveformChunk._();
  @$core.override
  WaveformChunk createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WaveformChunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WaveformChunk>(create);
  static WaveformChunk? _defaultInstance;

  /// Interleaved min/max als int16 (little-endian): [min0, max0, min1, max1, ...].
  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get totalBuckets => $_getIZ(1);
  @$pb.TagNumber(2)
  set totalBuckets($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalBuckets() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalBuckets() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get channels => $_getIZ(2);
  @$pb.TagNumber(3)
  set channels($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChannels() => $_has(2);
  @$pb.TagNumber(3)
  void clearChannels() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get sampleRate => $_getIZ(3);
  @$pb.TagNumber(4)
  set sampleRate($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSampleRate() => $_has(3);
  @$pb.TagNumber(4)
  void clearSampleRate() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get durationMs => $_getN(4);
  @$pb.TagNumber(5)
  set durationMs($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDurationMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearDurationMs() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
