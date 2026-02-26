import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/todo_provider.dart';

// -------------------------------------------------------------------------
// 知识点：数据统计页面 (Version 2.0 - 使用 fl_chart)
// -------------------------------------------------------------------------

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          final todos = provider.todos;

          if (todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_chart_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无数据，快去添加任务吧！',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final completedCount = todos.where((t) => t.isCompleted).length;
          final pendingCount = todos.length - completedCount;
          final completionRate = completionRatePercent(
            completedCount,
            todos.length,
          );

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '统计概览',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),

                  // 1. 任务完成率环形图
                  SizedBox(
                    height: 250,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: completedCount.toDouble(),
                                color: Colors.greenAccent[400],
                                title:
                                    '${(completionRate).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              PieChartSectionData(
                                value: pendingCount.toDouble(),
                                color: Colors.orangeAccent[400],
                                title: '',
                                radius: 40,
                              ),
                            ],
                            sectionsSpace: 4,
                            centerSpaceRadius: 60,
                            startDegreeOffset: -90,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '总任务',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${todos.length}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 2. 统计卡片
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: '已完成',
                          value: '$completedCount',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: '待办',
                          value: '$pendingCount',
                          icon: Icons.schedule,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. 标签分析
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '标签分布',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          _TagStatList(todos: todos),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double completionRatePercent(int completed, int total) {
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _TagStatList extends StatelessWidget {
  final List<dynamic> todos;

  const _TagStatList({required this.todos});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> tagCounts = {};
    for (var todo in todos) {
      if (todo.tags != null) {
        for (var tag in todo.tags!) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }

    if (tagCounts.isEmpty) {
      return const Text('暂无标签数据');
    }

    // Sort by count desc
    final sortedEntries = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.take(5).map((e) {
        final percentage = (e.value / todos.length);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  e.key,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text('${e.value}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
