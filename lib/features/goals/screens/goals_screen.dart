import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/goals_provider.dart';
import '../widgets/goal_section.dart';
import '../widgets/sort_controls.dart';
import '../widgets/task_tile.dart';
import '../../../core/widgets/seasonal_background.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsListProvider);
    final ungroupedAsync = ref.watch(ungroupedTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Goals')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (goals) {
          final ungroupedTasks = ungroupedAsync.valueOrNull ?? [];

          if (goals.isEmpty && ungroupedTasks.isEmpty) {
            return const EmptyState(
              icon: Icons.flag_outlined,
              title: 'No goals yet',
              subtitle: 'Tap + to create your first goal or task',
            );
          }

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                child: SnowCapped(
                  borderRadius: 22,
                  snowHeight: 10,
                  horizontalInset: 10,
                  snowWidthFactor: 0.92,
                  child: const SortControls(),
                ),
              ),

              ...goals.map((goal) {
                final tasksAsync = ref.watch(tasksByGoalProvider(goal.id));
                final tasks = tasksAsync.valueOrNull ?? [];

                return GoalSection(
                  goal: goal,
                  tasks: tasks,
                  onTaskTap: (task) => _editTask(context, task.id),
                  onTaskDelete: (task) => _deleteTask(ref, task.id),
                  onTaskStatusChanged: (task, status) =>
                      _updateTaskStatus(ref, task, status),
                  onGoalTap: () => _editGoal(context, goal.id),
                );
              }),
              if (ungroupedTasks.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16),
                  child: Text(
                    'Ungrouped',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                ...ref.watch(sortedTasksProvider(ungroupedTasks)).map((task) {
                  return TaskTile(
                    task: task,
                    onTap: () => _editTask(context, task.id),
                    onDelete: () => _deleteTask(ref, task.id),
                    onStatusChanged: (status) =>
                        _updateTaskStatus(ref, task, status),
                  );
                }),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('New Goal'),
              onTap: () {
                Navigator.pop(context);
                _createGoal(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('New Task'),
              onTap: () {
                Navigator.pop(context);
                _createTask(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createGoal(BuildContext context) {
    context.push('/goals/goal/new');
  }

  void _createTask(BuildContext context) {
    context.push('/goals/task/new');
  }

  void _editGoal(BuildContext context, String goalId) {
    context.push('/goals/goal/$goalId');
  }

  void _editTask(BuildContext context, String taskId) {
    context.push('/goals/task/$taskId');
  }

  void _deleteTask(WidgetRef ref, String taskId) {
    ref.read(taskRepositoryProvider).deleteTask(taskId);
  }

  Future<void> _updateTaskStatus(WidgetRef ref, task, TaskStatus status) async {
    final now = DateTime.now();
    if (status == TaskStatus.done && !task.gotRewards) {
      await ref.read(rewardServiceProvider).grantTaskReward(task);
      await ref
          .read(taskRepositoryProvider)
          .updateTask(
            task.copyWith(status: status, gotRewards: true, updatedAt: now),
          );
    } else {
      await ref
          .read(taskRepositoryProvider)
          .updateTask(task.copyWith(status: status, updatedAt: now));
    }

    if (task.goalId != null && status == TaskStatus.done) {
      final goalTasks = await ref
          .read(taskRepositoryProvider)
          .getTasksByGoalId(task.goalId!);
      final allDone =
          goalTasks.isNotEmpty &&
          goalTasks.every((t) => t.status == TaskStatus.done);
      if (allDone) {
        final goal = await ref
            .read(goalRepositoryProvider)
            .getGoalById(task.goalId!);
        if (goal != null && !goal.gotRewards) {
          await ref
              .read(rewardServiceProvider)
              .grantGoalReward(goal, goalTasks.length);
        }
      }
    }
  }
}
