import 'package:flutter/material.dart';
import '../models/enums.dart';

class StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _color),
      ),
    );
  }

  String get _label {
    switch (status) {
      case TaskStatus.todo: return 'TO DO';
      case TaskStatus.inProgress: return 'IN PROGRESS';
      case TaskStatus.done: return 'DONE';
    }
  }

  Color get _color {
    switch (status) {
      case TaskStatus.todo: return Colors.grey;
      case TaskStatus.inProgress: return Colors.blue;
      case TaskStatus.done: return Colors.green;
    }
  }
}
