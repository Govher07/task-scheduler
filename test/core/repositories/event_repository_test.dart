import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_scheduler/core/database/database.dart' hide Event, Task, Goal;
import 'package:task_scheduler/core/models/event.dart' as model;
import 'package:task_scheduler/core/repositories/event_repository.dart';

void main() {
  late AppDatabase db;
  late DriftEventRepository repository;
  final now = DateTime(2026, 4, 24, 12, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftEventRepository(db);
  });

  tearDown(() => db.close());

  test('createEvent inserts and returns an event', () async {
    final event = model.Event(
      id: 'e1',
      name: 'Daily gym session',
      startTime: DateTime(2026, 4, 24, 19, 0),
      endTime: DateTime(2026, 4, 24, 20, 0),
      createdAt: now,
      updatedAt: now,
    );

    await repository.createEvent(event);
    final result = await repository.getEventById('e1');

    expect(result, isNotNull);
    expect(result!.name, 'Daily gym session');
    expect(result.isRepeating, false);
  });

  test('getEventsByDateRange returns events within range', () async {
    await repository.createEvent(model.Event(
      id: 'e1', name: 'April 24 event',
      startTime: DateTime(2026, 4, 24, 10, 0), endTime: DateTime(2026, 4, 24, 11, 0),
      createdAt: now, updatedAt: now,
    ));
    await repository.createEvent(model.Event(
      id: 'e2', name: 'April 25 event',
      startTime: DateTime(2026, 4, 25, 10, 0), endTime: DateTime(2026, 4, 25, 11, 0),
      createdAt: now, updatedAt: now,
    ));
    await repository.createEvent(model.Event(
      id: 'e3', name: 'April 30 event',
      startTime: DateTime(2026, 4, 30, 10, 0), endTime: DateTime(2026, 4, 30, 11, 0),
      createdAt: now, updatedAt: now,
    ));

    final rangeEvents = await repository.getEventsByDateRange(
      DateTime(2026, 4, 24), DateTime(2026, 4, 26),
    );

    expect(rangeEvents, hasLength(2));
    expect(rangeEvents.map((e) => e.name), containsAll(['April 24 event', 'April 25 event']));
  });

  test('getEventsByDate returns events for a specific day', () async {
    await repository.createEvent(model.Event(
      id: 'e1', name: 'Morning event',
      startTime: DateTime(2026, 4, 24, 9, 0), endTime: DateTime(2026, 4, 24, 10, 0),
      createdAt: now, updatedAt: now,
    ));
    await repository.createEvent(model.Event(
      id: 'e2', name: 'Evening event',
      startTime: DateTime(2026, 4, 24, 18, 0), endTime: DateTime(2026, 4, 24, 19, 0),
      createdAt: now, updatedAt: now,
    ));
    await repository.createEvent(model.Event(
      id: 'e3', name: 'Tomorrow event',
      startTime: DateTime(2026, 4, 25, 9, 0), endTime: DateTime(2026, 4, 25, 10, 0),
      createdAt: now, updatedAt: now,
    ));

    final dayEvents = await repository.getEventsByDate(DateTime(2026, 4, 24));
    expect(dayEvents, hasLength(2));
  });

  test('updateEvent modifies existing event', () async {
    await repository.createEvent(model.Event(
      id: 'e1', name: 'Old name',
      startTime: DateTime(2026, 4, 24, 10, 0), endTime: DateTime(2026, 4, 24, 11, 0),
      createdAt: now, updatedAt: now,
    ));

    final event = await repository.getEventById('e1');
    await repository.updateEvent(event!.copyWith(name: 'New name'));

    final updated = await repository.getEventById('e1');
    expect(updated!.name, 'New name');
  });

  test('deleteEvent removes the event', () async {
    await repository.createEvent(model.Event(
      id: 'e1', name: 'Event',
      startTime: DateTime(2026, 4, 24, 10, 0), endTime: DateTime(2026, 4, 24, 11, 0),
      createdAt: now, updatedAt: now,
    ));

    await repository.deleteEvent('e1');
    final result = await repository.getEventById('e1');
    expect(result, isNull);
  });

  test('watchEventsByDate emits updates', () async {
    final stream = repository.watchEventsByDate(DateTime(2026, 4, 24));

    final future = expectLater(
      stream,
      emitsInOrder([
        hasLength(0),
        hasLength(1),
      ]),
    );

    await Future.delayed(Duration.zero);

    await repository.createEvent(model.Event(
      id: 'e1', name: 'Event',
      startTime: DateTime(2026, 4, 24, 10, 0), endTime: DateTime(2026, 4, 24, 11, 0),
      createdAt: now, updatedAt: now,
    ));

    await future;
  });
}
