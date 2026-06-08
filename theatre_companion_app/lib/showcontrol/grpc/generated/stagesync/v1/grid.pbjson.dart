// This is a generated file - do not edit.
//
// Generated from stagesync/v1/grid.proto.

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

@$core.Deprecated('Use launchModeDescriptor instead')
const LaunchMode$json = {
  '1': 'LaunchMode',
  '2': [
    {'1': 'LAUNCH_TRIGGER', '2': 0},
    {'1': 'LAUNCH_GATE', '2': 1},
    {'1': 'LAUNCH_TOGGLE', '2': 2},
  ],
};

/// Descriptor for `LaunchMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List launchModeDescriptor = $convert.base64Decode(
    'CgpMYXVuY2hNb2RlEhIKDkxBVU5DSF9UUklHR0VSEAASDwoLTEFVTkNIX0dBVEUQARIRCg1MQV'
    'VOQ0hfVE9HR0xFEAI=');

@$core.Deprecated('Use followActionDescriptor instead')
const FollowAction$json = {
  '1': 'FollowAction',
  '2': [
    {'1': 'FOLLOW_NONE', '2': 0},
    {'1': 'FOLLOW_NEXT_CLIP', '2': 1},
    {'1': 'FOLLOW_NEXT_SCENE', '2': 2},
    {'1': 'FOLLOW_STOP', '2': 3},
  ],
};

/// Descriptor for `FollowAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List followActionDescriptor = $convert.base64Decode(
    'CgxGb2xsb3dBY3Rpb24SDwoLRk9MTE9XX05PTkUQABIUChBGT0xMT1dfTkVYVF9DTElQEAESFQ'
    'oRRk9MTE9XX05FWFRfU0NFTkUQAhIPCgtGT0xMT1dfU1RPUBAD');

@$core.Deprecated('Use gridQuantizeDescriptor instead')
const GridQuantize$json = {
  '1': 'GridQuantize',
  '2': [
    {'1': 'QUANTIZE_OFF', '2': 0},
    {'1': 'QUANTIZE_ON', '2': 1},
  ],
};

/// Descriptor for `GridQuantize`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gridQuantizeDescriptor = $convert.base64Decode(
    'CgxHcmlkUXVhbnRpemUSEAoMUVVBTlRJWkVfT0ZGEAASDwoLUVVBTlRJWkVfT04QAQ==');

@$core.Deprecated('Use gridDescriptor instead')
const Grid$json = {
  '1': 'Grid',
  '2': [
    {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'tracks',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.GridTrack',
      '10': 'tracks'
    },
    {
      '1': 'scenes',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.GridScene',
      '10': 'scenes'
    },
    {
      '1': 'clips',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.GridClip',
      '10': 'clips'
    },
    {
      '1': 'quantize',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.GridQuantize',
      '10': 'quantize'
    },
    {'1': 'version', '3': 7, '4': 1, '5': 3, '10': 'version'},
  ],
};

/// Descriptor for `Grid`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridDescriptor = $convert.base64Decode(
    'CgRHcmlkEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBISCgRuYW1lGAIgASgJUgRuYW1lEi8KBn'
    'RyYWNrcxgDIAMoCzIXLnN0YWdlc3luYy52MS5HcmlkVHJhY2tSBnRyYWNrcxIvCgZzY2VuZXMY'
    'BCADKAsyFy5zdGFnZXN5bmMudjEuR3JpZFNjZW5lUgZzY2VuZXMSLAoFY2xpcHMYBSADKAsyFi'
    '5zdGFnZXN5bmMudjEuR3JpZENsaXBSBWNsaXBzEjYKCHF1YW50aXplGAYgASgOMhouc3RhZ2Vz'
    'eW5jLnYxLkdyaWRRdWFudGl6ZVIIcXVhbnRpemUSGAoHdmVyc2lvbhgHIAEoA1IHdmVyc2lvbg'
    '==');

