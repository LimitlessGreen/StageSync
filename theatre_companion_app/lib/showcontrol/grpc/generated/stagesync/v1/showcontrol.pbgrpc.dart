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

  /// CueList ersetzen (Master/Editor-Role erforderlich)
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

  /// PatchConfig setzen (Master/Editor erforderlich)
  $grpc.ResponseFuture<$0.PatchConfigResponse> updatePatchConfig(
    $0.UpdatePatchConfigRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updatePatchConfig, request, options: options);
  }

  /// Per-Cue Audio-Kontrolle (Server routet zu Nodes und updated Engine-State atomar)
  $grpc.ResponseFuture<$1.Empty> pauseCueAudio(
    $0.PauseCueAudioRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$pauseCueAudio, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> resumeCueAudio(
    $0.ResumeCueAudioRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resumeCueAudio, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> stopCueAudio(
    $0.StopCueAudioRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stopCueAudio, request, options: options);
  }

  /// ── 4-Stream EventBus ────────────────────────────────────────────────────
  /// Stream 1: Show-Definition (CueList, Patch, Assets)
  $grpc.ResponseStream<$0.ShowDefinitionEvent> watchShowDefinition(
    $0.WatchShowDefinitionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchShowDefinition, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Stream 2: Show-Execution (Transport, Cue-States)
  $grpc.ResponseStream<$0.ShowExecutionEvent> watchShowExecution(
    $0.WatchShowExecutionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchShowExecution, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Stream 3: Node Health (Online/Offline, Clock-Delta)
  $grpc.ResponseStream<$0.NodeHealthEvent> watchNodeHealth(
    $0.WatchNodeHealthRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchNodeHealth, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Stream 4: Media Sync (Asset-Änderungen)
  $grpc.ResponseStream<$0.MediaSyncEvent> watchMediaSync(
    $0.WatchMediaSyncRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchMediaSync, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Erkannten Stille-Offset für ein Asset abfragen (nach Preload verfügbar)
  $grpc.ResponseFuture<$0.GetAssetSilenceInfoResponse> getAssetSilenceInfo(
    $0.GetAssetSilenceInfoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAssetSilenceInfo, request, options: options);
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
  static final _$updatePatchConfig =
      $grpc.ClientMethod<$0.UpdatePatchConfigRequest, $0.PatchConfigResponse>(
          '/stagesync.v1.ShowControlService/UpdatePatchConfig',
          ($0.UpdatePatchConfigRequest value) => value.writeToBuffer(),
          $0.PatchConfigResponse.fromBuffer);
  static final _$pauseCueAudio =
      $grpc.ClientMethod<$0.PauseCueAudioRequest, $1.Empty>(
          '/stagesync.v1.ShowControlService/PauseCueAudio',
          ($0.PauseCueAudioRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$resumeCueAudio =
      $grpc.ClientMethod<$0.ResumeCueAudioRequest, $1.Empty>(
          '/stagesync.v1.ShowControlService/ResumeCueAudio',
          ($0.ResumeCueAudioRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$stopCueAudio =
      $grpc.ClientMethod<$0.StopCueAudioRequest, $1.Empty>(
          '/stagesync.v1.ShowControlService/StopCueAudio',
          ($0.StopCueAudioRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$watchShowDefinition =
      $grpc.ClientMethod<$0.WatchShowDefinitionRequest, $0.ShowDefinitionEvent>(
          '/stagesync.v1.ShowControlService/WatchShowDefinition',
          ($0.WatchShowDefinitionRequest value) => value.writeToBuffer(),
          $0.ShowDefinitionEvent.fromBuffer);
  static final _$watchShowExecution =
      $grpc.ClientMethod<$0.WatchShowExecutionRequest, $0.ShowExecutionEvent>(
          '/stagesync.v1.ShowControlService/WatchShowExecution',
          ($0.WatchShowExecutionRequest value) => value.writeToBuffer(),
          $0.ShowExecutionEvent.fromBuffer);
  static final _$watchNodeHealth =
      $grpc.ClientMethod<$0.WatchNodeHealthRequest, $0.NodeHealthEvent>(
          '/stagesync.v1.ShowControlService/WatchNodeHealth',
          ($0.WatchNodeHealthRequest value) => value.writeToBuffer(),
          $0.NodeHealthEvent.fromBuffer);
  static final _$watchMediaSync =
      $grpc.ClientMethod<$0.WatchMediaSyncRequest, $0.MediaSyncEvent>(
          '/stagesync.v1.ShowControlService/WatchMediaSync',
          ($0.WatchMediaSyncRequest value) => value.writeToBuffer(),
          $0.MediaSyncEvent.fromBuffer);
  static final _$getAssetSilenceInfo = $grpc.ClientMethod<
          $0.GetAssetSilenceInfoRequest, $0.GetAssetSilenceInfoResponse>(
      '/stagesync.v1.ShowControlService/GetAssetSilenceInfo',
      ($0.GetAssetSilenceInfoRequest value) => value.writeToBuffer(),
      $0.GetAssetSilenceInfoResponse.fromBuffer);
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
    $addMethod($grpc.ServiceMethod<$0.UpdatePatchConfigRequest,
            $0.PatchConfigResponse>(
        'UpdatePatchConfig',
        updatePatchConfig_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdatePatchConfigRequest.fromBuffer(value),
        ($0.PatchConfigResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PauseCueAudioRequest, $1.Empty>(
        'PauseCueAudio',
        pauseCueAudio_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PauseCueAudioRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ResumeCueAudioRequest, $1.Empty>(
        'ResumeCueAudio',
        resumeCueAudio_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ResumeCueAudioRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StopCueAudioRequest, $1.Empty>(
        'StopCueAudio',
        stopCueAudio_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.StopCueAudioRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchShowDefinitionRequest,
            $0.ShowDefinitionEvent>(
        'WatchShowDefinition',
        watchShowDefinition_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WatchShowDefinitionRequest.fromBuffer(value),
        ($0.ShowDefinitionEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchShowExecutionRequest,
            $0.ShowExecutionEvent>(
        'WatchShowExecution',
        watchShowExecution_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WatchShowExecutionRequest.fromBuffer(value),
        ($0.ShowExecutionEvent value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.WatchNodeHealthRequest, $0.NodeHealthEvent>(
            'WatchNodeHealth',
            watchNodeHealth_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.WatchNodeHealthRequest.fromBuffer(value),
            ($0.NodeHealthEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchMediaSyncRequest, $0.MediaSyncEvent>(
        'WatchMediaSync',
        watchMediaSync_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WatchMediaSyncRequest.fromBuffer(value),
        ($0.MediaSyncEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetAssetSilenceInfoRequest,
            $0.GetAssetSilenceInfoResponse>(
        'GetAssetSilenceInfo',
        getAssetSilenceInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetAssetSilenceInfoRequest.fromBuffer(value),
        ($0.GetAssetSilenceInfoResponse value) => value.writeToBuffer()));
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

  $async.Future<$0.PatchConfigResponse> updatePatchConfig_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdatePatchConfigRequest> $request) async {
    return updatePatchConfig($call, await $request);
  }

  $async.Future<$0.PatchConfigResponse> updatePatchConfig(
      $grpc.ServiceCall call, $0.UpdatePatchConfigRequest request);

  $async.Future<$1.Empty> pauseCueAudio_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PauseCueAudioRequest> $request) async {
    return pauseCueAudio($call, await $request);
  }

  $async.Future<$1.Empty> pauseCueAudio(
      $grpc.ServiceCall call, $0.PauseCueAudioRequest request);

  $async.Future<$1.Empty> resumeCueAudio_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ResumeCueAudioRequest> $request) async {
    return resumeCueAudio($call, await $request);
  }

  $async.Future<$1.Empty> resumeCueAudio(
      $grpc.ServiceCall call, $0.ResumeCueAudioRequest request);

  $async.Future<$1.Empty> stopCueAudio_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StopCueAudioRequest> $request) async {
    return stopCueAudio($call, await $request);
  }

  $async.Future<$1.Empty> stopCueAudio(
      $grpc.ServiceCall call, $0.StopCueAudioRequest request);

  $async.Stream<$0.ShowDefinitionEvent> watchShowDefinition_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.WatchShowDefinitionRequest> $request) async* {
    yield* watchShowDefinition($call, await $request);
  }

  $async.Stream<$0.ShowDefinitionEvent> watchShowDefinition(
      $grpc.ServiceCall call, $0.WatchShowDefinitionRequest request);

  $async.Stream<$0.ShowExecutionEvent> watchShowExecution_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.WatchShowExecutionRequest> $request) async* {
    yield* watchShowExecution($call, await $request);
  }

  $async.Stream<$0.ShowExecutionEvent> watchShowExecution(
      $grpc.ServiceCall call, $0.WatchShowExecutionRequest request);

  $async.Stream<$0.NodeHealthEvent> watchNodeHealth_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchNodeHealthRequest> $request) async* {
    yield* watchNodeHealth($call, await $request);
  }

  $async.Stream<$0.NodeHealthEvent> watchNodeHealth(
      $grpc.ServiceCall call, $0.WatchNodeHealthRequest request);

  $async.Stream<$0.MediaSyncEvent> watchMediaSync_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchMediaSyncRequest> $request) async* {
    yield* watchMediaSync($call, await $request);
  }

  $async.Stream<$0.MediaSyncEvent> watchMediaSync(
      $grpc.ServiceCall call, $0.WatchMediaSyncRequest request);

  $async.Future<$0.GetAssetSilenceInfoResponse> getAssetSilenceInfo_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetAssetSilenceInfoRequest> $request) async {
    return getAssetSilenceInfo($call, await $request);
  }

  $async.Future<$0.GetAssetSilenceInfoResponse> getAssetSilenceInfo(
      $grpc.ServiceCall call, $0.GetAssetSilenceInfoRequest request);
}
