// This is a generated file - do not edit.
//
// Generated from stagesync/v1/node.proto.

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

@$core.Deprecated('Use audioDeviceInfoDescriptor instead')
const AudioDeviceInfo$json = {
  '1': 'AudioDeviceInfo',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'is_default', '3': 3, '4': 1, '5': 8, '10': 'isDefault'},
    {'1': 'backend', '3': 4, '4': 1, '5': 9, '10': 'backend'},
  ],
};

/// Descriptor for `AudioDeviceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioDeviceInfoDescriptor = $convert.base64Decode(
    'Cg9BdWRpb0RldmljZUluZm8SFAoFaW5kZXgYASABKAVSBWluZGV4EhIKBG5hbWUYAiABKAlSBG'
    '5hbWUSHQoKaXNfZGVmYXVsdBgDIAEoCFIJaXNEZWZhdWx0EhgKB2JhY2tlbmQYBCABKAlSB2Jh'
    'Y2tlbmQ=');

@$core.Deprecated('Use audioCapabilitiesDescriptor instead')
const AudioCapabilities$json = {
  '1': 'AudioCapabilities',
  '2': [
    {'1': 'output_devices', '3': 1, '4': 3, '5': 9, '10': 'outputDevices'},
    {
      '1': 'supported_formats',
      '3': 2,
      '4': 3,
      '5': 9,
      '10': 'supportedFormats'
    },
    {'1': 'max_simultaneous', '3': 3, '4': 1, '5': 5, '10': 'maxSimultaneous'},
    {'1': 'media_server_url', '3': 4, '4': 1, '5': 9, '10': 'mediaServerUrl'},
    {
      '1': 'available_devices',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.AudioDeviceInfo',
      '10': 'availableDevices'
    },
    {'1': 'selected_device', '3': 6, '4': 1, '5': 5, '10': 'selectedDevice'},
    {'1': 'active_backend', '3': 7, '4': 1, '5': 9, '10': 'activeBackend'},
    {'1': 'backend_priority', '3': 8, '4': 3, '5': 9, '10': 'backendPriority'},
    {'1': 'sample_rate', '3': 9, '4': 1, '5': 13, '10': 'sampleRate'},
    {'1': 'channels', '3': 10, '4': 1, '5': 13, '10': 'channels'},
  ],
};

/// Descriptor for `AudioCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioCapabilitiesDescriptor = $convert.base64Decode(
    'ChFBdWRpb0NhcGFiaWxpdGllcxIlCg5vdXRwdXRfZGV2aWNlcxgBIAMoCVINb3V0cHV0RGV2aW'
    'NlcxIrChFzdXBwb3J0ZWRfZm9ybWF0cxgCIAMoCVIQc3VwcG9ydGVkRm9ybWF0cxIpChBtYXhf'
    'c2ltdWx0YW5lb3VzGAMgASgFUg9tYXhTaW11bHRhbmVvdXMSKAoQbWVkaWFfc2VydmVyX3VybB'
    'gEIAEoCVIObWVkaWFTZXJ2ZXJVcmwSSgoRYXZhaWxhYmxlX2RldmljZXMYBSADKAsyHS5zdGFn'
    'ZXN5bmMudjEuQXVkaW9EZXZpY2VJbmZvUhBhdmFpbGFibGVEZXZpY2VzEicKD3NlbGVjdGVkX2'
    'RldmljZRgGIAEoBVIOc2VsZWN0ZWREZXZpY2USJQoOYWN0aXZlX2JhY2tlbmQYByABKAlSDWFj'
    'dGl2ZUJhY2tlbmQSKQoQYmFja2VuZF9wcmlvcml0eRgIIAMoCVIPYmFja2VuZFByaW9yaXR5Eh'
    '8KC3NhbXBsZV9yYXRlGAkgASgNUgpzYW1wbGVSYXRlEhoKCGNoYW5uZWxzGAogASgNUghjaGFu'
    'bmVscw==');

@$core.Deprecated('Use mediaFileInfoDescriptor instead')
const MediaFileInfo$json = {
  '1': 'MediaFileInfo',
  '2': [
    {'1': 'filename', '3': 1, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'size_bytes', '3': 2, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'format', '3': 3, '4': 1, '5': 9, '10': 'format'},
    {'1': 'duration_ms', '3': 4, '4': 1, '5': 3, '10': 'durationMs'},
    {
      '1': 'modified_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Timestamp',
      '10': 'modifiedAt'
    },
  ],
};