@$core.Deprecated('Use gridTrackDescriptor instead')
const GridTrack$json = {
  '1': 'GridTrack',
  '2': [
    {'1': 'track_id', '3': 1, '4': 1, '5': 9, '10': 'trackId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'color_hex', '3': 3, '4': 1, '5': 9, '10': 'colorHex'},
    {
      '1': 'bus_sends',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.BusSend',
      '10': 'busSends'
    },
    {'1': 'exclusive', '3': 5, '4': 1, '5': 8, '10': 'exclusive'},
  ],
};

/// Descriptor for `GridTrack`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridTrackDescriptor = $convert.base64Decode(
    'CglHcmlkVHJhY2sSGQoIdHJhY2tfaWQYASABKAlSB3RyYWNrSWQSEgoEbmFtZRgCIAEoCVIEbm'
    'FtZRIbCgljb2xvcl9oZXgYAyABKAlSCGNvbG9ySGV4EjIKCWJ1c19zZW5kcxgEIAMoCzIVLnN0'
    'YWdlc3luYy52MS5CdXNTZW5kUghidXNTZW5kcxIcCglleGNsdXNpdmUYBSABKAhSCWV4Y2x1c2'
    'l2ZQ==');

@$core.Deprecated('Use gridSceneDescriptor instead')
const GridScene$json = {
  '1': 'GridScene',
  '2': [
    {'1': 'scene_id', '3': 1, '4': 1, '5': 9, '10': 'sceneId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'color_hex', '3': 3, '4': 1, '5': 9, '10': 'colorHex'},
  ],
};

/// Descriptor for `GridScene`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridSceneDescriptor = $convert.base64Decode(
    'CglHcmlkU2NlbmUSGQoIc2NlbmVfaWQYASABKAlSB3NjZW5lSWQSEgoEbmFtZRgCIAEoCVIEbm'
    'FtZRIbCgljb2xvcl9oZXgYAyABKAlSCGNvbG9ySGV4');

