// This is a generated file - do not edit.
//
// Generated from stagesync/v1/showcontrol.proto.

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

@$core.Deprecated('Use cueDescriptor instead')
const Cue$json = {
  '1': 'Cue',
  '2': [
    {'1': 'cue_id', '3': 1, '4': 1, '5': 9, '10': 'cueId'},
    {'1': 'number', '3': 2, '4': 1, '5': 9, '10': 'number'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {
      '1': 'cue_type',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.CueType',
      '10': 'cueType'
    },
    {
      '1': 'state',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.CueState',
      '10': 'state'
    },
    {'1': 'target_node_id', '3': 6, '4': 1, '5': 9, '10': 'targetNodeId'},
    {'1': 'auto_continue', '3': 7, '4': 1, '5': 8, '10': 'autoContinue'},
    {'1': 'pre_wait_ms', '3': 8, '4': 1, '5': 1, '10': 'preWaitMs'},
    {'1': 'post_wait_ms', '3': 9, '4': 1, '5': 1, '10': 'postWaitMs'},
    {
      '1': 'audio',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioCueParams',
      '9': 0,
      '10': 'audio'
    },
    {
      '1': 'ma_osc',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.MaOscCueParams',
      '9': 0,
      '10': 'maOsc'
    },
    {
      '1': 'wait',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.WaitCueParams',
      '9': 0,
      '10': 'wait'
    },
    {
      '1': 'goto_p',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.GotoCueParams',
      '9': 0,
      '10': 'gotoP'
    },
    {
      '1': 'created_at',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Timestamp',
      '10': 'updatedAt'
    },
    {'1': 'version', '3': 16, '4': 1, '5': 3, '10': 'version'},
  ],
  '8': [
    {'1': 'params'},
  ],
};

/// Descriptor for `Cue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cueDescriptor = $convert.base64Decode(
    'CgNDdWUSFQoGY3VlX2lkGAEgASgJUgVjdWVJZBIWCgZudW1iZXIYAiABKAlSBm51bWJlchIUCg'
    'VsYWJlbBgDIAEoCVIFbGFiZWwSMAoIY3VlX3R5cGUYBCABKA4yFS5zdGFnZXN5bmMudjEuQ3Vl'
    'VHlwZVIHY3VlVHlwZRIsCgVzdGF0ZRgFIAEoDjIWLnN0YWdlc3luYy52MS5DdWVTdGF0ZVIFc3'
    'RhdGUSJAoOdGFyZ2V0X25vZGVfaWQYBiABKAlSDHRhcmdldE5vZGVJZBIjCg1hdXRvX2NvbnRp'
    'bnVlGAcgASgIUgxhdXRvQ29udGludWUSHgoLcHJlX3dhaXRfbXMYCCABKAFSCXByZVdhaXRNcx'
    'IgCgxwb3N0X3dhaXRfbXMYCSABKAFSCnBvc3RXYWl0TXMSNAoFYXVkaW8YCiABKAsyHC5zdGFn'
    'ZXN5bmMudjEuQXVkaW9DdWVQYXJhbXNIAFIFYXVkaW8SNQoGbWFfb3NjGAsgASgLMhwuc3RhZ2'
    'VzeW5jLnYxLk1hT3NjQ3VlUGFyYW1zSABSBW1hT3NjEjEKBHdhaXQYDCABKAsyGy5zdGFnZXN5'
    'bmMudjEuV2FpdEN1ZVBhcmFtc0gAUgR3YWl0EjQKBmdvdG9fcBgNIAEoCzIbLnN0YWdlc3luYy'
    '52MS5Hb3RvQ3VlUGFyYW1zSABSBWdvdG9QEjYKCmNyZWF0ZWRfYXQYDiABKAsyFy5zdGFnZXN5'
    'bmMudjEuVGltZXN0YW1wUgljcmVhdGVkQXQSNgoKdXBkYXRlZF9hdBgPIAEoCzIXLnN0YWdlc3'
    'luYy52MS5UaW1lc3RhbXBSCXVwZGF0ZWRBdBIYCgd2ZXJzaW9uGBAgASgDUgd2ZXJzaW9uQggK'
    'BnBhcmFtcw==');