/// Descriptor for `MediaFileInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaFileInfoDescriptor = $convert.base64Decode(
    'Cg1NZWRpYUZpbGVJbmZvEhoKCGZpbGVuYW1lGAEgASgJUghmaWxlbmFtZRIdCgpzaXplX2J5dG'
    'VzGAIgASgDUglzaXplQnl0ZXMSFgoGZm9ybWF0GAMgASgJUgZmb3JtYXQSHwoLZHVyYXRpb25f'
    'bXMYBCABKANSCmR1cmF0aW9uTXMSOAoLbW9kaWZpZWRfYXQYBSABKAsyFy5zdGFnZXN5bmMudj'
    'EuVGltZXN0YW1wUgptb2RpZmllZEF0');

@$core.Deprecated('Use maCapabilitiesDescriptor instead')
const MaCapabilities$json = {
  '1': 'MaCapabilities',
  '2': [
    {'1': 'grandma_version', '3': 1, '4': 1, '5': 9, '10': 'grandmaVersion'},
    {'1': 'grandma_address', '3': 2, '4': 1, '5': 9, '10': 'grandmaAddress'},
    {'1': 'grandma_osc_port', '3': 3, '4': 1, '5': 5, '10': 'grandmaOscPort'},
    {'1': 'osc_enabled', '3': 4, '4': 1, '5': 8, '10': 'oscEnabled'},
    {'1': 'telnet_enabled', '3': 5, '4': 1, '5': 8, '10': 'telnetEnabled'},
  ],
};

/// Descriptor for `MaCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List maCapabilitiesDescriptor = $convert.base64Decode(
    'Cg5NYUNhcGFiaWxpdGllcxInCg9ncmFuZG1hX3ZlcnNpb24YASABKAlSDmdyYW5kbWFWZXJzaW'
    '9uEicKD2dyYW5kbWFfYWRkcmVzcxgCIAEoCVIOZ3JhbmRtYUFkZHJlc3MSKAoQZ3JhbmRtYV9v'
    'c2NfcG9ydBgDIAEoBVIOZ3JhbmRtYU9zY1BvcnQSHwoLb3NjX2VuYWJsZWQYBCABKAhSCm9zY0'
    'VuYWJsZWQSJQoOdGVsbmV0X2VuYWJsZWQYBSABKAhSDXRlbG5ldEVuYWJsZWQ=');

@$core.Deprecated('Use nodeCapabilitiesDescriptor instead')
const NodeCapabilities$json = {
  '1': 'NodeCapabilities',
  '2': [
    {
      '1': 'audio',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioCapabilities',
      '10': 'audio'
    },
    {
      '1': 'ma',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.MaCapabilities',
      '10': 'ma'
    },
    {
      '1': 'audition_supported',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'auditionSupported'
    },
    {'1': 'audition_device', '3': 4, '4': 1, '5': 9, '10': 'auditionDevice'},
  ],
};

/// Descriptor for `NodeCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeCapabilitiesDescriptor = $convert.base64Decode(
    'ChBOb2RlQ2FwYWJpbGl0aWVzEjUKBWF1ZGlvGAEgASgLMh8uc3RhZ2VzeW5jLnYxLkF1ZGlvQ2'
    'FwYWJpbGl0aWVzUgVhdWRpbxIsCgJtYRgCIAEoCzIcLnN0YWdlc3luYy52MS5NYUNhcGFiaWxp'
    'dGllc1ICbWESLQoSYXVkaXRpb25fc3VwcG9ydGVkGAMgASgIUhFhdWRpdGlvblN1cHBvcnRlZB'
    'InCg9hdWRpdGlvbl9kZXZpY2UYBCABKAlSDmF1ZGl0aW9uRGV2aWNl');

@$core.Deprecated('Use registerNodeRequestDescriptor instead')
const RegisterNodeRequest$json = {
  '1': 'RegisterNodeRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'node',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeInfo',
      '10': 'node'
    },
    {
      '1': 'capabilities',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeCapabilities',
      '10': 'capabilities'
    },
  ],
};

/// Descriptor for `RegisterNodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerNodeRequestDescriptor = $convert.base64Decode(
    'ChNSZWdpc3Rlck5vZGVSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIUCg'
    'V0b2tlbhgCIAEoCVIFdG9rZW4SKgoEbm9kZRgDIAEoCzIWLnN0YWdlc3luYy52MS5Ob2RlSW5m'
    'b1IEbm9kZRJCCgxjYXBhYmlsaXRpZXMYBCABKAsyHi5zdGFnZXN5bmMudjEuTm9kZUNhcGFiaW'
    'xpdGllc1IMY2FwYWJpbGl0aWVz');