@$core.Deprecated('Use gridClipDescriptor instead')
const GridClip$json = {
  '1': 'GridClip',
  '2': [
    {'1': 'clip_id', '3': 1, '4': 1, '5': 9, '10': 'clipId'},
    {'1': 'track_index', '3': 2, '4': 1, '5': 5, '10': 'trackIndex'},
    {'1': 'scene_index', '3': 3, '4': 1, '5': 5, '10': 'sceneIndex'},
    {'1': 'label', '3': 4, '4': 1, '5': 9, '10': 'label'},
    {'1': 'color_hex', '3': 5, '4': 1, '5': 9, '10': 'colorHex'},
    {
      '1': 'launch_mode',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.LaunchMode',
      '10': 'launchMode'
    },
    {
      '1': 'follow',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.FollowAction',
      '10': 'follow'
    },
    {
      '1': 'audio',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioClipPayload',
      '9': 0,
      '10': 'audio'
    },
    {
      '1': 'osc',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.OscClipPayload',
      '9': 0,
      '10': 'osc'
    },
    {
      '1': 'midi',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.MidiClipPayload',
      '9': 0,
      '10': 'midi'
    },
    {
      '1': 'cue_ref',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.CueRefPayload',
      '9': 0,
      '10': 'cueRef'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `GridClip`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridClipDescriptor = $convert.base64Decode(
    'CghHcmlkQ2xpcBIXCgdjbGlwX2lkGAEgASgJUgZjbGlwSWQSHwoLdHJhY2tfaW5kZXgYAiABKA'
    'VSCnRyYWNrSW5kZXgSHwoLc2NlbmVfaW5kZXgYAyABKAVSCnNjZW5lSW5kZXgSFAoFbGFiZWwY'
    'BCABKAlSBWxhYmVsEhsKCWNvbG9yX2hleBgFIAEoCVIIY29sb3JIZXgSOQoLbGF1bmNoX21vZG'
    'UYBiABKA4yGC5zdGFnZXN5bmMudjEuTGF1bmNoTW9kZVIKbGF1bmNoTW9kZRIyCgZmb2xsb3cY'
    'ByABKA4yGi5zdGFnZXN5bmMudjEuRm9sbG93QWN0aW9uUgZmb2xsb3cSNgoFYXVkaW8YCiABKA'
    'syHi5zdGFnZXN5bmMudjEuQXVkaW9DbGlwUGF5bG9hZEgAUgVhdWRpbxIwCgNvc2MYCyABKAsy'
    'HC5zdGFnZXN5bmMudjEuT3NjQ2xpcFBheWxvYWRIAFIDb3NjEjMKBG1pZGkYDCABKAsyHS5zdG'
    'FnZXN5bmMudjEuTWlkaUNsaXBQYXlsb2FkSABSBG1pZGkSNgoHY3VlX3JlZhgNIAEoCzIbLnN0'
    'YWdlc3luYy52MS5DdWVSZWZQYXlsb2FkSABSBmN1ZVJlZkIJCgdwYXlsb2Fk');

@$core.Deprecated('Use audioClipPayloadDescriptor instead')
const AudioClipPayload$json = {
  '1': 'AudioClipPayload',
  '2': [
    {'1': 'asset_id', '3': 1, '4': 1, '5': 9, '10': 'assetId'},
    {'1': 'volume_db', '3': 2, '4': 1, '5': 1, '10': 'volumeDb'},
    {'1': 'fade_in_ms', '3': 3, '4': 1, '5': 1, '10': 'fadeInMs'},
    {'1': 'fade_out_ms', '3': 4, '4': 1, '5': 1, '10': 'fadeOutMs'},
    {'1': 'loop', '3': 5, '4': 1, '5': 8, '10': 'loop'},
    {'1': 'start_time_ms', '3': 6, '4': 1, '5': 1, '10': 'startTimeMs'},
    {'1': 'end_time_ms', '3': 7, '4': 1, '5': 1, '10': 'endTimeMs'},
    {
      '1': 'declared_duration_ms',
      '3': 8,
      '4': 1,
      '5': 1,
      '10': 'declaredDurationMs'
    },
  ],
};

/// Descriptor for `AudioClipPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioClipPayloadDescriptor = $convert.base64Decode(
    'ChBBdWRpb0NsaXBQYXlsb2FkEhkKCGFzc2V0X2lkGAEgASgJUgdhc3NldElkEhsKCXZvbHVtZV'
    '9kYhgCIAEoAVIIdm9sdW1lRGISHAoKZmFkZV9pbl9tcxgDIAEoAVIIZmFkZUluTXMSHgoLZmFk'
    'ZV9vdXRfbXMYBCABKAFSCWZhZGVPdXRNcxISCgRsb29wGAUgASgIUgRsb29wEiIKDXN0YXJ0X3'
    'RpbWVfbXMYBiABKAFSC3N0YXJ0VGltZU1zEh4KC2VuZF90aW1lX21zGAcgASgBUgllbmRUaW1l'
    'TXMSMAoUZGVjbGFyZWRfZHVyYXRpb25fbXMYCCABKAFSEmRlY2xhcmVkRHVyYXRpb25Ncw==');

@$core.Deprecated('Use oscClipPayloadDescriptor instead')
const OscClipPayload$json = {
  '1': 'OscClipPayload',
  '2': [
    {'1': 'address', '3': 1, '4': 1, '5': 9, '10': 'address'},
    {'1': 'args', '3': 2, '4': 3, '5': 9, '10': 'args'},
    {'1': 'target_node_id', '3': 3, '4': 1, '5': 9, '10': 'targetNodeId'},
  ],
};

/// Descriptor for `OscClipPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List oscClipPayloadDescriptor = $convert.base64Decode(
    'Cg5Pc2NDbGlwUGF5bG9hZBIYCgdhZGRyZXNzGAEgASgJUgdhZGRyZXNzEhIKBGFyZ3MYAiADKA'
    'lSBGFyZ3MSJAoOdGFyZ2V0X25vZGVfaWQYAyABKAlSDHRhcmdldE5vZGVJZA==');

@$core.Deprecated('Use midiClipPayloadDescriptor instead')
const MidiClipPayload$json = {
  '1': 'MidiClipPayload',
  '2': [
    {'1': 'channel', '3': 1, '4': 1, '5': 5, '10': 'channel'},
    {'1': 'command', '3': 2, '4': 1, '5': 5, '10': 'command'},
    {'1': 'data1', '3': 3, '4': 1, '5': 5, '10': 'data1'},
    {'1': 'data2', '3': 4, '4': 1, '5': 5, '10': 'data2'},
  ],
};

/// Descriptor for `MidiClipPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List midiClipPayloadDescriptor = $convert.base64Decode(
    'Cg9NaWRpQ2xpcFBheWxvYWQSGAoHY2hhbm5lbBgBIAEoBVIHY2hhbm5lbBIYCgdjb21tYW5kGA'
    'IgASgFUgdjb21tYW5kEhQKBWRhdGExGAMgASgFUgVkYXRhMRIUCgVkYXRhMhgEIAEoBVIFZGF0'
    'YTI=');

