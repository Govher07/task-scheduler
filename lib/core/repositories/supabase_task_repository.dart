import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enums.dart';
import '../models/task.dart';
import 'task_repository.dart';

class SupabaseTaskRepository implements TaskRepository {
  final SupabaseClient _client;

  SupabaseTaskRepository(this._client);

  Task _fromRow(Map<String, dynamic> row) {
    return Task(
      id: row['id'] as String,
      name: row['name'] as String,
      goalId: row['goal_id'] as String?,
      priority: Priority.values.byName(row['priority'] as String),
      deadline: row['deadline'] != null
          ? DateTime.parse(row['deadline'] as String)
          : null,
      estimatedDurationMinutes: row['estimated_duration_minutes'] as int?,
      effortLevel: EffortLevel.values.byName(row['effort_level'] as String),
      status: TaskStatus.values.byName(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> _toRow(Task task) {
    return {
      'id': task.id,
      'name': task.name,
      'goal_id': task.goalId,
      'priority': task.priority.name,
      'deadline': task.deadline?.toIso8601String(),
      'estimated_duration_minutes': task.estimatedDurationMinutes,
      'effort_level': task.effortLevel.name,
      'status': task.status.name,
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
    };
  }

  @override
  Future<void> createTask(Task task) async {
    await _client.from('tasks').insert(_toRow(task));
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final row =
        await _client.from('tasks').select().eq('id', id).maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<Task>> getAllTasks() async {
    final rows = await _client.from('tasks').select();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Task>> getTasksByGoalId(String goalId) async {
    final rows =
        await _client.from('tasks').select().eq('goal_id', goalId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Task>> getUngroupedTasks() async {
    final rows =
        await _client.from('tasks').select().isFilter('goal_id', null);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Task>> getIncompleteTasks() async {
    final rows = await _client
        .from('tasks')
        .select()
        .inFilter('status', ['todo', 'inProgress']);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> updateTask(Task task) async {
    await _client.from('tasks').update(_toRow(task)).eq('id', task.id);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  @override
  Stream<List<Task>> watchTasksByGoalId(String goalId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('goal_id', goalId)
        .map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Stream<List<Task>> watchUngroupedTasks() {
    return _client.from('tasks').stream(primaryKey: ['id']).map(
        (rows) => rows.map(_fromRow).where((t) => t.goalId == null).toList());
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id']).map((rows) => rows.map(_fromRow).toList());
  }
}
