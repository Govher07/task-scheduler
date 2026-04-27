import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task.dart';
import '../../../core/providers.dart';
import 'scoring.dart';

final skippedTaskIdsProvider = StateProvider<Set<String>>((ref) => {});

final allTasksProvider = FutureProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).getAllTasks();
});

final recommendedTaskProvider = Provider<Task?>((ref) {
  final tasksAsync = ref.watch(allTasksProvider);
  final skippedIds = ref.watch(skippedTaskIdsProvider);
  return tasksAsync.whenOrNull(
    data: (tasks) => recommendTask(tasks, DateTime.now(), skippedIds),
  );
});