@$core.Deprecated('Use audioCueParamsDescriptor instead')
const AudioCueParams$json = {
  '1': 'AudioCueParams',
  '2': [
    {'1': 'file_path', '3': 1, '4': 1, '5': 9, '10': 'filePath'},
    {'1': 'volume_db', '3': 2, '4': 1, '5': 1, '10': 'volumeDb'},
    {'1': 'fade_in_ms', '3': 3, '4': 1, '5': 1, '10': 'fadeInMs'},
    {'1': 'fade_out_ms', '3': 4, '4': 1, '5': 1, '10': 'fadeOutMs'},
    {'1': 'loop', '3': 5, '4': 1, '5': 8, '10': 'loop'},
    {'1': 'start_time_ms', '3': 6, '4': 1, '5': 1, '10': 'startTimeMs'},
    {'1': 'end_time_ms', '3': 7, '4': 1, '5': 1, '10': 'endTimeMs'},
    {'1': 'output_device', '3': 8, '4': 1, '5': 9, '10': 'outputDevice'},
  ],
};

/// Descriptor for `AudioCueParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioCueParamsDescriptor = $convert.base64Decode(
    'Cg5BdWRpb0N1ZVBhcmFtcxIbCglmaWxlX3BhdGgYASABKAlSCGZpbGVQYXRoEhsKCXZvbHVtZV'
    '9kYhgCIAEoAVIIdm9sdW1lRGISHAoKZmFkZV9pbl9tcxgDIAEoAVIIZmFkZUluTXMSHgoLZmFk'
    'ZV9vdXRfbXMYBCABKAFSCWZhZGVPdXRNcxISCgRsb29wGAUgASgIUgRsb29wEiIKDXN0YXJ0X3'
    'RpbWVfbXMYBiABKAFSC3N0YXJ0VGltZU1zEh4KC2VuZF90aW1lX21zGAcgASgBUgllbmRUaW1l'
    'TXMSIwoNb3V0cHV0X2RldmljZRgIIAEoCVIMb3V0cHV0RGV2aWNl');

@$core.Deprecated('Use maOscCueParamsDescriptor instead')
const MaOscCueParams$json = {
  '1': 'MaOscCueParams',
  '2': [
    {'1': 'osc_address', '3': 1, '4': 1, '5': 9, '10': 'oscAddress'},
    {'1': 'osc_argument', '3': 2, '4': 1, '5': 9, '10': 'oscArgument'},
    {'1': 'executor_page', '3': 3, '4': 1, '5': 5, '10': 'executorPage'},
    {'1': 'executor_no', '3': 4, '4': 1, '5': 5, '10': 'executorNo'},
    {
      '1': 'command',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.MaOscCueParams.MaCommand',
      '10': 'command'
    },
    {'1': 'goto_cue', '3': 6, '4': 1, '5': 5, '10': 'gotoCue'},
  ],
  '4': [MaOscCueParams_MaCommand$json],
};

@$core.Deprecated('Use maOscCueParamsDescriptor instead')
const MaOscCueParams_MaCommand$json = {
  '1': 'MaCommand',
  '2': [
    {'1': 'MA_CMD_UNSPECIFIED', '2': 0},
    {'1': 'MA_CMD_GO', '2': 1},
    {'1': 'MA_CMD_OFF', '2': 2},
    {'1': 'MA_CMD_PAUSE', '2': 3},
    {'1': 'MA_CMD_GOTO', '2': 4},
  ],
};

