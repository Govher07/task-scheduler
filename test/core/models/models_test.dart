import 'package:flutter_test/flutter_test.dart';
import 'package:task_scheduler/core/models/enums.dart';
import 'package:task_scheduler/core/models/task.dart';
import 'package:task_scheduler/core/models/event.dart';
import 'package:task_scheduler/core/models/goal.dart';

void main() {
  final now = DateTime(2026, 4, 24, 12, 0);

  group('Task', () {
    test('creates with defaults', () {
      final task = Task(
        id: '1',
        name: 'Go to the gym',
        createdAt: now,
        updatedAt: now,
      );

      expect(task.priority, Priority.medium);
      expect(task.effortLevel, EffortLevel.medium);
      expect(task.status, TaskStatus.todo);
      expect(task.goalId, isNull);
      expect(task.deadline, isNull);
    });

    test('copyWith updates fields', () {
      final task = Task(id: '1', name: 'Test', createdAt: now, updatedAt: now);
      final updated = task.copyWith(status: TaskStatus.done);

      expect(updated.status, TaskStatus.done);
      expect(updated.name, 'Test');
    });

    test('serializes to and from JSON', () {
      final task = Task(
        id: '1',
        name: 'Go to the gym',
        goalId: 'goal-1',
        priority: Priority.high,
        deadline: DateTime(2026, 5, 1),
        estimatedDurationMinutes: 60,
        effortLevel: EffortLevel.high,
        status: TaskStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      );

      final json = task.toJson();
      final restored = Task.fromJson(json);

      expect(restored, task);
    });

    test('equality works', () {
      final a = Task(id: '1', name: 'Test', createdAt: now, updatedAt: now);
      final b = Task(id: '1', name: 'Test', createdAt: now, updatedAt: now);
      final c = Task(id: '2', name: 'Test', createdAt: now, updatedAt: now);

      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('Event', () {
    test('creates with defaults', () {
      final event = Event(
        id: '1',
        name: 'Meeting',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      );

      expect(event.isRepeating, false);
      expect(event.taskId, isNull);
      expect(event.recurrenceRule, isNull);
    });

    test('serializes to and from JSON', () {
      final event = Event(
        id: '1',
        name: 'Daily gym',
        taskId: 'task-1',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        isRepeating: true,
        recurrenceRule: 'RRULE:FREQ=DAILY',
        createdAt: now,
        updatedAt: now,
      );

      final json = event.toJson();
      final restored = Event.fromJson(json);

      expect(restored, event);
    });
  });

  group('Goal', () {
    test('creates with defaults', () {
      final goal = Goal(
        id: '1',
        name: 'Get healthier',
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.type, GoalType.completable);
      expect(goal.description, isNull);
    });

    test('ongoing goal type', () {
      final goal = Goal(
        id: '1',
        name: 'Stay healthy',
        type: GoalType.ongoing,
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.type, GoalType.ongoing);
    });

    test('serializes to and from JSON', () {
      final goal = Goal(
        id: '1',
        name: 'Get healthier',
        type: GoalType.completable,
        description: 'Focus on fitness',
        createdAt: now,
        updatedAt: now,
      );

      final json = goal.toJson();
      final restored = Goal.fromJson(json);

      expect(restored, goal);
    });
  });
}
