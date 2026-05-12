import 'package:flutter/material.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/task.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/effort_indicator.dart';
import 'package:intl/intl.dart';

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
        onTap: onTap,
      ),
    );
  }
}
