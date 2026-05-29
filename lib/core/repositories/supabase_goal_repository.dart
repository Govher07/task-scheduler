import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import 'goal_repository.dart';

class SupabaseGoalRepository implements GoalRepository {
  final SupabaseClient _client;

  SupabaseGoalRepository(this._client);

  Goal _fromRow(Map<String, dynamic> row) {
    return Goal(
      id: row['id'] as String,
      name: row['name'] as String,
      type: GoalType.values.byName(row['type'] as String),
      description: row['description'] as String?,
      starttime: row['starttime'] != null
          ? DateTime.parse(row['starttime'] as String)
          : null,
      deadline: row['deadline'] != null
          ? DateTime.parse(row['deadline'] as String)
          : null,
      gotRewards: row['got_rewards'] as bool? ?? false,
      rewardCoins: row['reward_coins'] as int? ?? 50,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> _toRow(Goal goal) {
    return {
      'id': goal.id,
      'name': goal.name,
      'type': goal.type.name,
      'description': goal.description,
      'starttime': goal.starttime?.toIso8601String(),
      'deadline': goal.deadline?.toIso8601String(),
      'got_rewards': goal.gotRewards,
      'reward_coins': goal.rewardCoins,
      'user_id': _client.auth.currentUser?.id,
      'created_at': goal.createdAt.toIso8601String(),
      'updated_at': goal.updatedAt.toIso8601String(),
    };
  }

  @override
  Future<void> createGoal(Goal goal) async {
    await _client.from('goals').insert(_toRow(goal));
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    final row = await _client.from('goals').select().eq('id', id).maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<Goal>> getAllGoals() async {
    final rows = await _client.from('goals').select();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    await _client.from('goals').update(_toRow(goal)).eq('id', goal.id);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _client.from('goals').delete().eq('id', id);
  }

  @override
  Stream<List<Goal>> watchAllGoals() {
    return _client
        .from('goals')
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(_fromRow).toList());
  }
}
