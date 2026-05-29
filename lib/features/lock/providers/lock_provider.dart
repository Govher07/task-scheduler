import 'package:flutter_riverpod/flutter_riverpod.dart';

class LockState {
  final DateTime? lockEndTime;
  const LockState({this.lockEndTime});

  bool get isLocked =>
      lockEndTime != null && DateTime.now().isBefore(lockEndTime!);

  Duration get remaining {
    if (lockEndTime == null) return Duration.zero;
    final diff = lockEndTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

class LockNotifier extends Notifier<LockState> {
  @override
  LockState build() => const LockState();

  void lock(Duration duration) {
    state = LockState(lockEndTime: DateTime.now().add(duration));
  }

  void unlock() {
    state = const LockState();
  }
}

final lockProvider = NotifierProvider<LockNotifier, LockState>(
  LockNotifier.new,
);
