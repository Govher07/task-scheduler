import 'package:flutter_test/flutter_test.dart';
import 'package:task_scheduler/core/models/event.dart';
import 'package:task_scheduler/core/services/recurrence_expander.dart';

void main() {
  group('Recurrence Expander Tests', () {
    test('expands weekly repeat on Friday correctly', () {
      final startTime = DateTime(2026, 5, 29, 10, 0); // Friday, May 29, 2026
      final endTime = DateTime(2026, 5, 29, 11, 0);
      final event = Event(
        id: '1',
        name: 'Weekly Friday Event',
        startTime: startTime,
        endTime: endTime,
        isRepeating: true,
        recurrenceRule: 'RRULE:FREQ=WEEKLY;BYDAY=FR',
        isDone: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final windowStart = DateTime(2026, 5, 25); // Monday of that week
      final windowEnd = DateTime(2026, 6, 15);   // 3 weeks later

      final occurrences = expandEvents([event], windowStart, windowEnd);

      // Should have 3 occurrences:
      // May 29 (Friday)
      // Jun 5 (Friday)
      // Jun 12 (Friday)
      expect(occurrences.length, equals(3));
      expect(occurrences[0].startTime, equals(DateTime(2026, 5, 29, 10, 0)));
      expect(occurrences[1].startTime, equals(DateTime(2026, 6, 5, 10, 0)));
      expect(occurrences[2].startTime, equals(DateTime(2026, 6, 12, 10, 0)));
    });

    test('expands daily repeat correctly', () {
      final startTime = DateTime(2026, 5, 29, 10, 0);
      final endTime = DateTime(2026, 5, 29, 11, 0);
      final event = Event(
        id: '1',
        name: 'Daily Event',
        startTime: startTime,
        endTime: endTime,
        isRepeating: true,
        recurrenceRule: 'RRULE:FREQ=DAILY;INTERVAL=2;COUNT=3',
        isDone: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final windowStart = DateTime(2026, 5, 25);
      final windowEnd = DateTime(2026, 6, 15);

      final occurrences = expandEvents([event], windowStart, windowEnd);

      // Should have 3 occurrences total due to COUNT=3:
      // May 29, May 31, June 2
      expect(occurrences.length, equals(3));
      expect(occurrences[0].startTime, equals(DateTime(2026, 5, 29, 10, 0)));
      expect(occurrences[1].startTime, equals(DateTime(2026, 5, 31, 10, 0)));
      expect(occurrences[2].startTime, equals(DateTime(2026, 6, 2, 10, 0)));
    });
  });
}
