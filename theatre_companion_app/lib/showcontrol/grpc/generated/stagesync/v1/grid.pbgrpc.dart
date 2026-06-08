// This is a generated file - do not edit.
//
// Generated from stagesync/v1/grid.proto.

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
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $1;

import 'grid.pb.dart' as $0;

export 'grid.pb.dart';

@$pb.GrpcServiceName('stagesync.v1.GridService')
class GridServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  GridServiceClient(super.channel, {super.options, super.interceptors});

  /// ── Definition (Editor) ──────────────────────────────────────────────────
  $grpc.ResponseFuture<$0.GridResponse> getGrid(
    $0.GetGridRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getGrid, request, options: options);
  }

  $grpc.ResponseFuture<$0.GridResponse> updateGrid(
    $0.UpdateGridRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateGrid, request, options: options);
  }

  $grpc.ResponseFuture<$0.ClipResponse> upsertClip(
    $0.UpsertClipRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$upsertClip, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> deleteClip(
    $0.DeleteClipRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteClip, request, options: options);
  }

  /// ── Execution (Transport) ────────────────────────────────────────────────
  $grpc.ResponseFuture<$1.Empty> launchClip(
    $0.LaunchClipRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$launchClip, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> launchScene(
    $0.LaunchSceneRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$launchScene, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> stopTrack(
    $0.StopTrackRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stopTrack, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> stopAll(
    $0.StopAllRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stopAll, request, options: options);
  }

  /// ── Streams ──────────────────────────────────────────────────────────────
  $grpc.ResponseStream<$0.GridExecutionEvent> watchGridExecution(
    $0.WatchGridExecRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchGridExecution, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$0.WaveformChunk> getWaveform(
    $0.WaveformRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$getWaveform, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getGrid =
      $grpc.ClientMethod<$0.GetGridRequest, $0.GridResponse>(
          '/stagesync.v1.GridService/GetGrid',
          ($0.GetGridRequest value) => value.writeToBuffer(),
          $0.GridResponse.fromBuffer);
  static final _$updateGrid =
      $grpc.ClientMethod<$0.UpdateGridRequest, $0.GridResponse>(
          '/stagesync.v1.GridService/UpdateGrid',
          ($0.UpdateGridRequest value) => value.writeToBuffer(),
          $0.GridResponse.fromBuffer);
  static final _$upsertClip =
      $grpc.ClientMethod<$0.UpsertClipRequest, $0.ClipResponse>(
          '/stagesync.v1.GridService/UpsertClip',
          ($0.UpsertClipRequest value) => value.writeToBuffer(),
          $0.ClipResponse.fromBuffer);
  static final _$deleteClip =
      $grpc.ClientMethod<$0.DeleteClipRequest, $1.Empty>(
          '/stagesync.v1.GridService/DeleteClip',
          ($0.DeleteClipRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$launchClip =
      $grpc.ClientMethod<$0.LaunchClipRequest, $1.Empty>(
          '/stagesync.v1.GridService/LaunchClip',
          ($0.LaunchClipRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$launchScene =
      $grpc.ClientMethod<$0.LaunchSceneRequest, $1.Empty>(
          '/stagesync.v1.GridService/LaunchScene',
          ($0.LaunchSceneRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$stopTrack = $grpc.ClientMethod<$0.StopTrackRequest, $1.Empty>(
      '/stagesync.v1.GridService/StopTrack',
      ($0.StopTrackRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$stopAll = $grpc.ClientMethod<$0.StopAllRequest, $1.Empty>(
      '/stagesync.v1.GridService/StopAll',
      ($0.StopAllRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$watchGridExecution =
      $grpc.ClientMethod<$0.WatchGridExecRequest, $0.GridExecutionEvent>(
          '/stagesync.v1.GridService/WatchGridExecution',
          ($0.WatchGridExecRequest value) => value.writeToBuffer(),
          $0.GridExecutionEvent.fromBuffer);
  static final _$getWaveform =
      $grpc.ClientMethod<$0.WaveformRequest, $0.WaveformChunk>(
          '/stagesync.v1.GridService/GetWaveform',
          ($0.WaveformRequest value) => value.writeToBuffer(),
          $0.WaveformChunk.fromBuffer);
}

@$pb.GrpcServiceName('stagesync.v1.GridService')
abstract class GridServiceBase extends $grpc.Service {
  $core.String get $name => 'stagesync.v1.GridService';

  GridServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetGridRequest, $0.GridResponse>(
        'GetGrid',
        getGrid_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetGridRequest.fromBuffer(value),
        ($0.GridResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateGridRequest, $0.GridResponse>(
        'UpdateGrid',
        updateGrid_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UpdateGridRequest.fromBuffer(value),
        ($0.GridResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpsertClipRequest, $0.ClipResponse>(
        'UpsertClip',
        upsertClip_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UpsertClipRequest.fromBuffer(value),
        ($0.ClipResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteClipRequest, $1.Empty>(
        'DeleteClip',
        deleteClip_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteClipRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LaunchClipRequest, $1.Empty>(
        'LaunchClip',
        launchClip_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LaunchClipRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LaunchSceneRequest, $1.Empty>(
        'LaunchScene',
        launchScene_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.LaunchSceneRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StopTrackRequest, $1.Empty>(
        'StopTrack',
        stopTrack_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StopTrackRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StopAllRequest, $1.Empty>(
        'StopAll',
        stopAll_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StopAllRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.WatchGridExecRequest, $0.GridExecutionEvent>(
            'WatchGridExecution',
            watchGridExecution_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.WatchGridExecRequest.fromBuffer(value),
            ($0.GridExecutionEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WaveformRequest, $0.WaveformChunk>(
        'GetWaveform',
        getWaveform_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WaveformRequest.fromBuffer(value),
        ($0.WaveformChunk value) => value.writeToBuffer()));
  }

  $async.Future<$0.GridResponse> getGrid_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetGridRequest> $request) async {
    return getGrid($call, await $request);
  }

  $async.Future<$0.GridResponse> getGrid(
      $grpc.ServiceCall call, $0.GetGridRequest request);

  $async.Future<$0.GridResponse> updateGrid_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateGridRequest> $request) async {
    return updateGrid($call, await $request);
  }

  $async.Future<$0.GridResponse> updateGrid(
      $grpc.ServiceCall call, $0.UpdateGridRequest request);

  $async.Future<$0.ClipResponse> upsertClip_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpsertClipRequest> $request) async {
    return upsertClip($call, await $request);
  }

  $async.Future<$0.ClipResponse> upsertClip(
      $grpc.ServiceCall call, $0.UpsertClipRequest request);

  $async.Future<$1.Empty> deleteClip_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteClipRequest> $request) async {
    return deleteClip($call, await $request);
  }

  $async.Future<$1.Empty> deleteClip(
      $grpc.ServiceCall call, $0.DeleteClipRequest request);

  $async.Future<$1.Empty> launchClip_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LaunchClipRequest> $request) async {
    return launchClip($call, await $request);
  }

  $async.Future<$1.Empty> launchClip(
      $grpc.ServiceCall call, $0.LaunchClipRequest request);

  $async.Future<$1.Empty> launchScene_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LaunchSceneRequest> $request) async {
    return launchScene($call, await $request);
  }

  $async.Future<$1.Empty> launchScene(
      $grpc.ServiceCall call, $0.LaunchSceneRequest request);

  $async.Future<$1.Empty> stopTrack_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StopTrackRequest> $request) async {
    return stopTrack($call, await $request);
  }

  $async.Future<$1.Empty> stopTrack(
      $grpc.ServiceCall call, $0.StopTrackRequest request);

  $async.Future<$1.Empty> stopAll_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StopAllRequest> $request) async {
    return stopAll($call, await $request);
  }

  $async.Future<$1.Empty> stopAll(
      $grpc.ServiceCall call, $0.StopAllRequest request);

  $async.Stream<$0.GridExecutionEvent> watchGridExecution_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.WatchGridExecRequest> $request) async* {
    yield* watchGridExecution($call, await $request);
  }

  $async.Stream<$0.GridExecutionEvent> watchGridExecution(
      $grpc.ServiceCall call, $0.WatchGridExecRequest request);

  $async.Stream<$0.WaveformChunk> getWaveform_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WaveformRequest> $request) async* {
    yield* getWaveform($call, await $request);
  }

  $async.Stream<$0.WaveformChunk> getWaveform(
      $grpc.ServiceCall call, $0.WaveformRequest request);
}
