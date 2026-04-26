import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/goal.dart';
import '../../../core/models/task.dart';
import '../../../core/providers.dart';

enum SortField { priority, deadline, effort }

final sortFieldProvider = StateProvider<SortField>((ref) => SortField.priority);

final goalsListProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalRepositoryProvider).watchAllGoals();
});

final tasksByGoalProvider = StreamProvider.family<List<Task>, String>((ref, goalId) {
  return ref.watch(taskRepositoryProvider).watchTasksByGoalId(goalId);
});

final ungroupedTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchUngroupedTasks();
});

final sortedTasksProvider = Provider.family<List<Task>, List<Task>>((ref, tasks) {
  final sortField = ref.watch(sortFieldProvider);
  final sorted = List<Task>.from(tasks);

  switch (sortField) {
    case SortField.priority:
      sorted.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    case SortField.deadline:
      sorted.sort((a, b) {
        if (a.deadline == null && b.deadline == null) return 0;
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      });
    case SortField.effort:
      sorted.sort((a, b) => b.effortLevel.index.compareTo(a.effortLevel.index));
  }

  return sorted;
});

double goalProgress(List<Task> tasks) {
  if (tasks.isEmpty) return 0.0;
  final doneCount = tasks.where((t) => t.status == TaskStatus.done).length;
  return doneCount / tasks.length;
}