@$core.Deprecated('Use nodeResponseDescriptor instead')
const NodeResponse$json = {
  '1': 'NodeResponse',
  '2': [
    {
      '1': 'node',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeInfo',
      '10': 'node'
    },
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `NodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeResponseDescriptor = $convert.base64Decode(
    'CgxOb2RlUmVzcG9uc2USKgoEbm9kZRgBIAEoCzIWLnN0YWdlc3luYy52MS5Ob2RlSW5mb1IEbm'
    '9kZRIUCgV0b2tlbhgCIAEoCVIFdG9rZW4=');

@$core.Deprecated('Use unregisterNodeRequestDescriptor instead')
const UnregisterNodeRequest$json = {
  '1': 'UnregisterNodeRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `UnregisterNodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unregisterNodeRequestDescriptor = $convert.base64Decode(
    'ChVVbnJlZ2lzdGVyTm9kZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh'
    'cKB25vZGVfaWQYAiABKAlSBm5vZGVJZBIUCgV0b2tlbhgDIAEoCVIFdG9rZW4=');

@$core.Deprecated('Use listNodesRequestDescriptor instead')
const ListNodesRequest$json = {
  '1': 'ListNodesRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `ListNodesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listNodesRequestDescriptor = $convert.base64Decode(
    'ChBMaXN0Tm9kZXNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIUCgV0b2'
    'tlbhgCIAEoCVIFdG9rZW4=');

@$core.Deprecated('Use listNodesResponseDescriptor instead')
const ListNodesResponse$json = {
  '1': 'ListNodesResponse',
  '2': [
    {
      '1': 'nodes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.NodeInfo',
      '10': 'nodes'
    },
  ],
};

/// Descriptor for `ListNodesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listNodesResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0Tm9kZXNSZXNwb25zZRIsCgVub2RlcxgBIAMoCzIWLnN0YWdlc3luYy52MS5Ob2RlSW'
    '5mb1IFbm9kZXM=');

@$core.Deprecated('Use watchNodesRequestDescriptor instead')
const WatchNodesRequest$json = {
  '1': 'WatchNodesRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `WatchNodesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchNodesRequestDescriptor = $convert.base64Decode(
    'ChFXYXRjaE5vZGVzUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG'
    '9rZW4YAiABKAlSBXRva2Vu');

@$core.Deprecated('Use nodeEventDescriptor instead')
const NodeEvent$json = {
  '1': 'NodeEvent',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.NodeEvent.Type',
      '10': 'type'
    },
    {
      '1': 'node',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeInfo',
      '10': 'node'
    },
    {
      '1': 'occurred_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.Timestamp',
      '10': 'occurredAt'
    },
  ],
  '4': [NodeEvent_Type$json],
};

@$core.Deprecated('Use nodeEventDescriptor instead')
const NodeEvent_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'TYPE_UNSPECIFIED', '2': 0},
    {'1': 'TYPE_REGISTERED', '2': 1},
    {'1': 'TYPE_UNREGISTERED', '2': 2},
    {'1': 'TYPE_OFFLINE', '2': 3},
    {'1': 'TYPE_ONLINE', '2': 4},
    {'1': 'TYPE_CAPS_UPDATED', '2': 5},
  ],
};

/// Descriptor for `NodeEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeEventDescriptor = $convert.base64Decode(
    'CglOb2RlRXZlbnQSMAoEdHlwZRgBIAEoDjIcLnN0YWdlc3luYy52MS5Ob2RlRXZlbnQuVHlwZV'
    'IEdHlwZRIqCgRub2RlGAIgASgLMhYuc3RhZ2VzeW5jLnYxLk5vZGVJbmZvUgRub2RlEjgKC29j'
    'Y3VycmVkX2F0GAMgASgLMhcuc3RhZ2VzeW5jLnYxLlRpbWVzdGFtcFIKb2NjdXJyZWRBdCKCAQ'
    'oEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASEwoPVFlQRV9SRUdJU1RFUkVEEAESFQoRVFlQ'
    'RV9VTlJFR0lTVEVSRUQQAhIQCgxUWVBFX09GRkxJTkUQAxIPCgtUWVBFX09OTElORRAEEhUKEV'
    'RZUEVfQ0FQU19VUERBVEVEEAU=');

@$core.Deprecated('Use updateCapabilitiesRequestDescriptor instead')
const UpdateCapabilitiesRequest$json = {
  '1': 'UpdateCapabilitiesRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'capabilities',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeCapabilities',
      '10': 'capabilities'
    },
  ],
};

/// Descriptor for `UpdateCapabilitiesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateCapabilitiesRequestDescriptor = $convert.base64Decode(
    'ChlVcGRhdGVDYXBhYmlsaXRpZXNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb2'
    '5JZBIXCgdub2RlX2lkGAIgASgJUgZub2RlSWQSFAoFdG9rZW4YAyABKAlSBXRva2VuEkIKDGNh'
    'cGFiaWxpdGllcxgEIAEoCzIeLnN0YWdlc3luYy52MS5Ob2RlQ2FwYWJpbGl0aWVzUgxjYXBhYm'
    'lsaXRpZXM=');

