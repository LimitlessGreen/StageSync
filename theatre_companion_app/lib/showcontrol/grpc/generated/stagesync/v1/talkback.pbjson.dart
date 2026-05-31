// This is a generated file - do not edit.
//
// Generated from stagesync/v1/talkback.proto.

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

@$core.Deprecated('Use talkbackInitFrameDescriptor instead')
const TalkbackInitFrame$json = {
  '1': 'TalkbackInitFrame',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'client_id', '3': 3, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'display_name', '3': 4, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'target_bus_ids', '3': 5, '4': 3, '5': 9, '10': 'targetBusIds'},
    {'1': 'sample_rate', '3': 6, '4': 1, '5': 5, '10': 'sampleRate'},
    {'1': 'channels', '3': 7, '4': 1, '5': 5, '10': 'channels'},
  ],
};

/// Descriptor for `TalkbackInitFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List talkbackInitFrameDescriptor = $convert.base64Decode(
    'ChFUYWxrYmFja0luaXRGcmFtZRIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG'
    '9rZW4YAiABKAlSBXRva2VuEhsKCWNsaWVudF9pZBgDIAEoCVIIY2xpZW50SWQSIQoMZGlzcGxh'
    'eV9uYW1lGAQgASgJUgtkaXNwbGF5TmFtZRIkCg50YXJnZXRfYnVzX2lkcxgFIAMoCVIMdGFyZ2'
    'V0QnVzSWRzEh8KC3NhbXBsZV9yYXRlGAYgASgFUgpzYW1wbGVSYXRlEhoKCGNoYW5uZWxzGAcg'
    'ASgFUghjaGFubmVscw==');

@$core.Deprecated('Use audioChunkDescriptor instead')
const AudioChunk$json = {
  '1': 'AudioChunk',
  '2': [
    {'1': 'opus_data', '3': 1, '4': 1, '5': 12, '10': 'opusData'},
    {'1': 'timestamp_ms', '3': 2, '4': 1, '5': 3, '10': 'timestampMs'},
    {'1': 'sequence', '3': 3, '4': 1, '5': 13, '10': 'sequence'},
  ],
};

/// Descriptor for `AudioChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioChunkDescriptor = $convert.base64Decode(
    'CgpBdWRpb0NodW5rEhsKCW9wdXNfZGF0YRgBIAEoDFIIb3B1c0RhdGESIQoMdGltZXN0YW1wX2'
    '1zGAIgASgDUgt0aW1lc3RhbXBNcxIaCghzZXF1ZW5jZRgDIAEoDVIIc2VxdWVuY2U=');

@$core.Deprecated('Use talkbackFrameDescriptor instead')
const TalkbackFrame$json = {
  '1': 'TalkbackFrame',
  '2': [
    {
      '1': 'init',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.TalkbackInitFrame',
      '9': 0,
      '10': 'init'
    },
    {
      '1': 'audio',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioChunk',
      '9': 0,
      '10': 'audio'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `TalkbackFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List talkbackFrameDescriptor = $convert.base64Decode(
    'Cg1UYWxrYmFja0ZyYW1lEjUKBGluaXQYASABKAsyHy5zdGFnZXN5bmMudjEuVGFsa2JhY2tJbm'
    'l0RnJhbWVIAFIEaW5pdBIwCgVhdWRpbxgCIAEoCzIYLnN0YWdlc3luYy52MS5BdWRpb0NodW5r'
    'SABSBWF1ZGlvQgkKB3BheWxvYWQ=');

@$core.Deprecated('Use talkbackStatusDescriptor instead')
const TalkbackStatus$json = {
  '1': 'TalkbackStatus',
  '2': [
    {'1': 'active', '3': 1, '4': 1, '5': 8, '10': 'active'},
    {
      '1': 'active_talkers',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.ActiveTalker',
      '10': 'activeTalkers'
    },
    {'1': 'error_msg', '3': 3, '4': 1, '5': 9, '10': 'errorMsg'},
  ],
};

/// Descriptor for `TalkbackStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List talkbackStatusDescriptor = $convert.base64Decode(
    'Cg5UYWxrYmFja1N0YXR1cxIWCgZhY3RpdmUYASABKAhSBmFjdGl2ZRJBCg5hY3RpdmVfdGFsa2'
    'VycxgCIAMoCzIaLnN0YWdlc3luYy52MS5BY3RpdmVUYWxrZXJSDWFjdGl2ZVRhbGtlcnMSGwoJ'
    'ZXJyb3JfbXNnGAMgASgJUghlcnJvck1zZw==');

@$core.Deprecated('Use activeTalkerDescriptor instead')
const ActiveTalker$json = {
  '1': 'ActiveTalker',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'latency_ms', '3': 3, '4': 1, '5': 3, '10': 'latencyMs'},
    {'1': 'bus_ids', '3': 4, '4': 3, '5': 9, '10': 'busIds'},
  ],
};

/// Descriptor for `ActiveTalker`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeTalkerDescriptor = $convert.base64Decode(
    'CgxBY3RpdmVUYWxrZXISGwoJY2xpZW50X2lkGAEgASgJUghjbGllbnRJZBIhCgxkaXNwbGF5X2'
    '5hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEh0KCmxhdGVuY3lfbXMYAyABKANSCWxhdGVuY3lNcxIX'
    'CgdidXNfaWRzGAQgAygJUgZidXNJZHM=');

@$core.Deprecated('Use listActiveTalkersRequestDescriptor instead')
const ListActiveTalkersRequest$json = {
  '1': 'ListActiveTalkersRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `ListActiveTalkersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listActiveTalkersRequestDescriptor =
    $convert.base64Decode(
        'ChhMaXN0QWN0aXZlVGFsa2Vyc1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbk'
        'lkEhQKBXRva2VuGAIgASgJUgV0b2tlbg==');

@$core.Deprecated('Use listActiveTalkersResponseDescriptor instead')
const ListActiveTalkersResponse$json = {
  '1': 'ListActiveTalkersResponse',
  '2': [
    {
      '1': 'talkers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.ActiveTalker',
      '10': 'talkers'
    },
  ],
};

/// Descriptor for `ListActiveTalkersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listActiveTalkersResponseDescriptor =
    $convert.base64Decode(
        'ChlMaXN0QWN0aXZlVGFsa2Vyc1Jlc3BvbnNlEjQKB3RhbGtlcnMYASADKAsyGi5zdGFnZXN5bm'
        'MudjEuQWN0aXZlVGFsa2VyUgd0YWxrZXJz');
