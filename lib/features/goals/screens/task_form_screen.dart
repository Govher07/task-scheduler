import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/task.dart';
import '../../../core/providers.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final String? taskId;
  const TaskFormScreen({super.key, this.taskId});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Priority _priority = Priority.medium;
  EffortLevel _effortLevel = EffortLevel.medium;
  DateTime? _starttime;
  DateTime? _deadline;
  String? _goalId;
  Task? _existingTask;
  bool _isLoading = true;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadTask();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadTask() async {
    final task = await ref.read(taskRepositoryProvider).getTaskById(widget.taskId!);
    if (task != null && mounted) {
      setState(() {
        _existingTask = task;
        _nameController.text = task.name;
        _priority = task.priority;
        _effortLevel = task.effortLevel;
        _starttime = task.starttime;
        _deadline = task.deadline;
        _goalId = task.goalId;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'New Task')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'New Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Task Name', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EffortLevel>(
              value: _effortLevel,
              decoration: const InputDecoration(labelText: 'Effort Level', border: OutlineInputBorder()),
              items: EffortLevel.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
              onChanged: (value) => setState(() => _effortLevel = value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_starttime == null ? 'No StartTime' : 'StartTime: ${DateFormat.yMMMd().format(_starttime!)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_starttime != null)
                    IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _starttime = null)),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _starttime ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (date != null) setState(() => _starttime = date);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_deadline == null ? 'No Deadline' : 'Deadline: ${DateFormat.yMMMd().format(_deadline!)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_deadline != null)
                    IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _deadline = null)),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _deadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (date != null) setState(() => _deadline = date);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: ref.read(goalRepositoryProvider).getAllGoals(),
              builder: (context, snapshot) {
                final goals = snapshot.data ?? [];
                return DropdownButtonFormField<String?>(
                  value: _goalId,
                  decoration: const InputDecoration(labelText: 'Goal (optional)', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No goal')),
                    ...goals.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
                  ],
                  onChanged: (value) => setState(() => _goalId = value),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final task = Task(
      id: _existingTask?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      goalId: _goalId,
      priority: _priority,
      starttime: _starttime,
      deadline: _deadline,
      estimatedDurationMinutes: _existingTask?.estimatedDurationMinutes,
      effortLevel: _effortLevel,
      status: _existingTask?.status ?? TaskStatus.todo,
      createdAt: _existingTask?.createdAt ?? now,
      updatedAt: now,
    );
    final repo = ref.read(taskRepositoryProvider);
    if (_isEditing) { await repo.updateTask(task); } else { await repo.createTask(task); }
    if (mounted) context.pop();
  }
}
