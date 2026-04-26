import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/database.dart';
import 'database/connection.dart';
import 'repositories/goal_repository.dart';
import 'repositories/task_repository.dart';
import 'repositories/event_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = createDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return DriftGoalRepository(ref.watch(databaseProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return DriftTaskRepository(ref.watch(databaseProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return DriftEventRepository(ref.watch(databaseProvider));
});
