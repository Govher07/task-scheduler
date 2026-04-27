import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/effort_indicator.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/recommender_provider.dart';

class RecommenderScreen extends ConsumerWidget {
  const RecommenderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);
    final recommended = ref.watch(recommendedTaskProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recommend')),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (_) {
          if (recommended == null) {
            return const EmptyState(
              icon: Icons.lightbulb_outline,
              title: 'Nothing to recommend',
              subtitle: 'All tasks are done or skipped.',
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'You should work on:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            recommended.name,
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              PriorityBadge(priority: recommended.priority),
                              EffortIndicator(level: recommended.effortLevel),
                              if (recommended.deadline != null)
                                Chip(
                                  label: Text(
                                    'Due ${DateFormat('MMM d').format(recommended.deadline!)}',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Skip'),
                        onPressed: () {
                          final current = ref.read(skippedTaskIdsProvider);
                          ref.read(skippedTaskIdsProvider.notifier).state = {
                            ...current,
                            recommended.id,
                          };
                        },
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        onPressed: () async {
                          final repo = ref.read(taskRepositoryProvider);
                          await repo.updateTask(
                            recommended.copyWith(status: TaskStatus.inProgress),
                          );
                          ref.invalidate(allTasksProvider);
                        },
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        onPressed: () async {
                          final repo = ref.read(taskRepositoryProvider);
                          await repo.updateTask(
                            recommended.copyWith(status: TaskStatus.done),
                          );
                          ref.invalidate(allTasksProvider);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