@$core.Deprecated('Use cueRefPayloadDescriptor instead')
const CueRefPayload$json = {
  '1': 'CueRefPayload',
  '2': [
    {'1': 'cue_list_id', '3': 1, '4': 1, '5': 9, '10': 'cueListId'},
    {'1': 'cue_id', '3': 2, '4': 1, '5': 9, '10': 'cueId'},
  ],
};

/// Descriptor for `CueRefPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cueRefPayloadDescriptor = $convert.base64Decode(
    'Cg1DdWVSZWZQYXlsb2FkEh4KC2N1ZV9saXN0X2lkGAEgASgJUgljdWVMaXN0SWQSFQoGY3VlX2'
    'lkGAIgASgJUgVjdWVJZA==');

@$core.Deprecated('Use getGridRequestDescriptor instead')
const GetGridRequest$json = {
  '1': 'GetGridRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'grid_id', '3': 3, '4': 1, '5': 9, '10': 'gridId'},
  ],
};

/// Descriptor for `GetGridRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGridRequestDescriptor = $convert.base64Decode(
    'Cg5HZXRHcmlkUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG9rZW'
    '4YAiABKAlSBXRva2VuEhcKB2dyaWRfaWQYAyABKAlSBmdyaWRJZA==');

@$core.Deprecated('Use gridResponseDescriptor instead')
const GridResponse$json = {
  '1': 'GridResponse',
  '2': [
    {
      '1': 'grid',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Grid',
      '10': 'grid'
    },
  ],
};

/// Descriptor for `GridResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridResponseDescriptor = $convert.base64Decode(
    'CgxHcmlkUmVzcG9uc2USJgoEZ3JpZBgBIAEoCzISLnN0YWdlc3luYy52MS5HcmlkUgRncmlk');

@$core.Deprecated('Use updateGridRequestDescriptor instead')
const UpdateGridRequest$json = {
  '1': 'UpdateGridRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'grid',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Grid',
      '10': 'grid'
    },
  ],
};

/// Descriptor for `UpdateGridRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateGridRequestDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVHcmlkUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG'
    '9rZW4YAiABKAlSBXRva2VuEiYKBGdyaWQYAyABKAsyEi5zdGFnZXN5bmMudjEuR3JpZFIEZ3Jp'
    'ZA==');

@$core.Deprecated('Use upsertClipRequestDescriptor instead')
const UpsertClipRequest$json = {
  '1': 'UpsertClipRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'grid_id', '3': 3, '4': 1, '5': 9, '10': 'gridId'},
    {
      '1': 'clip',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.GridClip',
      '10': 'clip'
    },
  ],
};

