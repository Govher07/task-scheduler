import 'package:flutter/material.dart';
import '../models/enums.dart';

class EffortIndicator extends StatelessWidget {
  final EffortLevel level;

  const EffortIndicator({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt, size: 14, color: _color),
        const SizedBox(width: 2),
        Text(level.name, style: theme.textTheme.labelSmall?.copyWith(color: _color)),
      ],
    );
  }

  Color get _color {
    switch (level) {
      case EffortLevel.low: return Colors.green;
      case EffortLevel.medium: return Colors.orange;
      case EffortLevel.high: return Colors.red;
    }
  }
}
