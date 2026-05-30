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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'media.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'media.pbenum.dart';

class StreamFileRequest extends $pb.GeneratedMessage {
  factory StreamFileRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? assetId,
    $core.String? name,
    $fixnum.Int64? offset,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (assetId != null) result.assetId = assetId;
    if (name != null) result.name = name;
    if (offset != null) result.offset = offset;
    return result;
  }

  StreamFileRequest._();

  factory StreamFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamFileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'assetId')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aInt64(5, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamFileRequest copyWith(void Function(StreamFileRequest) updates) =>
      super.copyWith((message) => updates(message as StreamFileRequest))
          as StreamFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamFileRequest create() => StreamFileRequest._();
  @$core.override
  StreamFileRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamFileRequest>(create);
  static StreamFileRequest? _defaultInstance;

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

  /// Asset-Identifikation: asset_id (SHA-256) bevorzugt; name als Fallback.
  @$pb.TagNumber(3)
  $core.String get assetId => $_getSZ(2);
  @$pb.TagNumber(3)
  set assetId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAssetId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAssetId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  /// Resumable: Byte-Offset vom dem gestreamt wird (0 = Anfang).
  @$pb.TagNumber(5)
  $fixnum.Int64 get offset => $_getI64(4);
  @$pb.TagNumber(5)
  set offset($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearOffset() => $_clearField(5);
}

class FileChunk extends $pb.GeneratedMessage {
  factory FileChunk({
    $core.List<$core.int>? data,
    $fixnum.Int64? offset,
    $fixnum.Int64? totalBytes,
  }) {
    final result = create();
    if (data != null) result.data = data;
    if (offset != null) result.offset = offset;
    if (totalBytes != null) result.totalBytes = totalBytes;
    return result;
  }

  FileChunk._();

  factory FileChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileChunk',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aInt64(2, _omitFieldNames ? '' : 'offset')
    ..aInt64(3, _omitFieldNames ? '' : 'totalBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileChunk copyWith(void Function(FileChunk) updates) =>
      super.copyWith((message) => updates(message as FileChunk)) as FileChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileChunk create() => FileChunk._();
  @$core.override
  FileChunk createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileChunk getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FileChunk>(create);
  static FileChunk? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get totalBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set totalBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotalBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotalBytes() => $_clearField(3);
}

enum UploadChunk_Payload { meta, data, notSet }

class UploadChunk extends $pb.GeneratedMessage {
  factory UploadChunk({
    UploadMeta? meta,
    $core.List<$core.int>? data,
  }) {
    final result = create();
    if (meta != null) result.meta = meta;
    if (data != null) result.data = data;
    return result;
  }

  UploadChunk._();

  factory UploadChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UploadChunk_Payload>
      _UploadChunk_PayloadByTag = {
    1: UploadChunk_Payload.meta,
    2: UploadChunk_Payload.data,
    0: UploadChunk_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadChunk',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<UploadMeta>(1, _omitFieldNames ? '' : 'meta',
        subBuilder: UploadMeta.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadChunk copyWith(void Function(UploadChunk) updates) =>
      super.copyWith((message) => updates(message as UploadChunk))
          as UploadChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadChunk create() => UploadChunk._();
  @$core.override
  UploadChunk createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UploadChunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadChunk>(create);
  static UploadChunk? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UploadChunk_Payload whichPayload() =>
      _UploadChunk_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  UploadMeta get meta => $_getN(0);
  @$pb.TagNumber(1)
  set meta(UploadMeta value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMeta() => $_has(0);
  @$pb.TagNumber(1)
  void clearMeta() => $_clearField(1);
  @$pb.TagNumber(1)
  UploadMeta ensureMeta() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);
}

class UploadMeta extends $pb.GeneratedMessage {
  factory UploadMeta({
    $core.String? sessionId,
    $core.String? token,
    $core.String? filename,
    $fixnum.Int64? totalBytes,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (filename != null) result.filename = filename;
    if (totalBytes != null) result.totalBytes = totalBytes;
    return result;
  }

  UploadMeta._();

  factory UploadMeta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadMeta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadMeta',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'filename')
    ..aInt64(4, _omitFieldNames ? '' : 'totalBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadMeta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadMeta copyWith(void Function(UploadMeta) updates) =>
      super.copyWith((message) => updates(message as UploadMeta)) as UploadMeta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadMeta create() => UploadMeta._();
  @$core.override
  UploadMeta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UploadMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadMeta>(create);
  static UploadMeta? _defaultInstance;

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
  $core.String get filename => $_getSZ(2);
  @$pb.TagNumber(3)
  set filename($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFilename() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilename() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get totalBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set totalBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalBytes() => $_clearField(4);
}

class UploadResponse extends $pb.GeneratedMessage {
  factory UploadResponse({
    $core.String? assetId,
    $core.String? name,
    $fixnum.Int64? sizeBytes,
    AudioMeta? audio,
  }) {
    final result = create();
    if (assetId != null) result.assetId = assetId;
    if (name != null) result.name = name;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (audio != null) result.audio = audio;
    return result;
  }

  UploadResponse._();

  factory UploadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'assetId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aInt64(3, _omitFieldNames ? '' : 'sizeBytes')
    ..aOM<AudioMeta>(4, _omitFieldNames ? '' : 'audio',
        subBuilder: AudioMeta.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadResponse copyWith(void Function(UploadResponse) updates) =>
      super.copyWith((message) => updates(message as UploadResponse))
          as UploadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadResponse create() => UploadResponse._();
  @$core.override
  UploadResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UploadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadResponse>(create);
  static UploadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get assetId => $_getSZ(0);
  @$pb.TagNumber(1)
  set assetId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAssetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAssetId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sizeBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSizeBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearSizeBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  AudioMeta get audio => $_getN(3);
  @$pb.TagNumber(4)
  set audio(AudioMeta value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAudio() => $_has(3);
  @$pb.TagNumber(4)
  void clearAudio() => $_clearField(4);
  @$pb.TagNumber(4)
  AudioMeta ensureAudio() => $_ensure(3);
}

class DeleteFileRequest extends $pb.GeneratedMessage {
  factory DeleteFileRequest({
    $core.String? sessionId,
    $core.String? token,
    $core.String? name,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    if (name != null) result.name = name;
    return result;
  }

  DeleteFileRequest._();

  factory DeleteFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteFileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFileRequest copyWith(void Function(DeleteFileRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteFileRequest))
          as DeleteFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteFileRequest create() => DeleteFileRequest._();
  @$core.override
  DeleteFileRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteFileRequest>(create);
  static DeleteFileRequest? _defaultInstance;

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
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);
}

class DeleteFileResponse extends $pb.GeneratedMessage {
  factory DeleteFileResponse({
    $core.bool? success,
  }) {
    final result = create();
    if (success != null) result.success = success;
    return result;
  }

  DeleteFileResponse._();

  factory DeleteFileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteFileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteFileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFileResponse copyWith(void Function(DeleteFileResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteFileResponse))
          as DeleteFileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteFileResponse create() => DeleteFileResponse._();
  @$core.override
  DeleteFileResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteFileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteFileResponse>(create);
  static DeleteFileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class WatchManifestRequest extends $pb.GeneratedMessage {
  factory WatchManifestRequest({
    $core.String? sessionId,
    $core.String? token,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (token != null) result.token = token;
    return result;
  }

  WatchManifestRequest._();

  factory WatchManifestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchManifestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchManifestRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchManifestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchManifestRequest copyWith(void Function(WatchManifestRequest) updates) =>
      super.copyWith((message) => updates(message as WatchManifestRequest))
          as WatchManifestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchManifestRequest create() => WatchManifestRequest._();
  @$core.override
  WatchManifestRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchManifestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchManifestRequest>(create);
  static WatchManifestRequest? _defaultInstance;

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

class ManifestEvent extends $pb.GeneratedMessage {
  factory ManifestEvent({
    ManifestEvent_EventType? type,
    $fixnum.Int64? seq,
    $core.Iterable<AssetInfo>? assets,
    $core.String? removedName,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (seq != null) result.seq = seq;
    if (assets != null) result.assets.addAll(assets);
    if (removedName != null) result.removedName = removedName;
    return result;
  }

  ManifestEvent._();

  factory ManifestEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ManifestEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ManifestEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aE<ManifestEvent_EventType>(1, _omitFieldNames ? '' : 'type',
        enumValues: ManifestEvent_EventType.values)
    ..aInt64(2, _omitFieldNames ? '' : 'seq')
    ..pPM<AssetInfo>(3, _omitFieldNames ? '' : 'assets',
        subBuilder: AssetInfo.create)
    ..aOS(4, _omitFieldNames ? '' : 'removedName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManifestEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManifestEvent copyWith(void Function(ManifestEvent) updates) =>
      super.copyWith((message) => updates(message as ManifestEvent))
          as ManifestEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ManifestEvent create() => ManifestEvent._();
  @$core.override
  ManifestEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ManifestEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ManifestEvent>(create);
  static ManifestEvent? _defaultInstance;

  @$pb.TagNumber(1)
  ManifestEvent_EventType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(ManifestEvent_EventType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get seq => $_getI64(1);
  @$pb.TagNumber(2)
  set seq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeq() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<AssetInfo> get assets => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get removedName => $_getSZ(3);
  @$pb.TagNumber(4)
  set removedName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRemovedName() => $_has(3);
  @$pb.TagNumber(4)
  void clearRemovedName() => $_clearField(4);
}

class AssetInfo extends $pb.GeneratedMessage {
  factory AssetInfo({
    $core.String? assetId,
    $core.String? name,
    $fixnum.Int64? sizeBytes,
    $core.String? mimeType,
    $fixnum.Int64? modifiedMs,
    AudioMeta? audio,
  }) {
    final result = create();
    if (assetId != null) result.assetId = assetId;
    if (name != null) result.name = name;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (mimeType != null) result.mimeType = mimeType;
    if (modifiedMs != null) result.modifiedMs = modifiedMs;
    if (audio != null) result.audio = audio;
    return result;
  }

  AssetInfo._();

  factory AssetInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AssetInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AssetInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'assetId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aInt64(3, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(4, _omitFieldNames ? '' : 'mimeType')
    ..aInt64(5, _omitFieldNames ? '' : 'modifiedMs')
    ..aOM<AudioMeta>(6, _omitFieldNames ? '' : 'audio',
        subBuilder: AudioMeta.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AssetInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AssetInfo copyWith(void Function(AssetInfo) updates) =>
      super.copyWith((message) => updates(message as AssetInfo)) as AssetInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AssetInfo create() => AssetInfo._();
  @$core.override
  AssetInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AssetInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AssetInfo>(create);
  static AssetInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get assetId => $_getSZ(0);
  @$pb.TagNumber(1)
  set assetId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAssetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAssetId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sizeBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSizeBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearSizeBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get mimeType => $_getSZ(3);
  @$pb.TagNumber(4)
  set mimeType($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMimeType() => $_has(3);
  @$pb.TagNumber(4)
  void clearMimeType() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get modifiedMs => $_getI64(4);
  @$pb.TagNumber(5)
  set modifiedMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModifiedMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearModifiedMs() => $_clearField(5);

  @$pb.TagNumber(6)
  AudioMeta get audio => $_getN(5);
  @$pb.TagNumber(6)
  set audio(AudioMeta value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasAudio() => $_has(5);
  @$pb.TagNumber(6)
  void clearAudio() => $_clearField(6);
  @$pb.TagNumber(6)
  AudioMeta ensureAudio() => $_ensure(5);
}

class AudioMeta extends $pb.GeneratedMessage {
  factory AudioMeta({
    $fixnum.Int64? durationMs,
    $core.int? channels,
    $core.int? sampleRate,
    $core.int? bitDepth,
    $core.double? loudnessLufs,
    $core.bool? hasLoudness,
  }) {
    final result = create();
    if (durationMs != null) result.durationMs = durationMs;
    if (channels != null) result.channels = channels;
    if (sampleRate != null) result.sampleRate = sampleRate;
    if (bitDepth != null) result.bitDepth = bitDepth;
    if (loudnessLufs != null) result.loudnessLufs = loudnessLufs;
    if (hasLoudness != null) result.hasLoudness = hasLoudness;
    return result;
  }

  AudioMeta._();

  factory AudioMeta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioMeta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioMeta',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'stagesync.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'durationMs')
    ..aI(2, _omitFieldNames ? '' : 'channels')
    ..aI(3, _omitFieldNames ? '' : 'sampleRate')
    ..aI(4, _omitFieldNames ? '' : 'bitDepth')
    ..aD(5, _omitFieldNames ? '' : 'loudnessLufs')
    ..aOB(6, _omitFieldNames ? '' : 'hasLoudness')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioMeta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioMeta copyWith(void Function(AudioMeta) updates) =>
      super.copyWith((message) => updates(message as AudioMeta)) as AudioMeta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioMeta create() => AudioMeta._();
  @$core.override
  AudioMeta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioMeta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioMeta>(create);
  static AudioMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get durationMs => $_getI64(0);
  @$pb.TagNumber(1)
  set durationMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDurationMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearDurationMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get channels => $_getIZ(1);
  @$pb.TagNumber(2)
  set channels($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannels() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannels() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sampleRate => $_getIZ(2);
  @$pb.TagNumber(3)
  set sampleRate($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSampleRate() => $_has(2);
  @$pb.TagNumber(3)
  void clearSampleRate() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get bitDepth => $_getIZ(3);
  @$pb.TagNumber(4)
  set bitDepth($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBitDepth() => $_has(3);
  @$pb.TagNumber(4)
  void clearBitDepth() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get loudnessLufs => $_getN(4);
  @$pb.TagNumber(5)
  set loudnessLufs($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLoudnessLufs() => $_has(4);
  @$pb.TagNumber(5)
  void clearLoudnessLufs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get hasLoudness => $_getBF(5);
  @$pb.TagNumber(6)
  set hasLoudness($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHasLoudness() => $_has(5);
  @$pb.TagNumber(6)
  void clearHasLoudness() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
