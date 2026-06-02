import '../models/event.dart';

/// Expands a list of Events into all concrete occurrences within
/// [windowStart, windowEnd). Non-repeating events are included if their
/// startTime is in the window. Repeating events are expanded via their RRULE.
///
/// Supported RRULE fields (matching what event_form_screen writes):
///   FREQ = DAILY | WEEKLY | MONTHLY | YEARLY
///   INTERVAL = N           (default 1)
///   BYDAY = MO,TU,...      (weekly only)
///   UNTIL = datetime       (end date, inclusive)
///   COUNT = N              (max total occurrences from startTime)
List<Event> expandEvents(
  List<Event> rawEvents,
  DateTime windowStart,
  DateTime windowEnd,
) {
  final result = <Event>[];

  for (final event in rawEvents) {
    if (!event.isRepeating || event.recurrenceRule == null) {
      if (!event.startTime.isBefore(windowStart) &&
          event.startTime.isBefore(windowEnd)) {
        result.add(event);
      }
      continue;
    }
    result.addAll(_expandRecurring(event, windowStart, windowEnd));
  }

  return result;
}

// ---------------------------------------------------------------------------
// Core expansion logic
// ---------------------------------------------------------------------------

List<Event> _expandRecurring(
    Event event, DateTime windowStart, DateTime windowEnd) {
  final fields = _parseRRule(event.recurrenceRule!);
  final freq = fields['FREQ'] ?? 'DAILY';
  final interval = int.tryParse(fields['INTERVAL'] ?? '1') ?? 1;
  final count = int.tryParse(fields['COUNT'] ?? '');
  final until = _parseUntil(fields['UNTIL']);
  final byDay = _parseByDay(fields['BYDAY']); // ISO weekdays: 1=Mon…7=Sun

  final duration = event.endTime.difference(event.startTime);

  final dates = _generateDates(
    freq: freq,
    interval: interval,
    startTime: event.startTime,
    byDay: byDay,
    count: count,
    until: until,
    windowStart: windowStart,
    windowEnd: windowEnd,
  );

  return dates
      .map((dt) => event.copyWith(startTime: dt, endTime: dt.add(duration)))
      .toList();
}

// ---------------------------------------------------------------------------
// Date generation per frequency
// ---------------------------------------------------------------------------

List<DateTime> _generateDates({
  required String freq,
  required int interval,
  required DateTime startTime,
  required Set<int> byDay,
  required int? count,
  required DateTime? until,
  required DateTime windowStart,
  required DateTime windowEnd,
}) {
  switch (freq) {
    case 'DAILY':
      return _generateDaily(
          startTime, interval, count, until, windowStart, windowEnd);
    case 'WEEKLY':
      return _generateWeekly(
          startTime, interval, byDay, count, until, windowStart, windowEnd);
    case 'MONTHLY':
      return _generateMonthly(
          startTime, interval, count, until, windowStart, windowEnd);
    case 'YEARLY':
      return _generateYearly(
          startTime, interval, count, until, windowStart, windowEnd);
    default:
      return _generateDaily(
          startTime, interval, count, until, windowStart, windowEnd);
  }
}

// ── DAILY ────────────────────────────────────────────────────────────────────

List<DateTime> _generateDaily(DateTime startTime, int interval, int? count,
    DateTime? until, DateTime windowStart, DateTime windowEnd) {
  final results = <DateTime>[];
  var cursor = startTime;
  int totalCount = 0;

  while (true) {
    if (count != null && totalCount >= count) break;
    if (until != null && cursor.isAfter(until)) break;
    if (cursor.isAfter(windowEnd)) break;

    if (!cursor.isBefore(windowStart)) results.add(cursor);

    cursor = cursor.add(Duration(days: interval));
    totalCount++;
  }
  return results;
}

// ── WEEKLY ───────────────────────────────────────────────────────────────────

