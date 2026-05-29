// This is a generated file - do not edit.
//
// Generated from stagesync/v1/session.proto.

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

import 'session.pb.dart' as $0;

export 'session.pb.dart';

@$pb.GrpcServiceName('stagesync.v1.SessionService')
class SessionServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SessionServiceClient(super.channel, {super.options, super.interceptors});

  /// Session erstellen (wird Master)
  $grpc.ResponseFuture<$0.SessionResponse> createSession(
    $0.CreateSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createSession, request, options: options);
  }

  /// Einer bestehenden Session beitreten
  $grpc.ResponseFuture<$0.SessionResponse> joinSession(
    $0.JoinSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$joinSession, request, options: options);
  }

  /// Session verlassen
  $grpc.ResponseFuture<$1.Empty> leaveSession(
    $0.LeaveSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$leaveSession, request, options: options);
  }

  /// Heartbeat — Node meldet sich als aktiv
  $grpc.ResponseFuture<$0.HeartbeatResponse> heartbeat(
    $0.HeartbeatRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$heartbeat, request, options: options);
  }

  /// Session-Events streamen (Node-Join/Leave, Master-Wechsel, etc.)
  $grpc.ResponseStream<$0.SessionEvent> watchSession(
    $0.WatchSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchSession, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Alle aktiven Sessions im Netz auflisten
  $grpc.ResponseFuture<$0.ListSessionsResponse> listSessions(
    $0.ListSessionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSessions, request, options: options);
  }

  // method descriptors

  static final _$createSession =
      $grpc.ClientMethod<$0.CreateSessionRequest, $0.SessionResponse>(
          '/stagesync.v1.SessionService/CreateSession',
          ($0.CreateSessionRequest value) => value.writeToBuffer(),
          $0.SessionResponse.fromBuffer);
  static final _$joinSession =
      $grpc.ClientMethod<$0.JoinSessionRequest, $0.SessionResponse>(
          '/stagesync.v1.SessionService/JoinSession',
          ($0.JoinSessionRequest value) => value.writeToBuffer(),
          $0.SessionResponse.fromBuffer);
  static final _$leaveSession =
      $grpc.ClientMethod<$0.LeaveSessionRequest, $1.Empty>(
          '/stagesync.v1.SessionService/LeaveSession',
          ($0.LeaveSessionRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$heartbeat =
      $grpc.ClientMethod<$0.HeartbeatRequest, $0.HeartbeatResponse>(
          '/stagesync.v1.SessionService/Heartbeat',
          ($0.HeartbeatRequest value) => value.writeToBuffer(),
          $0.HeartbeatResponse.fromBuffer);
  static final _$watchSession =
      $grpc.ClientMethod<$0.WatchSessionRequest, $0.SessionEvent>(
          '/stagesync.v1.SessionService/WatchSession',
          ($0.WatchSessionRequest value) => value.writeToBuffer(),
          $0.SessionEvent.fromBuffer);
  static final _$listSessions =
      $grpc.ClientMethod<$0.ListSessionsRequest, $0.ListSessionsResponse>(
          '/stagesync.v1.SessionService/ListSessions',
          ($0.ListSessionsRequest value) => value.writeToBuffer(),
          $0.ListSessionsResponse.fromBuffer);
}

@$pb.GrpcServiceName('stagesync.v1.SessionService')
abstract class SessionServiceBase extends $grpc.Service {
  $core.String get $name => 'stagesync.v1.SessionService';

  SessionServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CreateSessionRequest, $0.SessionResponse>(
        'CreateSession',
        createSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateSessionRequest.fromBuffer(value),
        ($0.SessionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.JoinSessionRequest, $0.SessionResponse>(
        'JoinSession',
        joinSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.JoinSessionRequest.fromBuffer(value),
        ($0.SessionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LeaveSessionRequest, $1.Empty>(
        'LeaveSession',
        leaveSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.LeaveSessionRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.HeartbeatRequest, $0.HeartbeatResponse>(
        'Heartbeat',
        heartbeat_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HeartbeatRequest.fromBuffer(value),
        ($0.HeartbeatResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchSessionRequest, $0.SessionEvent>(
        'WatchSession',
        watchSession_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WatchSessionRequest.fromBuffer(value),
        ($0.SessionEvent value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListSessionsRequest, $0.ListSessionsResponse>(
            'ListSessions',
            listSessions_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListSessionsRequest.fromBuffer(value),
            ($0.ListSessionsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SessionResponse> createSession_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateSessionRequest> $request) async {
    return createSession($call, await $request);
  }

  $async.Future<$0.SessionResponse> createSession(
      $grpc.ServiceCall call, $0.CreateSessionRequest request);

  $async.Future<$0.SessionResponse> joinSession_Pre($grpc.ServiceCall $call,
      $async.Future<$0.JoinSessionRequest> $request) async {
    return joinSession($call, await $request);
  }

  $async.Future<$0.SessionResponse> joinSession(
      $grpc.ServiceCall call, $0.JoinSessionRequest request);

  $async.Future<$1.Empty> leaveSession_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LeaveSessionRequest> $request) async {
    return leaveSession($call, await $request);
  }

  $async.Future<$1.Empty> leaveSession(
      $grpc.ServiceCall call, $0.LeaveSessionRequest request);

  $async.Future<$0.HeartbeatResponse> heartbeat_Pre($grpc.ServiceCall $call,
      $async.Future<$0.HeartbeatRequest> $request) async {
    return heartbeat($call, await $request);
  }

  $async.Future<$0.HeartbeatResponse> heartbeat(
      $grpc.ServiceCall call, $0.HeartbeatRequest request);

  $async.Stream<$0.SessionEvent> watchSession_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchSessionRequest> $request) async* {
    yield* watchSession($call, await $request);
  }

  $async.Stream<$0.SessionEvent> watchSession(
      $grpc.ServiceCall call, $0.WatchSessionRequest request);

  $async.Future<$0.ListSessionsResponse> listSessions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListSessionsRequest> $request) async {
    return listSessions($call, await $request);
  }

  $async.Future<$0.ListSessionsResponse> listSessions(
      $grpc.ServiceCall call, $0.ListSessionsRequest request);
}
