// This is a generated file - do not edit.
//
// Generated from stagesync/v1/showcontrol.proto.

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

import 'showcontrol.pb.dart' as $0;

export 'showcontrol.pb.dart';

@$pb.GrpcServiceName('stagesync.v1.ShowControlService')
class ShowControlServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ShowControlServiceClient(super.channel, {super.options, super.interceptors});

  /// Aktuelle CueList abrufen
  $grpc.ResponseFuture<$0.CueListResponse> getCueList(
    $0.GetCueListRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getCueList, request, options: options);
  }

  /// CueList ersetzen (Master/Client-Role erforderlich)
  $grpc.ResponseFuture<$0.CueListResponse> updateCueList(
    $0.UpdateCueListRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateCueList, request, options: options);
  }

  /// Eine einzelne Cue hinzufügen / aktualisieren
  $grpc.ResponseFuture<$0.CueResponse> upsertCue(
    $0.UpsertCueRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$upsertCue, request, options: options);
  }

  /// Eine Cue löschen
  $grpc.ResponseFuture<$1.Empty> deleteCue(
    $0.DeleteCueRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteCue, request, options: options);
  }

  /// GO — nächste Cue oder spezifische Cue ausführen
  $grpc.ResponseFuture<$0.GoResponse> go(
    $0.GoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$go, request, options: options);
  }

  /// STOP — alle laufenden Cues stoppen
  $grpc.ResponseFuture<$1.Empty> stop(
    $0.StopRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stop, request, options: options);
  }

  /// PAUSE / RESUME
  $grpc.ResponseFuture<$1.Empty> pause(
    $0.PauseRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$pause, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> resume(
    $0.ResumeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resume, request, options: options);
  }

  /// Show-State streamen (aktuelle Cue, Nodes-Status, etc.)
  $grpc.ResponseStream<$0.ShowStateEvent> watchShowState(
    $0.WatchShowStateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchShowState, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getCueList =
      $grpc.ClientMethod<$0.GetCueListRequest, $0.CueListResponse>(
          '/stagesync.v1.ShowControlService/GetCueList',
          ($0.GetCueListRequest value) => value.writeToBuffer(),
          $0.CueListResponse.fromBuffer);
  static final _$updateCueList =
      $grpc.ClientMethod<$0.UpdateCueListRequest, $0.CueListResponse>(
          '/stagesync.v1.ShowControlService/UpdateCueList',
          ($0.UpdateCueListRequest value) => value.writeToBuffer(),
          $0.CueListResponse.fromBuffer);
  static final _$upsertCue =
      $grpc.ClientMethod<$0.UpsertCueRequest, $0.CueResponse>(
          '/stagesync.v1.ShowControlService/UpsertCue',
          ($0.UpsertCueRequest value) => value.writeToBuffer(),
          $0.CueResponse.fromBuffer);
  static final _$deleteCue = $grpc.ClientMethod<$0.DeleteCueRequest, $1.Empty>(
      '/stagesync.v1.ShowControlService/DeleteCue',
      ($0.DeleteCueRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$go = $grpc.ClientMethod<$0.GoRequest, $0.GoResponse>(
      '/stagesync.v1.ShowControlService/Go',
      ($0.GoRequest value) => value.writeToBuffer(),
      $0.GoResponse.fromBuffer);
  static final _$stop = $grpc.ClientMethod<$0.StopRequest, $1.Empty>(
      '/stagesync.v1.ShowControlService/Stop',
      ($0.StopRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$pause = $grpc.ClientMethod<$0.PauseRequest, $1.Empty>(
      '/stagesync.v1.ShowControlService/Pause',
      ($0.PauseRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$resume = $grpc.ClientMethod<$0.ResumeRequest, $1.Empty>(
      '/stagesync.v1.ShowControlService/Resume',
      ($0.ResumeRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$watchShowState =
      $grpc.ClientMethod<$0.WatchShowStateRequest, $0.ShowStateEvent>(
          '/stagesync.v1.ShowControlService/WatchShowState',
          ($0.WatchShowStateRequest value) => value.writeToBuffer(),
          $0.ShowStateEvent.fromBuffer);
}

@$pb.GrpcServiceName('stagesync.v1.ShowControlService')
abstract class ShowControlServiceBase extends $grpc.Service {
  $core.String get $name => 'stagesync.v1.ShowControlService';

  ShowControlServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetCueListRequest, $0.CueListResponse>(
        'GetCueList',
        getCueList_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetCueListRequest.fromBuffer(value),
        ($0.CueListResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateCueListRequest, $0.CueListResponse>(
        'UpdateCueList',
        updateCueList_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateCueListRequest.fromBuffer(value),
        ($0.CueListResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpsertCueRequest, $0.CueResponse>(
        'UpsertCue',
        upsertCue_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UpsertCueRequest.fromBuffer(value),
        ($0.CueResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteCueRequest, $1.Empty>(
        'DeleteCue',
        deleteCue_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteCueRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GoRequest, $0.GoResponse>(
        'Go',
        go_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GoRequest.fromBuffer(value),
        ($0.GoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StopRequest, $1.Empty>(
        'Stop',
        stop_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StopRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PauseRequest, $1.Empty>(
        'Pause',
        pause_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PauseRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ResumeRequest, $1.Empty>(
        'Resume',
        resume_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ResumeRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchShowStateRequest, $0.ShowStateEvent>(
        'WatchShowState',
        watchShowState_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WatchShowStateRequest.fromBuffer(value),
        ($0.ShowStateEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.CueListResponse> getCueList_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetCueListRequest> $request) async {
    return getCueList($call, await $request);
  }

  $async.Future<$0.CueListResponse> getCueList(
      $grpc.ServiceCall call, $0.GetCueListRequest request);

  $async.Future<$0.CueListResponse> updateCueList_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateCueListRequest> $request) async {
    return updateCueList($call, await $request);
  }

  $async.Future<$0.CueListResponse> updateCueList(
      $grpc.ServiceCall call, $0.UpdateCueListRequest request);

  $async.Future<$0.CueResponse> upsertCue_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpsertCueRequest> $request) async {
    return upsertCue($call, await $request);
  }

  $async.Future<$0.CueResponse> upsertCue(
      $grpc.ServiceCall call, $0.UpsertCueRequest request);

  $async.Future<$1.Empty> deleteCue_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteCueRequest> $request) async {
    return deleteCue($call, await $request);
  }

  $async.Future<$1.Empty> deleteCue(
      $grpc.ServiceCall call, $0.DeleteCueRequest request);

  $async.Future<$0.GoResponse> go_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.GoRequest> $request) async {
    return go($call, await $request);
  }

  $async.Future<$0.GoResponse> go($grpc.ServiceCall call, $0.GoRequest request);

  $async.Future<$1.Empty> stop_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.StopRequest> $request) async {
    return stop($call, await $request);
  }

  $async.Future<$1.Empty> stop($grpc.ServiceCall call, $0.StopRequest request);

  $async.Future<$1.Empty> pause_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PauseRequest> $request) async {
    return pause($call, await $request);
  }

  $async.Future<$1.Empty> pause(
      $grpc.ServiceCall call, $0.PauseRequest request);

  $async.Future<$1.Empty> resume_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ResumeRequest> $request) async {
    return resume($call, await $request);
  }

  $async.Future<$1.Empty> resume(
      $grpc.ServiceCall call, $0.ResumeRequest request);

  $async.Stream<$0.ShowStateEvent> watchShowState_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchShowStateRequest> $request) async* {
    yield* watchShowState($call, await $request);
  }

  $async.Stream<$0.ShowStateEvent> watchShowState(
      $grpc.ServiceCall call, $0.WatchShowStateRequest request);
}