List<DateTime> _generateWeekly(
    DateTime startTime,
    int interval,
    Set<int> byDay,
    int? count,
    DateTime? until,
    DateTime windowStart,
    DateTime windowEnd) {
  // If no BYDAY, repeat on the same weekday as startTime.
  final effectiveDays = byDay.isEmpty ? {startTime.weekday} : byDay;
  final sortedDays = effectiveDays.toList()..sort();

  // Monday of the week that contains startTime.
  final daysFromMonday = startTime.weekday - DateTime.monday; // 0=Mon…6=Sun
  final firstWeekMonday = DateTime(
    startTime.year,
    startTime.month,
    startTime.day - daysFromMonday,
    // Preserve time-of-day on the anchor, not the Monday
  );

  final results = <DateTime>[];
  int totalCount = 0;

  for (int weekIdx = 0; ; weekIdx++) {
    final weekMonday = firstWeekMonday.add(Duration(days: 7 * interval * weekIdx));

    // Safety exit: if the whole week is past the window, stop.
    if (weekMonday
        .isAfter(windowEnd.add(const Duration(days: 7)))) {
      break;
    }

    for (final isoDay in sortedDays) {
      // ISO day offset from Monday (0=Mon … 6=Sun)
      final dayOffset = isoDay - DateTime.monday;
      final occDate = DateTime(
        weekMonday.year,
        weekMonday.month,
        weekMonday.day + dayOffset,
        startTime.hour,
        startTime.minute,
        startTime.second,
      );

      // Skip occurrences that are before the event actually starts.
      if (occDate.isBefore(startTime)) continue;

      // COUNT applies from the very beginning (not just the window).
      if (count != null && totalCount >= count) return results;
      if (until != null && occDate.isAfter(until)) return results;
      if (occDate.isAfter(windowEnd)) return results;

      if (!occDate.isBefore(windowStart)) results.add(occDate);

      totalCount++;
    }
  }
  return results;
}

// ── MONTHLY ──────────────────────────────────────────────────────────────────

List<DateTime> _generateMonthly(DateTime startTime, int interval, int? count,
    DateTime? until, DateTime windowStart, DateTime windowEnd) {
  final results = <DateTime>[];
  int totalCount = 0;

  var year = startTime.year;
  var month = startTime.month;

  while (true) {
    // Clamp day to the last day of the month (e.g. Jan 31 → Feb 28).
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = startTime.day.clamp(1, lastDay);
    final cursor = DateTime(
        year, month, day, startTime.hour, startTime.minute, startTime.second);

    if (count != null && totalCount >= count) break;
    if (until != null && cursor.isAfter(until)) break;
    if (cursor.isAfter(windowEnd)) break;

    if (!cursor.isBefore(windowStart)) results.add(cursor);

    totalCount++;

    month += interval;
    while (month > 12) {
      month -= 12;
      year++;
    }
  }
  return results;
}

// ── YEARLY ───────────────────────────────────────────────────────────────────

List<DateTime> _generateYearly(DateTime startTime, int interval, int? count,
    DateTime? until, DateTime windowStart, DateTime windowEnd) {
  final results = <DateTime>[];
  int totalCount = 0;
  var cursor = startTime;

  while (true) {
    if (count != null && totalCount >= count) break;
    if (until != null && cursor.isAfter(until)) break;
    if (cursor.isAfter(windowEnd)) break;

    if (!cursor.isBefore(windowStart)) results.add(cursor);

    cursor = DateTime(cursor.year + interval, cursor.month, cursor.day,
        cursor.hour, cursor.minute, cursor.second);
    totalCount++;
  }
  return results;
}

// ---------------------------------------------------------------------------
// RRULE parsing helpers
// ---------------------------------------------------------------------------

Map<String, String> _parseRRule(String rrule) {
  final raw = rrule.replaceFirst('RRULE:', '');
  final map = <String, String>{};
  for (final part in raw.split(';')) {
    final idx = part.indexOf('=');
    if (idx == -1) continue;
    map[part.substring(0, idx)] = part.substring(idx + 1);
  }
  return map;
}

DateTime? _parseUntil(String? raw) {
  if (raw == null) return null;
  try {
    // Normalise compact form (20261231T235959Z) to ISO 8601
    final normalized = raw.replaceAllMapped(
      RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z?$'),
      (m) => '${m[1]}-${m[2]}-${m[3]}T${m[4]}:${m[5]}:${m[6]}Z',
    );
    return DateTime.parse(normalized).toLocal();
  } catch (_) {
    return null;
  }
}

/// Maps BYDAY abbreviations to Dart's ISO weekday integers (1=Mon … 7=Sun).
Set<int> _parseByDay(String? byday) {
  if (byday == null || byday.isEmpty) return {};
  const map = {
    'MO': 1,
    'TU': 2,
    'WE': 3,
    'TH': 4,
    'FR': 5,
    'SA': 6,
    'SU': 7,
  };
  return byday
      .split(',')
      .map((d) => map[d.trim()])
      .whereType<int>()
      .toSet();
}
