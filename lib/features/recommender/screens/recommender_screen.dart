import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/task.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/effort_indicator.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/seasonal_background.dart';
import '../providers/recommender_provider.dart';

final rewardBalanceProvider = FutureProvider<int>((ref) async {
  return ref.watch(rewardServiceProvider).getBalance();
});

class RecommenderScreen extends ConsumerWidget {
  const RecommenderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);
    final recommended = ref.watch(recommendedTaskProvider);
    final balanceAsync = ref.watch(rewardBalanceProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.72),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Change theme',
          icon: const Icon(Icons.palette_outlined),
          onPressed: () => _showThemePicker(context, ref),
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
        data: (tasks) {
          final completedTasks = tasks
              .where((task) => task.status == TaskStatus.done)
              .length;

          final inProgressTasks = tasks
              .where((task) => task.status == TaskStatus.inProgress)
              .length;

          final coinBalance = balanceAsync.valueOrNull ?? 0;

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minHeight = constraints.maxHeight > 16
                    ? constraints.maxHeight - 16
                    : 0.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RewardsSection(
                              coinBalance: coinBalance,
                              completedTasks: completedTasks,
                              inProgressTasks: inProgressTasks,
                            ),

                            const SizedBox(height: 8),

                            recommended == null
                                ? const _NoRecommendationCard()
                                : _RecommendedTaskCard(
                                    recommended: recommended,
                                    onSkip: () {
                                      final current = ref.read(
                                        skippedTaskIdsProvider,
                                      );

                                      ref
                                          .read(skippedTaskIdsProvider.notifier)
                                          .state = {
                                        ...current,
                                        recommended.id,
                                      };
                                    },
                                    onStart: () async {
                                      final repo = ref.read(
                                        taskRepositoryProvider,
                                      );

                                      await repo.updateTask(
                                        recommended.copyWith(
                                          status: TaskStatus.inProgress,
                                          updatedAt: DateTime.now(),
                                        ),
                                      );

                                      ref.invalidate(allTasksProvider);
                                      ref.invalidate(recommendedTaskProvider);

                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Started "${recommended.name}"',
                                          ),
                                        ),
                                      );

                                      context.go('/goals');
                                    },
                                    onDone: () async {
                                      await _markTaskDoneAndGrantRewards(
                                        ref,
                                        recommended,
                                      );

                                      ref.invalidate(allTasksProvider);
                                      ref.invalidate(recommendedTaskProvider);
                                      ref.invalidate(rewardBalanceProvider);
                                    },
                                  ),
                          ],
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

  Future<void> _markTaskDoneAndGrantRewards(WidgetRef ref, Task task) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final rewardService = ref.read(rewardServiceProvider);
    final now = DateTime.now();

    if (task.status == TaskStatus.done) {
      return;
    }

    if (!task.gotRewards) {
      await rewardService.grantTaskReward(task);

      await taskRepo.updateTask(
        task.copyWith(
          status: TaskStatus.done,
          gotRewards: true,
          updatedAt: now,
        ),
      );
    } else {
      await taskRepo.updateTask(
        task.copyWith(status: TaskStatus.done, updatedAt: now),
      );
    }

    if (task.goalId == null) {
      return;
    }

    final goalTasks = await taskRepo.getTasksByGoalId(task.goalId!);

    final updatedGoalTasks = goalTasks.map((goalTask) {
      if (goalTask.id == task.id) {
        return goalTask.copyWith(status: TaskStatus.done);
      }

      return goalTask;
    }).toList();

    final allDone =
        updatedGoalTasks.isNotEmpty &&
        updatedGoalTasks.every(
          (goalTask) => goalTask.status == TaskStatus.done,
        );

    if (!allDone) {
      return;
    }

    final goalRepo = ref.read(goalRepositoryProvider);
    final goal = await goalRepo.getGoalById(task.goalId!);

    if (goal != null && !goal.gotRewards) {
      await rewardService.grantGoalReward(goal, updatedGoalTasks.length);
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.40,
          maxChildSize: 0.90,
          builder: (context, scrollController) {
            final selectedTheme = ref.watch(moodThemeProvider);
            final colorScheme = Theme.of(context).colorScheme;

            return SafeArea(
              top: false,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                child: Material(
                  color: colorScheme.surface,
                  elevation: 12,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Choose Theme',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          children: [
                            ...MoodTheme.values.map((theme) {
                              final isSelected = theme == selectedTheme;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  tileColor: isSelected
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerHighest,
                                  leading: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline,
                                  ),
                                  title: Text(
                                    theme.label,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  onTap: () {
                                    ref.read(moodThemeProvider.notifier).state =
                                        theme;
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _themeLabel(MoodTheme theme) {
    switch (theme) {
      case MoodTheme.classic:
        return 'Classic';
      case MoodTheme.calmBlue:
        return 'Calm Blue';
      case MoodTheme.warmCozy:
        return 'Warm Cozy';
      case MoodTheme.night:
        return 'Night';
      case MoodTheme.toonPop:
        return 'Toon Pop';
      case MoodTheme.winterFrost:
        return 'Winter Frost';
      case MoodTheme.springBloom:
        return 'Spring Bloom';
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    context.go('/login');
  }
}

class _RewardsSection extends StatelessWidget {
  const _RewardsSection({
    required this.coinBalance,
    required this.completedTasks,
    required this.inProgressTasks,
  });

  final int coinBalance;
  final int completedTasks;
  final int inProgressTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: SnowCapped(
        borderRadius: 18,
        snowHeight: 10,
        horizontalInset: 2,
        child: Card(
          margin: EdgeInsets.zero,
          color: colorScheme.primaryContainer,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        size: 20,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rewards',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.go('/gaming');
                      },
                      icon: const Icon(Icons.storefront_outlined, size: 18),
                      label: const Text('Shop'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RewardStat(
                        icon: Icons.monetization_on_outlined,
                        label: 'Balance',
                        value: coinBalance.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RewardStat(
                        icon: Icons.check_circle_outline,
                        label: 'Done',
                        value: completedTasks.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RewardStat(
                        icon: Icons.play_circle_outline,
                        label: 'Active',
                        value: inProgressTasks.toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardStat extends StatelessWidget {
  const _RewardStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoRecommendationCard extends StatelessWidget {
  const _NoRecommendationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SnowCapped(
      borderRadius: 18,
      snowHeight: 10,
      horizontalInset: 2,
      child: Card(
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerHighest,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 40,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                'Nothing to recommend',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All tasks are done or skipped.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedTaskCard extends StatelessWidget {
  const _RecommendedTaskCard({
    required this.recommended,
    required this.onSkip,
    required this.onStart,
    required this.onDone,
  });

  final Task recommended;
  final VoidCallback onSkip;
  final VoidCallback onStart;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lightbulb, size: 34, color: colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          'You should work on:',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SnowCapped(
            borderRadius: 18,
            snowHeight: 10,
            horizontalInset: 2,
            child: Card(
              margin: EdgeInsets.zero,
              color: colorScheme.surfaceContainerHighest,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      recommended.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        PriorityBadge(priority: recommended.priority),
                        EffortIndicator(level: recommended.effortLevel),
                        if (recommended.deadline != null)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: colorScheme.secondaryContainer,
                            labelStyle: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                            label: Text(
                              'Due ${DateFormat('MMM d').format(recommended.deadline!)}',
                            ),
                          ),
                        _RewardPreviewChip(task: recommended),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 42,
              child: SnowCapped(
                borderRadius: 22,
                snowHeight: 10,
                horizontalInset: 3,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: onStart,
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: SnowCapped(
                      borderRadius: 22,
                      snowHeight: 10,
                      horizontalInset: 3,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text('Skip'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: onSkip,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: SnowCapped(
                      borderRadius: 22,
                      snowHeight: 10,
                      horizontalInset: 3,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Done'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: onDone,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _RewardPreviewChip extends StatelessWidget {
  const _RewardPreviewChip({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(
        Icons.monetization_on_outlined,
        size: 16,
        color: colorScheme.onTertiaryContainer,
      ),
      backgroundColor: colorScheme.tertiaryContainer,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: colorScheme.onTertiaryContainer,
      ),
      label: Text('${task.rewardCoins} coins'),
    );
  }
}
