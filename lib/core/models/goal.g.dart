// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GoalImpl _$$GoalImplFromJson(Map<String, dynamic> json) => _$GoalImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  type:
      $enumDecodeNullable(_$GoalTypeEnumMap, json['type']) ??
      GoalType.completable,
  description: json['description'] as String?,
  starttime: json['starttime'] == null
      ? null
      : DateTime.parse(json['starttime'] as String),
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  gotRewards: json['gotRewards'] as bool? ?? false,
  rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 50,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$GoalImplToJson(_$GoalImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$GoalTypeEnumMap[instance.type]!,
      'description': instance.description,
      'starttime': instance.starttime?.toIso8601String(),
      'deadline': instance.deadline?.toIso8601String(),
      'gotRewards': instance.gotRewards,
      'rewardCoins': instance.rewardCoins,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$GoalTypeEnumMap = {
  GoalType.completable: 'completable',
  GoalType.ongoing: 'ongoing',
};
