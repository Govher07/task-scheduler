import 'dart:async';
import '../models/event.dart';
import '../database/mock_data.dart';
import 'event_repository.dart';

class MockEventRepository implements EventRepository {
  final List<Event> _events = List.from(mockEvents);
  final _controller = StreamController<List<Event>>.broadcast();

  void _emit() => _controller.add(List.from(_events));

  //for mock
  void dispose() => _controller.close();

  List<Event> _filterByRange(List<Event> events, DateTime start, DateTime end) {
    return events
        .where((e) => !e.startTime.isBefore(start) && e.startTime.isBefore(end))
        .toList();
  }

  @override
  Future<void> createEvent(Event event) async {
    _events.add(event);
    _emit();
  }

  @override
  Future<Event?> getEventById(String id) async {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Event>> getAllEvents() async {
    return List.from(_events);
  }

  @override
  Future<List<Event>> getEventsByDateRange(DateTime start, DateTime end) async {
    return _filterByRange(_events, start, end);
  }

  @override
  Future<List<Event>> getEventsByDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return getEventsByDateRange(dayStart, dayEnd);
  }

  @override
  Future<void> updateEvent(Event event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) _events[index] = event;
    _emit();
  }

  @override
  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    _emit();
  }

  @override
  Stream<List<Event>> watchEventsByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return watchEventsByDateRange(dayStart, dayEnd);
  }

  @override
  Stream<List<Event>> watchEventsByDateRange(DateTime start, DateTime end) {
    _emit();
    return _controller.stream.map(
      (events) => _filterByRange(events, start, end),
    );
  }

  @override
  Stream<List<Event>> watchAllRepeatingEvents() {
    _emit();
    return _controller.stream
        .map((events) => events.where((e) => e.isRepeating).toList());
  }
}
