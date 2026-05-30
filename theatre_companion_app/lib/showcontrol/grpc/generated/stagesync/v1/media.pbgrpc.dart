// This is a generated file - do not edit.
//
// Generated from stagesync/v1/media.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'media.pb.dart' as $0;

export 'media.pb.dart';

@$pb.GrpcServiceName('stagesync.v1.MediaService')
class MediaServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MediaServiceClient(super.channel, {super.options, super.interceptors});

  /// Datei in 64-KB-Chunks streamen. Cache-Hit: aus RAM; Miss: von Disk + Cache füllen.
  $grpc.ResponseStream<$0.FileChunk> streamFile(
    $0.StreamFileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamFile, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Datei chunk-weise hochladen. Erstes Paket = UploadMeta, Rest = Daten.
  $grpc.ResponseFuture<$0.UploadResponse> uploadFile(
    $async.Stream<$0.UploadChunk> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$uploadFile, request, options: options).single;
  }

  /// Datei auf dem Server löschen.
  $grpc.ResponseFuture<$0.DeleteFileResponse> deleteFile(
    $0.DeleteFileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteFile, request, options: options);
  }

  /// Manifest-Stream: Snapshot beim Verbinden, dann inkrementelle Events.
  /// Ersetzt HTTP GET /media/manifest + GET /media/events (SSE).
  $grpc.ResponseStream<$0.ManifestEvent> watchManifest(
    $0.WatchManifestRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchManifest, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$streamFile =
      $grpc.ClientMethod<$0.StreamFileRequest, $0.FileChunk>(
          '/stagesync.v1.MediaService/StreamFile',
          ($0.StreamFileRequest value) => value.writeToBuffer(),
          $0.FileChunk.fromBuffer);
  static final _$uploadFile =
      $grpc.ClientMethod<$0.UploadChunk, $0.UploadResponse>(
          '/stagesync.v1.MediaService/UploadFile',
          ($0.UploadChunk value) => value.writeToBuffer(),
          $0.UploadResponse.fromBuffer);
  static final _$deleteFile =
      $grpc.ClientMethod<$0.DeleteFileRequest, $0.DeleteFileResponse>(
          '/stagesync.v1.MediaService/DeleteFile',
          ($0.DeleteFileRequest value) => value.writeToBuffer(),
          $0.DeleteFileResponse.fromBuffer);
  static final _$watchManifest =
      $grpc.ClientMethod<$0.WatchManifestRequest, $0.ManifestEvent>(
          '/stagesync.v1.MediaService/WatchManifest',
          ($0.WatchManifestRequest value) => value.writeToBuffer(),
          $0.ManifestEvent.fromBuffer);
}

@$pb.GrpcServiceName('stagesync.v1.MediaService')
abstract class MediaServiceBase extends $grpc.Service {
  $core.String get $name => 'stagesync.v1.MediaService';

  MediaServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.StreamFileRequest, $0.FileChunk>(
        'StreamFile',
        streamFile_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.StreamFileRequest.fromBuffer(value),
        ($0.FileChunk value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UploadChunk, $0.UploadResponse>(
        'UploadFile',
        uploadFile,
        true,
        false,
        ($core.List<$core.int> value) => $0.UploadChunk.fromBuffer(value),
        ($0.UploadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteFileRequest, $0.DeleteFileResponse>(
        'DeleteFile',
        deleteFile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteFileRequest.fromBuffer(value),
        ($0.DeleteFileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchManifestRequest, $0.ManifestEvent>(
        'WatchManifest',
        watchManifest_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WatchManifestRequest.fromBuffer(value),
        ($0.ManifestEvent value) => value.writeToBuffer()));
  }

  $async.Stream<$0.FileChunk> streamFile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StreamFileRequest> $request) async* {
    yield* streamFile($call, await $request);
  }

  $async.Stream<$0.FileChunk> streamFile(
      $grpc.ServiceCall call, $0.StreamFileRequest request);

  $async.Future<$0.UploadResponse> uploadFile(
      $grpc.ServiceCall call, $async.Stream<$0.UploadChunk> request);

  $async.Future<$0.DeleteFileResponse> deleteFile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteFileRequest> $request) async {
    return deleteFile($call, await $request);
  }

  $async.Future<$0.DeleteFileResponse> deleteFile(
      $grpc.ServiceCall call, $0.DeleteFileRequest request);

  $async.Stream<$0.ManifestEvent> watchManifest_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchManifestRequest> $request) async* {
    yield* watchManifest($call, await $request);
  }

  $async.Stream<$0.ManifestEvent> watchManifest(
      $grpc.ServiceCall call, $0.WatchManifestRequest request);
}
