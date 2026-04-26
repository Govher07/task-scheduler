import 'package:flutter/material.dart';
import '../models/enums.dart';

class PriorityBadge extends StatelessWidget {
  final Priority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _color),
      ),
    );
  }

  Color get _color {
    switch (priority) {
      case Priority.high: return Colors.red;
      case Priority.medium: return Colors.orange;
      case Priority.low: return Colors.green;
    }
  }
}
