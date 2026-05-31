// This is a generated file - do not edit.
//
// Generated from stagesync/v1/talkback.proto.

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

import 'talkback.pb.dart' as $0;

export 'talkback.pb.dart';

@$pb.GrpcServiceName('stagesync.v1.TalkbackService')
class TalkbackServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TalkbackServiceClient(super.channel, {super.options, super.interceptors});

  /// Bidirektionaler Stream: Client sendet Audio, Server liefert Status-Updates.
  /// Erstes Frame MUSS TalkbackInitFrame sein.
  $grpc.ResponseStream<$0.TalkbackStatus> streamTalkback(
    $async.Stream<$0.TalkbackFrame> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$streamTalkback, request, options: options);
  }

  /// Aktive Talkback-Sessions der aktuellen Session abfragen (Einmal-Abfrage).
  $grpc.ResponseFuture<$0.ListActiveTalkersResponse> listActiveTalkers(
    $0.ListActiveTalkersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listActiveTalkers, request, options: options);
  }

  // method descriptors

  static final _$streamTalkback =
      $grpc.ClientMethod<$0.TalkbackFrame, $0.TalkbackStatus>(
          '/stagesync.v1.TalkbackService/StreamTalkback',
          ($0.TalkbackFrame value) => value.writeToBuffer(),
          $0.TalkbackStatus.fromBuffer);
  static final _$listActiveTalkers = $grpc.ClientMethod<
          $0.ListActiveTalkersRequest, $0.ListActiveTalkersResponse>(
      '/stagesync.v1.TalkbackService/ListActiveTalkers',
      ($0.ListActiveTalkersRequest value) => value.writeToBuffer(),
      $0.ListActiveTalkersResponse.fromBuffer);
}

@$pb.GrpcServiceName('stagesync.v1.TalkbackService')
abstract class TalkbackServiceBase extends $grpc.Service {
  $core.String get $name => 'stagesync.v1.TalkbackService';

  TalkbackServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.TalkbackFrame, $0.TalkbackStatus>(
        'StreamTalkback',
        streamTalkback,
        true,
        true,
        ($core.List<$core.int> value) => $0.TalkbackFrame.fromBuffer(value),
        ($0.TalkbackStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListActiveTalkersRequest,
            $0.ListActiveTalkersResponse>(
        'ListActiveTalkers',
        listActiveTalkers_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListActiveTalkersRequest.fromBuffer(value),
        ($0.ListActiveTalkersResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.TalkbackStatus> streamTalkback(
      $grpc.ServiceCall call, $async.Stream<$0.TalkbackFrame> request);

  $async.Future<$0.ListActiveTalkersResponse> listActiveTalkers_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListActiveTalkersRequest> $request) async {
    return listActiveTalkers($call, await $request);
  }

  $async.Future<$0.ListActiveTalkersResponse> listActiveTalkers(
      $grpc.ServiceCall call, $0.ListActiveTalkersRequest request);
}
