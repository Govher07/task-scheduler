import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import 'event_repository.dart';

class SupabaseEventRepository implements EventRepository {
  final SupabaseClient _client;

  SupabaseEventRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Event _fromRow(Map<String, dynamic> row) {
    return Event(
      id: row['id'] as String,
      name: row['name'] as String,
      taskId: row['task_id'] as String?,
      startTime: DateTime.parse(row['start_time'] as String),
      endTime: DateTime.parse(row['end_time'] as String),
      isRepeating: row['is_repeating'] as bool,
      recurrenceRule: row['recurrence_rule'] as String?,
      isDone: row['is_done'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> _toRow(Event event) {
    return {
      'id': event.id,
      'name': event.name,
      'task_id': event.taskId,
      'start_time': event.startTime.toIso8601String(),
      'end_time': event.endTime.toIso8601String(),
      'is_repeating': event.isRepeating,
      'recurrence_rule': event.recurrenceRule,
      // 'is_done': event.isDone, // TODO: Uncomment after running ALTER TABLE events ADD COLUMN is_done BOOLEAN DEFAULT false; in Supabase
      'user_id': _userId,
      'created_at': event.createdAt.toIso8601String(),
      'updated_at': event.updatedAt.toIso8601String(),
    };
  }

  @override
  Future<void> createEvent(Event event) async {
    await _client.from('events').insert(_toRow(event));
  }

  @override
  Future<Event?> getEventById(String id) async {
    final row = await _client
        .from('events')
        .select()
        .eq('id', id)
<<<<<<< HEAD
=======
        .eq('user_id', _userId)
>>>>>>> upstream/main
        .maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<Event>> getAllEvents() async {
    final rows = await _client.from('events').select().eq('user_id', _userId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Event>> getEventsByDateRange(DateTime start, DateTime end) async {
    final rows = await _client
        .from('events')
        .select()
        .eq('user_id', _userId)
        .gte('start_time', start.toIso8601String())
        .lt('start_time', end.toIso8601String());
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Event>> getEventsByDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return getEventsByDateRange(dayStart, dayEnd);
  }

  @override
  Future<void> updateEvent(Event event) async {
    await _client
        .from('events')
        .update(_toRow(event))
        .eq('id', event.id)
        .eq('user_id', _userId);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _client.from('events').delete().eq('id', id).eq('user_id', _userId);
  }

  @override
  Stream<List<Event>> watchEventsByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return watchEventsByDateRange(dayStart, dayEnd);
  }

  @override
  Stream<List<Event>> watchEventsByDateRange(DateTime start, DateTime end) {
<<<<<<< HEAD
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .map(
          (rows) => rows
              .map(_fromRow)
              .where(
                (e) =>
                    !e.startTime.isBefore(start) && e.startTime.isBefore(end),
              )
              .toList(),
        );
=======
    // stream() only supports one .eq() filter, so we filter user_id and date range in map
    final userId = _userId;
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows
            .map(_fromRow)
            .where((e) =>
                !e.startTime.isBefore(start) && e.startTime.isBefore(end))
            .toList());
  }

  @override
  Stream<List<Event>> watchAllRepeatingEvents() {
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .map((rows) => rows.map(_fromRow).where((e) => e.isRepeating).toList());
>>>>>>> upstream/main
  }
}
