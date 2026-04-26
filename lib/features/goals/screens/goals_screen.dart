import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/goals_provider.dart';
import '../widgets/goal_section.dart';
import '../widgets/sort_controls.dart';
import '../widgets/task_tile.dart';

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
              const SortControls(),
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
                // Navigation will be wired in Task 10
              },
            ),
            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('New Task'),
              onTap: () {
                Navigator.pop(context);
                // Navigation will be wired in Task 10
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editGoal(BuildContext context, String goalId) {
    // Navigation will be wired in Task 10
  }

  void _editTask(BuildContext context, String taskId) {
    // Navigation will be wired in Task 10
  }

  void _deleteTask(WidgetRef ref, String taskId) {
    ref.read(taskRepositoryProvider).deleteTask(taskId);
  }

  void _updateTaskStatus(WidgetRef ref, task, TaskStatus status) {
    ref.read(taskRepositoryProvider).updateTask(
          task.copyWith(status: status, updatedAt: DateTime.now()),
        );
  }
}
