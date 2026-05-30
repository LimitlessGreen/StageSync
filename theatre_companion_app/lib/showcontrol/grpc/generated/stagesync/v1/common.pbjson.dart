// This is a generated file - do not edit.
//
// Generated from stagesync/v1/common.proto.

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

@$core.Deprecated('Use nodeTypeDescriptor instead')
const NodeType$json = {
  '1': 'NodeType',
  '2': [
    {'1': 'NODE_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'NODE_TYPE_MASTER', '2': 1},
    {'1': 'NODE_TYPE_AUDIO', '2': 2},
    {'1': 'NODE_TYPE_VIEWER', '2': 3},
    {'1': 'NODE_TYPE_MA', '2': 4},
    {'1': 'NODE_TYPE_LIGHTING', '2': 5},
  ],
};

/// Descriptor for `NodeType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeTypeDescriptor = $convert.base64Decode(
    'CghOb2RlVHlwZRIZChVOT0RFX1RZUEVfVU5TUEVDSUZJRUQQABIUChBOT0RFX1RZUEVfTUFTVE'
    'VSEAESEwoPTk9ERV9UWVBFX0FVRElPEAISFAoQTk9ERV9UWVBFX1ZJRVdFUhADEhAKDE5PREVf'
    'VFlQRV9NQRAEEhYKEk5PREVfVFlQRV9MSUdIVElORxAF');

@$core.Deprecated('Use nodeRoleDescriptor instead')
const NodeRole$json = {
  '1': 'NodeRole',
  '2': [
    {'1': 'NODE_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'NODE_ROLE_MASTER', '2': 1},
    {'1': 'NODE_ROLE_BACKUP', '2': 2},
    {'1': 'NODE_ROLE_CLIENT', '2': 3},
    {'1': 'NODE_ROLE_VIEWER', '2': 4},
  ],
};

/// Descriptor for `NodeRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeRoleDescriptor = $convert.base64Decode(
    'CghOb2RlUm9sZRIZChVOT0RFX1JPTEVfVU5TUEVDSUZJRUQQABIUChBOT0RFX1JPTEVfTUFTVE'
    'VSEAESFAoQTk9ERV9ST0xFX0JBQ0tVUBACEhQKEE5PREVfUk9MRV9DTElFTlQQAxIUChBOT0RF'
    'X1JPTEVfVklFV0VSEAQ=');

@$core.Deprecated('Use nodeTaskDescriptor instead')
const NodeTask$json = {
  '1': 'NodeTask',
  '2': [
    {'1': 'NODE_TASK_UNSPECIFIED', '2': 0},
    {'1': 'NODE_TASK_MASTER', '2': 1},
    {'1': 'NODE_TASK_AUDIO_OUTPUT', '2': 2},
    {'1': 'NODE_TASK_EDITOR', '2': 3},
    {'1': 'NODE_TASK_VIEWER', '2': 4},
    {'1': 'NODE_TASK_MA_OSC', '2': 5},
  ],
};

/// Descriptor for `NodeTask`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeTaskDescriptor = $convert.base64Decode(
    'CghOb2RlVGFzaxIZChVOT0RFX1RBU0tfVU5TUEVDSUZJRUQQABIUChBOT0RFX1RBU0tfTUFTVE'
    'VSEAESGgoWTk9ERV9UQVNLX0FVRElPX09VVFBVVBACEhQKEE5PREVfVEFTS19FRElUT1IQAxIU'
    'ChBOT0RFX1RBU0tfVklFV0VSEAQSFAoQTk9ERV9UQVNLX01BX09TQxAF');

@$core.Deprecated('Use cueTypeDescriptor instead')
const CueType$json = {
  '1': 'CueType',
  '2': [
    {'1': 'CUE_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'CUE_TYPE_AUDIO', '2': 1},
    {'1': 'CUE_TYPE_MA_OSC', '2': 2},
    {'1': 'CUE_TYPE_WAIT', '2': 3},
    {'1': 'CUE_TYPE_GROUP', '2': 4},
    {'1': 'CUE_TYPE_GOTO', '2': 5},
    {'1': 'CUE_TYPE_NOTE', '2': 6},
    {'1': 'CUE_TYPE_FADE', '2': 7},
  ],
};

/// Descriptor for `CueType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cueTypeDescriptor = $convert.base64Decode(
    'CgdDdWVUeXBlEhgKFENVRV9UWVBFX1VOU1BFQ0lGSUVEEAASEgoOQ1VFX1RZUEVfQVVESU8QAR'
    'ITCg9DVUVfVFlQRV9NQV9PU0MQAhIRCg1DVUVfVFlQRV9XQUlUEAMSEgoOQ1VFX1RZUEVfR1JP'
    'VVAQBBIRCg1DVUVfVFlQRV9HT1RPEAUSEQoNQ1VFX1RZUEVfTk9URRAGEhEKDUNVRV9UWVBFX0'
    'ZBREUQBw==');

