// This is a generated file - do not edit.
//
// Generated from stagesync/v1/media.proto.

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

@$core.Deprecated('Use streamFileRequestDescriptor instead')
const StreamFileRequest$json = {
  '1': 'StreamFileRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'asset_id', '3': 3, '4': 1, '5': 9, '10': 'assetId'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'offset', '3': 5, '4': 1, '5': 3, '10': 'offset'},
  ],
};

/// Descriptor for `StreamFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamFileRequestDescriptor = $convert.base64Decode(
    'ChFTdHJlYW1GaWxlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG'
    '9rZW4YAiABKAlSBXRva2VuEhkKCGFzc2V0X2lkGAMgASgJUgdhc3NldElkEhIKBG5hbWUYBCAB'
    'KAlSBG5hbWUSFgoGb2Zmc2V0GAUgASgDUgZvZmZzZXQ=');

@$core.Deprecated('Use fileChunkDescriptor instead')
const FileChunk$json = {
  '1': 'FileChunk',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    {'1': 'offset', '3': 2, '4': 1, '5': 3, '10': 'offset'},
    {'1': 'total_bytes', '3': 3, '4': 1, '5': 3, '10': 'totalBytes'},
  ],
};

/// Descriptor for `FileChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileChunkDescriptor = $convert.base64Decode(
    'CglGaWxlQ2h1bmsSEgoEZGF0YRgBIAEoDFIEZGF0YRIWCgZvZmZzZXQYAiABKANSBm9mZnNldB'
    'IfCgt0b3RhbF9ieXRlcxgDIAEoA1IKdG90YWxCeXRlcw==');

@$core.Deprecated('Use uploadChunkDescriptor instead')
const UploadChunk$json = {
  '1': 'UploadChunk',
  '2': [
    {
      '1': 'meta',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.UploadMeta',
      '9': 0,
      '10': 'meta'
    },
    {'1': 'data', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'data'},
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `UploadChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadChunkDescriptor = $convert.base64Decode(
    'CgtVcGxvYWRDaHVuaxIuCgRtZXRhGAEgASgLMhguc3RhZ2VzeW5jLnYxLlVwbG9hZE1ldGFIAF'
    'IEbWV0YRIUCgRkYXRhGAIgASgMSABSBGRhdGFCCQoHcGF5bG9hZA==');

@$core.Deprecated('Use uploadMetaDescriptor instead')
const UploadMeta$json = {
  '1': 'UploadMeta',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'filename', '3': 3, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'total_bytes', '3': 4, '4': 1, '5': 3, '10': 'totalBytes'},
  ],
};

/// Descriptor for `UploadMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadMetaDescriptor = $convert.base64Decode(
    'CgpVcGxvYWRNZXRhEh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIUCgV0b2tlbhgCIA'
    'EoCVIFdG9rZW4SGgoIZmlsZW5hbWUYAyABKAlSCGZpbGVuYW1lEh8KC3RvdGFsX2J5dGVzGAQg'
    'ASgDUgp0b3RhbEJ5dGVz');

@$core.Deprecated('Use uploadResponseDescriptor instead')
const UploadResponse$json = {
  '1': 'UploadResponse',
  '2': [
    {'1': 'asset_id', '3': 1, '4': 1, '5': 9, '10': 'assetId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'size_bytes', '3': 3, '4': 1, '5': 3, '10': 'sizeBytes'},
    {
      '1': 'audio',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioMeta',
      '10': 'audio'
    },
  ],
};

/// Descriptor for `UploadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadResponseDescriptor = $convert.base64Decode(
    'Cg5VcGxvYWRSZXNwb25zZRIZCghhc3NldF9pZBgBIAEoCVIHYXNzZXRJZBISCgRuYW1lGAIgAS'
    'gJUgRuYW1lEh0KCnNpemVfYnl0ZXMYAyABKANSCXNpemVCeXRlcxItCgVhdWRpbxgEIAEoCzIX'
    'LnN0YWdlc3luYy52MS5BdWRpb01ldGFSBWF1ZGlv');

@$core.Deprecated('Use deleteFileRequestDescriptor instead')
const DeleteFileRequest$json = {
  '1': 'DeleteFileRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `DeleteFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteFileRequestDescriptor = $convert.base64Decode(
    'ChFEZWxldGVGaWxlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdG'
    '9rZW4YAiABKAlSBXRva2VuEhIKBG5hbWUYAyABKAlSBG5hbWU=');

@$core.Deprecated('Use deleteFileResponseDescriptor instead')
const DeleteFileResponse$json = {
  '1': 'DeleteFileResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `DeleteFileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteFileResponseDescriptor =
    $convert.base64Decode(
        'ChJEZWxldGVGaWxlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2Vzcw==');

@$core.Deprecated('Use watchManifestRequestDescriptor instead')
const WatchManifestRequest$json = {
  '1': 'WatchManifestRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `WatchManifestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchManifestRequestDescriptor = $convert.base64Decode(
    'ChRXYXRjaE1hbmlmZXN0UmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFA'
    'oFdG9rZW4YAiABKAlSBXRva2Vu');

@$core.Deprecated('Use manifestEventDescriptor instead')
const ManifestEvent$json = {
  '1': 'ManifestEvent',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.stagesync.v1.ManifestEvent.EventType',
      '10': 'type'
    },
    {'1': 'seq', '3': 2, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'assets',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.stagesync.v1.AssetInfo',
      '10': 'assets'
    },
    {'1': 'removed_name', '3': 4, '4': 1, '5': 9, '10': 'removedName'},
  ],
  '4': [ManifestEvent_EventType$json],
};

@$core.Deprecated('Use manifestEventDescriptor instead')
const ManifestEvent_EventType$json = {
  '1': 'EventType',
  '2': [
    {'1': 'MANIFEST_SNAPSHOT', '2': 0},
    {'1': 'ASSET_ADDED', '2': 1},
    {'1': 'ASSET_REMOVED', '2': 2},
    {'1': 'ASSET_UPDATED', '2': 3},
  ],
};

/// Descriptor for `ManifestEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List manifestEventDescriptor = $convert.base64Decode(
    'Cg1NYW5pZmVzdEV2ZW50EjkKBHR5cGUYASABKA4yJS5zdGFnZXN5bmMudjEuTWFuaWZlc3RFdm'
    'VudC5FdmVudFR5cGVSBHR5cGUSEAoDc2VxGAIgASgDUgNzZXESLwoGYXNzZXRzGAMgAygLMhcu'
    'c3RhZ2VzeW5jLnYxLkFzc2V0SW5mb1IGYXNzZXRzEiEKDHJlbW92ZWRfbmFtZRgEIAEoCVILcm'
    'Vtb3ZlZE5hbWUiWQoJRXZlbnRUeXBlEhUKEU1BTklGRVNUX1NOQVBTSE9UEAASDwoLQVNTRVRf'
    'QURERUQQARIRCg1BU1NFVF9SRU1PVkVEEAISEQoNQVNTRVRfVVBEQVRFRBAD');

