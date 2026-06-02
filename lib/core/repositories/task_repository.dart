import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/enums.dart';
import '../models/task.dart' as model;

abstract class TaskRepository {
  Future<void> createTask(model.Task task);
  Future<model.Task?> getTaskById(String id);
  Future<List<model.Task>> getAllTasks();
  Future<List<model.Task>> getTasksByGoalId(String goalId);
  Future<List<model.Task>> getUngroupedTasks();
  Future<List<model.Task>> getIncompleteTasks();
  Future<void> updateTask(model.Task task);
  Future<void> deleteTask(String id);
  Stream<List<model.Task>> watchTasksByGoalId(String goalId);
  Stream<List<model.Task>> watchUngroupedTasks();
  Stream<List<model.Task>> watchAllTasks();
}

class DriftTaskRepository implements TaskRepository {
  final AppDatabase _db;

  DriftTaskRepository(this._db);

  model.Task _toModel(Task row) {
    return model.Task(
      id: row.id,
      name: row.name,
      goalId: row.goalId,
      priority: Priority.values[row.priority],
      starttime: row.starttime,
      deadline: row.deadline,
      estimatedDurationMinutes: row.estimatedDurationMinutes,
      effortLevel: EffortLevel.values[row.effortLevel],
      status: TaskStatus.values[row.status],
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TasksCompanion _toCompanion(model.Task task) {
    return TasksCompanion(
      id: Value(task.id),
      name: Value(task.name),
      goalId: Value(task.goalId),
      priority: Value(task.priority.index),
      starttime: Value(task.starttime),
      deadline: Value(task.deadline),
      estimatedDurationMinutes: Value(task.estimatedDurationMinutes),
      effortLevel: Value(task.effortLevel.index),
      status: Value(task.status.index),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
    );
  }

  @override
  Future<void> createTask(model.Task task) async {
    await _db.into(_db.tasks).insert(_toCompanion(task));
  }

  @override
  Future<model.Task?> getTaskById(String id) async {
    final row = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<List<model.Task>> getAllTasks() async {
    final rows = await _db.select(_db.tasks).get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<model.Task>> getTasksByGoalId(String goalId) async {
    final rows = await (_db.select(
      _db.tasks,
    )..where((t) => t.goalId.equals(goalId))).get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<model.Task>> getUngroupedTasks() async {
    final rows = await (_db.select(
      _db.tasks,
    )..where((t) => t.goalId.isNull())).get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<model.Task>> getIncompleteTasks() async {
    final rows =
        await (_db.select(_db.tasks)..where(
              (t) => t.status.isIn([
                TaskStatus.todo.index,
                TaskStatus.inProgress.index,
              ]),
            ))
            .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> updateTask(model.Task task) async {
    await (_db.update(
      _db.tasks,
    )..where((t) => t.id.equals(task.id))).write(_toCompanion(task));
  }

  @override
  Future<void> deleteTask(String id) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<model.Task>> watchTasksByGoalId(String goalId) {
    return (_db.select(_db.tasks)..where((t) => t.goalId.equals(goalId)))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }

  @override
  Stream<List<model.Task>> watchUngroupedTasks() {
    return (_db.select(_db.tasks)..where((t) => t.goalId.isNull())).watch().map(
      (rows) => rows.map(_toModel).toList(),
    );
  }

  @override
  Stream<List<model.Task>> watchAllTasks() {
    return _db
        .select(_db.tasks)
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }
}