/// Descriptor for `UpsertClipRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List upsertClipRequestDescriptor = $convert.base64Decode(
    'ChFVcHNlcnRDbGlwUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG'
    '9rZW4YAiABKAlSBXRva2VuEhcKB2dyaWRfaWQYAyABKAlSBmdyaWRJZBIqCgRjbGlwGAQgASgL'
    'MhYuc3RhZ2VzeW5jLnYxLkdyaWRDbGlwUgRjbGlw');

@$core.Deprecated('Use clipResponseDescriptor instead')
const ClipResponse$json = {
  '1': 'ClipResponse',
  '2': [
    {
      '1': 'clip',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.GridClip',
      '10': 'clip'
    },
  ],
};

/// Descriptor for `ClipResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clipResponseDescriptor = $convert.base64Decode(
    'CgxDbGlwUmVzcG9uc2USKgoEY2xpcBgBIAEoCzIWLnN0YWdlc3luYy52MS5HcmlkQ2xpcFIEY2'
    'xpcA==');

@$core.Deprecated('Use deleteClipRequestDescriptor instead')
const DeleteClipRequest$json = {
  '1': 'DeleteClipRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'grid_id', '3': 3, '4': 1, '5': 9, '10': 'gridId'},
    {'1': 'clip_id', '3': 4, '4': 1, '5': 9, '10': 'clipId'},
  ],
};

/// Descriptor for `DeleteClipRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteClipRequestDescriptor = $convert.base64Decode(
    'ChFEZWxldGVDbGlwUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG'
    '9rZW4YAiABKAlSBXRva2VuEhcKB2dyaWRfaWQYAyABKAlSBmdyaWRJZBIXCgdjbGlwX2lkGAQg'
    'ASgJUgZjbGlwSWQ=');

@$core.Deprecated('Use launchClipRequestDescriptor instead')
const LaunchClipRequest$json = {
  '1': 'LaunchClipRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'grid_id', '3': 3, '4': 1, '5': 9, '10': 'gridId'},
    {'1': 'track_index', '3': 4, '4': 1, '5': 5, '10': 'trackIndex'},
    {'1': 'scene_index', '3': 5, '4': 1, '5': 5, '10': 'sceneIndex'},
    {'1': 'command_id', '3': 6, '4': 1, '5': 9, '10': 'commandId'},
    {'1': 'released', '3': 7, '4': 1, '5': 8, '10': 'released'},
  ],
};

/// Descriptor for `LaunchClipRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List launchClipRequestDescriptor = $convert.base64Decode(
    'ChFMYXVuY2hDbGlwUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG'
    '9rZW4YAiABKAlSBXRva2VuEhcKB2dyaWRfaWQYAyABKAlSBmdyaWRJZBIfCgt0cmFja19pbmRl'
    'eBgEIAEoBVIKdHJhY2tJbmRleBIfCgtzY2VuZV9pbmRleBgFIAEoBVIKc2NlbmVJbmRleBIdCg'
    'pjb21tYW5kX2lkGAYgASgJUgljb21tYW5kSWQSGgoIcmVsZWFzZWQYByABKAhSCHJlbGVhc2Vk');

@$core.Deprecated('Use launchSceneRequestDescriptor instead')
const LaunchSceneRequest$json = {
  '1': 'LaunchSceneRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'grid_id', '3': 3, '4': 1, '5': 9, '10': 'gridId'},
    {'1': 'scene_index', '3': 4, '4': 1, '5': 5, '10': 'sceneIndex'},
    {'1': 'command_id', '3': 5, '4': 1, '5': 9, '10': 'commandId'},
  ],
};

/// Descriptor for `LaunchSceneRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List launchSceneRequestDescriptor = $convert.base64Decode(
    'ChJMYXVuY2hTY2VuZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhQKBX'
    'Rva2VuGAIgASgJUgV0b2tlbhIXCgdncmlkX2lkGAMgASgJUgZncmlkSWQSHwoLc2NlbmVfaW5k'
    'ZXgYBCABKAVSCnNjZW5lSW5kZXgSHQoKY29tbWFuZF9pZBgFIAEoCVIJY29tbWFuZElk');