/// Descriptor for `MaOscCueParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List maOscCueParamsDescriptor = $convert.base64Decode(
    'Cg5NYU9zY0N1ZVBhcmFtcxIfCgtvc2NfYWRkcmVzcxgBIAEoCVIKb3NjQWRkcmVzcxIhCgxvc2'
    'NfYXJndW1lbnQYAiABKAlSC29zY0FyZ3VtZW50EiMKDWV4ZWN1dG9yX3BhZ2UYAyABKAVSDGV4'
    'ZWN1dG9yUGFnZRIfCgtleGVjdXRvcl9ubxgEIAEoBVIKZXhlY3V0b3JObxJACgdjb21tYW5kGA'
    'UgASgOMiYuc3RhZ2VzeW5jLnYxLk1hT3NjQ3VlUGFyYW1zLk1hQ29tbWFuZFIHY29tbWFuZBIZ'
    'Cghnb3RvX2N1ZRgGIAEoBVIHZ290b0N1ZSJlCglNYUNvbW1hbmQSFgoSTUFfQ01EX1VOU1BFQ0'
    'lGSUVEEAASDQoJTUFfQ01EX0dPEAESDgoKTUFfQ01EX09GRhACEhAKDE1BX0NNRF9QQVVTRRAD'
    'Eg8KC01BX0NNRF9HT1RPEAQ=');

@$core.Deprecated('Use waitCueParamsDescriptor instead')
const WaitCueParams$json = {
  '1': 'WaitCueParams',
  '2': [
    {'1': 'duration_ms', '3': 1, '4': 1, '5': 1, '10': 'durationMs'},
  ],
};

/// Descriptor for `WaitCueParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List waitCueParamsDescriptor = $convert.base64Decode(
    'Cg1XYWl0Q3VlUGFyYW1zEh8KC2R1cmF0aW9uX21zGAEgASgBUgpkdXJhdGlvbk1z');

@$core.Deprecated('Use gotoCueParamsDescriptor instead')
const GotoCueParams$json = {
  '1': 'GotoCueParams',
  '2': [
    {'1': 'target_cue_id', '3': 1, '4': 1, '5': 9, '10': 'targetCueId'},
    {'1': 'target_number', '3': 2, '4': 1, '5': 9, '10': 'targetNumber'},
  ],
};

/// Descriptor for `GotoCueParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gotoCueParamsDescriptor = $convert.base64Decode(
    'Cg1Hb3RvQ3VlUGFyYW1zEiIKDXRhcmdldF9jdWVfaWQYASABKAlSC3RhcmdldEN1ZUlkEiMKDX'
    'RhcmdldF9udW1iZXIYAiABKAlSDHRhcmdldE51bWJlcg==');

@$core.Deprecated('Use cueListDescriptor instead')
const CueList$json = {
  '1': 'CueList',
  '2': [
    {'1': 'cue_list_id', '3': 1, '4': 1, '5': 9, '10': 'cueListId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'cues',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.Cue',
      '10': 'cues'
    },
    {'1': 'active_cue_id', '3': 4, '4': 1, '5': 9, '10': 'activeCueId'},
    {'1': 'next_cue_id', '3': 5, '4': 1, '5': 9, '10': 'nextCueId'},
    {'1': 'version', '3': 6, '4': 1, '5': 3, '10': 'version'},
    {
      '1': 'updated_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Timestamp',
      '10': 'updatedAt'
    },
  ],
};

/// Descriptor for `CueList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cueListDescriptor = $convert.base64Decode(
    'CgdDdWVMaXN0Eh4KC2N1ZV9saXN0X2lkGAEgASgJUgljdWVMaXN0SWQSEgoEbmFtZRgCIAEoCV'
    'IEbmFtZRIlCgRjdWVzGAMgAygLMhEuc3RhZ2VzeW5jLnYxLkN1ZVIEY3VlcxIiCg1hY3RpdmVf'
    'Y3VlX2lkGAQgASgJUgthY3RpdmVDdWVJZBIeCgtuZXh0X2N1ZV9pZBgFIAEoCVIJbmV4dEN1ZU'
    'lkEhgKB3ZlcnNpb24YBiABKANSB3ZlcnNpb24SNgoKdXBkYXRlZF9hdBgHIAEoCzIXLnN0YWdl'
    'c3luYy52MS5UaW1lc3RhbXBSCXVwZGF0ZWRBdA==');

