import 'dart:async';
import '../models/goal.dart';
import '../database/mock_data.dart';
import 'goal_repository.dart';

class MockGoalRepository implements GoalRepository {
  final List<Goal> _goals = List.from(mockGoals);
  final _controller = StreamController<List<Goal>>.broadcast();

  void _emit() => _controller.add(List.from(_goals));

  //for mock
  void dispose() => _controller.close();

  @override
  Future<void> createGoal(Goal goal) async {
    _goals.add(goal);
    _emit();
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Goal>> getAllGoals() async {
    return List.from(_goals);
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) _goals[index] = goal;
    _emit();
  }

  @override
  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    _emit();
  }

  @override
  Stream<List<Goal>> watchAllGoals() {
    // 用 Stream.multi 確保訂閱後才發射
    return Stream.multi((controller) {
      controller.add(List.from(_goals)); // 先給一次當前資料
      _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    });
  }
}