@$core.Deprecated('Use stopTrackRequestDescriptor instead')
const StopTrackRequest$json = {
  '1': 'StopTrackRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'grid_id', '3': 3, '4': 1, '5': 9, '10': 'gridId'},
    {'1': 'track_index', '3': 4, '4': 1, '5': 5, '10': 'trackIndex'},
    {'1': 'command_id', '3': 5, '4': 1, '5': 9, '10': 'commandId'},
  ],
};

/// Descriptor for `StopTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopTrackRequestDescriptor = $convert.base64Decode(
    'ChBTdG9wVHJhY2tSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIUCgV0b2'
    'tlbhgCIAEoCVIFdG9rZW4SFwoHZ3JpZF9pZBgDIAEoCVIGZ3JpZElkEh8KC3RyYWNrX2luZGV4'
    'GAQgASgFUgp0cmFja0luZGV4Eh0KCmNvbW1hbmRfaWQYBSABKAlSCWNvbW1hbmRJZA==');

@$core.Deprecated('Use stopAllRequestDescriptor instead')
const StopAllRequest$json = {
  '1': 'StopAllRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'grid_id', '3': 3, '4': 1, '5': 9, '10': 'gridId'},
    {'1': 'command_id', '3': 4, '4': 1, '5': 9, '10': 'commandId'},
  ],
};

/// Descriptor for `StopAllRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopAllRequestDescriptor = $convert.base64Decode(
    'Cg5TdG9wQWxsUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG9rZW'
    '4YAiABKAlSBXRva2VuEhcKB2dyaWRfaWQYAyABKAlSBmdyaWRJZBIdCgpjb21tYW5kX2lkGAQg'
    'ASgJUgljb21tYW5kSWQ=');

@$core.Deprecated('Use watchGridExecRequestDescriptor instead')
const WatchGridExecRequest$json = {
  '1': 'WatchGridExecRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
    {'1': 'grid_id', '3': 4, '4': 1, '5': 9, '10': 'gridId'},
  ],
};

/// Descriptor for `WatchGridExecRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchGridExecRequestDescriptor = $convert.base64Decode(
    'ChRXYXRjaEdyaWRFeGVjUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFw'
    'oHbm9kZV9pZBgCIAEoCVIGbm9kZUlkEhQKBXRva2VuGAMgASgJUgV0b2tlbhIXCgdncmlkX2lk'
    'GAQgASgJUgZncmlkSWQ=');

@$core.Deprecated('Use gridExecutionEventDescriptor instead')
const GridExecutionEvent$json = {
  '1': 'GridExecutionEvent',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.GridExecutionEvent.Type',
      '10': 'type'
    },
    {
      '1': 'occurred_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Timestamp',
      '10': 'occurredAt'
    },
    {'1': 'clip_id', '3': 10, '4': 1, '5': 9, '10': 'clipId'},
    {'1': 'track_index', '3': 11, '4': 1, '5': 5, '10': 'trackIndex'},
    {'1': 'scene_index', '3': 12, '4': 1, '5': 5, '10': 'sceneIndex'},
    {'1': 'started_at_ms', '3': 13, '4': 1, '5': 3, '10': 'startedAtMs'},
    {'1': 'clip_length_ms', '3': 14, '4': 1, '5': 1, '10': 'clipLengthMs'},
    {'1': 'error_msg', '3': 15, '4': 1, '5': 9, '10': 'errorMsg'},
    {'1': 'running_clip_ids', '3': 16, '4': 3, '5': 9, '10': 'runningClipIds'},
  ],
  '4': [GridExecutionEvent_Type$json],
};

@$core.Deprecated('Use gridExecutionEventDescriptor instead')
const GridExecutionEvent_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'GRID_SNAPSHOT', '2': 0},
    {'1': 'CLIP_LAUNCHED', '2': 1},
    {'1': 'CLIP_PLAYING', '2': 2},
    {'1': 'CLIP_STOPPED', '2': 3},
    {'1': 'CLIP_DONE', '2': 4},
    {'1': 'CLIP_ERROR', '2': 5},
  ],
};

