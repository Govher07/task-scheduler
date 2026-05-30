import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/event.dart';
import '../../../core/providers.dart';
import '../../../core/services/recurrence_expander.dart';

enum CalendarViewMode { monthly, daily }

final calendarViewModeProvider = StateProvider<CalendarViewMode>(
  (ref) => CalendarViewMode.monthly,
);

final selectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final focusedMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// ---------------------------------------------------------------------------
// All repeating events (needed for recurrence expansion across any window).
// ---------------------------------------------------------------------------

final _allRepeatingEventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAllRepeatingEvents();
});

// ---------------------------------------------------------------------------
// Month events – non-repeating in window + expanded recurring
// ---------------------------------------------------------------------------

final _monthWindowEventsProvider = StreamProvider<List<Event>>((ref) {
  final focusedMonth = ref.watch(focusedMonthProvider);
  final windowStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
  final windowEnd = DateTime(focusedMonth.year, focusedMonth.month + 1, 1);

  return ref
      .watch(eventRepositoryProvider)
      .watchEventsByDateRange(windowStart, windowEnd);
});

final monthEventsProvider = StreamProvider<List<Event>>((ref) {
  final focusedMonth = ref.watch(focusedMonthProvider);
  final windowStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
  final windowEnd = DateTime(focusedMonth.year, focusedMonth.month + 1, 1);

  final windowAsync = ref.watch(_monthWindowEventsProvider);
  final repeatingAsync = ref.watch(_allRepeatingEventsProvider);

  if (windowAsync.hasError) {
    return Stream.error(windowAsync.error!, windowAsync.stackTrace);
  }
  if (repeatingAsync.hasError) {
    return Stream.error(repeatingAsync.error!, repeatingAsync.stackTrace);
  }

  final windowEvents = windowAsync.value;
  final repeatingEvents = repeatingAsync.value;

  if (windowEvents != null && repeatingEvents != null) {
    final plain = windowEvents.where((e) => !e.isRepeating).toList();
    final expanded = expandEvents(repeatingEvents, windowStart, windowEnd);
    return Stream.value([...plain, ...expanded]);
  }

  final controller = StreamController<List<Event>>();
  ref.onDispose(controller.close);
  return controller.stream;
});

// ---------------------------------------------------------------------------
// Daily events – non-repeating on date + expanded recurring
// ---------------------------------------------------------------------------

final _dailyWindowEventsProvider = StreamProvider<List<Event>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final dayStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  return ref
      .watch(eventRepositoryProvider)
      .watchEventsByDateRange(dayStart, dayEnd);
});

final dailyEventsProvider = StreamProvider<List<Event>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final dayStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final windowAsync = ref.watch(_dailyWindowEventsProvider);
  final repeatingAsync = ref.watch(_allRepeatingEventsProvider);

  if (windowAsync.hasError) {
    return Stream.error(windowAsync.error!, windowAsync.stackTrace);
  }
  if (repeatingAsync.hasError) {
    return Stream.error(repeatingAsync.error!, repeatingAsync.stackTrace);
  }

  final windowEvents = windowAsync.value;
  final repeatingEvents = repeatingAsync.value;

  if (windowEvents != null && repeatingEvents != null) {
    final plain = windowEvents.where((e) => !e.isRepeating).toList();
    final expanded = expandEvents(repeatingEvents, dayStart, dayEnd);
    return Stream.value([...plain, ...expanded]);
  }

  final controller = StreamController<List<Event>>();
  ref.onDispose(controller.close);
  return controller.stream;
});
