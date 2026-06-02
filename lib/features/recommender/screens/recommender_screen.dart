import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/task.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/assistant_chat_sheet.dart';
import '../../lock/providers/lock_provider.dart';
import '../providers/recommender_provider.dart';

class RecommenderScreen extends ConsumerWidget {
  const RecommenderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);
    final balanceAsync = ref.watch(rewardBalanceProvider);

    // Refresh balance whenever the task list changes (e.g. task marked done
    // triggers a coin grant in the DB).
    ref.listen<AsyncValue<List<Task>>>(allTasksProvider, (_, __) {
      ref.invalidate(rewardBalanceProvider);
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
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

                            const _AssistantChatCard(),

                            const SizedBox(height: 8),

                            const _FocusCard(),
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
                                    ref
                                        .read(moodThemeProvider.notifier)
                                        .setTheme(theme);
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
      child: Card(
        color: colorScheme.surfaceContainerHighest,
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
                        color: colorScheme.onSurface,
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

/// The Home page's primary entry into the AI assistant: a small hero that
/// surfaces one-tap suggestions (each auto-sends into the chat, driving the
/// deterministic recommender) plus an "ask anything" affordance. All paths
/// open the shared [AssistantChatSheet].
class _AssistantChatCard extends StatelessWidget {
  const _AssistantChatCard();

  static const _suggestions = <_Suggestion>[
    _Suggestion(
      label: 'What should I do now?',
      icon: Icons.bolt_outlined,
      prompt: 'What should I work on right now?',
    ),
    _Suggestion(
      label: 'I have 30 min',
      icon: Icons.timer_outlined,
      prompt: 'What should I work on? I have 30 minutes.',
    ),
    _Suggestion(
      label: 'Plan my day',
      icon: Icons.event_note_outlined,
      prompt: 'Help me plan my day around my tasks.',
    ),
  ];

  void _openChat(BuildContext context, {String? prompt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssistantChatSheet(initialPrompt: prompt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your assistant',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Quick picks, or ask your own',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in _suggestions)
                  _SuggestionChip(
                    suggestion: suggestion,
                    onTap: () => _openChat(context, prompt: suggestion.prompt),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Material(
              color: colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openChat(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ask anything…',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.label,
    required this.icon,
    required this.prompt,
  });

  final String label;
  final IconData icon;
  final String prompt;
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.suggestion, required this.onTap});

  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(suggestion.icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                suggestion.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Focus mode entry on the Home page: pick a duration inline, then lock the
/// phone for that long. Drives the existing [lockProvider] and the `/lock`
/// countdown screen — replaces the old standalone Lock tab.
class _FocusCard extends ConsumerStatefulWidget {
  const _FocusCard();

  @override
  ConsumerState<_FocusCard> createState() => _FocusCardState();
}

class _FocusCardState extends ConsumerState<_FocusCard> {
  Duration _selected = const Duration(minutes: 25);

  static const _options = [
    (label: '5 min', duration: Duration(minutes: 5)),
    (label: '15 min', duration: Duration(minutes: 15)),
    (label: '25 min', duration: Duration(minutes: 25)),
    (label: '45 min', duration: Duration(minutes: 45)),
    (label: '1 hour', duration: Duration(hours: 1)),
  ];

  void _lockNow() {
    ref.read(lockProvider.notifier).lock(_selected);
    context.go('/lock');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_clock,
                    size: 20,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to focus?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Lock your phone for a set time',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opt in _options)
                  ChoiceChip(
                    label: Text(opt.label),
                    selected: opt.duration == _selected,
                    onSelected: (_) =>
                        setState(() => _selected = opt.duration),
                    showCheckmark: false,
                    backgroundColor: colorScheme.surface.withValues(alpha: 0.7),
                    selectedColor: colorScheme.primary,
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      color: opt.duration == _selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _lockNow,
                icon: const Icon(Icons.lock),
                label: const Text('Lock phone now'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
