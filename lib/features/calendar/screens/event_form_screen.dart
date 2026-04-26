import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/event.dart';
import '../../../core/providers.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const EventFormScreen({super.key, this.eventId});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  String? _taskId;
  Event? _existingEvent;
  bool _isLoading = true;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadEvent();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadEvent() async {
    final event = await ref.read(eventRepositoryProvider).getEventById(widget.eventId!);
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

  String _formatDateTime(DateTime dt) {
    return DateFormat('EEE, MMM d  h:mm a').format(dt);
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
          picked.year, picked.month, picked.day,
          _startTime.hour, _startTime.minute,
        );
      } else {
        _endTime = DateTime(
          picked.year, picked.month, picked.day,
          _endTime.hour, _endTime.minute,
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
          _startTime.year, _startTime.month, _startTime.day,
          picked.hour, picked.minute,
        );
      } else {
        _endTime = DateTime(
          _endTime.year, _endTime.month, _endTime.day,
          picked.hour, picked.minute,
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
    if (_isEditing) {
      await repo.updateEvent(event);
    } else {
      await repo.createEvent(event);
    }
    if (mounted) context.pop();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(eventRepositoryProvider).deleteEvent(widget.eventId!);
              if (mounted) context.pop();
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
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete),
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
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Name is required' : null,
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
                    const DropdownMenuItem(value: null, child: Text('No task')),
                    ...tasks.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                  ],
                  onChanged: (value) => setState(() => _taskId = value),
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