@$core.Deprecated('Use streamNodeCommandsRequestDescriptor instead')
const StreamNodeCommandsRequest$json = {
  '1': 'StreamNodeCommandsRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `StreamNodeCommandsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamNodeCommandsRequestDescriptor =
    $convert.base64Decode(
        'ChlTdHJlYW1Ob2RlQ29tbWFuZHNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb2'
        '5JZBIXCgdub2RlX2lkGAIgASgJUgZub2RlSWQSFAoFdG9rZW4YAyABKAlSBXRva2Vu');

@$core.Deprecated('Use nodeCommandRequestDescriptor instead')
const NodeCommandRequest$json = {
  '1': 'NodeCommandRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'command_id', '3': 2, '4': 1, '5': 9, '10': 'commandId'},
    {'1': 'target_node_id', '3': 3, '4': 1, '5': 9, '10': 'targetNodeId'},
    {
      '1': 'target_task',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.NodeTask',
      '10': 'targetTask'
    },
    {
      '1': 'audio_preload',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioPreloadCommand',
      '9': 0,
      '10': 'audioPreload'
    },
    {
      '1': 'audio_play',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioPlayCommand',
      '9': 0,
      '10': 'audioPlay'
    },
    {
      '1': 'audio_stop',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioStopCommand',
      '9': 0,
      '10': 'audioStop'
    },
    {
      '1': 'ma_osc',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.MaOscCommand',
      '9': 0,
      '10': 'maOsc'
    },
    {
      '1': 'audio_pause',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioPauseCommand',
      '9': 0,
      '10': 'audioPause'
    },
    {
      '1': 'audio_resume',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioResumeCommand',
      '9': 0,
      '10': 'audioResume'
    },
    {
      '1': 'audio_test',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioTestSignalCommand',
      '9': 0,
      '10': 'audioTest'
    },
    {
      '1': 'node_config',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeConfigCommand',
      '9': 0,
      '10': 'nodeConfig'
    },
    {
      '1': 'audio_fade',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioFadeCommand',
      '9': 0,
      '10': 'audioFade'
    },
    {
      '1': 'audio_talkback',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioTalkbackChunkCommand',
      '9': 0,
      '10': 'audioTalkback'
    },
    {
      '1': 'audio_talkback_ctrl',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioTalkbackControlCommand',
      '9': 0,
      '10': 'audioTalkbackCtrl'
    },
  ],
  '8': [
    {'1': 'command'},
  ],
};

/// Descriptor for `NodeCommandRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeCommandRequestDescriptor = $convert.base64Decode(
    'ChJOb2RlQ29tbWFuZFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh0KCm'
    'NvbW1hbmRfaWQYAiABKAlSCWNvbW1hbmRJZBIkCg50YXJnZXRfbm9kZV9pZBgDIAEoCVIMdGFy'
    'Z2V0Tm9kZUlkEjcKC3RhcmdldF90YXNrGAggASgOMhYuc3RhZ2VzeW5jLnYxLk5vZGVUYXNrUg'
    'p0YXJnZXRUYXNrEkgKDWF1ZGlvX3ByZWxvYWQYBCABKAsyIS5zdGFnZXN5bmMudjEuQXVkaW9Q'
    'cmVsb2FkQ29tbWFuZEgAUgxhdWRpb1ByZWxvYWQSPwoKYXVkaW9fcGxheRgFIAEoCzIeLnN0YW'
    'dlc3luYy52MS5BdWRpb1BsYXlDb21tYW5kSABSCWF1ZGlvUGxheRI/CgphdWRpb19zdG9wGAYg'
    'ASgLMh4uc3RhZ2VzeW5jLnYxLkF1ZGlvU3RvcENvbW1hbmRIAFIJYXVkaW9TdG9wEjMKBm1hX2'
    '9zYxgHIAEoCzIaLnN0YWdlc3luYy52MS5NYU9zY0NvbW1hbmRIAFIFbWFPc2MSQgoLYXVkaW9f'
    'cGF1c2UYCSABKAsyHy5zdGFnZXN5bmMudjEuQXVkaW9QYXVzZUNvbW1hbmRIAFIKYXVkaW9QYX'
    'VzZRJFCgxhdWRpb19yZXN1bWUYCiABKAsyIC5zdGFnZXN5bmMudjEuQXVkaW9SZXN1bWVDb21t'
    'YW5kSABSC2F1ZGlvUmVzdW1lEkUKCmF1ZGlvX3Rlc3QYCyABKAsyJC5zdGFnZXN5bmMudjEuQX'
    'VkaW9UZXN0U2lnbmFsQ29tbWFuZEgAUglhdWRpb1Rlc3QSQgoLbm9kZV9jb25maWcYDCABKAsy'
    'Hy5zdGFnZXN5bmMudjEuTm9kZUNvbmZpZ0NvbW1hbmRIAFIKbm9kZUNvbmZpZxI/CgphdWRpb1'
    '9mYWRlGA0gASgLMh4uc3RhZ2VzeW5jLnYxLkF1ZGlvRmFkZUNvbW1hbmRIAFIJYXVkaW9GYWRl'
    'ElAKDmF1ZGlvX3RhbGtiYWNrGA4gASgLMicuc3RhZ2VzeW5jLnYxLkF1ZGlvVGFsa2JhY2tDaH'
    'Vua0NvbW1hbmRIAFINYXVkaW9UYWxrYmFjaxJbChNhdWRpb190YWxrYmFja19jdHJsGA8gASgL'
    'Mikuc3RhZ2VzeW5jLnYxLkF1ZGlvVGFsa2JhY2tDb250cm9sQ29tbWFuZEgAUhFhdWRpb1RhbG'
    'tiYWNrQ3RybEIJCgdjb21tYW5k');

