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
    {
      '1': 'logical_output_id',
      '3': 18,
      '4': 1,
      '5': 9,
      '10': 'logicalOutputId'
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
      '1': 'group',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.GroupCueParams',
      '9': 0,
      '10': 'group'
    },
    {
      '1': 'note',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NoteCueParams',
      '9': 0,
      '10': 'note'
    },
    {
      '1': 'fade',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.FadeCueParams',
      '9': 0,
      '10': 'fade'
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
    'RhdGUSKgoRbG9naWNhbF9vdXRwdXRfaWQYEiABKAlSD2xvZ2ljYWxPdXRwdXRJZBIkCg50YXJn'
    'ZXRfbm9kZV9pZBgGIAEoCVIMdGFyZ2V0Tm9kZUlkEiMKDWF1dG9fY29udGludWUYByABKAhSDG'
    'F1dG9Db250aW51ZRIeCgtwcmVfd2FpdF9tcxgIIAEoAVIJcHJlV2FpdE1zEiAKDHBvc3Rfd2Fp'
    'dF9tcxgJIAEoAVIKcG9zdFdhaXRNcxI0CgVhdWRpbxgKIAEoCzIcLnN0YWdlc3luYy52MS5BdW'
    'Rpb0N1ZVBhcmFtc0gAUgVhdWRpbxI1CgZtYV9vc2MYCyABKAsyHC5zdGFnZXN5bmMudjEuTWFP'
    'c2NDdWVQYXJhbXNIAFIFbWFPc2MSMQoEd2FpdBgMIAEoCzIbLnN0YWdlc3luYy52MS5XYWl0Q3'
    'VlUGFyYW1zSABSBHdhaXQSNAoGZ290b19wGA0gASgLMhsuc3RhZ2VzeW5jLnYxLkdvdG9DdWVQ'
    'YXJhbXNIAFIFZ290b1ASNAoFZ3JvdXAYESABKAsyHC5zdGFnZXN5bmMudjEuR3JvdXBDdWVQYX'
    'JhbXNIAFIFZ3JvdXASMQoEbm90ZRgTIAEoCzIbLnN0YWdlc3luYy52MS5Ob3RlQ3VlUGFyYW1z'
    'SABSBG5vdGUSMQoEZmFkZRgUIAEoCzIbLnN0YWdlc3luYy52MS5GYWRlQ3VlUGFyYW1zSABSBG'
    'ZhZGUSNgoKY3JlYXRlZF9hdBgOIAEoCzIXLnN0YWdlc3luYy52MS5UaW1lc3RhbXBSCWNyZWF0'
    'ZWRBdBI2Cgp1cGRhdGVkX2F0GA8gASgLMhcuc3RhZ2VzeW5jLnYxLlRpbWVzdGFtcFIJdXBkYX'
    'RlZEF0EhgKB3ZlcnNpb24YECABKANSB3ZlcnNpb25CCAoGcGFyYW1z');

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
    {'1': 'asset_id', '3': 9, '4': 1, '5': 9, '10': 'assetId'},
    {
      '1': 'declared_duration_ms',
      '3': 10,
      '4': 1,
      '5': 1,
      '10': 'declaredDurationMs'
    },
    {
      '1': 'pause_behavior',
      '3': 11,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.AudioCueParams.PauseBehavior',
      '10': 'pauseBehavior'
    },
    {'1': 'pause_fade_ms', '3': 12, '4': 1, '5': 1, '10': 'pauseFadeMs'},
    {
      '1': 'resume_behavior',
      '3': 13,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.AudioCueParams.ResumeBehavior',
      '10': 'resumeBehavior'
    },
    {'1': 'resume_fade_ms', '3': 14, '4': 1, '5': 1, '10': 'resumeFadeMs'},
  ],
  '4': [AudioCueParams_PauseBehavior$json, AudioCueParams_ResumeBehavior$json],
};

@$core.Deprecated('Use audioCueParamsDescriptor instead')
const AudioCueParams_PauseBehavior$json = {
  '1': 'PauseBehavior',
  '2': [
    {'1': 'PAUSE_HARD', '2': 0},
    {'1': 'PAUSE_FADE_OUT', '2': 1},
  ],
};

