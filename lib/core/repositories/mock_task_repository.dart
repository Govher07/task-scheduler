import 'dart:async';
import '../models/task.dart';
import '../models/enums.dart';
import '../database/mock_data.dart';
import 'task_repository.dart';

class MockTaskRepository implements TaskRepository {
  final List<Task> _tasks = List.from(mockTasks);
  final _controller = StreamController<List<Task>>.broadcast();

  void _emit() => _controller.add(List.from(_tasks));

  //for mock
  void dispose() => _controller.close();

  @override
  Future<void> createTask(Task task) async {
    _tasks.add(task);
    _emit();
  }

  @override
  Future<Task?> getTaskById(String id) async {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Task>> getAllTasks() async {
    return List.from(_tasks);
  }

  @override
  Future<List<Task>> getTasksByGoalId(String goalId) async {
    return _tasks.where((t) => t.goalId == goalId).toList();
  }

  @override
  Future<List<Task>> getUngroupedTasks() async {
    return _tasks.where((t) => t.goalId == null).toList();
  }

  @override
  Future<List<Task>> getIncompleteTasks() async {
    return _tasks
        .where(
          (t) =>
              t.status == TaskStatus.todo || t.status == TaskStatus.inProgress,
        )
        .toList();
  }

  @override
  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) _tasks[index] = task;
    _emit();
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    _emit();
  }

  @override
  Stream<List<Task>> watchTasksByGoalId(String goalId) {
    _emit();
    return _controller.stream.map(
      (tasks) => tasks.where((t) => t.goalId == goalId).toList(),
    );
  }

  @override
  Stream<List<Task>> watchUngroupedTasks() {
    _emit();
    return _controller.stream.map(
      (tasks) => tasks.where((t) => t.goalId == null).toList(),
    );
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    _emit();
    return _controller.stream;
  }
}
