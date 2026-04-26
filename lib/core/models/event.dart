import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';
part 'event.g.dart';

@freezed
class Event with _$Event {
  const factory Event({
    required String id,
    required String name,
    String? taskId,
    required DateTime startTime,
    required DateTime endTime,
    @Default(false) bool isRepeating,
    String? recurrenceRule,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}