@$core.Deprecated('Use audioCueParamsDescriptor instead')
const AudioCueParams_ResumeBehavior$json = {
  '1': 'ResumeBehavior',
  '2': [
    {'1': 'RESUME_CONTINUE', '2': 0},
    {'1': 'RESUME_FADE_IN', '2': 1},
    {'1': 'RESUME_FROM_START', '2': 2},
  ],
};

/// Descriptor for `AudioCueParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioCueParamsDescriptor = $convert.base64Decode(
    'Cg5BdWRpb0N1ZVBhcmFtcxIbCglmaWxlX3BhdGgYASABKAlSCGZpbGVQYXRoEhsKCXZvbHVtZV'
    '9kYhgCIAEoAVIIdm9sdW1lRGISHAoKZmFkZV9pbl9tcxgDIAEoAVIIZmFkZUluTXMSHgoLZmFk'
    'ZV9vdXRfbXMYBCABKAFSCWZhZGVPdXRNcxISCgRsb29wGAUgASgIUgRsb29wEiIKDXN0YXJ0X3'
    'RpbWVfbXMYBiABKAFSC3N0YXJ0VGltZU1zEh4KC2VuZF90aW1lX21zGAcgASgBUgllbmRUaW1l'
    'TXMSIwoNb3V0cHV0X2RldmljZRgIIAEoCVIMb3V0cHV0RGV2aWNlEhkKCGFzc2V0X2lkGAkgAS'
    'gJUgdhc3NldElkEjAKFGRlY2xhcmVkX2R1cmF0aW9uX21zGAogASgBUhJkZWNsYXJlZER1cmF0'
    'aW9uTXMSUQoOcGF1c2VfYmVoYXZpb3IYCyABKA4yKi5zdGFnZXN5bmMudjEuQXVkaW9DdWVQYX'
    'JhbXMuUGF1c2VCZWhhdmlvclINcGF1c2VCZWhhdmlvchIiCg1wYXVzZV9mYWRlX21zGAwgASgB'
    'UgtwYXVzZUZhZGVNcxJUCg9yZXN1bWVfYmVoYXZpb3IYDSABKA4yKy5zdGFnZXN5bmMudjEuQX'
    'VkaW9DdWVQYXJhbXMuUmVzdW1lQmVoYXZpb3JSDnJlc3VtZUJlaGF2aW9yEiQKDnJlc3VtZV9m'
    'YWRlX21zGA4gASgBUgxyZXN1bWVGYWRlTXMiMwoNUGF1c2VCZWhhdmlvchIOCgpQQVVTRV9IQV'
    'JEEAASEgoOUEFVU0VfRkFERV9PVVQQASJQCg5SZXN1bWVCZWhhdmlvchITCg9SRVNVTUVfQ09O'
    'VElOVUUQABISCg5SRVNVTUVfRkFERV9JThABEhUKEVJFU1VNRV9GUk9NX1NUQVJUEAI=');

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

@$core.Deprecated('Use groupCueParamsDescriptor instead')
const GroupCueParams$json = {
  '1': 'GroupCueParams',
  '2': [
    {'1': 'child_cue_ids', '3': 1, '4': 3, '5': 9, '10': 'childCueIds'},
    {'1': 'sequential', '3': 2, '4': 1, '5': 8, '10': 'sequential'},
  ],
};

/// Descriptor for `GroupCueParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupCueParamsDescriptor = $convert.base64Decode(
    'Cg5Hcm91cEN1ZVBhcmFtcxIiCg1jaGlsZF9jdWVfaWRzGAEgAygJUgtjaGlsZEN1ZUlkcxIeCg'
    'pzZXF1ZW50aWFsGAIgASgIUgpzZXF1ZW50aWFs');

@$core.Deprecated('Use noteCueParamsDescriptor instead')
const NoteCueParams$json = {
  '1': 'NoteCueParams',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'color_hex', '3': 2, '4': 1, '5': 9, '10': 'colorHex'},
  ],
};

/// Descriptor for `NoteCueParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List noteCueParamsDescriptor = $convert.base64Decode(
    'Cg1Ob3RlQ3VlUGFyYW1zEhIKBHRleHQYASABKAlSBHRleHQSGwoJY29sb3JfaGV4GAIgASgJUg'
    'hjb2xvckhleA==');

