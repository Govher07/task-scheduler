import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/event.dart' as model;

abstract class EventRepository {
  Future<void> createEvent(model.Event event);
  Future<model.Event?> getEventById(String id);
  Future<List<model.Event>> getAllEvents();
  Future<List<model.Event>> getEventsByDateRange(DateTime start, DateTime end);
  Future<List<model.Event>> getEventsByDate(DateTime date);
  Future<void> updateEvent(model.Event event);
  Future<void> deleteEvent(String id);
  Stream<List<model.Event>> watchEventsByDate(DateTime date);
  Stream<List<model.Event>> watchEventsByDateRange(DateTime start, DateTime end);
}

class DriftEventRepository implements EventRepository {
  final AppDatabase _db;

  DriftEventRepository(this._db);

  model.Event _toModel(Event row) {
    return model.Event(
      id: row.id,
      name: row.name,
      taskId: row.taskId,
      startTime: row.startTime,
      endTime: row.endTime,
      isRepeating: row.isRepeating,
      recurrenceRule: row.recurrenceRule,
      isDone: row.isDone,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  EventsCompanion _toCompanion(model.Event event) {
    return EventsCompanion(
      id: Value(event.id),
      name: Value(event.name),
      taskId: Value(event.taskId),
      startTime: Value(event.startTime),
      endTime: Value(event.endTime),
      isRepeating: Value(event.isRepeating),
      recurrenceRule: Value(event.recurrenceRule),
      isDone: Value(event.isDone),
      createdAt: Value(event.createdAt),
      updatedAt: Value(event.updatedAt),
    );
  }

  @override
  Future<void> createEvent(model.Event event) async {
    await _db.into(_db.events).insert(_toCompanion(event));
  }

  @override
  Future<model.Event?> getEventById(String id) async {
    final row = await (_db.select(_db.events)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<List<model.Event>> getAllEvents() async {
    final rows = await _db.select(_db.events).get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<model.Event>> getEventsByDateRange(DateTime start, DateTime end) async {
    final rows = await (_db.select(_db.events)
          ..where((t) => t.startTime.isBiggerOrEqualValue(start) & t.startTime.isSmallerThanValue(end)))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<model.Event>> getEventsByDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return getEventsByDateRange(dayStart, dayEnd);
  }

  @override
  Future<void> updateEvent(model.Event event) async {
    await (_db.update(_db.events)..where((t) => t.id.equals(event.id)))
        .write(_toCompanion(event));
  }

  @override
  Future<void> deleteEvent(String id) async {
    await (_db.delete(_db.events)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<model.Event>> watchEventsByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return watchEventsByDateRange(dayStart, dayEnd);
  }

  @override
  Stream<List<model.Event>> watchEventsByDateRange(DateTime start, DateTime end) {
    return (_db.select(_db.events)
          ..where((t) => t.startTime.isBiggerOrEqualValue(start) & t.startTime.isSmallerThanValue(end)))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }
}
