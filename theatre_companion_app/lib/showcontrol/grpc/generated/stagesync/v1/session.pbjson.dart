// This is a generated file - do not edit.
//
// Generated from stagesync/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use sessionDescriptor instead')
const Session$json = {
  '1': 'Session',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'show_name', '3': 3, '4': 1, '5': 9, '10': 'showName'},
    {
      '1': 'password_protected',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'passwordProtected'
    },
    {'1': 'master_node_id', '3': 5, '4': 1, '5': 9, '10': 'masterNodeId'},
    {
      '1': 'nodes',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.NodeInfo',
      '10': 'nodes'
    },
    {
      '1': 'created_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Timestamp',
      '10': 'createdAt'
    },
    {'1': 'persistent', '3': 8, '4': 1, '5': 8, '10': 'persistent'},
  ],
};

/// Descriptor for `Session`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionDescriptor = $convert.base64Decode(
    'CgdTZXNzaW9uEh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBISCgRuYW1lGAIgASgJUg'
    'RuYW1lEhsKCXNob3dfbmFtZRgDIAEoCVIIc2hvd05hbWUSLQoScGFzc3dvcmRfcHJvdGVjdGVk'
    'GAQgASgIUhFwYXNzd29yZFByb3RlY3RlZBIkCg5tYXN0ZXJfbm9kZV9pZBgFIAEoCVIMbWFzdG'
    'VyTm9kZUlkEiwKBW5vZGVzGAYgAygLMhYuc3RhZ2VzeW5jLnYxLk5vZGVJbmZvUgVub2RlcxI2'
    'CgpjcmVhdGVkX2F0GAcgASgLMhcuc3RhZ2VzeW5jLnYxLlRpbWVzdGFtcFIJY3JlYXRlZEF0Eh'
    '4KCnBlcnNpc3RlbnQYCCABKAhSCnBlcnNpc3RlbnQ=');

@$core.Deprecated('Use createSessionRequestDescriptor instead')
const CreateSessionRequest$json = {
  '1': 'CreateSessionRequest',
  '2': [
    {'1': 'session_name', '3': 1, '4': 1, '5': 9, '10': 'sessionName'},
    {'1': 'show_name', '3': 2, '4': 1, '5': 9, '10': 'showName'},
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
    {
      '1': 'my_node',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeInfo',
      '10': 'myNode'
    },
    {'1': 'persistent', '3': 5, '4': 1, '5': 8, '10': 'persistent'},
  ],
};

/// Descriptor for `CreateSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSessionRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVTZXNzaW9uUmVxdWVzdBIhCgxzZXNzaW9uX25hbWUYASABKAlSC3Nlc3Npb25OYW'
    '1lEhsKCXNob3dfbmFtZRgCIAEoCVIIc2hvd05hbWUSGgoIcGFzc3dvcmQYAyABKAlSCHBhc3N3'
    'b3JkEi8KB215X25vZGUYBCABKAsyFi5zdGFnZXN5bmMudjEuTm9kZUluZm9SBm15Tm9kZRIeCg'
    'pwZXJzaXN0ZW50GAUgASgIUgpwZXJzaXN0ZW50');

@$core.Deprecated('Use joinSessionRequestDescriptor instead')
const JoinSessionRequest$json = {
  '1': 'JoinSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    {
      '1': 'my_node',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeInfo',
      '10': 'myNode'
    },
  ],
};

/// Descriptor for `JoinSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinSessionRequestDescriptor = $convert.base64Decode(
    'ChJKb2luU2Vzc2lvblJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCH'
    'Bhc3N3b3JkGAIgASgJUghwYXNzd29yZBIvCgdteV9ub2RlGAMgASgLMhYuc3RhZ2VzeW5jLnYx'
    'Lk5vZGVJbmZvUgZteU5vZGU=');

@$core.Deprecated('Use leaveSessionRequestDescriptor instead')
const LeaveSessionRequest$json = {
  '1': 'LeaveSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `LeaveSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaveSessionRequestDescriptor = $convert.base64Decode(
    'ChNMZWF2ZVNlc3Npb25SZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIXCg'
    'dub2RlX2lkGAIgASgJUgZub2RlSWQSFAoFdG9rZW4YAyABKAlSBXRva2Vu');

@$core.Deprecated('Use sessionResponseDescriptor instead')
const SessionResponse$json = {
  '1': 'SessionResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Session',
      '10': 'session'
    },
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'assigned_node',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeInfo',
      '10': 'assignedNode'
    },
  ],
};

/// Descriptor for `SessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionResponseDescriptor = $convert.base64Decode(
    'Cg9TZXNzaW9uUmVzcG9uc2USLwoHc2Vzc2lvbhgBIAEoCzIVLnN0YWdlc3luYy52MS5TZXNzaW'
    '9uUgdzZXNzaW9uEhQKBXRva2VuGAIgASgJUgV0b2tlbhI7Cg1hc3NpZ25lZF9ub2RlGAMgASgL'
    'MhYuc3RhZ2VzeW5jLnYxLk5vZGVJbmZvUgxhc3NpZ25lZE5vZGU=');