@$core.Deprecated('Use fadeCueParamsDescriptor instead')
const FadeCueParams$json = {
  '1': 'FadeCueParams',
  '2': [
    {'1': 'target_cue_id', '3': 1, '4': 1, '5': 9, '10': 'targetCueId'},
    {'1': 'target_cue_number', '3': 2, '4': 1, '5': 9, '10': 'targetCueNumber'},
    {
      '1': 'action',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.FadeCueParams.FadeAction',
      '10': 'action'
    },
    {'1': 'target_volume_db', '3': 4, '4': 1, '5': 1, '10': 'targetVolumeDb'},
    {'1': 'duration_ms', '3': 5, '4': 1, '5': 1, '10': 'durationMs'},
    {'1': 'stop_when_done', '3': 6, '4': 1, '5': 8, '10': 'stopWhenDone'},
  ],
  '4': [FadeCueParams_FadeAction$json],
};

@$core.Deprecated('Use fadeCueParamsDescriptor instead')
const FadeCueParams_FadeAction$json = {
  '1': 'FadeAction',
  '2': [
    {'1': 'FADE_ACTION_VOLUME', '2': 0},
    {'1': 'FADE_ACTION_STOP', '2': 1},
    {'1': 'FADE_ACTION_PAUSE', '2': 2},
    {'1': 'FADE_ACTION_RESUME', '2': 3},
  ],
};

/// Descriptor for `FadeCueParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fadeCueParamsDescriptor = $convert.base64Decode(
    'Cg1GYWRlQ3VlUGFyYW1zEiIKDXRhcmdldF9jdWVfaWQYASABKAlSC3RhcmdldEN1ZUlkEioKEX'
    'RhcmdldF9jdWVfbnVtYmVyGAIgASgJUg90YXJnZXRDdWVOdW1iZXISPgoGYWN0aW9uGAMgASgO'
    'MiYuc3RhZ2VzeW5jLnYxLkZhZGVDdWVQYXJhbXMuRmFkZUFjdGlvblIGYWN0aW9uEigKEHRhcm'
    'dldF92b2x1bWVfZGIYBCABKAFSDnRhcmdldFZvbHVtZURiEh8KC2R1cmF0aW9uX21zGAUgASgB'
    'UgpkdXJhdGlvbk1zEiQKDnN0b3Bfd2hlbl9kb25lGAYgASgIUgxzdG9wV2hlbkRvbmUiaQoKRm'
    'FkZUFjdGlvbhIWChJGQURFX0FDVElPTl9WT0xVTUUQABIUChBGQURFX0FDVElPTl9TVE9QEAES'
    'FQoRRkFERV9BQ1RJT05fUEFVU0UQAhIWChJGQURFX0FDVElPTl9SRVNVTUUQAw==');

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

@$core.Deprecated('Use updatePatchConfigRequestDescriptor instead')
const UpdatePatchConfigRequest$json = {
  '1': 'UpdatePatchConfigRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'patch_config',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.PatchConfig',
      '10': 'patchConfig'
    },
  ],
};

/// Descriptor for `UpdatePatchConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePatchConfigRequestDescriptor = $convert.base64Decode(
    'ChhVcGRhdGVQYXRjaENvbmZpZ1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbk'
    'lkEhQKBXRva2VuGAIgASgJUgV0b2tlbhI8CgxwYXRjaF9jb25maWcYAyABKAsyGS5zdGFnZXN5'
    'bmMudjEuUGF0Y2hDb25maWdSC3BhdGNoQ29uZmln');

@$core.Deprecated('Use patchConfigResponseDescriptor instead')
const PatchConfigResponse$json = {
  '1': 'PatchConfigResponse',
  '2': [
    {
      '1': 'patch_config',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.PatchConfig',
      '10': 'patchConfig'
    },
  ],
};

/// Descriptor for `PatchConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List patchConfigResponseDescriptor = $convert.base64Decode(
    'ChNQYXRjaENvbmZpZ1Jlc3BvbnNlEjwKDHBhdGNoX2NvbmZpZxgBIAEoCzIZLnN0YWdlc3luYy'
    '52MS5QYXRjaENvbmZpZ1ILcGF0Y2hDb25maWc=');

