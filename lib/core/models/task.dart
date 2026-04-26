import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String name,
    String? goalId,
    @Default(Priority.medium) Priority priority,
    DateTime? deadline,
    int? estimatedDurationMinutes,
    @Default(EffortLevel.medium) EffortLevel effortLevel,
    @Default(TaskStatus.todo) TaskStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
