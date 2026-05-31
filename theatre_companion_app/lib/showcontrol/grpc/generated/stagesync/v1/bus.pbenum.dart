// This is a generated file - do not edit.
//
// Generated from stagesync/v1/bus.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AudioBusType extends $pb.ProtobufEnum {
  static const AudioBusType AUDIO_BUS_TYPE_UNSPECIFIED =
      AudioBusType._(0, _omitEnumNames ? '' : 'AUDIO_BUS_TYPE_UNSPECIFIED');
  static const AudioBusType AUDIO_BUS_TYPE_MAIN =
      AudioBusType._(1, _omitEnumNames ? '' : 'AUDIO_BUS_TYPE_MAIN');
  static const AudioBusType AUDIO_BUS_TYPE_MONITOR =
      AudioBusType._(2, _omitEnumNames ? '' : 'AUDIO_BUS_TYPE_MONITOR');
  static const AudioBusType AUDIO_BUS_TYPE_TALKBACK =
      AudioBusType._(3, _omitEnumNames ? '' : 'AUDIO_BUS_TYPE_TALKBACK');
  static const AudioBusType AUDIO_BUS_TYPE_AUX =
      AudioBusType._(4, _omitEnumNames ? '' : 'AUDIO_BUS_TYPE_AUX');
  static const AudioBusType AUDIO_BUS_TYPE_IEM =
      AudioBusType._(5, _omitEnumNames ? '' : 'AUDIO_BUS_TYPE_IEM');

  static const $core.List<AudioBusType> values = <AudioBusType>[
    AUDIO_BUS_TYPE_UNSPECIFIED,
    AUDIO_BUS_TYPE_MAIN,
    AUDIO_BUS_TYPE_MONITOR,
    AUDIO_BUS_TYPE_TALKBACK,
    AUDIO_BUS_TYPE_AUX,
    AUDIO_BUS_TYPE_IEM,
  ];

  static final $core.List<AudioBusType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static AudioBusType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AudioBusType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