@$core.Deprecated('Use cueStateDescriptor instead')
const CueState$json = {
  '1': 'CueState',
  '2': [
    {'1': 'CUE_STATE_UNSPECIFIED', '2': 0},
    {'1': 'CUE_STATE_IDLE', '2': 1},
    {'1': 'CUE_STATE_ARMED', '2': 2},
    {'1': 'CUE_STATE_PLAYING', '2': 3},
    {'1': 'CUE_STATE_PAUSED', '2': 4},
    {'1': 'CUE_STATE_DONE', '2': 5},
    {'1': 'CUE_STATE_ERROR', '2': 6},
  ],
};

/// Descriptor for `CueState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cueStateDescriptor = $convert.base64Decode(
    'CghDdWVTdGF0ZRIZChVDVUVfU1RBVEVfVU5TUEVDSUZJRUQQABISCg5DVUVfU1RBVEVfSURMRR'
    'ABEhMKD0NVRV9TVEFURV9BUk1FRBACEhUKEUNVRV9TVEFURV9QTEFZSU5HEAMSFAoQQ1VFX1NU'
    'QVRFX1BBVVNFRBAEEhIKDkNVRV9TVEFURV9ET05FEAUSEwoPQ1VFX1NUQVRFX0VSUk9SEAY=');

@$core.Deprecated('Use timestampDescriptor instead')
const Timestamp$json = {
  '1': 'Timestamp',
  '2': [
    {'1': 'unix_millis', '3': 1, '4': 1, '5': 3, '10': 'unixMillis'},
  ],
};

/// Descriptor for `Timestamp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timestampDescriptor = $convert.base64Decode(
    'CglUaW1lc3RhbXASHwoLdW5peF9taWxsaXMYASABKANSCnVuaXhNaWxsaXM=');

@$core.Deprecated('Use nodeInfoDescriptor instead')
const NodeInfo$json = {
  '1': 'NodeInfo',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'node_type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.NodeType',
      '10': 'nodeType'
    },
    {
      '1': 'node_role',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.NodeRole',
      '10': 'nodeRole'
    },
    {'1': 'address', '3': 5, '4': 1, '5': 9, '10': 'address'},
    {'1': 'online', '3': 6, '4': 1, '5': 8, '10': 'online'},
    {
      '1': 'tasks',
      '3': 7,
      '4': 3,
      '5': 14,
      '6': '.stagesync.v1.NodeTask',
      '10': 'tasks'
    },
    {'1': 'media_server_url', '3': 8, '4': 1, '5': 9, '10': 'mediaServerUrl'},
  ],
};

/// Descriptor for `NodeInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeInfoDescriptor = $convert.base64Decode(
    'CghOb2RlSW5mbxIXCgdub2RlX2lkGAEgASgJUgZub2RlSWQSEgoEbmFtZRgCIAEoCVIEbmFtZR'
    'IzCglub2RlX3R5cGUYAyABKA4yFi5zdGFnZXN5bmMudjEuTm9kZVR5cGVSCG5vZGVUeXBlEjMK'
    'CW5vZGVfcm9sZRgEIAEoDjIWLnN0YWdlc3luYy52MS5Ob2RlUm9sZVIIbm9kZVJvbGUSGAoHYW'
    'RkcmVzcxgFIAEoCVIHYWRkcmVzcxIWCgZvbmxpbmUYBiABKAhSBm9ubGluZRIsCgV0YXNrcxgH'
    'IAMoDjIWLnN0YWdlc3luYy52MS5Ob2RlVGFza1IFdGFza3MSKAoQbWVkaWFfc2VydmVyX3VybB'
    'gIIAEoCVIObWVkaWFTZXJ2ZXJVcmw=');
