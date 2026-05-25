import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/goal.dart';
import '../../../core/models/task.dart';
import '../../../core/services/reward_service.dart';
import '../providers/goals_provider.dart';
import 'task_tile.dart';

class GoalSection extends ConsumerWidget {
  final Goal goal;
  final List<Task> tasks;
  final void Function(Task task) onTaskTap;
  final void Function(Task task) onTaskDelete;
  final void Function(Task task, TaskStatus status) onTaskStatusChanged;
  final VoidCallback onGoalTap;

  const GoalSection({
    super.key,
    required this.goal,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskDelete,
    required this.onTaskStatusChanged,
    required this.onGoalTap,
  });

  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedTasks = ref.watch(sortedTasksProvider(tasks));
    final theme = Theme.of(context);
    final progress = goalProgress(tasks);
    final dayProgress = goalDaysProgress(goal);
    final hasDaysBar = goal.starttime != null && goal.deadline != null;
    final showDeadline = goal.starttime == null && goal.deadline != null;

    return ExpansionTile(
      title: GestureDetector(
        onTap: onGoalTap,
        child: Row(
          children: [
            Expanded(child: Text(goal.name)),
            if (goal.type == GoalType.completable && tasks.isNotEmpty) ...[
              Text(
                  'progress\t\t\t\t',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            _GoalCoinBadge(
              coins: goal.rewardCoins + RewardService.calcGoalDynamicBonus(goal, tasks.length),
              collected: goal.gotRewards,
            ),
          ],
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (goal.type == GoalType.completable && tasks.isNotEmpty)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          if (hasDaysBar) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${DateFormat.MMMd().format(goal.starttime!)} - ${DateFormat.MMMd().format(goal.deadline!)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(dayProgress * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ],
          if (showDeadline) ...[
            const SizedBox(width: 6),
            Text(
              'Due ${DateFormat.MMMd().format(goal.deadline!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          if (hasDaysBar) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: dayProgress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.tertiary,
              ),
            ),
          ],
        ],
      ),
      initiallyExpanded: true,
      children: sortedTasks.map((task) {
        return TaskTile(
          task: task,
          onTap: () => onTaskTap(task),
          onDelete: () => onTaskDelete(task),
          onStatusChanged: (status) => onTaskStatusChanged(task, status),
        );
      }).toList(),
    );
  }
}

class _GoalCoinBadge extends StatelessWidget {
  final int coins;
  final bool collected;

  const _GoalCoinBadge({required this.coins, required this.collected});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: collected ? 0.35 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF5C842).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF5C842)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 3),
            Text(
              '$coins',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B6914),
              ),
            ),
          ],
        ),
      ),
    );
  }
}