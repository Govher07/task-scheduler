import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import '../models/task.dart';

class RewardService {
  final SupabaseClient _client;

  RewardService(this._client);

  // ── Coin calculation ────────────────────────────────────────────────────────

  // Static: base + priority + effort — stored in DB, never changes
  static int calcStaticReward(Priority priority, EffortLevel effortLevel) {
    int coins = 10;

    coins += switch (priority) {
      Priority.high => 20,
      Priority.medium => 10,
      _ => 0,
    };

    coins += switch (effortLevel) {
      EffortLevel.high => 20,
      EffortLevel.medium => 10,
      _ => 0,
    };

    return coins;
  }

  // Dynamic: deadline bonus based on today — changes every day, never stored
  static int calcDeadlineBonus(DateTime? deadline) {
    if (deadline == null) return 0;
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft >= 3) return 20;
    if (daysLeft >= 1) return 10;
    return 0;
  }

  // Total at the moment of completion = static (DB) + live deadline bonus
  static int calcTotalReward(Task task) {
    return task.rewardCoins + calcDeadlineBonus(task.deadline);
  }

  // Dynamic goal bonus — task count changes, deadline bonus changes every day
  static int calcGoalDynamicBonus(Goal goal, int taskCount) {
    int bonus = taskCount * 5;
    if (goal.deadline != null && DateTime.now().isBefore(goal.deadline!)) {
      bonus += 30;
    }
    return bonus;
  }

  // Total at the moment of completion = stored base + live dynamic bonus
  static int calcTotalGoalReward(Goal goal, int taskCount) {
    return goal.rewardCoins + calcGoalDynamicBonus(goal, taskCount);
  }

  // ── Grant rewards ───────────────────────────────────────────────────────────

  Future<void> grantTaskReward(Task task) async {
    if (task.gotRewards) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final coins = calcTotalReward(task); // dynamic total at moment of completion

    await Future.wait([
      _client.from('coin_transactions').insert({
        'user_id': userId,
        'amount': coins,
        'reason': 'task_completed',
      }),
      _incrementBalance(userId, coins),
      _client.from('tasks').update({
        'got_rewards': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', task.id),
    ]);
  }

  Future<void> grantGoalReward(Goal goal, int taskCount) async {
    if (goal.gotRewards) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final coins = calcTotalGoalReward(goal, taskCount);

    await Future.wait([
      _client.from('coin_transactions').insert({
        'user_id': userId,
        'amount': coins,
        'reason': 'goal_completed',
      }),
      _incrementBalance(userId, coins),
      _client.from('goals').update({
        'got_rewards': true,
        'reward_coins': coins,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', goal.id),
    ]);
  }

  // ── Balance ─────────────────────────────────────────────────────────────────

  Future<int> getBalance() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final row = await _client
        .from('profiles')
        .select('balance')
        .eq('id', userId)
        .single();

    return row['balance'] as int? ?? 0;
  }

  Future<void> purchaseItem(String itemId, int price) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final balance = await getBalance();
    if (balance < price) throw Exception('Insufficient coins');

    await Future.wait([
      _client.from('coin_transactions').insert({
        'user_id': userId,
        'amount': -price,
        'reason': 'item_purchased',
      }),
      _incrementBalance(userId, -price),
      _client.from('shop_inventory').insert({
        'user_id': userId,
        'item_id': itemId,
        'price_paid': price,
      }),
    ]);
  }

  Future<Map<String, Map<String, dynamic>?>> getRoomSlots() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final rows = await _client
        .from('room_slots')
        .select('slot_type, shop_items(*)')
        .eq('user_id', userId);

    final result = <String, Map<String, dynamic>?>{
      'animals': null, 'plants': null, 'decor': null, 'characters': null,
    };
    for (final row in rows) {
      final slotType = row['slot_type'] as String;
      final itemData = row['shop_items'];
      if (itemData != null) result[slotType] = Map<String, dynamic>.from(itemData as Map);
    }
    return result;
  }

  Future<void> setRoomSlot(String slotType, String? itemId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (itemId == null) {
      await _client.from('room_slots').delete()
          .eq('user_id', userId).eq('slot_type', slotType);
    } else {
      await _client.from('room_slots').upsert({
        'user_id': userId,
        'slot_type': slotType,
        'item_id': itemId,
      }, onConflict: 'user_id,slot_type');
    }
  }

  Future<List<Map<String, dynamic>>> getShopItems() async {
    final rows = await _client
        .from('shop_items')
        .select()
        .eq('is_active', true)
        .order('category')
        .order('price');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getOwnedItems() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('shop_inventory')
        .select('shop_items(*)')
        .eq('user_id', userId);

    return rows
        .map((r) => Map<String, dynamic>.from(r['shop_items'] as Map))
        .toList();
  }

  Future<List<String>> getPurchasedItemNames() async {
    final owned = await getOwnedItems();
    return owned.map((r) => r['name'] as String).toList();
  }

  Future<void> spendCoins({
    required int amount,
    required String itemId,
    required int pricePaid,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final balance = await getBalance();
    if (balance < amount) throw Exception('Insufficient coins');

    await Future.wait([
      _client.from('coin_transactions').insert({
        'user_id': userId,
        'amount': -amount,
        'reason': 'item_purchased',
      }),
      _incrementBalance(userId, -amount),
      _client.from('shop_inventory').insert({
        'user_id': userId,
        'item_id': itemId,
        'price_paid': pricePaid,
      }),
    ]);
  }

  Future<void> _incrementBalance(String userId, int amount) async {
    final row = await _client
        .from('profiles')
        .select('balance')
        .eq('id', userId)
        .single();

    final current = row['balance'] as int? ?? 0;
    await _client.from('profiles').update({
      'balance': current + amount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}
