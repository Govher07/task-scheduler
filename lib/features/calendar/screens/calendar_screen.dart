

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/event.dart';
import '../../../core/providers.dart';
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

// _ChatBox is a ConsumerStatefulWidget so it can read the Supabase client
// and call the ai-assistant Edge Function whenever the user sends a message.
class _ChatBox extends ConsumerStatefulWidget {
  const _ChatBox();

  @override
  ConsumerState<_ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends ConsumerState<_ChatBox> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Sends the user's message to the ai-assistant Edge Function and appends
  /// the AI reply to the chat. The Edge Function handles all tool calls
  /// (including create_event) internally before returning the final reply.
  /// If the Edge Function fails (e.g. missing API key, 500 error), we fall back
  /// to a smart local event parser.
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final client = ref.read(supabaseClientProvider);

      // Build the full conversation history for the stateless Edge Function.
      final history = _messages
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
          .toList();

      final response = await client.functions.invoke(
        'ai-assistant',
        body: {'messages': history},
      );

      final reply = (response.data as Map<String, dynamic>)['reply'] as String? ??
          'Sorry, I could not process your request.';

      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      // Gracefully fall back to local parser when the remote Edge Function fails
      try {
        final reply = await _parseAndCreateEventLocally(text);
        setState(() {
          _messages.add(_ChatMessage(text: reply, isUser: false));
        });
      } catch (localError) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Error: ${localError.toString()}',
            isUser: false,
          ));
        });
      }
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  /// Parses the user message locally and inserts a new event into the database.
  /// This ensures functionality works even without an Anthropic API Key.
  Future<String> _parseAndCreateEventLocally(String text) async {
    final lower = text.toLowerCase();
    
    if (lower.contains('event') ||
        lower.contains('meeting') ||
        lower.contains('appointment') ||
        lower.contains('schedule') ||
        lower.contains('add') ||
        lower.contains('create')) {
      DateTime startTime = DateTime.now();
      startTime = DateTime(startTime.year, startTime.month, startTime.day, startTime.hour + 1, 0);

      // Try to extract date first
      final months = {
        'january': 1, 'jan': 1,
        'february': 2, 'feb': 2,
        'march': 3, 'mar': 3,
        'april': 4, 'apr': 4,
        'may': 5,
        'june': 6, 'jun': 6,
        'july': 7, 'jul': 7,
        'august': 8, 'aug': 8,
        'september': 9, 'sep': 9,
        'october': 10, 'oct': 10,
        'november': 11, 'nov': 11,
        'december': 12, 'dec': 12,
      };

      int? detectedMonth;
      int? detectedDay;

      for (final entry in months.entries) {
        if (lower.contains(entry.key)) {
          detectedMonth = entry.value;
          final dayReg = RegExp(entry.key + r'\s+(\d{1,2})(?:st|nd|rd|th)?', caseSensitive: false);
          final dayMatch = dayReg.firstMatch(lower);
          if (dayMatch != null) {
            detectedDay = int.tryParse(dayMatch.group(1) ?? '');
          } else {
            final dayRegBefore = RegExp(r'(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?' + entry.key, caseSensitive: false);
            final dayMatchBefore = dayRegBefore.firstMatch(lower);
            if (dayMatchBefore != null) {
              detectedDay = int.tryParse(dayMatchBefore.group(1) ?? '');
            }
          }
          break;
        }
      }

      if (detectedMonth != null && detectedDay != null) {
        final now = DateTime.now();
        int year = now.year;
        if (detectedMonth < now.month || (detectedMonth == now.month && detectedDay < now.day)) {
          year += 1;
        }
        startTime = DateTime(year, detectedMonth, detectedDay, startTime.hour, startTime.minute);
      } else if (lower.contains('tomorrow')) {
        startTime = startTime.add(const Duration(days: 1));
      }

      // Extract time (e.g., 3pm, 10am, 15:00)
      final timeReg = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false);
      final timeMatches = timeReg.allMatches(text);
      if (timeMatches.isNotEmpty) {
        var timeMatch = timeMatches.first;
        for (final m in timeMatches) {
          final startIdx = m.start;
          final beforeText = text.substring(0, startIdx).toLowerCase();
          if (beforeText.endsWith('at ') || beforeText.endsWith('at') || m.group(3) != null) {
            timeMatch = m;
            break;
          }
        }
        
        int hours = int.tryParse(timeMatch.group(1) ?? '') ?? startTime.hour;
        final minutes = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
        final ampm = timeMatch.group(3)?.toLowerCase();

        if (ampm == 'pm' && hours < 12) {
          hours += 12;
        } else if (ampm == 'am' && hours == 12) {
          hours = 0;
        }
        startTime = DateTime(startTime.year, startTime.month, startTime.day, hours, minutes);
      }

      final endTime = startTime.add(const Duration(hours: 1));

      // Clean up the name
      String name = text;
      // Remove leading action words
      name = name.replaceFirst(RegExp(r'^(?:create|add|new|schedule)\s+', caseSensitive: false), '');
      // Remove leading event type if generic
      name = name.replaceFirst(RegExp(r'^(?:a|an|the)\s+(?:meeting|event|appointment)\s+(?:at|on|for)\s+', caseSensitive: false), '');
      name = name.replaceFirst(RegExp(r'^(?:a|an|the)\s+(?:meeting|event|appointment)\s+', caseSensitive: false), '');
      name = name.replaceFirst(RegExp(r'^(?:a|an|the)\s+', caseSensitive: false), '');

      // Remove date/time phrases
      name = name.replaceAll(RegExp(r'\b(?:tomorrow|today)\b', caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'\b(?:at|on|for)?\s*\d{1,2}(?::\d{2})?\s*(?:am|pm)\b', caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'\b(?:at|on|for)?\s*\d{1,2}:\d{2}\b', caseSensitive: false), '');
      for (final monthName in months.keys) {
        name = name.replaceAll(RegExp(r'\b(?:at|on|for)?\s*' + monthName + r'\s+\d{1,2}(?:st|nd|rd|th)?\b', caseSensitive: false), '');
        name = name.replaceAll(RegExp(r'\b\d{1,2}(?:st|nd|rd|th)?\s+(?:of\s+)?' + monthName + r'\b', caseSensitive: false), '');
      }
      
      // Clean up leading/trailing prepositions and spaces
      name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
      name = name.replaceFirst(RegExp(r'^(?:at|on|for|with)\s+', caseSensitive: false), '');
      name = name.replaceFirst(RegExp(r'\s+(?:at|on|for|with)$', caseSensitive: false), '');
      name = name.trim();

      final lowerName = name.toLowerCase();
      if (lowerName.isEmpty || 
          lowerName == 'meeting' || 
          lowerName == 'event' || 
          lowerName == 'appointment') {
        name = 'Meeting';
      } else {
        if (lowerName.startsWith('meeting with ')) {
          name = 'Meeting with ' + name.substring(13);
        } else if (lowerName.startsWith('1:1 with ')) {
          name = '1:1 with ' + name.substring(9);
        } else {
          if (lower.contains('meeting with ') && !name.toLowerCase().startsWith('meeting with ')) {
            name = 'Meeting with ' + name;
          } else if (lower.contains('1:1 with ') && !name.toLowerCase().startsWith('1:1 with ')) {
            name = '1:1 with ' + name;
          } else {
            name = name[0].toUpperCase() + name.substring(1);
          }
        }
      }

      try {
        final repo = ref.read(eventRepositoryProvider);
        final newEvent = Event(
          id: const Uuid().v4(),
          name: name,
          startTime: startTime,
          endTime: endTime,
          isRepeating: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.createEvent(newEvent);

        final dateStr = DateFormat('EEE, MMM d').format(startTime);
        final timeStr = DateFormat('h:mm a').format(startTime);
        return 'I have successfully created the event "$name" for $dateStr at $timeStr!';
      } catch (e) {
        return 'I tried to create the event "$name" but failed: ${e.toString()}';
      }
    }

    return 'Hi! I am the support assistant. How can I help you today? You can ask me to "create an event named Standup tomorrow at 3pm".';
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
                          'How can I help you today?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try: "Add a meeting tomorrow at 3pm"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        // Typing indicator while waiting for AI reply
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: _TypingIndicator(),
                          ),
                        );
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
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
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
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

/// Three animated dots that show the AI is "thinking".
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final opacity = ((_ctrl.value * 3 - i).clamp(0.0, 1.0) *
                  (1 - (_ctrl.value * 3 - i - 1).clamp(0.0, 1.0)));
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: 0.3 + 0.7 * opacity,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              );
            }),
          );
        },
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