@$core.Deprecated('Use watchShowDefinitionRequestDescriptor instead')
const WatchShowDefinitionRequest$json = {
  '1': 'WatchShowDefinitionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `WatchShowDefinitionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchShowDefinitionRequestDescriptor =
    $convert.base64Decode(
        'ChpXYXRjaFNob3dEZWZpbml0aW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW'
        '9uSWQSFwoHbm9kZV9pZBgCIAEoCVIGbm9kZUlkEhQKBXRva2VuGAMgASgJUgV0b2tlbg==');

@$core.Deprecated('Use showDefinitionEventDescriptor instead')
const ShowDefinitionEvent$json = {
  '1': 'ShowDefinitionEvent',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.ShowDefinitionEvent.DefinitionEventType',
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
    {
      '1': 'cue_list',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.CueList',
      '10': 'cueList'
    },
    {
      '1': 'patch_config',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.PatchConfig',
      '10': 'patchConfig'
    },
  ],
  '4': [ShowDefinitionEvent_DefinitionEventType$json],
};

@$core.Deprecated('Use showDefinitionEventDescriptor instead')
const ShowDefinitionEvent_DefinitionEventType$json = {
  '1': 'DefinitionEventType',
  '2': [
    {'1': 'DEFINITION_SNAPSHOT', '2': 0},
    {'1': 'CUE_LIST_CHANGED', '2': 1},
    {'1': 'PATCH_CONFIG_CHANGED', '2': 2},
  ],
};

/// Descriptor for `ShowDefinitionEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List showDefinitionEventDescriptor = $convert.base64Decode(
    'ChNTaG93RGVmaW5pdGlvbkV2ZW50EhAKA3NlcRgBIAEoA1IDc2VxEkkKBHR5cGUYAiABKA4yNS'
    '5zdGFnZXN5bmMudjEuU2hvd0RlZmluaXRpb25FdmVudC5EZWZpbml0aW9uRXZlbnRUeXBlUgR0'
    'eXBlEjgKC29jY3VycmVkX2F0GAMgASgLMhcuc3RhZ2VzeW5jLnYxLlRpbWVzdGFtcFIKb2NjdX'
    'JyZWRBdBIwCghjdWVfbGlzdBgKIAEoCzIVLnN0YWdlc3luYy52MS5DdWVMaXN0UgdjdWVMaXN0'
    'EjwKDHBhdGNoX2NvbmZpZxgLIAEoCzIZLnN0YWdlc3luYy52MS5QYXRjaENvbmZpZ1ILcGF0Y2'
    'hDb25maWciXgoTRGVmaW5pdGlvbkV2ZW50VHlwZRIXChNERUZJTklUSU9OX1NOQVBTSE9UEAAS'
    'FAoQQ1VFX0xJU1RfQ0hBTkdFRBABEhgKFFBBVENIX0NPTkZJR19DSEFOR0VEEAI=');

@$core.Deprecated('Use patchConfigDescriptor instead')
const PatchConfig$json = {
  '1': 'PatchConfig',
  '2': [
    {
      '1': 'logical_outputs',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.PatchLogicalOutput',
      '10': 'logicalOutputs'
    },
    {
      '1': 'node_assigns',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.PatchNodeAssign',
      '10': 'nodeAssigns'
    },
    {
      '1': 'device_assigns',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.PatchDeviceAssign',
      '10': 'deviceAssigns'
    },
  ],
};

/// Descriptor for `PatchConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List patchConfigDescriptor = $convert.base64Decode(
    'CgtQYXRjaENvbmZpZxJJCg9sb2dpY2FsX291dHB1dHMYASADKAsyIC5zdGFnZXN5bmMudjEuUG'
    'F0Y2hMb2dpY2FsT3V0cHV0Ug5sb2dpY2FsT3V0cHV0cxJACgxub2RlX2Fzc2lnbnMYAiADKAsy'
    'HS5zdGFnZXN5bmMudjEuUGF0Y2hOb2RlQXNzaWduUgtub2RlQXNzaWducxJGCg5kZXZpY2VfYX'
    'NzaWducxgDIAMoCzIfLnN0YWdlc3luYy52MS5QYXRjaERldmljZUFzc2lnblINZGV2aWNlQXNz'
    'aWducw==');

