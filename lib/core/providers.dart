import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'repositories/goal_repository.dart';
import 'repositories/task_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/supabase_goal_repository.dart';
import 'repositories/supabase_task_repository.dart';
import 'repositories/supabase_event_repository.dart';
import 'repositories/mock_goal_repository.dart';
import 'repositories/mock_task_repository.dart';
import 'repositories/mock_event_repository.dart';
import 'services/reward_service.dart';

const bool useMock = false;

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  if (useMock) {
    final repo = MockGoalRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return SupabaseGoalRepository(ref.watch(supabaseClientProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  if (useMock) {
    final repo = MockTaskRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return SupabaseTaskRepository(ref.watch(supabaseClientProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  if (useMock) {
    final repo = MockEventRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return SupabaseEventRepository(ref.watch(supabaseClientProvider));
});

final rewardServiceProvider = Provider<RewardService>((ref) {
  return RewardService(ref.watch(supabaseClientProvider));
});
