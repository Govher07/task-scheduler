import '../../../core/models/enums.dart';
import '../../../core/models/task.dart';

int scoreTask(Task task, DateTime now) {
  int score = 0;

  switch (task.priority) {
    case Priority.high:
      score += 30;
    case Priority.medium:
      score += 20;
    case Priority.low:
      score += 10;
  }

  if (task.deadline != null) {
    final hoursUntilDeadline = task.deadline!.difference(now).inHours;
    if (hoursUntilDeadline < 0) {
      score += 50;
    } else if (hoursUntilDeadline < 24) {
      score += 40;
    } else if (hoursUntilDeadline < 72) {
      score += 25;
    } else if (hoursUntilDeadline < 168) {
      score += 15;
    }
  }

  return score;
}

Task? recommendTask(List<Task> tasks, DateTime now, Set<String> skippedIds) {
  final eligible = tasks
      .where((t) => t.status != TaskStatus.done)
      .where((t) => !skippedIds.contains(t.id))
      .toList();

  if (eligible.isEmpty) return null;

  eligible.sort((a, b) {
    final scoreA = scoreTask(a, now);
    final scoreB = scoreTask(b, now);
    if (scoreA != scoreB) return scoreB.compareTo(scoreA);
    return a.createdAt.compareTo(b.createdAt);
  });

  return eligible.first;
}
