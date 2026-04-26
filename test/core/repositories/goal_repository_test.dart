import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_scheduler/core/database/database.dart' hide Goal;
import 'package:task_scheduler/core/models/enums.dart';
import 'package:task_scheduler/core/models/goal.dart';
import 'package:task_scheduler/core/repositories/goal_repository.dart';

void main() {
  late AppDatabase db;
  late DriftGoalRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftGoalRepository(db);
  });

  tearDown(() => db.close());

  test('createGoal inserts and returns a goal', () async {
    final goal = Goal(
      id: 'g1',
      name: 'Get healthier',
      type: GoalType.completable,
      createdAt: DateTime(2026, 4, 24),
      updatedAt: DateTime(2026, 4, 24),
    );

    await repository.createGoal(goal);
    final result = await repository.getGoalById('g1');

    expect(result, isNotNull);
    expect(result!.name, 'Get healthier');
    expect(result.type, GoalType.completable);
  });

  test('getAllGoals returns all goals', () async {
    final now = DateTime(2026, 4, 24);
    await repository.createGoal(Goal(id: 'g1', name: 'Goal 1', createdAt: now, updatedAt: now));
    await repository.createGoal(Goal(id: 'g2', name: 'Goal 2', createdAt: now, updatedAt: now));

    final goals = await repository.getAllGoals();

    expect(goals, hasLength(2));
  });

  test('updateGoal modifies existing goal', () async {
    final now = DateTime(2026, 4, 24);
    final goal = Goal(id: 'g1', name: 'Old name', createdAt: now, updatedAt: now);
    await repository.createGoal(goal);

    await repository.updateGoal(goal.copyWith(name: 'New name'));
    final result = await repository.getGoalById('g1');

    expect(result!.name, 'New name');
  });

  test('deleteGoal removes the goal', () async {
    final now = DateTime(2026, 4, 24);
    await repository.createGoal(Goal(id: 'g1', name: 'Goal', createdAt: now, updatedAt: now));

    await repository.deleteGoal('g1');
    final result = await repository.getGoalById('g1');

    expect(result, isNull);
  });

  test('watchAllGoals emits updates', () async {
    final now = DateTime(2026, 4, 24);
    final stream = repository.watchAllGoals();

    final future = expectLater(
      stream,
      emitsInOrder([
        hasLength(0),
        hasLength(1),
      ]),
    );

    // Yield control so the stream can emit the initial empty list before inserting
    await Future<void>.delayed(Duration.zero);
    await repository.createGoal(Goal(id: 'g1', name: 'Goal', createdAt: now, updatedAt: now));

    await future;
  });
}
