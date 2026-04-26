import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/models/event.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/calendar/event/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MonthlyView extends ConsumerWidget {
  const _MonthlyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final monthEventsAsync = ref.watch(monthEventsProvider);

    final events = monthEventsAsync.valueOrNull ?? [];

    return TableCalendar<Event>(
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: focusedMonth,
      selectedDayPredicate: (day) => isSameDay(day, selectedDate),
      eventLoader: (day) {
        return events.where((e) => isSameDay(e.startTime, day)).toList();
      },
      calendarBuilders: CalendarBuilders<Event>(
        markerBuilder: (context, day, dayEvents) {
          if (dayEvents.isEmpty) return null;
          final displayCount = dayEvents.length > 3 ? 3 : dayEvents.length;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(displayCount, (index) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }),
          );
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        ref.read(selectedDateProvider.notifier).state = selectedDay;
        ref.read(focusedMonthProvider.notifier).state = focusedDay;
        ref.read(calendarViewModeProvider.notifier).state =
            CalendarViewMode.daily;
      },
      onPageChanged: (focusedDay) {
        ref.read(focusedMonthProvider.notifier).state = focusedDay;
      },
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
        // Date header with navigation arrows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state =
                      selectedDate.subtract(const Duration(days: 1));
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
                  ref.read(selectedDateProvider.notifier).state =
                      selectedDate.add(const Duration(days: 1));
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Events list
        Expanded(
          child: dailyEventsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Error: $error')),
            data: (events) {
              if (events.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_busy,
                  title: 'No events',
                  subtitle: 'No events scheduled for this day.',
                );
              }

              final sorted = [...events]
                ..sort((a, b) => a.startTime.compareTo(b.startTime));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final event = sorted[index];
                  final startStr = timeFormatter.format(event.startTime);
                  final endStr = timeFormatter.format(event.endTime);

                  return GestureDetector(
                    onTap: () =>
                        context.go('/calendar/event/${event.id}'),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      clipBehavior: Clip.antiAlias,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 6,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$startStr - $endStr',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
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