@$core.Deprecated('Use patchLogicalOutputDescriptor instead')
const PatchLogicalOutput$json = {
  '1': 'PatchLogicalOutput',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `PatchLogicalOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List patchLogicalOutputDescriptor = $convert.base64Decode(
    'ChJQYXRjaExvZ2ljYWxPdXRwdXQSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbW'
    'U=');

@$core.Deprecated('Use patchNodeAssignDescriptor instead')
const PatchNodeAssign$json = {
  '1': 'PatchNodeAssign',
  '2': [
    {'1': 'logical_output_id', '3': 1, '4': 1, '5': 9, '10': 'logicalOutputId'},
    {'1': 'node_ids', '3': 2, '4': 3, '5': 9, '10': 'nodeIds'},
  ],
};

/// Descriptor for `PatchNodeAssign`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List patchNodeAssignDescriptor = $convert.base64Decode(
    'Cg9QYXRjaE5vZGVBc3NpZ24SKgoRbG9naWNhbF9vdXRwdXRfaWQYASABKAlSD2xvZ2ljYWxPdX'
    'RwdXRJZBIZCghub2RlX2lkcxgCIAMoCVIHbm9kZUlkcw==');

@$core.Deprecated('Use patchDeviceAssignDescriptor instead')
const PatchDeviceAssign$json = {
  '1': 'PatchDeviceAssign',
  '2': [
    {'1': 'logical_output_id', '3': 1, '4': 1, '5': 9, '10': 'logicalOutputId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'device_index', '3': 3, '4': 1, '5': 5, '10': 'deviceIndex'},
    {'1': 'device_name', '3': 4, '4': 1, '5': 9, '10': 'deviceName'},
  ],
};

/// Descriptor for `PatchDeviceAssign`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List patchDeviceAssignDescriptor = $convert.base64Decode(
    'ChFQYXRjaERldmljZUFzc2lnbhIqChFsb2dpY2FsX291dHB1dF9pZBgBIAEoCVIPbG9naWNhbE'
    '91dHB1dElkEhcKB25vZGVfaWQYAiABKAlSBm5vZGVJZBIhCgxkZXZpY2VfaW5kZXgYAyABKAVS'
    'C2RldmljZUluZGV4Eh8KC2RldmljZV9uYW1lGAQgASgJUgpkZXZpY2VOYW1l');

@$core.Deprecated('Use watchShowExecutionRequestDescriptor instead')
const WatchShowExecutionRequest$json = {
  '1': 'WatchShowExecutionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `WatchShowExecutionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchShowExecutionRequestDescriptor =
    $convert.base64Decode(
        'ChlXYXRjaFNob3dFeGVjdXRpb25SZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb2'
        '5JZBIXCgdub2RlX2lkGAIgASgJUgZub2RlSWQSFAoFdG9rZW4YAyABKAlSBXRva2Vu');

@$core.Deprecated('Use showExecutionEventDescriptor instead')
const ShowExecutionEvent$json = {
  '1': 'ShowExecutionEvent',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.ShowExecutionEvent.ExecutionEventType',
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
    {
      '1': 'affected_cue',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Cue',
      '10': 'affectedCue'
    },
    {'1': 'node_id', '3': 11, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'error_msg', '3': 12, '4': 1, '5': 9, '10': 'errorMsg'},
    {'1': 'cue_started_at_ms', '3': 13, '4': 1, '5': 3, '10': 'cueStartedAtMs'},
    {'1': 'is_paused', '3': 14, '4': 1, '5': 8, '10': 'isPaused'},
    {'1': 'running_cue_ids', '3': 15, '4': 3, '5': 9, '10': 'runningCueIds'},
  ],
  '4': [ShowExecutionEvent_ExecutionEventType$json],
};

@$core.Deprecated('Use showExecutionEventDescriptor instead')
const ShowExecutionEvent_ExecutionEventType$json = {
  '1': 'ExecutionEventType',
  '2': [
    {'1': 'EXECUTION_SNAPSHOT', '2': 0},
    {'1': 'CUE_STARTED', '2': 1},
    {'1': 'CUE_PAUSED', '2': 2},
    {'1': 'CUE_RESUMED', '2': 3},
    {'1': 'CUE_STOPPED', '2': 4},
    {'1': 'CUE_DONE', '2': 5},
    {'1': 'CUE_ERROR', '2': 6},
  ],
};

