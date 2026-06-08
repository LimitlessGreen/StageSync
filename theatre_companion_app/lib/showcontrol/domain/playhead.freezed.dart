// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playhead.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NodeExecState {
  NodeExecPhase get phase => throw _privateConstructorUsedError;
  double? get bufferPct =>
      throw _privateConstructorUsedError; // 0.0–1.0, meaningful only during [buffering]
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of NodeExecState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NodeExecStateCopyWith<NodeExecState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NodeExecStateCopyWith<$Res> {
  factory $NodeExecStateCopyWith(
          NodeExecState value, $Res Function(NodeExecState) then) =
      _$NodeExecStateCopyWithImpl<$Res, NodeExecState>;
  @useResult
  $Res call({NodeExecPhase phase, double? bufferPct, String? errorMessage});
}

/// @nodoc
class _$NodeExecStateCopyWithImpl<$Res, $Val extends NodeExecState>
    implements $NodeExecStateCopyWith<$Res> {
  _$NodeExecStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NodeExecState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? phase = null,
    Object? bufferPct = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      phase: null == phase
          ? _value.phase
          : phase // ignore: cast_nullable_to_non_nullable
              as NodeExecPhase,
      bufferPct: freezed == bufferPct
          ? _value.bufferPct
          : bufferPct // ignore: cast_nullable_to_non_nullable
              as double?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NodeExecStateImplCopyWith<$Res>
    implements $NodeExecStateCopyWith<$Res> {
  factory _$$NodeExecStateImplCopyWith(
          _$NodeExecStateImpl value, $Res Function(_$NodeExecStateImpl) then) =
      __$$NodeExecStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({NodeExecPhase phase, double? bufferPct, String? errorMessage});
}

/// @nodoc
class __$$NodeExecStateImplCopyWithImpl<$Res>
    extends _$NodeExecStateCopyWithImpl<$Res, _$NodeExecStateImpl>
    implements _$$NodeExecStateImplCopyWith<$Res> {
  __$$NodeExecStateImplCopyWithImpl(
      _$NodeExecStateImpl _value, $Res Function(_$NodeExecStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of NodeExecState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? phase = null,
    Object? bufferPct = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$NodeExecStateImpl(
      phase: null == phase
          ? _value.phase
          : phase // ignore: cast_nullable_to_non_nullable
              as NodeExecPhase,
      bufferPct: freezed == bufferPct
          ? _value.bufferPct
          : bufferPct // ignore: cast_nullable_to_non_nullable
              as double?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$NodeExecStateImpl extends _NodeExecState {
  const _$NodeExecStateImpl(
      {required this.phase, this.bufferPct, this.errorMessage})
      : super._();

  @override
  final NodeExecPhase phase;
  @override
  final double? bufferPct;
// 0.0–1.0, meaningful only during [buffering]
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'NodeExecState(phase: $phase, bufferPct: $bufferPct, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NodeExecStateImpl &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.bufferPct, bufferPct) ||
                other.bufferPct == bufferPct) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, phase, bufferPct, errorMessage);

  /// Create a copy of NodeExecState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NodeExecStateImplCopyWith<_$NodeExecStateImpl> get copyWith =>
      __$$NodeExecStateImplCopyWithImpl<_$NodeExecStateImpl>(this, _$identity);
}

abstract class _NodeExecState extends NodeExecState {
  const factory _NodeExecState(
      {required final NodeExecPhase phase,
      final double? bufferPct,
      final String? errorMessage}) = _$NodeExecStateImpl;
  const _NodeExecState._() : super._();

  @override
  NodeExecPhase get phase;
  @override
  double? get bufferPct; // 0.0–1.0, meaningful only during [buffering]
  @override
  String? get errorMessage;

  /// Create a copy of NodeExecState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NodeExecStateImplCopyWith<_$NodeExecStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CueRunState {
  CueLifecycle get lifecycle => throw _privateConstructorUsedError;

  /// nodeId → per-node execution state.
  Map<String, NodeExecState> get nodes => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of CueRunState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CueRunStateCopyWith<CueRunState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CueRunStateCopyWith<$Res> {
  factory $CueRunStateCopyWith(
          CueRunState value, $Res Function(CueRunState) then) =
      _$CueRunStateCopyWithImpl<$Res, CueRunState>;
  @useResult
  $Res call(
      {CueLifecycle lifecycle,
      Map<String, NodeExecState> nodes,
      String? errorMessage});
}

/// @nodoc
class _$CueRunStateCopyWithImpl<$Res, $Val extends CueRunState>
    implements $CueRunStateCopyWith<$Res> {
  _$CueRunStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CueRunState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lifecycle = null,
    Object? nodes = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      lifecycle: null == lifecycle
          ? _value.lifecycle
          : lifecycle // ignore: cast_nullable_to_non_nullable
              as CueLifecycle,
      nodes: null == nodes
          ? _value.nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as Map<String, NodeExecState>,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CueRunStateImplCopyWith<$Res>
    implements $CueRunStateCopyWith<$Res> {
  factory _$$CueRunStateImplCopyWith(
          _$CueRunStateImpl value, $Res Function(_$CueRunStateImpl) then) =
      __$$CueRunStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CueLifecycle lifecycle,
      Map<String, NodeExecState> nodes,
      String? errorMessage});
}

/// @nodoc
class __$$CueRunStateImplCopyWithImpl<$Res>
    extends _$CueRunStateCopyWithImpl<$Res, _$CueRunStateImpl>
    implements _$$CueRunStateImplCopyWith<$Res> {
  __$$CueRunStateImplCopyWithImpl(
      _$CueRunStateImpl _value, $Res Function(_$CueRunStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of CueRunState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lifecycle = null,
    Object? nodes = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$CueRunStateImpl(
      lifecycle: null == lifecycle
          ? _value.lifecycle
          : lifecycle // ignore: cast_nullable_to_non_nullable
              as CueLifecycle,
      nodes: null == nodes
          ? _value._nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as Map<String, NodeExecState>,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$CueRunStateImpl extends _CueRunState {
  const _$CueRunStateImpl(
      {required this.lifecycle,
      final Map<String, NodeExecState> nodes = const {},
      this.errorMessage})
      : _nodes = nodes,
        super._();

  @override
  final CueLifecycle lifecycle;

  /// nodeId → per-node execution state.
  final Map<String, NodeExecState> _nodes;

  /// nodeId → per-node execution state.
  @override
  @JsonKey()
  Map<String, NodeExecState> get nodes {
    if (_nodes is EqualUnmodifiableMapView) return _nodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_nodes);
  }

  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'CueRunState(lifecycle: $lifecycle, nodes: $nodes, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CueRunStateImpl &&
            (identical(other.lifecycle, lifecycle) ||
                other.lifecycle == lifecycle) &&
            const DeepCollectionEquality().equals(other._nodes, _nodes) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, lifecycle,
      const DeepCollectionEquality().hash(_nodes), errorMessage);

  /// Create a copy of CueRunState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CueRunStateImplCopyWith<_$CueRunStateImpl> get copyWith =>
      __$$CueRunStateImplCopyWithImpl<_$CueRunStateImpl>(this, _$identity);
}

abstract class _CueRunState extends CueRunState {
  const factory _CueRunState(
      {required final CueLifecycle lifecycle,
      final Map<String, NodeExecState> nodes,
      final String? errorMessage}) = _$CueRunStateImpl;
  const _CueRunState._() : super._();

  @override
  CueLifecycle get lifecycle;

  /// nodeId → per-node execution state.
  @override
  Map<String, NodeExecState> get nodes;
  @override
  String? get errorMessage;

  /// Create a copy of CueRunState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CueRunStateImplCopyWith<_$CueRunStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
