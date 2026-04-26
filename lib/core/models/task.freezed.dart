// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Task _$TaskFromJson(Map<String, dynamic> json) {
  return _Task.fromJson(json);
}

/// @nodoc
mixin _$Task {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get goalId => throw _privateConstructorUsedError;
  Priority get priority => throw _privateConstructorUsedError;
  DateTime? get deadline => throw _privateConstructorUsedError;
  int? get estimatedDurationMinutes => throw _privateConstructorUsedError;
  EffortLevel get effortLevel => throw _privateConstructorUsedError;
  TaskStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskCopyWith<Task> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) then) =
      _$TaskCopyWithImpl<$Res, Task>;
  @useResult
  $Res call({
    String id,
    String name,
    String? goalId,
    Priority priority,
    DateTime? deadline,
    int? estimatedDurationMinutes,
    EffortLevel effortLevel,
    TaskStatus status,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$TaskCopyWithImpl<$Res, $Val extends Task>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? goalId = freezed,
    Object? priority = null,
    Object? deadline = freezed,
    Object? estimatedDurationMinutes = freezed,
    Object? effortLevel = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            goalId: freezed == goalId
                ? _value.goalId
                : goalId // ignore: cast_nullable_to_non_nullable
                      as String?,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as Priority,
            deadline: freezed == deadline
                ? _value.deadline
                : deadline // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            estimatedDurationMinutes: freezed == estimatedDurationMinutes
                ? _value.estimatedDurationMinutes
                : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            effortLevel: null == effortLevel
                ? _value.effortLevel
                : effortLevel // ignore: cast_nullable_to_non_nullable
                      as EffortLevel,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TaskStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskImplCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$$TaskImplCopyWith(
    _$TaskImpl value,
    $Res Function(_$TaskImpl) then,
  ) = __$$TaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? goalId,
    Priority priority,
    DateTime? deadline,
    int? estimatedDurationMinutes,
    EffortLevel effortLevel,
    TaskStatus status,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$TaskImplCopyWithImpl<$Res>
    extends _$TaskCopyWithImpl<$Res, _$TaskImpl>
    implements _$$TaskImplCopyWith<$Res> {
  __$$TaskImplCopyWithImpl(_$TaskImpl _value, $Res Function(_$TaskImpl) _then)
    : super(_value, _then);

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? goalId = freezed,
    Object? priority = null,
    Object? deadline = freezed,
    Object? estimatedDurationMinutes = freezed,
    Object? effortLevel = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$TaskImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        goalId: freezed == goalId
            ? _value.goalId
            : goalId // ignore: cast_nullable_to_non_nullable
                  as String?,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as Priority,
        deadline: freezed == deadline
            ? _value.deadline
            : deadline // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        estimatedDurationMinutes: freezed == estimatedDurationMinutes
            ? _value.estimatedDurationMinutes
            : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        effortLevel: null == effortLevel
            ? _value.effortLevel
            : effortLevel // ignore: cast_nullable_to_non_nullable
                  as EffortLevel,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TaskStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskImpl implements _Task {
  const _$TaskImpl({
    required this.id,
    required this.name,
    this.goalId,
    this.priority = Priority.medium,
    this.deadline,
    this.estimatedDurationMinutes,
    this.effortLevel = EffortLevel.medium,
    this.status = TaskStatus.todo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$TaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? goalId;
  @override
  @JsonKey()
  final Priority priority;
  @override
  final DateTime? deadline;
  @override
  final int? estimatedDurationMinutes;
  @override
  @JsonKey()
  final EffortLevel effortLevel;
  @override
  @JsonKey()
  final TaskStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Task(id: $id, name: $name, goalId: $goalId, priority: $priority, deadline: $deadline, estimatedDurationMinutes: $estimatedDurationMinutes, effortLevel: $effortLevel, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.goalId, goalId) || other.goalId == goalId) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(
                  other.estimatedDurationMinutes,
                  estimatedDurationMinutes,
                ) ||
                other.estimatedDurationMinutes == estimatedDurationMinutes) &&
            (identical(other.effortLevel, effortLevel) ||
                other.effortLevel == effortLevel) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    goalId,
    priority,
    deadline,
    estimatedDurationMinutes,
    effortLevel,
    status,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      __$$TaskImplCopyWithImpl<_$TaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskImplToJson(this);
  }
}

abstract class _Task implements Task {
  const factory _Task({
    required final String id,
    required final String name,
    final String? goalId,
    final Priority priority,
    final DateTime? deadline,
    final int? estimatedDurationMinutes,
    final EffortLevel effortLevel,
    final TaskStatus status,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$TaskImpl;

  factory _Task.fromJson(Map<String, dynamic> json) = _$TaskImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get goalId;
  @override
  Priority get priority;
  @override
  DateTime? get deadline;
  @override
  int? get estimatedDurationMinutes;
  @override
  EffortLevel get effortLevel;
  @override
  TaskStatus get status;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
