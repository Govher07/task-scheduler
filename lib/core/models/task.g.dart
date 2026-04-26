// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskImpl _$$TaskImplFromJson(Map<String, dynamic> json) => _$TaskImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  goalId: json['goalId'] as String?,
  priority:
      $enumDecodeNullable(_$PriorityEnumMap, json['priority']) ??
      Priority.medium,
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num?)?.toInt(),
  effortLevel:
      $enumDecodeNullable(_$EffortLevelEnumMap, json['effortLevel']) ??
      EffortLevel.medium,
  status:
      $enumDecodeNullable(_$TaskStatusEnumMap, json['status']) ??
      TaskStatus.todo,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$TaskImplToJson(_$TaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'goalId': instance.goalId,
      'priority': _$PriorityEnumMap[instance.priority]!,
      'deadline': instance.deadline?.toIso8601String(),
      'estimatedDurationMinutes': instance.estimatedDurationMinutes,
      'effortLevel': _$EffortLevelEnumMap[instance.effortLevel]!,
      'status': _$TaskStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$PriorityEnumMap = {
  Priority.low: 'low',
  Priority.medium: 'medium',
  Priority.high: 'high',
};

const _$EffortLevelEnumMap = {
  EffortLevel.low: 'low',
  EffortLevel.medium: 'medium',
  EffortLevel.high: 'high',
};

const _$TaskStatusEnumMap = {
  TaskStatus.todo: 'todo',
  TaskStatus.inProgress: 'inProgress',
  TaskStatus.done: 'done',
};