@$core.Deprecated('Use heartbeatRequestDescriptor instead')
const HeartbeatRequest$json = {
  '1': 'HeartbeatRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
    {'1': 'unix_millis', '3': 4, '4': 1, '5': 3, '10': 'unixMillis'},
  ],
};

/// Descriptor for `HeartbeatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatRequestDescriptor = $convert.base64Decode(
    'ChBIZWFydGJlYXRSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIXCgdub2'
    'RlX2lkGAIgASgJUgZub2RlSWQSFAoFdG9rZW4YAyABKAlSBXRva2VuEh8KC3VuaXhfbWlsbGlz'
    'GAQgASgDUgp1bml4TWlsbGlz');

@$core.Deprecated('Use heartbeatResponseDescriptor instead')
const HeartbeatResponse$json = {
  '1': 'HeartbeatResponse',
  '2': [
    {
      '1': 'server_unix_millis',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'serverUnixMillis'
    },
    {'1': 'session_healthy', '3': 2, '4': 1, '5': 8, '10': 'sessionHealthy'},
  ],
};

/// Descriptor for `HeartbeatResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatResponseDescriptor = $convert.base64Decode(
    'ChFIZWFydGJlYXRSZXNwb25zZRIsChJzZXJ2ZXJfdW5peF9taWxsaXMYASABKANSEHNlcnZlcl'
    'VuaXhNaWxsaXMSJwoPc2Vzc2lvbl9oZWFsdGh5GAIgASgIUg5zZXNzaW9uSGVhbHRoeQ==');

@$core.Deprecated('Use watchSessionRequestDescriptor instead')
const WatchSessionRequest$json = {
  '1': 'WatchSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `WatchSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchSessionRequestDescriptor = $convert.base64Decode(
    'ChNXYXRjaFNlc3Npb25SZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIXCg'
    'dub2RlX2lkGAIgASgJUgZub2RlSWQSFAoFdG9rZW4YAyABKAlSBXRva2Vu');

@$core.Deprecated('Use sessionEventDescriptor instead')
const SessionEvent$json = {
  '1': 'SessionEvent',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.SessionEvent.Type',
      '10': 'type'
    },
    {
      '1': 'session',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Session',
      '10': 'session'
    },
    {
      '1': 'affected_node',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeInfo',
      '10': 'affectedNode'
    },
    {
      '1': 'occurred_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Timestamp',
      '10': 'occurredAt'
    },
  ],
  '4': [SessionEvent_Type$json],
};

@$core.Deprecated('Use sessionEventDescriptor instead')
const SessionEvent_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'TYPE_UNSPECIFIED', '2': 0},
    {'1': 'TYPE_NODE_JOINED', '2': 1},
    {'1': 'TYPE_NODE_LEFT', '2': 2},
    {'1': 'TYPE_NODE_OFFLINE', '2': 3},
    {'1': 'TYPE_MASTER_CHANGED', '2': 4},
    {'1': 'TYPE_SESSION_CLOSED', '2': 5},
  ],
};

/// Descriptor for `SessionEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionEventDescriptor = $convert.base64Decode(
    'CgxTZXNzaW9uRXZlbnQSMwoEdHlwZRgBIAEoDjIfLnN0YWdlc3luYy52MS5TZXNzaW9uRXZlbn'
    'QuVHlwZVIEdHlwZRIvCgdzZXNzaW9uGAIgASgLMhUuc3RhZ2VzeW5jLnYxLlNlc3Npb25SB3Nl'
    'c3Npb24SOwoNYWZmZWN0ZWRfbm9kZRgDIAEoCzIWLnN0YWdlc3luYy52MS5Ob2RlSW5mb1IMYW'
    'ZmZWN0ZWROb2RlEjgKC29jY3VycmVkX2F0GAQgASgLMhcuc3RhZ2VzeW5jLnYxLlRpbWVzdGFt'
    'cFIKb2NjdXJyZWRBdCKPAQoEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASFAoQVFlQRV9OT0'
    'RFX0pPSU5FRBABEhIKDlRZUEVfTk9ERV9MRUZUEAISFQoRVFlQRV9OT0RFX09GRkxJTkUQAxIX'
    'ChNUWVBFX01BU1RFUl9DSEFOR0VEEAQSFwoTVFlQRV9TRVNTSU9OX0NMT1NFRBAF');

@$core.Deprecated('Use listSessionsRequestDescriptor instead')
const ListSessionsRequest$json = {
  '1': 'ListSessionsRequest',
};

/// Descriptor for `ListSessionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsRequestDescriptor =
    $convert.base64Decode('ChNMaXN0U2Vzc2lvbnNSZXF1ZXN0');

@$core.Deprecated('Use listSessionsResponseDescriptor instead')
const ListSessionsResponse$json = {
  '1': 'ListSessionsResponse',
  '2': [
    {
      '1': 'sessions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.Session',
      '10': 'sessions'
    },
  ],
};

/// Descriptor for `ListSessionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0U2Vzc2lvbnNSZXNwb25zZRIxCghzZXNzaW9ucxgBIAMoCzIVLnN0YWdlc3luYy52MS'
    '5TZXNzaW9uUghzZXNzaW9ucw==');