@$core.Deprecated('Use nodeConfigCommandDescriptor instead')
const NodeConfigCommand$json = {
  '1': 'NodeConfigCommand',
  '2': [
    {
      '1': 'audio_device_index',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'audioDeviceIndex'
    },
    {'1': 'audio_device_name', '3': 2, '4': 1, '5': 9, '10': 'audioDeviceName'},
    {
      '1': 'network_interface_address',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'networkInterfaceAddress'
    },
    {
      '1': 'tasks',
      '3': 4,
      '4': 3,
      '5': 14,
      '6': '.stagesync.v1.NodeTask',
      '10': 'tasks'
    },
    {'1': 'audio_backend', '3': 5, '4': 1, '5': 9, '10': 'audioBackend'},
    {
      '1': 'audio_backend_priority',
      '3': 6,
      '4': 3,
      '5': 9,
      '10': 'audioBackendPriority'
    },
    {'1': 'sample_rate', '3': 7, '4': 1, '5': 13, '10': 'sampleRate'},
    {'1': 'channels', '3': 8, '4': 1, '5': 13, '10': 'channels'},
  ],
};

/// Descriptor for `NodeConfigCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeConfigCommandDescriptor = $convert.base64Decode(
    'ChFOb2RlQ29uZmlnQ29tbWFuZBIsChJhdWRpb19kZXZpY2VfaW5kZXgYASABKAVSEGF1ZGlvRG'
    'V2aWNlSW5kZXgSKgoRYXVkaW9fZGV2aWNlX25hbWUYAiABKAlSD2F1ZGlvRGV2aWNlTmFtZRI6'
    'ChluZXR3b3JrX2ludGVyZmFjZV9hZGRyZXNzGAMgASgJUhduZXR3b3JrSW50ZXJmYWNlQWRkcm'
    'VzcxIsCgV0YXNrcxgEIAMoDjIWLnN0YWdlc3luYy52MS5Ob2RlVGFza1IFdGFza3MSIwoNYXVk'
    'aW9fYmFja2VuZBgFIAEoCVIMYXVkaW9CYWNrZW5kEjQKFmF1ZGlvX2JhY2tlbmRfcHJpb3JpdH'
    'kYBiADKAlSFGF1ZGlvQmFja2VuZFByaW9yaXR5Eh8KC3NhbXBsZV9yYXRlGAcgASgNUgpzYW1w'
    'bGVSYXRlEhoKCGNoYW5uZWxzGAggASgNUghjaGFubmVscw==');

@$core.Deprecated('Use sendNodeCommandRequestDescriptor instead')
const SendNodeCommandRequest$json = {
  '1': 'SendNodeCommandRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'target_node_id', '3': 3, '4': 1, '5': 9, '10': 'targetNodeId'},
    {
      '1': 'command',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.NodeCommandRequest',
      '10': 'command'
    },
  ],
};

/// Descriptor for `SendNodeCommandRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendNodeCommandRequestDescriptor = $convert.base64Decode(
    'ChZTZW5kTm9kZUNvbW1hbmRSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZB'
    'IUCgV0b2tlbhgCIAEoCVIFdG9rZW4SJAoOdGFyZ2V0X25vZGVfaWQYAyABKAlSDHRhcmdldE5v'
    'ZGVJZBI6Cgdjb21tYW5kGAQgASgLMiAuc3RhZ2VzeW5jLnYxLk5vZGVDb21tYW5kUmVxdWVzdF'
    'IHY29tbWFuZA==');

