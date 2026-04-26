import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_scheduler/core/database/database.dart' hide Task, Goal;
import 'package:task_scheduler/core/models/enums.dart';
import 'package:task_scheduler/core/models/task.dart' as model;
import 'package:task_scheduler/core/models/goal.dart' as goal_model;
import 'package:task_scheduler/core/repositories/task_repository.dart';
import 'package:task_scheduler/core/repositories/goal_repository.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository repository;
  late DriftGoalRepository goalRepository;
  final now = DateTime(2026, 4, 24);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftTaskRepository(db);
    goalRepository = DriftGoalRepository(db);
  });

  tearDown(() => db.close());

  test('createTask inserts and returns a task', () async {
    final task = model.Task(
      id: 't1',
      name: 'Go to the gym',
      priority: Priority.high,
      effortLevel: EffortLevel.high,
      createdAt: now,
      updatedAt: now,
    );

    await repository.createTask(task);
    final result = await repository.getTaskById('t1');

    expect(result, isNotNull);
    expect(result!.name, 'Go to the gym');
    expect(result.priority, Priority.high);
    expect(result.status, TaskStatus.todo);
  });

  test('getTasksByGoalId returns tasks for a specific goal', () async {
    await goalRepository.createGoal(
      goal_model.Goal(id: 'g1', name: 'Fitness', createdAt: now, updatedAt: now),
    );

    await repository.createTask(
      model.Task(id: 't1', name: 'Gym', goalId: 'g1', createdAt: now, updatedAt: now),
    );
    await repository.createTask(
      model.Task(id: 't2', name: 'Run', goalId: 'g1', createdAt: now, updatedAt: now),
    );
    await repository.createTask(
      model.Task(id: 't3', name: 'Read', createdAt: now, updatedAt: now),
    );

    final goalTasks = await repository.getTasksByGoalId('g1');

    expect(goalTasks, hasLength(2));
    expect(goalTasks.every((t) => t.goalId == 'g1'), isTrue);
  });

  test('getUngroupedTasks returns tasks with no goal', () async {
    await goalRepository.createGoal(
      goal_model.Goal(id: 'g1', name: 'Fitness', createdAt: now, updatedAt: now),
    );
    await repository.createTask(
      model.Task(id: 't1', name: 'Gym', goalId: 'g1', createdAt: now, updatedAt: now),
    );
    await repository.createTask(
      model.Task(id: 't2', name: 'Read', createdAt: now, updatedAt: now),
    );

    final ungrouped = await repository.getUngroupedTasks();

    expect(ungrouped, hasLength(1));
    expect(ungrouped.first.name, 'Read');
  });

  test('getIncompleteTasks returns only todo and inProgress tasks', () async {
    await repository.createTask(
      model.Task(id: 't1', name: 'A', status: TaskStatus.todo, createdAt: now, updatedAt: now),
    );
    await repository.createTask(
      model.Task(id: 't2', name: 'B', status: TaskStatus.inProgress, createdAt: now, updatedAt: now),
    );
    await repository.createTask(
      model.Task(id: 't3', name: 'C', status: TaskStatus.done, createdAt: now, updatedAt: now),
    );

    final incomplete = await repository.getIncompleteTasks();

    expect(incomplete, hasLength(2));
    expect(incomplete.map((t) => t.name), containsAll(['A', 'B']));
  });

  test('updateTask modifies existing task', () async {
    await repository.createTask(
      model.Task(id: 't1', name: 'Old', createdAt: now, updatedAt: now),
    );

    final task = await repository.getTaskById('t1');
    await repository.updateTask(task!.copyWith(name: 'New', status: TaskStatus.done));

    final updated = await repository.getTaskById('t1');
    expect(updated!.name, 'New');
    expect(updated.status, TaskStatus.done);
  });

  test('deleteTask removes the task', () async {
    await repository.createTask(
      model.Task(id: 't1', name: 'Task', createdAt: now, updatedAt: now),
    );

    await repository.deleteTask('t1');
    final result = await repository.getTaskById('t1');

    expect(result, isNull);
  });

  test('watchTasksByGoalId emits updates', () async {
    await goalRepository.createGoal(
      goal_model.Goal(id: 'g1', name: 'Goal', createdAt: now, updatedAt: now),
    );

    final stream = repository.watchTasksByGoalId('g1');

    final future = expectLater(
      stream,
      emitsInOrder([
        hasLength(0),
        hasLength(1),
      ]),
    );

    await Future.delayed(Duration.zero);

    await repository.createTask(
      model.Task(id: 't1', name: 'Task', goalId: 'g1', createdAt: now, updatedAt: now),
    );

    await future;
  });
}
