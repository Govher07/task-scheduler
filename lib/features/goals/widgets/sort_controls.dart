import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/goals_provider.dart';

class SortControls extends ConsumerWidget {
  const SortControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sortFieldProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<SortField>(
        segments: const [
          ButtonSegment(value: SortField.priority, label: Text('Priority')),
          ButtonSegment(value: SortField.deadline, label: Text('Deadline')),
          ButtonSegment(value: SortField.effort, label: Text('Effort')),
        ],
        selected: {current},
        onSelectionChanged: (selection) {
          ref.read(sortFieldProvider.notifier).state = selection.first;
        },
      ),
    );
  }
}
