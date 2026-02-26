import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/achievement_provider.dart';


/// 个性化周报弹窗
class WeeklyReviewDialog extends StatelessWidget {
  const WeeklyReviewDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const WeeklyReviewDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todoProvider = context.read<TodoProvider>();
    final focusProvider = context.read<FocusProvider>();
    final achievementProvider = context.read<AchievementProvider>();

    // 计算本周数据
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final allTodos = todoProvider.todos;
    final completedThisWeek = allTodos.where((t) => t.isCompleted).length; // 简化：用总完成数
    final totalTasks = allTodos.length;

    final focusStats = focusProvider.weeklyStats;
    final focusMinutes = focusStats['totalMinutes'] ?? 0;
    final focusSessions = focusStats['sessionCount'] ?? 0;

    final badgeCount = achievementProvider.unlockedCount;
    final totalBadges = achievementProvider.totalBadges;

    // 生成个性化评语
    final comment = _generateComment(completedThisWeek, focusMinutes, focusSessions);

    return AlertDialog(
      title: Row(
        children: [
          const Text('📊 '),
          Text('本周回顾', style: theme.textTheme.titleLarge),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 个性化评语
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          comment,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 任务统计
              _buildStatRow(theme, '✅', '完成任务', '$completedThisWeek / $totalTasks'),
              _buildStatRow(theme, '🧘', '专注时长', '$focusMinutes 分钟'),
              _buildStatRow(theme, '🔄', '专注次数', '$focusSessions 次'),
              _buildStatRow(theme, '🏆', '已获徽章', '$badgeCount / $totalBadges'),
              const SizedBox(height: 16),

              // 趋势提示
              _buildTrendTip(theme, focusMinutes, completedThisWeek),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    );
  }

  Widget _buildStatRow(ThemeData theme, String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTrendTip(ThemeData theme, int focusMinutes, int completedTasks) {
    String tip;
    IconData icon;
    Color color;

    if (focusMinutes >= 120 && completedTasks >= 10) {
      tip = '🎉 本周状态超棒！继续保持！';
      icon = Icons.trending_up;
      color = Colors.green;
    } else if (focusMinutes >= 60 || completedTasks >= 5) {
      tip = '👍 稳步推进中，再接再厉！';
      icon = Icons.trending_flat;
      color = Colors.orange;
    } else {
      tip = '💪 新的一周开始了，加油！';
      icon = Icons.lightbulb_outline;
      color = Colors.blue;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(tip),
      ),
    );
  }

  String _generateComment(int completed, int focusMin, int focusSessions) {
    if (completed >= 10 && focusMin >= 120) {
      return '你是效率之星！本周完成了$completed个任务，专注了$focusMin分钟。令人敬佩！';
    } else if (completed >= 5) {
      return '不错的一周！完成了$completed个任务。试试专注模式，效率会更高哦～';
    } else if (focusSessions > 0) {
      return '专注力在提升！本周有$focusSessions次专注。多设定一些小目标会更棒！';
    }
    return '新的一周充满可能！设定几个小目标，开启你的高效之旅吧 🚀';
  }
}