@$core.Deprecated('Use assetInfoDescriptor instead')
const AssetInfo$json = {
  '1': 'AssetInfo',
  '2': [
    {'1': 'asset_id', '3': 1, '4': 1, '5': 9, '10': 'assetId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'size_bytes', '3': 3, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'mime_type', '3': 4, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'modified_ms', '3': 5, '4': 1, '5': 3, '10': 'modifiedMs'},
    {
      '1': 'audio',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.stagesync.v1.AudioMeta',
      '10': 'audio'
    },
  ],
};

/// Descriptor for `AssetInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List assetInfoDescriptor = $convert.base64Decode(
    'CglBc3NldEluZm8SGQoIYXNzZXRfaWQYASABKAlSB2Fzc2V0SWQSEgoEbmFtZRgCIAEoCVIEbm'
    'FtZRIdCgpzaXplX2J5dGVzGAMgASgDUglzaXplQnl0ZXMSGwoJbWltZV90eXBlGAQgASgJUght'
    'aW1lVHlwZRIfCgttb2RpZmllZF9tcxgFIAEoA1IKbW9kaWZpZWRNcxItCgVhdWRpbxgGIAEoCz'
    'IXLnN0YWdlc3luYy52MS5BdWRpb01ldGFSBWF1ZGlv');

@$core.Deprecated('Use audioMetaDescriptor instead')
const AudioMeta$json = {
  '1': 'AudioMeta',
  '2': [
    {'1': 'duration_ms', '3': 1, '4': 1, '5': 3, '10': 'durationMs'},
    {'1': 'channels', '3': 2, '4': 1, '5': 5, '10': 'channels'},
    {'1': 'sample_rate', '3': 3, '4': 1, '5': 5, '10': 'sampleRate'},
    {'1': 'bit_depth', '3': 4, '4': 1, '5': 5, '10': 'bitDepth'},
    {'1': 'loudness_lufs', '3': 5, '4': 1, '5': 1, '10': 'loudnessLufs'},
    {'1': 'has_loudness', '3': 6, '4': 1, '5': 8, '10': 'hasLoudness'},
  ],
};

/// Descriptor for `AudioMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioMetaDescriptor = $convert.base64Decode(
    'CglBdWRpb01ldGESHwoLZHVyYXRpb25fbXMYASABKANSCmR1cmF0aW9uTXMSGgoIY2hhbm5lbH'
    'MYAiABKAVSCGNoYW5uZWxzEh8KC3NhbXBsZV9yYXRlGAMgASgFUgpzYW1wbGVSYXRlEhsKCWJp'
    'dF9kZXB0aBgEIAEoBVIIYml0RGVwdGgSIwoNbG91ZG5lc3NfbHVmcxgFIAEoAVIMbG91ZG5lc3'
    'NMdWZzEiEKDGhhc19sb3VkbmVzcxgGIAEoCFILaGFzTG91ZG5lc3M=');