@$core.Deprecated('Use audioPreloadCommandDescriptor instead')
const AudioPreloadCommand$json = {
  '1': 'AudioPreloadCommand',
  '2': [
    {'1': 'cue_id', '3': 1, '4': 1, '5': 9, '10': 'cueId'},
    {'1': 'file_path', '3': 2, '4': 1, '5': 9, '10': 'filePath'},
    {'1': 'asset_id', '3': 3, '4': 1, '5': 9, '10': 'assetId'},
  ],
};

/// Descriptor for `AudioPreloadCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioPreloadCommandDescriptor = $convert.base64Decode(
    'ChNBdWRpb1ByZWxvYWRDb21tYW5kEhUKBmN1ZV9pZBgBIAEoCVIFY3VlSWQSGwoJZmlsZV9wYX'
    'RoGAIgASgJUghmaWxlUGF0aBIZCghhc3NldF9pZBgDIAEoCVIHYXNzZXRJZA==');

@$core.Deprecated('Use audioPlayCommandDescriptor instead')
const AudioPlayCommand$json = {
  '1': 'AudioPlayCommand',
  '2': [
    {'1': 'cue_id', '3': 1, '4': 1, '5': 9, '10': 'cueId'},
    {'1': 'start_unix_millis', '3': 2, '4': 1, '5': 3, '10': 'startUnixMillis'},
    {'1': 'volume_db', '3': 3, '4': 1, '5': 1, '10': 'volumeDb'},
    {'1': 'fade_in_ms', '3': 4, '4': 1, '5': 1, '10': 'fadeInMs'},
    {'1': 'fade_out_ms', '3': 5, '4': 1, '5': 1, '10': 'fadeOutMs'},
    {'1': 'loop', '3': 6, '4': 1, '5': 8, '10': 'loop'},
    {'1': 'start_time_ms', '3': 7, '4': 1, '5': 1, '10': 'startTimeMs'},
    {'1': 'end_time_ms', '3': 8, '4': 1, '5': 1, '10': 'endTimeMs'},
  ],
};

/// Descriptor for `AudioPlayCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioPlayCommandDescriptor = $convert.base64Decode(
    'ChBBdWRpb1BsYXlDb21tYW5kEhUKBmN1ZV9pZBgBIAEoCVIFY3VlSWQSKgoRc3RhcnRfdW5peF'
    '9taWxsaXMYAiABKANSD3N0YXJ0VW5peE1pbGxpcxIbCgl2b2x1bWVfZGIYAyABKAFSCHZvbHVt'
    'ZURiEhwKCmZhZGVfaW5fbXMYBCABKAFSCGZhZGVJbk1zEh4KC2ZhZGVfb3V0X21zGAUgASgBUg'
    'lmYWRlT3V0TXMSEgoEbG9vcBgGIAEoCFIEbG9vcBIiCg1zdGFydF90aW1lX21zGAcgASgBUgtz'
    'dGFydFRpbWVNcxIeCgtlbmRfdGltZV9tcxgIIAEoAVIJZW5kVGltZU1z');

@$core.Deprecated('Use audioStopCommandDescriptor instead')
const AudioStopCommand$json = {
  '1': 'AudioStopCommand',
  '2': [
    {'1': 'cue_id', '3': 1, '4': 1, '5': 9, '10': 'cueId'},
    {'1': 'fade_out_ms', '3': 2, '4': 1, '5': 1, '10': 'fadeOutMs'},
  ],
};

/// Descriptor for `AudioStopCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioStopCommandDescriptor = $convert.base64Decode(
    'ChBBdWRpb1N0b3BDb21tYW5kEhUKBmN1ZV9pZBgBIAEoCVIFY3VlSWQSHgoLZmFkZV9vdXRfbX'
    'MYAiABKAFSCWZhZGVPdXRNcw==');

@$core.Deprecated('Use audioPauseCommandDescriptor instead')
const AudioPauseCommand$json = {
  '1': 'AudioPauseCommand',
  '2': [
    {'1': 'cue_id', '3': 1, '4': 1, '5': 9, '10': 'cueId'},
    {'1': 'fade_out_ms', '3': 2, '4': 1, '5': 1, '10': 'fadeOutMs'},
  ],
};

/// Descriptor for `AudioPauseCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioPauseCommandDescriptor = $convert.base64Decode(
    'ChFBdWRpb1BhdXNlQ29tbWFuZBIVCgZjdWVfaWQYASABKAlSBWN1ZUlkEh4KC2ZhZGVfb3V0X2'
    '1zGAIgASgBUglmYWRlT3V0TXM=');

