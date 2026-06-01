

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/event.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/assistant_chat_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/calendar_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(calendarViewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<CalendarViewMode>(
              segments: const [
                ButtonSegment<CalendarViewMode>(
                  value: CalendarViewMode.monthly,
                  label: Text('Monthly'),
                  icon: Icon(Icons.calendar_month),
                ),
                ButtonSegment<CalendarViewMode>(
                  value: CalendarViewMode.daily,
                  label: Text('Daily'),
                  icon: Icon(Icons.view_day),
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (selection) {
                ref.read(calendarViewModeProvider.notifier).state =
                    selection.first;
              },
            ),
          ),
        ),
      ),
      body: viewMode == CalendarViewMode.monthly
          ? const _MonthlyView()
          : const _DailyView(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'chat_fab',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AssistantChatSheet(),
            ),
            child: const Icon(Icons.support_agent),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add_fab',
            onPressed: () {
              final selectedDate = ref.read(selectedDateProvider);
              context.go(_newEventPathForDate(selectedDate));
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _MonthlyView extends ConsumerWidget {
  const _MonthlyView();

  void _showSummary(BuildContext context, WidgetRef ref, DateTime focusedMonth, List<Event> events) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MonthSummarySheet(
        month: focusedMonth,
        events: events,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final monthEventsAsync = ref.watch(monthEventsProvider);

    return monthEventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (events) {
        final selectedEvents =
            events
                .where((event) => _isSameDay(event.startTime, selectedDate))
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            _MonthHeader(
              focusedMonth: focusedMonth,
              onPreviousMonth: () {
                ref.read(focusedMonthProvider.notifier).state = DateTime(
                  focusedMonth.year,
                  focusedMonth.month - 1,
                );
              },
              onNextMonth: () {
                ref.read(focusedMonthProvider.notifier).state = DateTime(
                  focusedMonth.year,
                  focusedMonth.month + 1,
                );
              },
              onToday: () {
                final today = DateTime.now();
                ref.read(selectedDateProvider.notifier).state = today;
                ref.read(focusedMonthProvider.notifier).state = DateTime(
                  today.year,
                  today.month,
                );
              },
              onSummarize: () => _showSummary(context, ref, focusedMonth, events),
            ),
            const SizedBox(height: 16),
            _MonthGrid(
              focusedMonth: focusedMonth,
              selectedDate: selectedDate,
              events: events,
              onDateSelected: (date) {
                ref.read(selectedDateProvider.notifier).state = date;

                final isDifferentMonth =
                    date.year != focusedMonth.year ||
                    date.month != focusedMonth.month;

                if (isDifferentMonth) {
                  ref.read(focusedMonthProvider.notifier).state = DateTime(
                    date.year,
                    date.month,
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              DateFormat('EEEE, MMMM d').format(selectedDate),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _SelectedDayEvents(
              events: selectedEvents,
              onEventTap: (event) => context.go('/calendar/event/${event.id}'),
              onAddEvent: () => context.go(_newEventPathForDate(selectedDate)),
              onEventToggle: (event, checked) {
                ref.read(eventRepositoryProvider).updateEvent(event.copyWith(isDone: checked));
              },
            ),
          ],
        );
      },
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.focusedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSummarize,
  });

  final DateTime focusedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final VoidCallback onSummarize;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(focusedMonth);

    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
          onPressed: onPreviousMonth,
        ),
        Expanded(
          child: Text(
            monthLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
          onPressed: onNextMonth,
        ),
        IconButton(
          tooltip: 'Summarize month',
          icon: const Icon(Icons.summarize_outlined),
          onPressed: onSummarize,
        ),
        IconButton(
          tooltip: 'Today',
          icon: const Icon(Icons.today_outlined),
          onPressed: onToday,
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.events,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<Event> events;
  final ValueChanged<DateTime> onDateSelected;

  static const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final dates = _visibleDatesForMonth(focusedMonth);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: weekdays.map((weekday) {
                return Expanded(
                  child: Center(
                    child: Text(
                      weekday,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = _isSameDay(date, selectedDate);
                final isToday = _isSameDay(date, DateTime.now());
                final isOutsideMonth = date.month != focusedMonth.month;
                final hasEvents = events.any(
                  (event) => _isSameDay(event.startTime, date),
                );

                return _DateCell(
                  date: date,
                  isSelected: isSelected,
                  isToday: isToday,
                  isOutsideMonth: isOutsideMonth,
                  hasEvents: hasEvents,
                  onTap: () => onDateSelected(date),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _visibleDatesForMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingDays = firstDayOfMonth.weekday % 7;
    final totalVisibleDays = leadingDays + daysInMonth;
    final rowCount = (totalVisibleDays / 7).ceil();

    final firstVisibleDate = firstDayOfMonth.subtract(
      Duration(days: leadingDays),
    );

    return List.generate(rowCount * 7, (index) {
      return firstVisibleDate.add(Duration(days: index));
    });
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isOutsideMonth,
    required this.hasEvents,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isOutsideMonth;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor = isSelected
        ? theme.colorScheme.primary
        : Colors.transparent;

    final textColor = isSelected
        ? theme.colorScheme.onPrimary
        : isOutsideMonth
        ? theme.colorScheme.outline
        : theme.colorScheme.onSurface;

    final borderColor = isToday
        ? theme.colorScheme.primary
        : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasEvents
                    ? isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayEvents extends StatelessWidget {
  const _SelectedDayEvents({
    required this.events,
    required this.onEventTap,
    required this.onAddEvent,
    required this.onEventToggle,
  });

  final List<Event> events;
  final ValueChanged<Event> onEventTap;
  final VoidCallback onAddEvent;
  final void Function(Event, bool) onEventToggle;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Column(
        children: [
          const EmptyState(
            icon: Icons.event_busy,
            title: 'No events',
            subtitle: 'No events scheduled for this day.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAddEvent,
            icon: const Icon(Icons.add),
            label: const Text('Add event'),
          ),
        ],
      );
    }

    final timeFormatter = DateFormat('h:mm a');

    return Column(
      children: [
        ...events.map((event) {
          final startTime = timeFormatter.format(event.startTime);
          final endTime = timeFormatter.format(event.endTime);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => onEventTap(event),
              leading: Checkbox(
                value: event.isDone == true,
                onChanged: (checked) {
                  if (checked != null) {
                    onEventToggle(event, checked);
                  }
                },
              ),
              title: Text(
                event.name,
                style: TextStyle(
                  decoration: event.isDone == true ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text('$startTime - $endTime'),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        }),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: onAddEvent,
          icon: const Icon(Icons.add),
          label: const Text('Add event'),
        ),
      ],
    );
  }
}

class _DailyView extends ConsumerWidget {
  const _DailyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dailyEventsAsync = ref.watch(dailyEventsProvider);

    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state = selectedDate
                      .subtract(const Duration(days: 1));
                },
              ),
              Expanded(
                child: Text(
                  dateFormatter.format(selectedDate),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state = selectedDate
                      .add(const Duration(days: 1));
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: dailyEventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (events) {
              if (events.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_busy,
                  title: 'No events',
                  subtitle: 'No events scheduled for this day.',
                );
              }

              final sortedEvents = [...events]
                ..sort((a, b) => a.startTime.compareTo(b.startTime));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: sortedEvents.length,
                itemBuilder: (context, index) {
                  final event = sortedEvents[index];
                  final startTime = timeFormatter.format(event.startTime);
                  final endTime = timeFormatter.format(event.endTime);

                  return GestureDetector(
                    onTap: () => context.go('/calendar/event/${event.id}'),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      clipBehavior: Clip.antiAlias,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 6,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: event.isDone == true,
                                      onChanged: (checked) {
                                        if (checked != null) {
                                          ref.read(eventRepositoryProvider).updateEvent(event.copyWith(isDone: checked));
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            event.name,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              decoration: event.isDone == true ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$startTime - $endTime',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
          ),
        ),
      ],
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _newEventPathForDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '/calendar/event/new?date=$year-$month-$day';
}

class _MonthSummarySheet extends ConsumerStatefulWidget {
  final DateTime month;
  final List<Event> events;

  const _MonthSummarySheet({
    required this.month,
    required this.events,
  });

  @override
  ConsumerState<_MonthSummarySheet> createState() => _MonthSummarySheetState();
}

class _MonthSummarySheetState extends ConsumerState<_MonthSummarySheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel = DateFormat('MMMM yyyy').format(widget.month);
    
    final scheduledEvents = widget.events;
    final doneEvents = widget.events.where((e) => e.isDone == true).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Summary for $monthLabel',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat(context, 'Scheduled', scheduledEvents.length.toString(), theme.colorScheme.primary),
                    _buildStat(context, 'Done', doneEvents.length.toString(), Colors.green),
                  ],
                ),
                if (scheduledEvents.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: scheduledEvents.map((event) {
                          final isDone = event.isDone == true;
                          return Chip(
                            label: Text(
                              event.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            backgroundColor: isDone ? Colors.green.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest,
                            labelStyle: TextStyle(
                              color: isDone ? Colors.green : theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
