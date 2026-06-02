import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/event.dart';
import '../../../core/providers.dart';

// ---------------------------------------------------------------------------
// Recurrence helpers
// ---------------------------------------------------------------------------

enum _RecurrenceFrequency { daily, weekly, monthly, yearly }

extension _RecurrenceFrequencyLabel on _RecurrenceFrequency {
  String get label {
    switch (this) {
      case _RecurrenceFrequency.daily:
        return 'Daily';
      case _RecurrenceFrequency.weekly:
        return 'Weekly';
      case _RecurrenceFrequency.monthly:
        return 'Monthly';
      case _RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }

  String get rruleFreq {
    switch (this) {
      case _RecurrenceFrequency.daily:
        return 'DAILY';
      case _RecurrenceFrequency.weekly:
        return 'WEEKLY';
      case _RecurrenceFrequency.monthly:
        return 'MONTHLY';
      case _RecurrenceFrequency.yearly:
        return 'YEARLY';
    }
  }
}

/// Builds a minimal RRULE string.
String _buildRRule({
  required _RecurrenceFrequency frequency,
  required int interval,
  List<int>? weekdays, // 0=MO … 6=SU (ISO weekday - 1)
  DateTime? until,
  int? count,
}) {
  const dayNames = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
  final parts = <String>[
    'FREQ=${frequency.rruleFreq}',
    if (interval > 1) 'INTERVAL=$interval',
    if (frequency == _RecurrenceFrequency.weekly &&
        weekdays != null &&
        weekdays.isNotEmpty)
      'BYDAY=${weekdays.map((d) => dayNames[d]).join(',')}',
    if (until != null)
      'UNTIL=${DateFormat("yyyyMMdd'T'HHmmss'Z'").format(until.toUtc())}',
    if (count != null && until == null) 'COUNT=$count',
  ];
  return 'RRULE:${parts.join(';')}';
}

/// Parses the subset of RRULE fields we write.
Map<String, String> _parseRRule(String rrule) {
  final raw = rrule.replaceFirst('RRULE:', '');
  return Map.fromEntries(
    raw.split(';').map((part) {
      final idx = part.indexOf('=');
      return MapEntry(part.substring(0, idx), part.substring(idx + 1));
    }),
  );
}

_RecurrenceFrequency _frequencyFromRRule(String freq) {
  switch (freq) {
    case 'DAILY':
      return _RecurrenceFrequency.daily;
    case 'WEEKLY':
      return _RecurrenceFrequency.weekly;
    case 'MONTHLY':
      return _RecurrenceFrequency.monthly;
    case 'YEARLY':
      return _RecurrenceFrequency.yearly;
    default:
      return _RecurrenceFrequency.daily;
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

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

  // ── Recurrence state ────────────────────────────────────────────────────
  bool _isRepeating = false;
  _RecurrenceFrequency _frequency = _RecurrenceFrequency.weekly;
  int _interval = 1;

  // Weekly: which days are selected (0=Mon … 6=Sun)
  final Set<int> _selectedWeekdays = {};

  // End condition
  _EndCondition _endCondition = _EndCondition.never;
  DateTime? _repeatUntil;
  int _occurrenceCount = 10;

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
    setState(() => _setInitialTimes());
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
    final event =
        await ref.read(eventRepositoryProvider).getEventById(widget.eventId!);

    if (event != null && mounted) {
      setState(() {
        _existingEvent = event;
        _nameController.text = event.name;
        _startTime = event.startTime;
        _endTime = event.endTime;
        _taskId = event.taskId;
        _isRepeating = event.isRepeating;

        if (event.isRepeating && event.recurrenceRule != null) {
          _parseAndApplyRRule(event.recurrenceRule!);
        }

        _isLoading = false;
      });
    }
  }

  void _parseAndApplyRRule(String rrule) {
    try {
      final fields = _parseRRule(rrule);
      _frequency = _frequencyFromRRule(fields['FREQ'] ?? 'DAILY');
      _interval = int.tryParse(fields['INTERVAL'] ?? '1') ?? 1;

      if (fields.containsKey('BYDAY')) {
        const dayNames = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
        _selectedWeekdays.clear();
        for (final d in fields['BYDAY']!.split(',')) {
          final idx = dayNames.indexOf(d);
          if (idx != -1) _selectedWeekdays.add(idx);
        }
      }

      if (fields.containsKey('UNTIL')) {
        _endCondition = _EndCondition.onDate;
        _repeatUntil = DateTime.tryParse(
          fields['UNTIL']!.replaceAll(RegExp(r'[TZ]'), ' ').trim(),
        );
      } else if (fields.containsKey('COUNT')) {
        _endCondition = _EndCondition.afterOccurrences;
        _occurrenceCount = int.tryParse(fields['COUNT']!) ?? 10;
      } else {
        _endCondition = _EndCondition.never;
      }
    } catch (_) {
      // Silently fall back to defaults if rule is malformed.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDateTime(DateTime dt) =>
      DateFormat('EEE, MMM d  h:mm a').format(dt);

  String? _buildCurrentRRule() {
    if (!_isRepeating) return null;
    return _buildRRule(
      frequency: _frequency,
      interval: _interval,
      weekdays: _frequency == _RecurrenceFrequency.weekly
          ? _selectedWeekdays.toList()
          : null,
      until: _endCondition == _EndCondition.onDate ? _repeatUntil : null,
      count: _endCondition == _EndCondition.afterOccurrences
          ? _occurrenceCount
          : null,
    );
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

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

  Future<void> _pickRepeatUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _repeatUntil ?? _startTime.add(const Duration(days: 30)),
      firstDate: _startTime,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _repeatUntil = picked);
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_endTime.isAfter(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    // Validate weekly: at least one day must be picked
    if (_isRepeating &&
        _frequency == _RecurrenceFrequency.weekly &&
        _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day for weekly repeat'),
        ),
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
      isRepeating: _isRepeating,
      recurrenceRule: _buildCurrentRRule(),
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
<<<<<<< HEAD
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
=======
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
>>>>>>> upstream/main
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
                if (mounted) context.go('/calendar');
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Event' : 'New Event')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

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
            // ── Event name ───────────────────────────────────────────────
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

            // ── Start / End ──────────────────────────────────────────────
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

            // ── Linked task ──────────────────────────────────────────────
            FutureBuilder(
              future: ref.read(taskRepositoryProvider).getAllTasks(),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
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
                  onChanged: (value) => setState(() => _taskId = value),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Repeat section ───────────────────────────────────────────
            _RepeatSection(
              isRepeating: _isRepeating,
              frequency: _frequency,
              interval: _interval,
              selectedWeekdays: _selectedWeekdays,
              endCondition: _endCondition,
              repeatUntil: _repeatUntil,
              occurrenceCount: _occurrenceCount,
              onToggleRepeat: (value) => setState(() => _isRepeating = value),
              onFrequencyChanged: (freq) =>
                  setState(() => _frequency = freq),
              onIntervalChanged: (val) => setState(() => _interval = val),
              onWeekdayToggled: (day) => setState(() {
                if (_selectedWeekdays.contains(day)) {
                  _selectedWeekdays.remove(day);
                } else {
                  _selectedWeekdays.add(day);
                }
              }),
              onEndConditionChanged: (cond) =>
                  setState(() => _endCondition = cond),
              onPickRepeatUntil: _pickRepeatUntil,
              onOccurrenceCountChanged: (val) =>
                  setState(() => _occurrenceCount = val),
              theme: theme,
            ),

            const SizedBox(height: 24),

            // ── Save ─────────────────────────────────────────────────────
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

// ---------------------------------------------------------------------------
// End-condition enum
// ---------------------------------------------------------------------------

enum _EndCondition { never, onDate, afterOccurrences }

extension _EndConditionLabel on _EndCondition {
  String get label {
    switch (this) {
      case _EndCondition.never:
        return 'Never';
      case _EndCondition.onDate:
        return 'On date';
      case _EndCondition.afterOccurrences:
        return 'After occurrences';
    }
  }
}

// ---------------------------------------------------------------------------
// Repeat section widget
// ---------------------------------------------------------------------------

class _RepeatSection extends StatelessWidget {
  const _RepeatSection({
    required this.isRepeating,
    required this.frequency,
    required this.interval,
    required this.selectedWeekdays,
    required this.endCondition,
    required this.repeatUntil,
    required this.occurrenceCount,
    required this.onToggleRepeat,
    required this.onFrequencyChanged,
    required this.onIntervalChanged,
    required this.onWeekdayToggled,
    required this.onEndConditionChanged,
    required this.onPickRepeatUntil,
    required this.onOccurrenceCountChanged,
    required this.theme,
  });

  final bool isRepeating;
  final _RecurrenceFrequency frequency;
  final int interval;
  final Set<int> selectedWeekdays;
  final _EndCondition endCondition;
  final DateTime? repeatUntil;
  final int occurrenceCount;

  final ValueChanged<bool> onToggleRepeat;
  final ValueChanged<_RecurrenceFrequency> onFrequencyChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onWeekdayToggled;
  final ValueChanged<_EndCondition> onEndConditionChanged;
  final VoidCallback onPickRepeatUntil;
  final ValueChanged<int> onOccurrenceCountChanged;

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Toggle row ───────────────────────────────────────────────
            SwitchListTile(
              value: isRepeating,
              onChanged: onToggleRepeat,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isRepeating
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.repeat,
                  color: isRepeating
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              title: const Text(
                'Repeat event',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: isRepeating
                  ? Text(
                      _summaryText(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Text('Tap to make this a recurring event'),
            ),

            if (isRepeating) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Frequency ────────────────────────────────────────
                    Text(
                      'Repeat frequency',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FrequencySelector(
                      selected: frequency,
                      onChanged: onFrequencyChanged,
                      theme: theme,
                    ),

                    const SizedBox(height: 16),

                    // ── Interval ─────────────────────────────────────────
                    Text(
                      'Every',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _IntervalPicker(
                      interval: interval,
                      frequency: frequency,
                      onChanged: onIntervalChanged,
                      theme: theme,
                    ),

                    // ── Weekday picker (weekly only) ──────────────────────
                    if (frequency == _RecurrenceFrequency.weekly) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Repeat on',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _WeekdayPicker(
                        selected: selectedWeekdays,
                        onToggle: onWeekdayToggled,
                        theme: theme,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── End condition ─────────────────────────────────────
                    Text(
                      'Ends',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _EndConditionPicker(
                      endCondition: endCondition,
                      repeatUntil: repeatUntil,
                      occurrenceCount: occurrenceCount,
                      onEndConditionChanged: onEndConditionChanged,
                      onPickDate: onPickRepeatUntil,
                      onOccurrenceCountChanged: onOccurrenceCountChanged,
                      theme: theme,
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _summaryText() {
    final freqLabel = frequency.label.toLowerCase();
    final intervalStr = interval == 1 ? freqLabel : 'every $interval ${freqLabel}s';

    String suffix = '';
    if (endCondition == _EndCondition.onDate && repeatUntil != null) {
      suffix = ' until ${DateFormat('MMM d, yyyy').format(repeatUntil!)}';
    } else if (endCondition == _EndCondition.afterOccurrences) {
      suffix = ', $occurrenceCount times';
    }

    return 'Repeats $intervalStr$suffix';
  }
}

// ---------------------------------------------------------------------------
// Frequency chips
// ---------------------------------------------------------------------------

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({
    required this.selected,
    required this.onChanged,
    required this.theme,
  });

  final _RecurrenceFrequency selected;
  final ValueChanged<_RecurrenceFrequency> onChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _RecurrenceFrequency.values.map((freq) {
        final isSelected = freq == selected;
        return ChoiceChip(
          label: Text(freq.label),
          selected: isSelected,
          onSelected: (_) => onChanged(freq),
          selectedColor: theme.colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Interval picker (stepper)
// ---------------------------------------------------------------------------

class _IntervalPicker extends StatelessWidget {
  const _IntervalPicker({
    required this.interval,
    required this.frequency,
    required this.onChanged,
    required this.theme,
  });

  final int interval;
  final _RecurrenceFrequency frequency;
  final ValueChanged<int> onChanged;
  final ThemeData theme;

  String get _unitLabel {
    switch (frequency) {
      case _RecurrenceFrequency.daily:
        return interval == 1 ? 'day' : 'days';
      case _RecurrenceFrequency.weekly:
        return interval == 1 ? 'week' : 'weeks';
      case _RecurrenceFrequency.monthly:
        return interval == 1 ? 'month' : 'months';
      case _RecurrenceFrequency.yearly:
        return interval == 1 ? 'year' : 'years';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove,
          onPressed: interval > 1 ? () => onChanged(interval - 1) : null,
          theme: theme,
        ),
        const SizedBox(width: 12),
        Text(
          '$interval $_unitLabel',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        _StepButton(
          icon: Icons.add,
          onPressed: interval < 99 ? () => onChanged(interval + 1) : null,
          theme: theme,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onPressed,
    required this.theme,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null
                ? theme.colorScheme.onSurface
                : theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekday picker
// ---------------------------------------------------------------------------

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({
    required this.selected,
    required this.onToggle,
    required this.theme,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;
  final ThemeData theme;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isSelected = selected.contains(index);
        return GestureDetector(
          onTap: () => onToggle(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
            ),
            alignment: Alignment.center,
            child: Text(
              _labels[index],
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// End condition picker
// ---------------------------------------------------------------------------

class _EndConditionPicker extends StatelessWidget {
  const _EndConditionPicker({
    required this.endCondition,
    required this.repeatUntil,
    required this.occurrenceCount,
    required this.onEndConditionChanged,
    required this.onPickDate,
    required this.onOccurrenceCountChanged,
    required this.theme,
  });

  final _EndCondition endCondition;
  final DateTime? repeatUntil;
  final int occurrenceCount;
  final ValueChanged<_EndCondition> onEndConditionChanged;
  final VoidCallback onPickDate;
  final ValueChanged<int> onOccurrenceCountChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented control for end condition
        SegmentedButton<_EndCondition>(
          segments: _EndCondition.values
              .map(
                (c) => ButtonSegment<_EndCondition>(
                  value: c,
                  label: Text(c.label),
                ),
              )
              .toList(),
          selected: {endCondition},
          onSelectionChanged: (s) => onEndConditionChanged(s.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
        ),

        // Date picker row
        if (endCondition == _EndCondition.onDate) ...[
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    repeatUntil != null
                        ? DateFormat('EEEE, MMMM d, yyyy').format(repeatUntil!)
                        : 'Pick end date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: repeatUntil != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Occurrence count stepper
        if (endCondition == _EndCondition.afterOccurrences) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                onPressed: occurrenceCount > 1
                    ? () => onOccurrenceCountChanged(occurrenceCount - 1)
                    : null,
                theme: theme,
              ),
              const SizedBox(width: 12),
              Text(
                '$occurrenceCount ${occurrenceCount == 1 ? "occurrence" : "occurrences"}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              _StepButton(
                icon: Icons.add,
                onPressed: occurrenceCount < 999
                    ? () => onOccurrenceCountChanged(occurrenceCount + 1)
                    : null,
                theme: theme,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Utility
// ---------------------------------------------------------------------------

bool _isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