@$core.Deprecated('Use audioResumeCommandDescriptor instead')
const AudioResumeCommand$json = {
  '1': 'AudioResumeCommand',
  '2': [
    {'1': 'cue_id', '3': 1, '4': 1, '5': 9, '10': 'cueId'},
    {'1': 'fade_in_ms', '3': 2, '4': 1, '5': 1, '10': 'fadeInMs'},
  ],
};

/// Descriptor for `AudioResumeCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioResumeCommandDescriptor = $convert.base64Decode(
    'ChJBdWRpb1Jlc3VtZUNvbW1hbmQSFQoGY3VlX2lkGAEgASgJUgVjdWVJZBIcCgpmYWRlX2luX2'
    '1zGAIgASgBUghmYWRlSW5Ncw==');

@$core.Deprecated('Use audioFadeCommandDescriptor instead')
const AudioFadeCommand$json = {
  '1': 'AudioFadeCommand',
  '2': [
    {'1': 'cue_id', '3': 1, '4': 1, '5': 9, '10': 'cueId'},
    {'1': 'target_volume_db', '3': 2, '4': 1, '5': 1, '10': 'targetVolumeDb'},
    {'1': 'duration_ms', '3': 3, '4': 1, '5': 1, '10': 'durationMs'},
    {'1': 'stop_when_done', '3': 4, '4': 1, '5': 8, '10': 'stopWhenDone'},
    {'1': 'pause_when_done', '3': 5, '4': 1, '5': 8, '10': 'pauseWhenDone'},
  ],
};

/// Descriptor for `AudioFadeCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioFadeCommandDescriptor = $convert.base64Decode(
    'ChBBdWRpb0ZhZGVDb21tYW5kEhUKBmN1ZV9pZBgBIAEoCVIFY3VlSWQSKAoQdGFyZ2V0X3ZvbH'
    'VtZV9kYhgCIAEoAVIOdGFyZ2V0Vm9sdW1lRGISHwoLZHVyYXRpb25fbXMYAyABKAFSCmR1cmF0'
    'aW9uTXMSJAoOc3RvcF93aGVuX2RvbmUYBCABKAhSDHN0b3BXaGVuRG9uZRImCg9wYXVzZV93aG'
    'VuX2RvbmUYBSABKAhSDXBhdXNlV2hlbkRvbmU=');

@$core.Deprecated('Use audioTestSignalCommandDescriptor instead')
const AudioTestSignalCommand$json = {
  '1': 'AudioTestSignalCommand',
  '2': [
    {'1': 'cue_id', '3': 1, '4': 1, '5': 9, '10': 'cueId'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.AudioTestSignalCommand.Kind',
      '10': 'kind'
    },
    {'1': 'start_hz', '3': 3, '4': 1, '5': 1, '10': 'startHz'},
    {'1': 'end_hz', '3': 4, '4': 1, '5': 1, '10': 'endHz'},
    {'1': 'frequency_hz', '3': 5, '4': 1, '5': 1, '10': 'frequencyHz'},
    {'1': 'duration_ms', '3': 6, '4': 1, '5': 1, '10': 'durationMs'},
    {'1': 'amplitude', '3': 7, '4': 1, '5': 1, '10': 'amplitude'},
  ],
  '4': [AudioTestSignalCommand_Kind$json],
};

@$core.Deprecated('Use audioTestSignalCommandDescriptor instead')
const AudioTestSignalCommand_Kind$json = {
  '1': 'Kind',
  '2': [
    {'1': 'KIND_TONE', '2': 0},
    {'1': 'KIND_SWEEP', '2': 1},
  ],
};

/// Descriptor for `AudioTestSignalCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioTestSignalCommandDescriptor = $convert.base64Decode(
    'ChZBdWRpb1Rlc3RTaWduYWxDb21tYW5kEhUKBmN1ZV9pZBgBIAEoCVIFY3VlSWQSPQoEa2luZB'
    'gCIAEoDjIpLnN0YWdlc3luYy52MS5BdWRpb1Rlc3RTaWduYWxDb21tYW5kLktpbmRSBGtpbmQS'
    'GQoIc3RhcnRfaHoYAyABKAFSB3N0YXJ0SHoSFQoGZW5kX2h6GAQgASgBUgVlbmRIehIhCgxmcm'
    'VxdWVuY3lfaHoYBSABKAFSC2ZyZXF1ZW5jeUh6Eh8KC2R1cmF0aW9uX21zGAYgASgBUgpkdXJh'
    'dGlvbk1zEhwKCWFtcGxpdHVkZRgHIAEoAVIJYW1wbGl0dWRlIiUKBEtpbmQSDQoJS0lORF9UT0'
    '5FEAASDgoKS0lORF9TV0VFUBAB');