/// Descriptor for `ShowExecutionEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List showExecutionEventDescriptor = $convert.base64Decode(
    'ChJTaG93RXhlY3V0aW9uRXZlbnQSEAoDc2VxGAEgASgDUgNzZXESRwoEdHlwZRgCIAEoDjIzLn'
    'N0YWdlc3luYy52MS5TaG93RXhlY3V0aW9uRXZlbnQuRXhlY3V0aW9uRXZlbnRUeXBlUgR0eXBl'
    'EjgKC29jY3VycmVkX2F0GAMgASgLMhcuc3RhZ2VzeW5jLnYxLlRpbWVzdGFtcFIKb2NjdXJyZW'
    'RBdBI0CgxhZmZlY3RlZF9jdWUYCiABKAsyES5zdGFnZXN5bmMudjEuQ3VlUgthZmZlY3RlZEN1'
    'ZRIXCgdub2RlX2lkGAsgASgJUgZub2RlSWQSGwoJZXJyb3JfbXNnGAwgASgJUghlcnJvck1zZx'
    'IpChFjdWVfc3RhcnRlZF9hdF9tcxgNIAEoA1IOY3VlU3RhcnRlZEF0TXMSGwoJaXNfcGF1c2Vk'
    'GA4gASgIUghpc1BhdXNlZBImCg9ydW5uaW5nX2N1ZV9pZHMYDyADKAlSDXJ1bm5pbmdDdWVJZH'
    'MijAEKEkV4ZWN1dGlvbkV2ZW50VHlwZRIWChJFWEVDVVRJT05fU05BUFNIT1QQABIPCgtDVUVf'
    'U1RBUlRFRBABEg4KCkNVRV9QQVVTRUQQAhIPCgtDVUVfUkVTVU1FRBADEg8KC0NVRV9TVE9QUE'
    'VEEAQSDAoIQ1VFX0RPTkUQBRINCglDVUVfRVJST1IQBg==');

@$core.Deprecated('Use watchNodeHealthRequestDescriptor instead')
const WatchNodeHealthRequest$json = {
  '1': 'WatchNodeHealthRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `WatchNodeHealthRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchNodeHealthRequestDescriptor =
    $convert.base64Decode(
        'ChZXYXRjaE5vZGVIZWFsdGhSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZB'
        'IXCgdub2RlX2lkGAIgASgJUgZub2RlSWQSFAoFdG9rZW4YAyABKAlSBXRva2Vu');

@$core.Deprecated('Use nodeHealthEventDescriptor instead')
const NodeHealthEvent$json = {
  '1': 'NodeHealthEvent',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.NodeHealthEvent.HealthEventType',
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
    {
      '1': 'node',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeInfo',
      '10': 'node'
    },
    {'1': 'clock_delta_ms', '3': 11, '4': 1, '5': 3, '10': 'clockDeltaMs'},
    {
      '1': 'capabilities',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeCapabilities',
      '10': 'capabilities'
    },
  ],
  '4': [NodeHealthEvent_HealthEventType$json],
};

@$core.Deprecated('Use nodeHealthEventDescriptor instead')
const NodeHealthEvent_HealthEventType$json = {
  '1': 'HealthEventType',
  '2': [
    {'1': 'HEALTH_SNAPSHOT', '2': 0},
    {'1': 'NODE_ONLINE', '2': 1},
    {'1': 'NODE_OFFLINE', '2': 2},
    {'1': 'NODE_DEGRADED', '2': 3},
    {'1': 'CLOCK_DELTA', '2': 4},
  ],
};

