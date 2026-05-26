import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: tasksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
        data: (_) {
          if (recommended == null) {
            return const EmptyState(
              icon: Icons.lightbulb_outline,
              title: 'Nothing to recommend',
              subtitle: 'All tasks are done or skipped.',
            );
          }

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 320,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lightbulb,
                                size: 48,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'You should work on:',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                child: Card(
                                  color: colorScheme.surfaceContainerHighest,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          recommended.name,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            PriorityBadge(
                                              priority: recommended.priority,
                                            ),
                                            EffortIndicator(
                                              level: recommended.effortLevel,
                                            ),
                                            if (recommended.deadline != null)
                                              Chip(
                                                backgroundColor: colorScheme
                                                    .secondaryContainer,
                                                labelStyle: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                  color: colorScheme
                                                      .onSecondaryContainer,
                                                ),
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
                              ),

                              const SizedBox(height: 24),

                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.skip_next),
                                    label: const Text('Skip'),
                                    onPressed: () {
                                      final current =
                                          ref.read(skippedTaskIdsProvider);

                                      ref
                                          .read(
                                            skippedTaskIdsProvider.notifier,
                                          )
                                          .state = {
                                        ...current,
                                        recommended.id,
                                      };
                                    },
                                  ),
                                 FilledButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Start'),
                                    onPressed: () async {
                                      final repo = ref.read(taskRepositoryProvider);

                                      await repo.updateTask(
                                        recommended.copyWith(
                                          status: TaskStatus.inProgress,
                                        ),
                                      );

                                      ref.invalidate(allTasksProvider);
                                      ref.invalidate(recommendedTaskProvider);

                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Started "${recommended.name}"'),
                                        ),
                                      );

                                      context.go('/goals');
                                    },
                                  ),
                                  FilledButton.tonalIcon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('Done'),
                                    onPressed: () async {
                                      final repo =
                                          ref.read(taskRepositoryProvider);

                                      await repo.updateTask(
                                        recommended.copyWith(
                                          status: TaskStatus.done,
                                        ),
                                      );

                                      ref.invalidate(allTasksProvider);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}