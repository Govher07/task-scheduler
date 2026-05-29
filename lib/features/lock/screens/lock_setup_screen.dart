import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/seasonal_background.dart';
import '../providers/lock_provider.dart';

class LockSetupScreen extends ConsumerStatefulWidget {
  const LockSetupScreen({super.key});

  @override
  ConsumerState<LockSetupScreen> createState() => _LockSetupScreenState();
}

class _LockSetupScreenState extends ConsumerState<LockSetupScreen> {
  Duration _selected = const Duration(minutes: 5);

  static const _options = [
    (label: '1 min', duration: Duration(minutes: 1)),
    (label: '5 min', duration: Duration(minutes: 5)),
    (label: '10 min', duration: Duration(minutes: 10)),
    (label: '15 min', duration: Duration(minutes: 15)),
    (label: '30 min', duration: Duration(minutes: 30)),
    (label: '1 hour', duration: Duration(hours: 1)),
  ];

  void _start() {
    ref.read(lockProvider.notifier).lock(_selected);
    context.go('/lock');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.lock_clock, size: 56, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Screen Lock',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how long to lock the screen',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),

              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: _options.map((opt) {
                  final isSelected = opt.duration == _selected;

                  return SnowCapped(
                    borderRadius: 999,
                    snowHeight: 6,
                    horizontalInset: 3,
                    snowWidthFactor: 0.92,
                    child: ChoiceChip(
                      label: Text(opt.label),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selected = opt.duration;
                        });
                      },
                      selectedColor: colorScheme.primaryContainer,
                      backgroundColor: colorScheme.surface.withValues(
                        alpha: 0.78,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: SnowCapped(
                  borderRadius: 22,
                  snowHeight: 8,
                  horizontalInset: 3,
                  snowWidthFactor: 0.99,
                  child: FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.lock),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
