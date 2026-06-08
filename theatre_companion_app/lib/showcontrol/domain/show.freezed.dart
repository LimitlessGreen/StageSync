// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'show.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CueTiming {
  double get preWaitMs => throw _privateConstructorUsedError;
  double get postWaitMs => throw _privateConstructorUsedError;
  bool get autoContinue => throw _privateConstructorUsedError;
  double? get durationMs => throw _privateConstructorUsedError;

  /// Create a copy of CueTiming
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CueTimingCopyWith<CueTiming> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CueTimingCopyWith<$Res> {
  factory $CueTimingCopyWith(CueTiming value, $Res Function(CueTiming) then) =
      _$CueTimingCopyWithImpl<$Res, CueTiming>;
  @useResult
  $Res call(
      {double preWaitMs,
      double postWaitMs,
      bool autoContinue,
      double? durationMs});
}

/// @nodoc
class _$CueTimingCopyWithImpl<$Res, $Val extends CueTiming>
    implements $CueTimingCopyWith<$Res> {
  _$CueTimingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CueTiming
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? preWaitMs = null,
    Object? postWaitMs = null,
    Object? autoContinue = null,
    Object? durationMs = freezed,
  }) {
    return _then(_value.copyWith(
      preWaitMs: null == preWaitMs
          ? _value.preWaitMs
          : preWaitMs // ignore: cast_nullable_to_non_nullable
              as double,
      postWaitMs: null == postWaitMs
          ? _value.postWaitMs
          : postWaitMs // ignore: cast_nullable_to_non_nullable
              as double,
      autoContinue: null == autoContinue
          ? _value.autoContinue
          : autoContinue // ignore: cast_nullable_to_non_nullable
              as bool,
      durationMs: freezed == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CueTimingImplCopyWith<$Res>
    implements $CueTimingCopyWith<$Res> {
  factory _$$CueTimingImplCopyWith(
          _$CueTimingImpl value, $Res Function(_$CueTimingImpl) then) =
      __$$CueTimingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double preWaitMs,
      double postWaitMs,
      bool autoContinue,
      double? durationMs});
}

/// @nodoc
class __$$CueTimingImplCopyWithImpl<$Res>
    extends _$CueTimingCopyWithImpl<$Res, _$CueTimingImpl>
    implements _$$CueTimingImplCopyWith<$Res> {
  __$$CueTimingImplCopyWithImpl(
      _$CueTimingImpl _value, $Res Function(_$CueTimingImpl) _then)
      : super(_value, _then);

  /// Create a copy of CueTiming
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? preWaitMs = null,
    Object? postWaitMs = null,
    Object? autoContinue = null,
    Object? durationMs = freezed,
  }) {
    return _then(_$CueTimingImpl(
      preWaitMs: null == preWaitMs
          ? _value.preWaitMs
          : preWaitMs // ignore: cast_nullable_to_non_nullable
              as double,
      postWaitMs: null == postWaitMs
          ? _value.postWaitMs
          : postWaitMs // ignore: cast_nullable_to_non_nullable
              as double,
      autoContinue: null == autoContinue
          ? _value.autoContinue
          : autoContinue // ignore: cast_nullable_to_non_nullable
              as bool,
      durationMs: freezed == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc

class _$CueTimingImpl implements _CueTiming {
  const _$CueTimingImpl(
      {this.preWaitMs = 0.0,
      this.postWaitMs = 0.0,
      this.autoContinue = false,
      this.durationMs});

  @override
  @JsonKey()
  final double preWaitMs;
  @override
  @JsonKey()
  final double postWaitMs;
  @override
  @JsonKey()
  final bool autoContinue;
  @override
  final double? durationMs;

  @override
  String toString() {
    return 'CueTiming(preWaitMs: $preWaitMs, postWaitMs: $postWaitMs, autoContinue: $autoContinue, durationMs: $durationMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CueTimingImpl &&
            (identical(other.preWaitMs, preWaitMs) ||
                other.preWaitMs == preWaitMs) &&
            (identical(other.postWaitMs, postWaitMs) ||
                other.postWaitMs == postWaitMs) &&
            (identical(other.autoContinue, autoContinue) ||
                other.autoContinue == autoContinue) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, preWaitMs, postWaitMs, autoContinue, durationMs);

  /// Create a copy of CueTiming
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CueTimingImplCopyWith<_$CueTimingImpl> get copyWith =>
      __$$CueTimingImplCopyWithImpl<_$CueTimingImpl>(this, _$identity);
}

abstract class _CueTiming implements CueTiming {
  const factory _CueTiming(
      {final double preWaitMs,
      final double postWaitMs,
      final bool autoContinue,
      final double? durationMs}) = _$CueTimingImpl;

  @override
  double get preWaitMs;
  @override
  double get postWaitMs;
  @override
  bool get autoContinue;
  @override
  double? get durationMs;

  /// Create a copy of CueTiming
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CueTimingImplCopyWith<_$CueTimingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Cue {
  String get id => throw _privateConstructorUsedError;
  String get number =>
      throw _privateConstructorUsedError; // display number: "1", "1.5", "2A"
  String get label => throw _privateConstructorUsedError;
  CueParams get params => throw _privateConstructorUsedError;
  CueTrigger get trigger => throw _privateConstructorUsedError;
  CueTiming get timing => throw _privateConstructorUsedError;
  String? get logicalOutputId => throw _privateConstructorUsedError;
  bool get armed => throw _privateConstructorUsedError;

  /// Create a copy of Cue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CueCopyWith<Cue> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CueCopyWith<$Res> {
  factory $CueCopyWith(Cue value, $Res Function(Cue) then) =
      _$CueCopyWithImpl<$Res, Cue>;
  @useResult
  $Res call(
      {String id,
      String number,
      String label,
      CueParams params,
      CueTrigger trigger,
      CueTiming timing,
      String? logicalOutputId,
      bool armed});

  $CueTimingCopyWith<$Res> get timing;
}

/// @nodoc
class _$CueCopyWithImpl<$Res, $Val extends Cue> implements $CueCopyWith<$Res> {
  _$CueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Cue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? number = null,
    Object? label = null,
    Object? params = null,
    Object? trigger = null,
    Object? timing = null,
    Object? logicalOutputId = freezed,
    Object? armed = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      params: null == params
          ? _value.params
          : params // ignore: cast_nullable_to_non_nullable
              as CueParams,
      trigger: null == trigger
          ? _value.trigger
          : trigger // ignore: cast_nullable_to_non_nullable
              as CueTrigger,
      timing: null == timing
          ? _value.timing
          : timing // ignore: cast_nullable_to_non_nullable
              as CueTiming,
      logicalOutputId: freezed == logicalOutputId
          ? _value.logicalOutputId
          : logicalOutputId // ignore: cast_nullable_to_non_nullable
              as String?,
      armed: null == armed
          ? _value.armed
          : armed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of Cue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CueTimingCopyWith<$Res> get timing {
    return $CueTimingCopyWith<$Res>(_value.timing, (value) {
      return _then(_value.copyWith(timing: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CueImplCopyWith<$Res> implements $CueCopyWith<$Res> {
  factory _$$CueImplCopyWith(_$CueImpl value, $Res Function(_$CueImpl) then) =
      __$$CueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String number,
      String label,
      CueParams params,
      CueTrigger trigger,
      CueTiming timing,
      String? logicalOutputId,
      bool armed});

  @override
  $CueTimingCopyWith<$Res> get timing;
}

/// @nodoc
class __$$CueImplCopyWithImpl<$Res> extends _$CueCopyWithImpl<$Res, _$CueImpl>
    implements _$$CueImplCopyWith<$Res> {
  __$$CueImplCopyWithImpl(_$CueImpl _value, $Res Function(_$CueImpl) _then)
      : super(_value, _then);

  /// Create a copy of Cue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? number = null,
    Object? label = null,
    Object? params = null,
    Object? trigger = null,
    Object? timing = null,
    Object? logicalOutputId = freezed,
    Object? armed = null,
  }) {
    return _then(_$CueImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      params: null == params
          ? _value.params
          : params // ignore: cast_nullable_to_non_nullable
              as CueParams,
      trigger: null == trigger
          ? _value.trigger
          : trigger // ignore: cast_nullable_to_non_nullable
              as CueTrigger,
      timing: null == timing
          ? _value.timing
          : timing // ignore: cast_nullable_to_non_nullable
              as CueTiming,
      logicalOutputId: freezed == logicalOutputId
          ? _value.logicalOutputId
          : logicalOutputId // ignore: cast_nullable_to_non_nullable
              as String?,
      armed: null == armed
          ? _value.armed
          : armed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$CueImpl extends _Cue {
  const _$CueImpl(
      {required this.id,
      required this.number,
      required this.label,
      required this.params,
      this.trigger = const CueTrigger(),
      this.timing = const CueTiming(),
      this.logicalOutputId,
      this.armed = false})
      : super._();

  @override
  final String id;
  @override
  final String number;
// display number: "1", "1.5", "2A"
  @override
  final String label;
  @override
  final CueParams params;
  @override
  @JsonKey()
  final CueTrigger trigger;
  @override
  @JsonKey()
  final CueTiming timing;
  @override
  final String? logicalOutputId;
  @override
  @JsonKey()
  final bool armed;

  @override
  String toString() {
    return 'Cue(id: $id, number: $number, label: $label, params: $params, trigger: $trigger, timing: $timing, logicalOutputId: $logicalOutputId, armed: $armed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CueImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.params, params) || other.params == params) &&
            (identical(other.trigger, trigger) || other.trigger == trigger) &&
            (identical(other.timing, timing) || other.timing == timing) &&
            (identical(other.logicalOutputId, logicalOutputId) ||
                other.logicalOutputId == logicalOutputId) &&
            (identical(other.armed, armed) || other.armed == armed));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, number, label, params,
      trigger, timing, logicalOutputId, armed);

  /// Create a copy of Cue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CueImplCopyWith<_$CueImpl> get copyWith =>
      __$$CueImplCopyWithImpl<_$CueImpl>(this, _$identity);
}

abstract class _Cue extends Cue {
  const factory _Cue(
      {required final String id,
      required final String number,
      required final String label,
      required final CueParams params,
      final CueTrigger trigger,
      final CueTiming timing,
      final String? logicalOutputId,
      final bool armed}) = _$CueImpl;
  const _Cue._() : super._();

  @override
  String get id;
  @override
  String get number; // display number: "1", "1.5", "2A"
  @override
  String get label;
  @override
  CueParams get params;
  @override
  CueTrigger get trigger;
  @override
  CueTiming get timing;
  @override
  String? get logicalOutputId;
  @override
  bool get armed;

  /// Create a copy of Cue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CueImplCopyWith<_$CueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CueList {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  CueListPlayMode get playMode => throw _privateConstructorUsedError;
  List<Cue> get cues => throw _privateConstructorUsedError;

  /// Create a copy of CueList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CueListCopyWith<CueList> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CueListCopyWith<$Res> {
  factory $CueListCopyWith(CueList value, $Res Function(CueList) then) =
      _$CueListCopyWithImpl<$Res, CueList>;
  @useResult
  $Res call({String id, String name, CueListPlayMode playMode, List<Cue> cues});
}

/// @nodoc
class _$CueListCopyWithImpl<$Res, $Val extends CueList>
    implements $CueListCopyWith<$Res> {
  _$CueListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CueList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? playMode = null,
    Object? cues = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      playMode: null == playMode
          ? _value.playMode
          : playMode // ignore: cast_nullable_to_non_nullable
              as CueListPlayMode,
      cues: null == cues
          ? _value.cues
          : cues // ignore: cast_nullable_to_non_nullable
              as List<Cue>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CueListImplCopyWith<$Res> implements $CueListCopyWith<$Res> {
  factory _$$CueListImplCopyWith(
          _$CueListImpl value, $Res Function(_$CueListImpl) then) =
      __$$CueListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, CueListPlayMode playMode, List<Cue> cues});
}

/// @nodoc
class __$$CueListImplCopyWithImpl<$Res>
    extends _$CueListCopyWithImpl<$Res, _$CueListImpl>
    implements _$$CueListImplCopyWith<$Res> {
  __$$CueListImplCopyWithImpl(
      _$CueListImpl _value, $Res Function(_$CueListImpl) _then)
      : super(_value, _then);

  /// Create a copy of CueList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? playMode = null,
    Object? cues = null,
  }) {
    return _then(_$CueListImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      playMode: null == playMode
          ? _value.playMode
          : playMode // ignore: cast_nullable_to_non_nullable
              as CueListPlayMode,
      cues: null == cues
          ? _value._cues
          : cues // ignore: cast_nullable_to_non_nullable
              as List<Cue>,
    ));
  }
}

/// @nodoc

class _$CueListImpl extends _CueList {
  const _$CueListImpl(
      {required this.id,
      required this.name,
      this.playMode = CueListPlayMode.sequential,
      required final List<Cue> cues})
      : _cues = cues,
        super._();

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final CueListPlayMode playMode;
  final List<Cue> _cues;
  @override
  List<Cue> get cues {
    if (_cues is EqualUnmodifiableListView) return _cues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cues);
  }

  @override
  String toString() {
    return 'CueList(id: $id, name: $name, playMode: $playMode, cues: $cues)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CueListImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.playMode, playMode) ||
                other.playMode == playMode) &&
            const DeepCollectionEquality().equals(other._cues, _cues));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, playMode,
      const DeepCollectionEquality().hash(_cues));

  /// Create a copy of CueList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CueListImplCopyWith<_$CueListImpl> get copyWith =>
      __$$CueListImplCopyWithImpl<_$CueListImpl>(this, _$identity);
}

abstract class _CueList extends CueList {
  const factory _CueList(
      {required final String id,
      required final String name,
      final CueListPlayMode playMode,
      required final List<Cue> cues}) = _$CueListImpl;
  const _CueList._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  CueListPlayMode get playMode;
  @override
  List<Cue> get cues;

  /// Create a copy of CueList
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CueListImplCopyWith<_$CueListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