@$core.Deprecated('Use getCueListRequestDescriptor instead')
const GetCueListRequest$json = {
  '1': 'GetCueListRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'cue_list_id', '3': 3, '4': 1, '5': 9, '10': 'cueListId'},
  ],
};

/// Descriptor for `GetCueListRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCueListRequestDescriptor = $convert.base64Decode(
    'ChFHZXRDdWVMaXN0UmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG'
    '9rZW4YAiABKAlSBXRva2VuEh4KC2N1ZV9saXN0X2lkGAMgASgJUgljdWVMaXN0SWQ=');

@$core.Deprecated('Use updateCueListRequestDescriptor instead')
const UpdateCueListRequest$json = {
  '1': 'UpdateCueListRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'cue_list',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.CueList',
      '10': 'cueList'
    },
  ],
};

/// Descriptor for `UpdateCueListRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateCueListRequestDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVDdWVMaXN0UmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFA'
    'oFdG9rZW4YAiABKAlSBXRva2VuEjAKCGN1ZV9saXN0GAMgASgLMhUuc3RhZ2VzeW5jLnYxLkN1'
    'ZUxpc3RSB2N1ZUxpc3Q=');

@$core.Deprecated('Use cueListResponseDescriptor instead')
const CueListResponse$json = {
  '1': 'CueListResponse',
  '2': [
    {
      '1': 'cue_list',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.CueList',
      '10': 'cueList'
    },
  ],
};

/// Descriptor for `CueListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cueListResponseDescriptor = $convert.base64Decode(
    'Cg9DdWVMaXN0UmVzcG9uc2USMAoIY3VlX2xpc3QYASABKAsyFS5zdGFnZXN5bmMudjEuQ3VlTG'
    'lzdFIHY3VlTGlzdA==');

@$core.Deprecated('Use upsertCueRequestDescriptor instead')
const UpsertCueRequest$json = {
  '1': 'UpsertCueRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'cue_list_id', '3': 3, '4': 1, '5': 9, '10': 'cueListId'},
    {
      '1': 'cue',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Cue',
      '10': 'cue'
    },
  ],
};

/// Descriptor for `UpsertCueRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List upsertCueRequestDescriptor = $convert.base64Decode(
    'ChBVcHNlcnRDdWVSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIUCgV0b2'
    'tlbhgCIAEoCVIFdG9rZW4SHgoLY3VlX2xpc3RfaWQYAyABKAlSCWN1ZUxpc3RJZBIjCgNjdWUY'
    'BCABKAsyES5zdGFnZXN5bmMudjEuQ3VlUgNjdWU=');

@$core.Deprecated('Use cueResponseDescriptor instead')
const CueResponse$json = {
  '1': 'CueResponse',
  '2': [
    {
      '1': 'cue',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Cue',
      '10': 'cue'
    },
  ],
};

/// Descriptor for `CueResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cueResponseDescriptor = $convert.base64Decode(
    'CgtDdWVSZXNwb25zZRIjCgNjdWUYASABKAsyES5zdGFnZXN5bmMudjEuQ3VlUgNjdWU=');

@$core.Deprecated('Use deleteCueRequestDescriptor instead')
const DeleteCueRequest$json = {
  '1': 'DeleteCueRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'cue_list_id', '3': 3, '4': 1, '5': 9, '10': 'cueListId'},
    {'1': 'cue_id', '3': 4, '4': 1, '5': 9, '10': 'cueId'},
  ],
};

