import 'package:flutter/material.dart';
import '../models/badge.dart';
import '../services/database_service.dart';

/// 成就系统 Provider - 管理徽章解锁和成就数据
class AchievementProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  String? _userId;
  List<UserBadge> _unlockedBadges = [];

  List<UserBadge> get unlockedBadges => _unlockedBadges;
  Set<String> get unlockedKeys => _unlockedBadges.map((b) => b.badgeKey).toSet();

  int get totalBadges => BadgeCatalog.all.length;
  int get unlockedCount => _unlockedBadges.length;

  void setUserId(String userId) {
    _userId = userId;
    loadBadges();
  }

  Future<void> loadBadges() async {
    if (_userId == null) return;
    _unlockedBadges = await _db.getUserBadges(_userId!);
    notifyListeners();
  }

  /// 尝试解锁徽章 (幂等: 已有则跳过)
  Future<bool> tryUnlock(String badgeKey) async {
    if (_userId == null) return false;
    if (unlockedKeys.contains(badgeKey)) return false;

    try {
      await _db.unlockBadge(_userId!, badgeKey);
      await loadBadges();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 根据事件触发徽章检查
  Future<List<String>> checkAndUnlock({
    int? totalCompletedTasks,
    int? dailyCompletedTasks,
    int? streakDays,
    int? totalCheckIns,
    int? focusSessions,
    int? singleFocusMinutes,
    int? totalFocusMinutes,
    bool? themeSwitched,
    bool? templateCreated,
    bool? dataExported,
  }) async {
    final newlyUnlocked = <String>[];

    Future<void> check(String key, bool condition) async {
      if (condition && !unlockedKeys.contains(key)) {
        final unlocked = await tryUnlock(key);
        if (unlocked) newlyUnlocked.add(key);
      }
    }

    // 任务类
    if (totalCompletedTasks != null) {
      await check('first_task', totalCompletedTasks >= 1);
      await check('task_10', totalCompletedTasks >= 10);
      await check('task_50', totalCompletedTasks >= 50);
      await check('task_100', totalCompletedTasks >= 100);
    }
    if (dailyCompletedTasks != null) {
      await check('daily_5', dailyCompletedTasks >= 5);
      await check('daily_10', dailyCompletedTasks >= 10);
    }

    // 习惯类
    if (streakDays != null) {
      await check('streak_7', streakDays >= 7);
      await check('streak_30', streakDays >= 30);
      await check('streak_100', streakDays >= 100);
    }
    if (totalCheckIns != null) {
      await check('checkin_total_50', totalCheckIns >= 50);
    }

    // 专注类
    if (focusSessions != null) {
      await check('focus_first', focusSessions >= 1);
    }
    if (singleFocusMinutes != null) {
      await check('focus_60', singleFocusMinutes >= 60);
    }
    if (totalFocusMinutes != null) {
      await check('focus_total_300', totalFocusMinutes >= 300);
    }

    // 探索类
    if (themeSwitched == true) await check('theme_switch', true);
    if (templateCreated == true) await check('template_create', true);
    if (dataExported == true) await check('data_export', true);

    return newlyUnlocked;
  }

  /// 按类别分组获取所有徽章 (含锁定状态)
  Map<String, List<MapEntry<BadgeDefinition, bool>>> getBadgesByCategory() {
    final map = <String, List<MapEntry<BadgeDefinition, bool>>>{};
    for (final badge in BadgeCatalog.all) {
      final unlocked = unlockedKeys.contains(badge.key);
      map.putIfAbsent(badge.category, () => []);
      map[badge.category]!.add(MapEntry(badge, unlocked));
    }
    return map;
  }
}
