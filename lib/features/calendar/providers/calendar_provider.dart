import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/event.dart';
import '../../../core/providers.dart';

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

final monthEventsProvider = StreamProvider<List<Event>>((ref) {
  final focusedMonth = ref.watch(focusedMonthProvider);
  final start = DateTime(focusedMonth.year, focusedMonth.month, 1);
  final end = DateTime(focusedMonth.year, focusedMonth.month + 1, 1);
  return ref.watch(eventRepositoryProvider).watchEventsByDateRange(start, end);
});

final dailyEventsProvider = StreamProvider<List<Event>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(eventRepositoryProvider).watchEventsByDate(selectedDate);
});
