import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'repositories/goal_repository.dart';
import 'repositories/task_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/supabase_goal_repository.dart';
import 'repositories/supabase_task_repository.dart';
import 'repositories/supabase_event_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return SupabaseGoalRepository(ref.watch(supabaseClientProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return SupabaseTaskRepository(ref.watch(supabaseClientProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return SupabaseEventRepository(ref.watch(supabaseClientProvider));
});
