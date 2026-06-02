import 'package:flutter/material.dart';
import '../models/enums.dart';

class PriorityBadge extends StatelessWidget {
  final Priority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color foregroundColor;
    final Color backgroundColor;

    switch (priority) {
      case Priority.high:
        foregroundColor = colorScheme.error;
        backgroundColor = colorScheme.errorContainer;
      case Priority.medium:
        foregroundColor = colorScheme.tertiary;
        backgroundColor = colorScheme.tertiaryContainer;
      case Priority.low:
        foregroundColor = colorScheme.primary;
        backgroundColor = colorScheme.primaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
      ),
    );
  }
}
