import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/enums.dart';
import '../models/goal.dart' as model;

abstract class GoalRepository {
  Future<void> createGoal(model.Goal goal);
  Future<model.Goal?> getGoalById(String id);
  Future<List<model.Goal>> getAllGoals();
  Future<void> updateGoal(model.Goal goal);
  Future<void> deleteGoal(String id);
  Stream<List<model.Goal>> watchAllGoals();
}

class DriftGoalRepository implements GoalRepository {
  final AppDatabase _db;

  DriftGoalRepository(this._db);

  model.Goal _toModel(Goal row) {
    return model.Goal(
      id: row.id,
      name: row.name,
      type: GoalType.values[row.type],
      description: row.description,
      starttime: row.starttime,
      deadline: row.deadline,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  GoalsCompanion _toCompanion(model.Goal goal) {
    return GoalsCompanion(
      id: Value(goal.id),
      name: Value(goal.name),
      type: Value(goal.type.index),
      description: Value(goal.description),
      starttime: Value(goal.starttime),
      deadline: Value(goal.deadline),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt),
    );
  }

  @override
  Future<void> createGoal(model.Goal goal) async {
    await _db.into(_db.goals).insert(_toCompanion(goal));
  }

  @override
  Future<model.Goal?> getGoalById(String id) async {
    final row = await (_db.select(_db.goals)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<List<model.Goal>> getAllGoals() async {
    final rows = await _db.select(_db.goals).get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> updateGoal(model.Goal goal) async {
    await (_db.update(_db.goals)..where((t) => t.id.equals(goal.id)))
        .write(_toCompanion(goal));
  }

  @override
  Future<void> deleteGoal(String id) async {
    await (_db.delete(_db.goals)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<model.Goal>> watchAllGoals() {
    return _db.select(_db.goals).watch().map(
          (rows) => rows.map(_toModel).toList(),
        );
  }
}