@$core.Deprecated('Use maOscCommandDescriptor instead')
const MaOscCommand$json = {
  '1': 'MaOscCommand',
  '2': [
    {'1': 'osc_address', '3': 1, '4': 1, '5': 9, '10': 'oscAddress'},
    {'1': 'osc_argument', '3': 2, '4': 1, '5': 9, '10': 'oscArgument'},
  ],
};

/// Descriptor for `MaOscCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List maOscCommandDescriptor = $convert.base64Decode(
    'CgxNYU9zY0NvbW1hbmQSHwoLb3NjX2FkZHJlc3MYASABKAlSCm9zY0FkZHJlc3MSIQoMb3NjX2'
    'FyZ3VtZW50GAIgASgJUgtvc2NBcmd1bWVudA==');

@$core.Deprecated('Use nodeCommandResponseDescriptor instead')
const NodeCommandResponse$json = {
  '1': 'NodeCommandResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error_msg', '3': 2, '4': 1, '5': 9, '10': 'errorMsg'},
  ],
};

/// Descriptor for `NodeCommandResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeCommandResponseDescriptor = $convert.base64Decode(
    'ChNOb2RlQ29tbWFuZFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGwoJZXJyb3'
    'JfbXNnGAIgASgJUghlcnJvck1zZw==');

@$core.Deprecated('Use audioTalkbackChunkCommandDescriptor instead')
const AudioTalkbackChunkCommand$json = {
  '1': 'AudioTalkbackChunkCommand',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'opus_data', '3': 2, '4': 1, '5': 12, '10': 'opusData'},
    {'1': 'timestamp_ms', '3': 3, '4': 1, '5': 3, '10': 'timestampMs'},
    {'1': 'sequence', '3': 4, '4': 1, '5': 13, '10': 'sequence'},
    {'1': 'level_db', '3': 5, '4': 1, '5': 2, '10': 'levelDb'},
  ],
};

/// Descriptor for `AudioTalkbackChunkCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioTalkbackChunkCommandDescriptor = $convert.base64Decode(
    'ChlBdWRpb1RhbGtiYWNrQ2h1bmtDb21tYW5kEhsKCWNsaWVudF9pZBgBIAEoCVIIY2xpZW50SW'
    'QSGwoJb3B1c19kYXRhGAIgASgMUghvcHVzRGF0YRIhCgx0aW1lc3RhbXBfbXMYAyABKANSC3Rp'
    'bWVzdGFtcE1zEhoKCHNlcXVlbmNlGAQgASgNUghzZXF1ZW5jZRIZCghsZXZlbF9kYhgFIAEoAl'
    'IHbGV2ZWxEYg==');

@$core.Deprecated('Use audioTalkbackControlCommandDescriptor instead')
const AudioTalkbackControlCommand$json = {
  '1': 'AudioTalkbackControlCommand',
  '2': [
    {
      '1': 'action',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.AudioTalkbackControlCommand.Action',
      '10': 'action'
    },
    {'1': 'client_id', '3': 2, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'duck_db', '3': 3, '4': 1, '5': 2, '10': 'duckDb'},
    {'1': 'duck_ms', '3': 4, '4': 1, '5': 5, '10': 'duckMs'},
  ],
  '4': [AudioTalkbackControlCommand_Action$json],
};

@$core.Deprecated('Use audioTalkbackControlCommandDescriptor instead')
const AudioTalkbackControlCommand_Action$json = {
  '1': 'Action',
  '2': [
    {'1': 'ACTION_START', '2': 0},
    {'1': 'ACTION_STOP', '2': 1},
    {'1': 'ACTION_DUCK', '2': 2},
  ],
};

/// Descriptor for `AudioTalkbackControlCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioTalkbackControlCommandDescriptor = $convert.base64Decode(
    'ChtBdWRpb1RhbGtiYWNrQ29udHJvbENvbW1hbmQSSAoGYWN0aW9uGAEgASgOMjAuc3RhZ2VzeW'
    '5jLnYxLkF1ZGlvVGFsa2JhY2tDb250cm9sQ29tbWFuZC5BY3Rpb25SBmFjdGlvbhIbCgljbGll'
    'bnRfaWQYAiABKAlSCGNsaWVudElkEhcKB2R1Y2tfZGIYAyABKAJSBmR1Y2tEYhIXCgdkdWNrX2'
    '1zGAQgASgFUgZkdWNrTXMiPAoGQWN0aW9uEhAKDEFDVElPTl9TVEFSVBAAEg8KC0FDVElPTl9T'
    'VE9QEAESDwoLQUNUSU9OX0RVQ0sQAg==');
