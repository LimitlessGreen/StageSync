// This is a generated file - do not edit.
//
// Generated from stagesync/v1/bus.proto.

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

@$core.Deprecated('Use audioBusTypeDescriptor instead')
const AudioBusType$json = {
  '1': 'AudioBusType',
  '2': [
    {'1': 'AUDIO_BUS_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'AUDIO_BUS_TYPE_MAIN', '2': 1},
    {'1': 'AUDIO_BUS_TYPE_MONITOR', '2': 2},
    {'1': 'AUDIO_BUS_TYPE_TALKBACK', '2': 3},
    {'1': 'AUDIO_BUS_TYPE_AUX', '2': 4},
    {'1': 'AUDIO_BUS_TYPE_IEM', '2': 5},
  ],
};

/// Descriptor for `AudioBusType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List audioBusTypeDescriptor = $convert.base64Decode(
    'CgxBdWRpb0J1c1R5cGUSHgoaQVVESU9fQlVTX1RZUEVfVU5TUEVDSUZJRUQQABIXChNBVURJT1'
    '9CVVNfVFlQRV9NQUlOEAESGgoWQVVESU9fQlVTX1RZUEVfTU9OSVRPUhACEhsKF0FVRElPX0JV'
    'U19UWVBFX1RBTEtCQUNLEAMSFgoSQVVESU9fQlVTX1RZUEVfQVVYEAQSFgoSQVVESU9fQlVTX1'
    'RZUEVfSUVNEAU=');

@$core.Deprecated('Use audioBusDescriptor instead')
const AudioBus$json = {
  '1': 'AudioBus',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.AudioBusType',
      '10': 'type'
    },
    {'1': 'output_level_db', '3': 4, '4': 1, '5': 2, '10': 'outputLevelDb'},
    {'1': 'muted', '3': 5, '4': 1, '5': 8, '10': 'muted'},
    {
      '1': 'patch',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.BusNodeAssign',
      '10': 'patch'
    },
  ],
};

/// Descriptor for `AudioBus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioBusDescriptor = $convert.base64Decode(
    'CghBdWRpb0J1cxIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIuCgR0eXBlGA'
    'MgASgOMhouc3RhZ2VzeW5jLnYxLkF1ZGlvQnVzVHlwZVIEdHlwZRImCg9vdXRwdXRfbGV2ZWxf'
    'ZGIYBCABKAJSDW91dHB1dExldmVsRGISFAoFbXV0ZWQYBSABKAhSBW11dGVkEjEKBXBhdGNoGA'
    'YgAygLMhsuc3RhZ2VzeW5jLnYxLkJ1c05vZGVBc3NpZ25SBXBhdGNo');

@$core.Deprecated('Use busNodeAssignDescriptor instead')
const BusNodeAssign$json = {
  '1': 'BusNodeAssign',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'device_index', '3': 2, '4': 1, '5': 5, '10': 'deviceIndex'},
    {'1': 'device_name', '3': 3, '4': 1, '5': 9, '10': 'deviceName'},
    {'1': 'channel_offset', '3': 4, '4': 1, '5': 5, '10': 'channelOffset'},
  ],
};

/// Descriptor for `BusNodeAssign`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List busNodeAssignDescriptor = $convert.base64Decode(
    'Cg1CdXNOb2RlQXNzaWduEhcKB25vZGVfaWQYASABKAlSBm5vZGVJZBIhCgxkZXZpY2VfaW5kZX'
    'gYAiABKAVSC2RldmljZUluZGV4Eh8KC2RldmljZV9uYW1lGAMgASgJUgpkZXZpY2VOYW1lEiUK'
    'DmNoYW5uZWxfb2Zmc2V0GAQgASgFUg1jaGFubmVsT2Zmc2V0');

@$core.Deprecated('Use busSendDescriptor instead')
const BusSend$json = {
  '1': 'BusSend',
  '2': [
    {'1': 'bus_id', '3': 1, '4': 1, '5': 9, '10': 'busId'},
    {'1': 'send_level_db', '3': 2, '4': 1, '5': 2, '10': 'sendLevelDb'},
    {'1': 'enabled', '3': 3, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `BusSend`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List busSendDescriptor = $convert.base64Decode(
    'CgdCdXNTZW5kEhUKBmJ1c19pZBgBIAEoCVIFYnVzSWQSIgoNc2VuZF9sZXZlbF9kYhgCIAEoAl'
    'ILc2VuZExldmVsRGISGAoHZW5hYmxlZBgDIAEoCFIHZW5hYmxlZA==');