/// Descriptor for `GridExecutionEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridExecutionEventDescriptor = $convert.base64Decode(
    'ChJHcmlkRXhlY3V0aW9uRXZlbnQSEAoDc2VxGAEgASgDUgNzZXESOQoEdHlwZRgCIAEoDjIlLn'
    'N0YWdlc3luYy52MS5HcmlkRXhlY3V0aW9uRXZlbnQuVHlwZVIEdHlwZRI4CgtvY2N1cnJlZF9h'
    'dBgDIAEoCzIXLnN0YWdlc3luYy52MS5UaW1lc3RhbXBSCm9jY3VycmVkQXQSFwoHY2xpcF9pZB'
    'gKIAEoCVIGY2xpcElkEh8KC3RyYWNrX2luZGV4GAsgASgFUgp0cmFja0luZGV4Eh8KC3NjZW5l'
    'X2luZGV4GAwgASgFUgpzY2VuZUluZGV4EiIKDXN0YXJ0ZWRfYXRfbXMYDSABKANSC3N0YXJ0ZW'
    'RBdE1zEiQKDmNsaXBfbGVuZ3RoX21zGA4gASgBUgxjbGlwTGVuZ3RoTXMSGwoJZXJyb3JfbXNn'
    'GA8gASgJUghlcnJvck1zZxIoChBydW5uaW5nX2NsaXBfaWRzGBAgAygJUg5ydW5uaW5nQ2xpcE'
    'lkcyJvCgRUeXBlEhEKDUdSSURfU05BUFNIT1QQABIRCg1DTElQX0xBVU5DSEVEEAESEAoMQ0xJ'
    'UF9QTEFZSU5HEAISEAoMQ0xJUF9TVE9QUEVEEAMSDQoJQ0xJUF9ET05FEAQSDgoKQ0xJUF9FUl'
    'JPUhAF');

@$core.Deprecated('Use waveformRequestDescriptor instead')
const WaveformRequest$json = {
  '1': 'WaveformRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'asset_id', '3': 3, '4': 1, '5': 9, '10': 'assetId'},
    {'1': 'buckets', '3': 4, '4': 1, '5': 5, '10': 'buckets'},
  ],
};

/// Descriptor for `WaveformRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List waveformRequestDescriptor = $convert.base64Decode(
    'Cg9XYXZlZm9ybVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhQKBXRva2'
    'VuGAIgASgJUgV0b2tlbhIZCghhc3NldF9pZBgDIAEoCVIHYXNzZXRJZBIYCgdidWNrZXRzGAQg'
    'ASgFUgdidWNrZXRz');

@$core.Deprecated('Use waveformChunkDescriptor instead')
const WaveformChunk$json = {
  '1': 'WaveformChunk',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    {'1': 'total_buckets', '3': 2, '4': 1, '5': 5, '10': 'totalBuckets'},
    {'1': 'channels', '3': 3, '4': 1, '5': 13, '10': 'channels'},
    {'1': 'sample_rate', '3': 4, '4': 1, '5': 13, '10': 'sampleRate'},
    {'1': 'duration_ms', '3': 5, '4': 1, '5': 1, '10': 'durationMs'},
  ],
};

/// Descriptor for `WaveformChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List waveformChunkDescriptor = $convert.base64Decode(
    'Cg1XYXZlZm9ybUNodW5rEhIKBGRhdGEYASABKAxSBGRhdGESIwoNdG90YWxfYnVja2V0cxgCIA'
    'EoBVIMdG90YWxCdWNrZXRzEhoKCGNoYW5uZWxzGAMgASgNUghjaGFubmVscxIfCgtzYW1wbGVf'
    'cmF0ZRgEIAEoDVIKc2FtcGxlUmF0ZRIfCgtkdXJhdGlvbl9tcxgFIAEoAVIKZHVyYXRpb25Ncw'
    '==');
