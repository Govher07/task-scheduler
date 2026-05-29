import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/event.dart';
import '../../../core/providers.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final String? eventId;
  final DateTime? initialDate;

  const EventFormScreen({super.key, this.eventId, this.initialDate});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late DateTime _startTime;
  late DateTime _endTime;

  String? _taskId;
  Event? _existingEvent;
  bool _isLoading = true;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();

    _setInitialTimes();

    if (_isEditing) {
      _loadEvent();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(covariant EventFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isEditing) return;
    if (oldWidget.initialDate == widget.initialDate) return;

    setState(() {
      _setInitialTimes();
    });
  }

  void _setInitialTimes() {
    final now = DateTime.now();
    final selectedDate = widget.initialDate ?? now;

    final isToday = _isSameCalendarDay(selectedDate, now);

    final startHour = isToday
        ? now.hour == 23
              ? 23
              : now.hour + 1
        : 9;

    _startTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startHour,
      0,
    );

    _endTime = _startTime.add(const Duration(hours: 1));
  }

  Future<void> _loadEvent() async {
    final event = await ref
        .read(eventRepositoryProvider)
        .getEventById(widget.eventId!);

    if (event != null && mounted) {
      setState(() {
        _existingEvent = event;
        _nameController.text = event.name;
        _startTime = event.startTime;
        _endTime = event.endTime;
        _taskId = event.taskId;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('EEE, MMM d  h:mm a').format(dateTime);
  }

  Future<void> _pickDate(bool isStart) async {
    final current = isStart ? _startTime : _endTime;

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _startTime.hour,
          _startTime.minute,
        );

        if (!_endTime.isAfter(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _endTime.hour,
          _endTime.minute,
        );
      }
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final current = isStart ? _startTime : _endTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startTime = DateTime(
          _startTime.year,
          _startTime.month,
          _startTime.day,
          picked.hour,
          picked.minute,
        );

        if (!_endTime.isAfter(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = DateTime(
          _endTime.year,
          _endTime.month,
          _endTime.day,
          picked.hour,
          picked.minute,
        );
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_endTime.isAfter(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final now = DateTime.now();

    final event = Event(
      id: _existingEvent?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      taskId: _taskId,
      startTime: _startTime,
      endTime: _endTime,
      isRepeating: _existingEvent?.isRepeating ?? false,
      recurrenceRule: _existingEvent?.recurrenceRule,
      createdAt: _existingEvent?.createdAt ?? now,
      updatedAt: now,
    );

    final repo = ref.read(eventRepositoryProvider);

    try {
      if (_isEditing) {
        await repo.updateEvent(event);
      } else {
        await repo.createEvent(event);
      }
    } catch (e, stack) {
      debugPrint('Error saving event: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                _isEditing ? Icons.edit_calendar : Icons.event_available,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(_isEditing ? 'Event Updated' : 'Event Created'),
            ],
          ),
          content: Text(
            'The event "${event.name}" has been successfully ${_isEditing ? "updated" : "created"}.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) {
                  context.go('/calendar');
                }
              },
              child: const Text('Back to Calendar'),
            ),
          ],
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              await ref
                  .read(eventRepositoryProvider)
                  .deleteEvent(widget.eventId!);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event successfully deleted'),
                  ),
                );
                context.go('/calendar');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Event' : 'New Event')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'New Event'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/calendar'),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Event Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start'),
              subtitle: Text(_formatDateTime(_startTime)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _pickTime(true),
                  ),
                ],
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End'),
              subtitle: Text(_formatDateTime(_endTime)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(false),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _pickTime(false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: ref.read(taskRepositoryProvider).getAllTasks(),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];

                return DropdownButtonFormField<String?>(
                  value: _taskId,
                  decoration: const InputDecoration(
                    labelText: 'Linked Task (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No task'),
                    ),
                    ...tasks.map(
                      (task) => DropdownMenuItem<String?>(
                        value: task.id,
                        child: Text(task.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _taskId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
