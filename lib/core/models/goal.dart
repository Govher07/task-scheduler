import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

@freezed
class Goal with _$Goal {
  const factory Goal({
    required String id,
    required String name,
    @Default(GoalType.completable) GoalType type,
    String? description,
    DateTime? starttime,
    DateTime? deadline,
    @Default(false) bool gotRewards,
    @Default(50) int rewardCoins,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}
