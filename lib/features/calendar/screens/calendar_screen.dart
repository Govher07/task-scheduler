import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
              builder: (_) => const _ChatBox(),
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
  });

  final DateTime focusedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

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
  });

  final List<Event> events;
  final ValueChanged<Event> onEventTap;
  final VoidCallback onAddEvent;

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
              leading: const Icon(Icons.event_outlined),
              title: Text(event.name),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$startTime - $endTime',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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

class _ChatBox extends StatefulWidget {
  const _ChatBox();

  @override
  State<_ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<_ChatBox> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Support Chat',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How can we help you?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _MessageBubble(message: _messages[index]),
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
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
