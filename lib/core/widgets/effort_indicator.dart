import 'package:flutter/material.dart';
import '../models/enums.dart';

class EffortIndicator extends StatelessWidget {
  final EffortLevel level;

  const EffortIndicator({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color color;

    switch (level) {
      case EffortLevel.low:
        color = colorScheme.primary;
      case EffortLevel.medium:
        color = colorScheme.tertiary;
      case EffortLevel.high:
        color = colorScheme.error;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          level.name,
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}