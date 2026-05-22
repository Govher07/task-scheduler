import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/goal.dart';
import '../../../core/providers.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  final String? goalId;
  const GoalFormScreen({super.key, this.goalId});

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _starttime;
  DateTime? _deadline;
  GoalType _type = GoalType.completable;
  Goal? _existingGoal;
  bool _isLoading = true;

  bool get _isEditing => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) { _loadGoal(); } else { _isLoading = false; }
  }

  Future<void> _loadGoal() async {
    final goal = await ref.read(goalRepositoryProvider).getGoalById(widget.goalId!);
    if (goal != null && mounted) {
      setState(() {
        _existingGoal = goal;
        _nameController.text = goal.name;
        _starttime = goal.starttime;
        _deadline = goal.deadline;
        _descriptionController.text = goal.description ?? '';
        _type = goal.type;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Goal' : 'New Goal')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Goal' : 'New Goal'),
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
              decoration: const InputDecoration(labelText: 'Goal Name', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
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
                      final lastDate = _deadline ?? DateTime.now().add(const Duration(days: 365 * 5));
                      final raw = _starttime ?? DateTime.now();
                      final initialDate = raw.isAfter(lastDate) ? lastDate : raw;
                      final date = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(2020),
                        lastDate: lastDate,
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
                      final firstDate = _starttime ?? DateTime(2020);
                      final raw = _deadline ?? DateTime.now();
                      final initialDate = raw.isBefore(firstDate) ? firstDate : raw;
                      final date = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: firstDate,
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GoalType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Goal Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: GoalType.completable, child: Text('Completable')),
                DropdownMenuItem(value: GoalType.ongoing, child: Text('Ongoing')),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(_isEditing ? 'Update' : 'Create')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final goal = Goal(
      id: _existingGoal?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _type,
      starttime: _starttime,
      deadline: _deadline,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      createdAt: _existingGoal?.createdAt ?? now,
      updatedAt: now,
    );
    final repo = ref.read(goalRepositoryProvider);
    if (_isEditing) { await repo.updateGoal(goal); } else { await repo.createGoal(goal); }
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Success'),
          content: Text(_isEditing
              ? 'Goal updated successfully.'
              : 'Goal created successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                if (mounted) context.pop(); // Return to goals screen
              },
              child: const Text('OK'),
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
        title: const Text('Delete Goal'),
        content: const Text('This will delete the goal but keep its tasks as ungrouped. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(goalRepositoryProvider).deleteGoal(widget.goalId!);
              if (mounted) context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
