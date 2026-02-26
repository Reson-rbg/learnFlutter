import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';
import '../providers/todo_provider.dart';
import '../providers/achievement_provider.dart';
import 'dart:math';

/// 专注计时页面 - 番茄钟 / 自定义时长
class FocusTimerPage extends StatefulWidget {
  const FocusTimerPage({super.key});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _selectedMinutes = 25;
  String? _selectedTodoId;

  final List<int> _presets = [15, 25, 45, 60];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();
    final todoProvider = context.watch<TodoProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('专注模式'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '专注记录',
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 周统计卡片
            _buildWeeklyStatsCard(focusProvider, theme),
            const SizedBox(height: 24),

            // 计时器圆环
            _buildTimerRing(focusProvider, theme),
            const SizedBox(height: 24),

            // 配置区 (仅未运行时可操作)
            if (!focusProvider.isRunning) ...[
              // 时长选择
              _buildPresetChips(focusProvider),
              const SizedBox(height: 16),

              // 绑定任务
              _buildTaskSelector(todoProvider, focusProvider),
              const SizedBox(height: 24),
            ],

            // 控制按钮
            _buildControlButtons(focusProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStatsCard(FocusProvider fp, ThemeData theme) {
    final stats = fp.weeklyStats;
    final totalMin = stats['totalMinutes'] ?? 0;
    final sessions = stats['sessionCount'] ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('本周专注', '${totalMin}分钟', Icons.timer, theme),
            _statItem('本周次数', '$sessions次', Icons.repeat, theme),
            _statItem('今日专注', '${fp.todayMinutes}分钟', Icons.today, theme),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildTimerRing(FocusProvider fp, ThemeData theme) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景环
          SizedBox(
            width: 260,
            height: 260,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 12,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          // 进度环
          SizedBox(
            width: 260,
            height: 260,
            child: CircularProgressIndicator(
              value: fp.progress,
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              color: fp.isRunning
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ),
          // 时间显示
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final scale = fp.isRunning
                  ? 1.0 + (_pulseController.value * 0.03)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fp.displayTime,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ),
                    if (fp.isRunning)
                      Text('专注中...', style: theme.textTheme.bodySmall),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChips(FocusProvider fp) {
    return Wrap(
      spacing: 12,
      children: _presets.map((m) {
        final selected = _selectedMinutes == m;
        return ChoiceChip(
          label: Text('$m 分钟'),
          selected: selected,
          onSelected: (_) {
            setState(() => _selectedMinutes = m);
            fp.configure(minutes: m, todoId: _selectedTodoId);
          },
        );
      }).toList(),
    );
  }

  Widget _buildTaskSelector(TodoProvider tp, FocusProvider fp) {
    final focusTodos = tp.focusTodos;
    if (focusTodos.isEmpty) {
      return const Text('提示: 将任务标记为"专注"可在此处关联', style: TextStyle(color: Colors.grey));
    }
    return DropdownButtonFormField<String>(
      initialValue: _selectedTodoId,
      decoration: const InputDecoration(
        labelText: '关联任务 (可选)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.link),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('不关联')),
        ...focusTodos.map((t) => DropdownMenuItem(
              value: t.id,
              child: Text(t.title, overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) {
        setState(() => _selectedTodoId = v);
        fp.configure(minutes: _selectedMinutes, todoId: v);
      },
    );
  }

  Widget _buildControlButtons(FocusProvider fp) {
    if (!fp.isRunning && fp.progress == 0) {
      // 初始状态
      return FilledButton.icon(
        onPressed: () {
          fp.configure(minutes: _selectedMinutes, todoId: _selectedTodoId);
          fp.start();
        },
        icon: const Icon(Icons.play_arrow, size: 32),
        label: const Text('开始专注', style: TextStyle(fontSize: 18)),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        ),
      );
    }

    if (fp.isRunning) {
      // 运行中
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: fp.pause,
            icon: const Icon(Icons.pause),
            label: const Text('暂停'),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: () => _confirmAbandon(fp),
            icon: const Icon(Icons.stop, color: Colors.red),
            label: const Text('结束', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    }

    // 暂停状态
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: fp.resume,
          icon: const Icon(Icons.play_arrow),
          label: const Text('继续'),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () => _confirmAbandon(fp),
          icon: const Icon(Icons.stop),
          label: const Text('放弃'),
        ),
      ],
    );
  }

  void _confirmAbandon(FocusProvider fp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('结束专注?'),
        content: const Text('已专注的时间仍会被记录。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await fp.abandon();
              // 触发成就检查
              if (mounted) {
                final ap = context.read<AchievementProvider>();
                final totalSessions = fp.sessions.length;
                final maxMin = fp.sessions.isEmpty
                    ? 0
                    : fp.sessions.map((s) => s.duration).reduce(max);
                final totalMin = fp.sessions.fold(0, (s, e) => s + e.duration);
                await ap.checkAndUnlock(
                  focusSessions: totalSessions,
                  singleFocusMinutes: maxMin,
                  totalFocusMinutes: totalMin,
                );
              }
            },
            child: const Text('确定结束'),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context) {
    final fp = context.read<FocusProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('专注记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: fp.sessions.isEmpty
                  ? const Center(child: Text('还没有专注记录'))
                  : ListView.builder(
                      controller: sc,
                      itemCount: fp.sessions.length,
                      itemBuilder: (_, i) {
                        final s = fp.sessions[i];
                        return ListTile(
                          leading: const Icon(Icons.timer_outlined),
                          title: Text('${s.duration} 分钟'),
                          subtitle: Text(
                            '${s.startTime.month}/${s.startTime.day} ${s.startTime.hour}:${s.startTime.minute.toString().padLeft(2, '0')}',
                          ),
                          trailing: s.todoId != null
                              ? const Chip(label: Text('关联任务'))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