/// Descriptor for `DeleteCueRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteCueRequestDescriptor = $convert.base64Decode(
    'ChBEZWxldGVDdWVSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIUCgV0b2'
    'tlbhgCIAEoCVIFdG9rZW4SHgoLY3VlX2xpc3RfaWQYAyABKAlSCWN1ZUxpc3RJZBIVCgZjdWVf'
    'aWQYBCABKAlSBWN1ZUlk');

@$core.Deprecated('Use goRequestDescriptor instead')
const GoRequest$json = {
  '1': 'GoRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'cue_id', '3': 3, '4': 1, '5': 9, '10': 'cueId'},
    {'1': 'command_id', '3': 4, '4': 1, '5': 9, '10': 'commandId'},
  ],
};

/// Descriptor for `GoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List goRequestDescriptor = $convert.base64Decode(
    'CglHb1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhQKBXRva2VuGAIgAS'
    'gJUgV0b2tlbhIVCgZjdWVfaWQYAyABKAlSBWN1ZUlkEh0KCmNvbW1hbmRfaWQYBCABKAlSCWNv'
    'bW1hbmRJZA==');

@$core.Deprecated('Use goResponseDescriptor instead')
const GoResponse$json = {
  '1': 'GoResponse',
  '2': [
    {
      '1': 'executing_cue',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Cue',
      '10': 'executingCue'
    },
    {
      '1': 'next_cue',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Cue',
      '10': 'nextCue'
    },
  ],
};

/// Descriptor for `GoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List goResponseDescriptor = $convert.base64Decode(
    'CgpHb1Jlc3BvbnNlEjYKDWV4ZWN1dGluZ19jdWUYASABKAsyES5zdGFnZXN5bmMudjEuQ3VlUg'
    'xleGVjdXRpbmdDdWUSLAoIbmV4dF9jdWUYAiABKAsyES5zdGFnZXN5bmMudjEuQ3VlUgduZXh0'
    'Q3Vl');

@$core.Deprecated('Use stopRequestDescriptor instead')
const StopRequest$json = {
  '1': 'StopRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'command_id', '3': 3, '4': 1, '5': 9, '10': 'commandId'},
  ],
};

/// Descriptor for `StopRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopRequestDescriptor = $convert.base64Decode(
    'CgtTdG9wUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG9rZW4YAi'
    'ABKAlSBXRva2VuEh0KCmNvbW1hbmRfaWQYAyABKAlSCWNvbW1hbmRJZA==');

@$core.Deprecated('Use pauseRequestDescriptor instead')
const PauseRequest$json = {
  '1': 'PauseRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'command_id', '3': 3, '4': 1, '5': 9, '10': 'commandId'},
  ],
};

/// Descriptor for `PauseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pauseRequestDescriptor = $convert.base64Decode(
    'CgxQYXVzZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhQKBXRva2VuGA'
    'IgASgJUgV0b2tlbhIdCgpjb21tYW5kX2lkGAMgASgJUgljb21tYW5kSWQ=');

@$core.Deprecated('Use resumeRequestDescriptor instead')
const ResumeRequest$json = {
  '1': 'ResumeRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'command_id', '3': 3, '4': 1, '5': 9, '10': 'commandId'},
  ],
};

/// Descriptor for `ResumeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resumeRequestDescriptor = $convert.base64Decode(
    'Cg1SZXN1bWVSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIUCgV0b2tlbh'
    'gCIAEoCVIFdG9rZW4SHQoKY29tbWFuZF9pZBgDIAEoCVIJY29tbWFuZElk');

@$core.Deprecated('Use watchShowStateRequestDescriptor instead')
const WatchShowStateRequest$json = {
  '1': 'WatchShowStateRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `WatchShowStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchShowStateRequestDescriptor = $convert.base64Decode(
    'ChVXYXRjaFNob3dTdGF0ZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh'
    'cKB25vZGVfaWQYAiABKAlSBm5vZGVJZBIUCgV0b2tlbhgDIAEoCVIFdG9rZW4=');