/// Descriptor for `NodeHealthEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeHealthEventDescriptor = $convert.base64Decode(
    'Cg9Ob2RlSGVhbHRoRXZlbnQSEAoDc2VxGAEgASgDUgNzZXESQQoEdHlwZRgCIAEoDjItLnN0YW'
    'dlc3luYy52MS5Ob2RlSGVhbHRoRXZlbnQuSGVhbHRoRXZlbnRUeXBlUgR0eXBlEjgKC29jY3Vy'
    'cmVkX2F0GAMgASgLMhcuc3RhZ2VzeW5jLnYxLlRpbWVzdGFtcFIKb2NjdXJyZWRBdBIqCgRub2'
    'RlGAogASgLMhYuc3RhZ2VzeW5jLnYxLk5vZGVJbmZvUgRub2RlEiQKDmNsb2NrX2RlbHRhX21z'
    'GAsgASgDUgxjbG9ja0RlbHRhTXMSQgoMY2FwYWJpbGl0aWVzGAwgASgLMh4uc3RhZ2VzeW5jLn'
    'YxLk5vZGVDYXBhYmlsaXRpZXNSDGNhcGFiaWxpdGllcyJtCg9IZWFsdGhFdmVudFR5cGUSEwoP'
    'SEVBTFRIX1NOQVBTSE9UEAASDwoLTk9ERV9PTkxJTkUQARIQCgxOT0RFX09GRkxJTkUQAhIRCg'
    '1OT0RFX0RFR1JBREVEEAMSDwoLQ0xPQ0tfREVMVEEQBA==');

@$core.Deprecated('Use watchMediaSyncRequestDescriptor instead')
const WatchMediaSyncRequest$json = {
  '1': 'WatchMediaSyncRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
    {'1': 'show_id', '3': 4, '4': 1, '5': 9, '10': 'showId'},
  ],
};

/// Descriptor for `WatchMediaSyncRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchMediaSyncRequestDescriptor = $convert.base64Decode(
    'ChVXYXRjaE1lZGlhU3luY1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh'
    'cKB25vZGVfaWQYAiABKAlSBm5vZGVJZBIUCgV0b2tlbhgDIAEoCVIFdG9rZW4SFwoHc2hvd19p'
    'ZBgEIAEoCVIGc2hvd0lk');

@$core.Deprecated('Use mediaSyncEventDescriptor instead')
const MediaSyncEvent$json = {
  '1': 'MediaSyncEvent',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.MediaSyncEvent.MediaEventType',
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
    {'1': 'asset_id', '3': 10, '4': 1, '5': 9, '10': 'assetId'},
    {'1': 'asset_name', '3': 11, '4': 1, '5': 9, '10': 'assetName'},
    {'1': 'sha256', '3': 12, '4': 1, '5': 9, '10': 'sha256'},
    {'1': 'size_bytes', '3': 13, '4': 1, '5': 3, '10': 'sizeBytes'},
  ],
  '4': [MediaSyncEvent_MediaEventType$json],
};

@$core.Deprecated('Use mediaSyncEventDescriptor instead')
const MediaSyncEvent_MediaEventType$json = {
  '1': 'MediaEventType',
  '2': [
    {'1': 'MEDIA_SNAPSHOT', '2': 0},
    {'1': 'ASSET_ADDED', '2': 1},
    {'1': 'ASSET_REMOVED', '2': 2},
    {'1': 'ASSET_UPDATED', '2': 3},
  ],
};

/// Descriptor for `MediaSyncEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaSyncEventDescriptor = $convert.base64Decode(
    'Cg5NZWRpYVN5bmNFdmVudBIQCgNzZXEYASABKANSA3NlcRI/CgR0eXBlGAIgASgOMisuc3RhZ2'
    'VzeW5jLnYxLk1lZGlhU3luY0V2ZW50Lk1lZGlhRXZlbnRUeXBlUgR0eXBlEjgKC29jY3VycmVk'
    'X2F0GAMgASgLMhcuc3RhZ2VzeW5jLnYxLlRpbWVzdGFtcFIKb2NjdXJyZWRBdBIZCghhc3NldF'
    '9pZBgKIAEoCVIHYXNzZXRJZBIdCgphc3NldF9uYW1lGAsgASgJUglhc3NldE5hbWUSFgoGc2hh'
    'MjU2GAwgASgJUgZzaGEyNTYSHQoKc2l6ZV9ieXRlcxgNIAEoA1IJc2l6ZUJ5dGVzIlsKDk1lZG'
    'lhRXZlbnRUeXBlEhIKDk1FRElBX1NOQVBTSE9UEAASDwoLQVNTRVRfQURERUQQARIRCg1BU1NF'
    'VF9SRU1PVkVEEAISEQoNQVNTRVRfVVBEQVRFRBAD');
