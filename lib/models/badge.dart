/// 徽章定义 (本地静态数据)
class BadgeDefinition {
  final String key;
  final String name;
  final String description;
  final String icon; // emoji
  final String category; // 任务/习惯/探索

  const BadgeDefinition({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
  });
}

/// 已解锁的徽章记录 (来自后端)
class UserBadge {
  final String id;
  final String userId;
  final String badgeKey;
  final DateTime unlockedAt;

  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeKey,
    required this.unlockedAt,
  });

  factory UserBadge.fromMap(Map<String, dynamic> map) => UserBadge(
    id: map['id'],
    userId: map['userId'],
    badgeKey: map['badgeKey'],
    unlockedAt: DateTime.parse(map['unlockedAt']),
  );
}

/// 所有可获取的徽章定义
class BadgeCatalog {
  static const List<BadgeDefinition> all = [
    // 任务类
    BadgeDefinition(key: 'first_task', name: '首战告捷', description: '创建第一个任务', icon: '🎯', category: '任务'),
    BadgeDefinition(key: 'task_10', name: '效率达人', description: '累计完成10个任务', icon: '⚡', category: '任务'),
    BadgeDefinition(key: 'task_50', name: '任务大师', description: '累计完成50个任务', icon: '🏆', category: '任务'),
    BadgeDefinition(key: 'task_100', name: '百事通', description: '累计完成100个任务', icon: '💯', category: '任务'),
    BadgeDefinition(key: 'daily_5', name: '日清五事', description: '单日完成5个任务', icon: '🔥', category: '任务'),
    BadgeDefinition(key: 'daily_10', name: '极限效率', description: '单日完成10个任务', icon: '💎', category: '任务'),
    // 习惯类
    BadgeDefinition(key: 'streak_7', name: '七日之约', description: '连续打卡7天', icon: '📅', category: '习惯'),
    BadgeDefinition(key: 'streak_30', name: '月度坚持', description: '连续打卡30天', icon: '🌟', category: '习惯'),
    BadgeDefinition(key: 'streak_100', name: '百日筑基', description: '连续打卡100天', icon: '👑', category: '习惯'),
    BadgeDefinition(key: 'checkin_total_50', name: '半百记录', description: '累计打卡50次', icon: '📝', category: '习惯'),
    // 专注类
    BadgeDefinition(key: 'focus_first', name: '初心者', description: '完成第一次专注', icon: '🧘', category: '探索'),
    BadgeDefinition(key: 'focus_60', name: '深度专注', description: '单次专注60分钟', icon: '⏰', category: '探索'),
    BadgeDefinition(key: 'focus_total_300', name: '时间管理者', description: '累计专注300分钟', icon: '⏳', category: '探索'),
    // 探索类
    BadgeDefinition(key: 'theme_switch', name: '主题收藏家', description: '切换过应用主题', icon: '🎨', category: '探索'),
    BadgeDefinition(key: 'template_create', name: '模板大师', description: '创建任务模板', icon: '📋', category: '探索'),
    BadgeDefinition(key: 'data_export', name: '数据守护者', description: '导出个人数据', icon: '💾', category: '探索'),
  ];

  static BadgeDefinition? getByKey(String key) {
    try {
      return all.firstWhere((b) => b.key == key);
    } catch (_) {
      return null;
    }
  }
}