@$core.Deprecated('Use showStateEventDescriptor instead')
const ShowStateEvent$json = {
  '1': 'ShowStateEvent',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.ShowStateEvent.Type',
      '10': 'type'
    },
    {
      '1': 'cue_list',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.CueList',
      '10': 'cueList'
    },
    {
      '1': 'affected_cue',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Cue',
      '10': 'affectedCue'
    },
    {'1': 'node_id', '3': 4, '4': 1, '5': 9, '10': 'nodeId'},
    {
      '1': 'occurred_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Timestamp',
      '10': 'occurredAt'
    },
    {'1': 'error_msg', '3': 6, '4': 1, '5': 9, '10': 'errorMsg'},
    {'1': 'seq', '3': 7, '4': 1, '5': 3, '10': 'seq'},
    {'1': 'is_paused', '3': 8, '4': 1, '5': 8, '10': 'isPaused'},
    {'1': 'cue_started_at_ms', '3': 9, '4': 1, '5': 3, '10': 'cueStartedAtMs'},
  ],
  '4': [ShowStateEvent_Type$json],
};

@$core.Deprecated('Use showStateEventDescriptor instead')
const ShowStateEvent_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'TYPE_UNSPECIFIED', '2': 0},
    {'1': 'TYPE_CUE_STARTED', '2': 1},
    {'1': 'TYPE_CUE_STOPPED', '2': 2},
    {'1': 'TYPE_CUE_PAUSED', '2': 3},
    {'1': 'TYPE_CUE_DONE', '2': 4},
    {'1': 'TYPE_CUE_ERROR', '2': 5},
    {'1': 'TYPE_LIST_UPDATED', '2': 6},
    {'1': 'TYPE_POSITION_CHANGED', '2': 7},
  ],
};

/// Descriptor for `ShowStateEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List showStateEventDescriptor = $convert.base64Decode(
    'Cg5TaG93U3RhdGVFdmVudBI1CgR0eXBlGAEgASgOMiEuc3RhZ2VzeW5jLnYxLlNob3dTdGF0ZU'
    'V2ZW50LlR5cGVSBHR5cGUSMAoIY3VlX2xpc3QYAiABKAsyFS5zdGFnZXN5bmMudjEuQ3VlTGlz'
    'dFIHY3VlTGlzdBI0CgxhZmZlY3RlZF9jdWUYAyABKAsyES5zdGFnZXN5bmMudjEuQ3VlUgthZm'
    'ZlY3RlZEN1ZRIXCgdub2RlX2lkGAQgASgJUgZub2RlSWQSOAoLb2NjdXJyZWRfYXQYBSABKAsy'
    'Fy5zdGFnZXN5bmMudjEuVGltZXN0YW1wUgpvY2N1cnJlZEF0EhsKCWVycm9yX21zZxgGIAEoCV'
    'IIZXJyb3JNc2cSEAoDc2VxGAcgASgDUgNzZXESGwoJaXNfcGF1c2VkGAggASgIUghpc1BhdXNl'
    'ZBIpChFjdWVfc3RhcnRlZF9hdF9tcxgJIAEoA1IOY3VlU3RhcnRlZEF0TXMitgEKBFR5cGUSFA'
    'oQVFlQRV9VTlNQRUNJRklFRBAAEhQKEFRZUEVfQ1VFX1NUQVJURUQQARIUChBUWVBFX0NVRV9T'
    'VE9QUEVEEAISEwoPVFlQRV9DVUVfUEFVU0VEEAMSEQoNVFlQRV9DVUVfRE9ORRAEEhIKDlRZUE'
    'VfQ1VFX0VSUk9SEAUSFQoRVFlQRV9MSVNUX1VQREFURUQQBhIZChVUWVBFX1BPU0lUSU9OX0NI'
    'QU5HRUQQBw==');
