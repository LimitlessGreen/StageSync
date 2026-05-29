// This is a generated file - do not edit.
//
// Generated from stagesync/v1/node.proto.

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

import 'node.pb.dart' as $0;

export 'node.pb.dart';

@$pb.GrpcServiceName('stagesync.v1.NodeService')
class NodeServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NodeServiceClient(super.channel, {super.options, super.interceptors});

  /// Node bei der Session registrieren
  $grpc.ResponseFuture<$0.NodeResponse> registerNode(
    $0.RegisterNodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$registerNode, request, options: options);
  }

  /// Node abmelden
  $grpc.ResponseFuture<$1.Empty> unregisterNode(
    $0.UnregisterNodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$unregisterNode, request, options: options);
  }

  /// Alle Nodes der Session auflisten
  $grpc.ResponseFuture<$0.ListNodesResponse> listNodes(
    $0.ListNodesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listNodes, request, options: options);
  }

  /// Node-Events streamen
  $grpc.ResponseStream<$0.NodeEvent> watchNodes(
    $0.WatchNodesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchNodes, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Node-Capability-Update (z.B. Audio-Device-Liste)
  $grpc.ResponseFuture<$1.Empty> updateCapabilities(
    $0.UpdateCapabilitiesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateCapabilities, request, options: options);
  }

  /// Node öffnet diesen Stream — Server pusht Commands (Audio play/stop, OSC, …)
  $grpc.ResponseStream<$0.NodeCommandRequest> streamNodeCommands(
    $0.StreamNodeCommandsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamNodeCommands, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Master/Client sendet Command an einen bestimmten Node (über Dispatcher)
  $grpc.ResponseFuture<$0.NodeCommandResponse> sendNodeCommand(
    $0.SendNodeCommandRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendNodeCommand, request, options: options);
  }

  // method descriptors

  static final _$registerNode =
      $grpc.ClientMethod<$0.RegisterNodeRequest, $0.NodeResponse>(
          '/stagesync.v1.NodeService/RegisterNode',
          ($0.RegisterNodeRequest value) => value.writeToBuffer(),
          $0.NodeResponse.fromBuffer);
  static final _$unregisterNode =
      $grpc.ClientMethod<$0.UnregisterNodeRequest, $1.Empty>(
          '/stagesync.v1.NodeService/UnregisterNode',
          ($0.UnregisterNodeRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$listNodes =
      $grpc.ClientMethod<$0.ListNodesRequest, $0.ListNodesResponse>(
          '/stagesync.v1.NodeService/ListNodes',
          ($0.ListNodesRequest value) => value.writeToBuffer(),
          $0.ListNodesResponse.fromBuffer);
  static final _$watchNodes =
      $grpc.ClientMethod<$0.WatchNodesRequest, $0.NodeEvent>(
          '/stagesync.v1.NodeService/WatchNodes',
          ($0.WatchNodesRequest value) => value.writeToBuffer(),
          $0.NodeEvent.fromBuffer);
  static final _$updateCapabilities =
      $grpc.ClientMethod<$0.UpdateCapabilitiesRequest, $1.Empty>(
          '/stagesync.v1.NodeService/UpdateCapabilities',
          ($0.UpdateCapabilitiesRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$streamNodeCommands =
      $grpc.ClientMethod<$0.StreamNodeCommandsRequest, $0.NodeCommandRequest>(
          '/stagesync.v1.NodeService/StreamNodeCommands',
          ($0.StreamNodeCommandsRequest value) => value.writeToBuffer(),
          $0.NodeCommandRequest.fromBuffer);
  static final _$sendNodeCommand =
      $grpc.ClientMethod<$0.SendNodeCommandRequest, $0.NodeCommandResponse>(
          '/stagesync.v1.NodeService/SendNodeCommand',
          ($0.SendNodeCommandRequest value) => value.writeToBuffer(),
          $0.NodeCommandResponse.fromBuffer);
}

@$pb.GrpcServiceName('stagesync.v1.NodeService')
abstract class NodeServiceBase extends $grpc.Service {
  $core.String get $name => 'stagesync.v1.NodeService';

  NodeServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.RegisterNodeRequest, $0.NodeResponse>(
        'RegisterNode',
        registerNode_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RegisterNodeRequest.fromBuffer(value),
        ($0.NodeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UnregisterNodeRequest, $1.Empty>(
        'UnregisterNode',
        unregisterNode_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UnregisterNodeRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListNodesRequest, $0.ListNodesResponse>(
        'ListNodes',
        listNodes_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListNodesRequest.fromBuffer(value),
        ($0.ListNodesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchNodesRequest, $0.NodeEvent>(
        'WatchNodes',
        watchNodes_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchNodesRequest.fromBuffer(value),
        ($0.NodeEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateCapabilitiesRequest, $1.Empty>(
        'UpdateCapabilities',
        updateCapabilities_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateCapabilitiesRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StreamNodeCommandsRequest,
            $0.NodeCommandRequest>(
        'StreamNodeCommands',
        streamNodeCommands_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.StreamNodeCommandsRequest.fromBuffer(value),
        ($0.NodeCommandRequest value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SendNodeCommandRequest, $0.NodeCommandResponse>(
            'SendNodeCommand',
            sendNodeCommand_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SendNodeCommandRequest.fromBuffer(value),
            ($0.NodeCommandResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.NodeResponse> registerNode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RegisterNodeRequest> $request) async {
    return registerNode($call, await $request);
  }

  $async.Future<$0.NodeResponse> registerNode(
      $grpc.ServiceCall call, $0.RegisterNodeRequest request);

  $async.Future<$1.Empty> unregisterNode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UnregisterNodeRequest> $request) async {
    return unregisterNode($call, await $request);
  }

  $async.Future<$1.Empty> unregisterNode(
      $grpc.ServiceCall call, $0.UnregisterNodeRequest request);

  $async.Future<$0.ListNodesResponse> listNodes_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListNodesRequest> $request) async {
    return listNodes($call, await $request);
  }

  $async.Future<$0.ListNodesResponse> listNodes(
      $grpc.ServiceCall call, $0.ListNodesRequest request);

  $async.Stream<$0.NodeEvent> watchNodes_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchNodesRequest> $request) async* {
    yield* watchNodes($call, await $request);
  }

  $async.Stream<$0.NodeEvent> watchNodes(
      $grpc.ServiceCall call, $0.WatchNodesRequest request);

  $async.Future<$1.Empty> updateCapabilities_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateCapabilitiesRequest> $request) async {
    return updateCapabilities($call, await $request);
  }

  $async.Future<$1.Empty> updateCapabilities(
      $grpc.ServiceCall call, $0.UpdateCapabilitiesRequest request);

  $async.Stream<$0.NodeCommandRequest> streamNodeCommands_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StreamNodeCommandsRequest> $request) async* {
    yield* streamNodeCommands($call, await $request);
  }

  $async.Stream<$0.NodeCommandRequest> streamNodeCommands(
      $grpc.ServiceCall call, $0.StreamNodeCommandsRequest request);

  $async.Future<$0.NodeCommandResponse> sendNodeCommand_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SendNodeCommandRequest> $request) async {
    return sendNodeCommand($call, await $request);
  }

  $async.Future<$0.NodeCommandResponse> sendNodeCommand(
      $grpc.ServiceCall call, $0.SendNodeCommandRequest request);
}
