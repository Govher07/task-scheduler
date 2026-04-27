import 'package:flutter_test/flutter_test.dart';
import 'package:task_scheduler/core/models/enums.dart';
import 'package:task_scheduler/core/models/task.dart';
import 'package:task_scheduler/features/recommender/providers/scoring.dart';

void main() {
  final now = DateTime(2026, 4, 24, 12, 0);

  group('scoreTask', () {
    test('high priority with no deadline scores 30', () {
      final task = Task(id: '1', name: 'Test', priority: Priority.high, createdAt: now, updatedAt: now);
      expect(scoreTask(task, now), 30);
    });

    test('medium priority with no deadline scores 20', () {
      final task = Task(id: '1', name: 'Test', priority: Priority.medium, createdAt: now, updatedAt: now);
      expect(scoreTask(task, now), 20);
    });

    test('low priority with no deadline scores 10', () {
      final task = Task(id: '1', name: 'Test', priority: Priority.low, createdAt: now, updatedAt: now);
      expect(scoreTask(task, now), 10);
    });

    test('overdue task adds 50', () {
      final task = Task(id: '1', name: 'Test', priority: Priority.low,
          deadline: now.subtract(const Duration(hours: 1)), createdAt: now, updatedAt: now);
      expect(scoreTask(task, now), 60);
    });

    test('due within 24h adds 40', () {
      final task = Task(id: '1', name: 'Test', priority: Priority.low,
          deadline: now.add(const Duration(hours: 12)), createdAt: now, updatedAt: now);
      expect(scoreTask(task, now), 50);
    });

    test('due within 3 days adds 25', () {
      final task = Task(id: '1', name: 'Test', priority: Priority.low,
          deadline: now.add(const Duration(days: 2)), createdAt: now, updatedAt: now);
      expect(scoreTask(task, now), 35);
    });

    test('due within 7 days adds 15', () {
      final task = Task(id: '1', name: 'Test', priority: Priority.low,
          deadline: now.add(const Duration(days: 5)), createdAt: now, updatedAt: now);
      expect(scoreTask(task, now), 25);
    });

    test('due later adds 0', () {
      final task = Task(id: '1', name: 'Test', priority: Priority.low,
          deadline: now.add(const Duration(days: 30)), createdAt: now, updatedAt: now);
      expect(scoreTask(task, now), 10);
    });
  });

  group('recommendTask', () {
    test('returns highest scoring task', () {
      final tasks = [
        Task(id: '1', name: 'Low', priority: Priority.low, createdAt: now, updatedAt: now),
        Task(id: '2', name: 'High overdue', priority: Priority.high,
            deadline: now.subtract(const Duration(days: 1)), createdAt: now, updatedAt: now),
        Task(id: '3', name: 'Med', priority: Priority.medium, createdAt: now, updatedAt: now),
      ];
      final result = recommendTask(tasks, now, {});
      expect(result, isNotNull);
      expect(result!.id, '2');
    });

    test('breaks ties by createdAt (older first)', () {
      final older = DateTime(2026, 4, 20);
      final newer = DateTime(2026, 4, 23);
      final tasks = [
        Task(id: '1', name: 'Newer', priority: Priority.high, createdAt: newer, updatedAt: newer),
        Task(id: '2', name: 'Older', priority: Priority.high, createdAt: older, updatedAt: older),
      ];
      final result = recommendTask(tasks, now, {});
      expect(result!.id, '2');
    });

    test('excludes skipped task ids', () {
      final tasks = [
        Task(id: '1', name: 'Best', priority: Priority.high, createdAt: now, updatedAt: now),
        Task(id: '2', name: 'Second', priority: Priority.medium, createdAt: now, updatedAt: now),
      ];
      final result = recommendTask(tasks, now, {'1'});
      expect(result!.id, '2');
    });

    test('filters out done tasks', () {
      final tasks = [
        Task(id: '1', name: 'Done', priority: Priority.high, status: TaskStatus.done, createdAt: now, updatedAt: now),
        Task(id: '2', name: 'Todo', priority: Priority.low, createdAt: now, updatedAt: now),
      ];
      final result = recommendTask(tasks, now, {});
      expect(result!.id, '2');
    });

    test('returns null when no tasks available', () {
      expect(recommendTask([], now, {}), isNull);
    });

    test('returns null when all tasks are skipped', () {
      final tasks = [Task(id: '1', name: 'Only', priority: Priority.high, createdAt: now, updatedAt: now)];
      expect(recommendTask(tasks, now, {'1'}), isNull);
    });
  });
}
