import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/task.dart';
import '../../../core/services/reward_service.dart';
import '../../../core/widgets/effort_indicator.dart';
import '../../../core/widgets/priority_badge.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatusChanged;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Checkbox(
          value: task.status == TaskStatus.done,
          tristate: false,
          onChanged: (checked) {
            if (checked == true) {
              onStatusChanged(TaskStatus.done);
            } else {
              onStatusChanged(TaskStatus.todo);
            }
          },
        ),
        title: Text(
          task.name,
          style: TextStyle(
            decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            PriorityBadge(priority: task.priority),
            const SizedBox(width: 8),
            EffortIndicator(level: task.effortLevel),
            if (task.deadline != null) ...[
              if (task.starttime != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${DateFormat.MMMd().format(task.starttime!)}  -',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ] else ...[
                const SizedBox(width: 8),
                Text(
                  'due',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
              const SizedBox(width: 8),
              Text(
                DateFormat.MMMd().format(task.deadline!),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
        trailing: _CoinBadge(
          coins: RewardService.calcTotalReward(task),
          collected: task.gotRewards,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  final int coins;
  final bool collected;

  const _CoinBadge({required this.coins, required this.collected});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: collected ? 0.35 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF5C842).withValues(alpha: 0.15),
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
