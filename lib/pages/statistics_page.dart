import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

// -------------------------------------------------------------------------
// 知识点：数据统计页面
// -------------------------------------------------------------------------
// 演示如何从 Provider 获取数据并进行可视化展示

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 来监听数据变化
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '任务概览',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              
              // 进度条卡片
              _buildProgressCard(context, provider),
              
              const SizedBox(height: 24),
              
              // 详细数据 Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      context,
                      '总任务',
                      '${provider.totalCount}',
                      Colors.blue,
                      Icons.list_alt,
                    ),
                    _buildStatCard(
                      context,
                      '已完成',
                      '${provider.completedCount}',
                      Colors.green,
                      Icons.check_circle_outline,
                    ),
                    _buildStatCard(
                      context,
                      '进行中',
                      '${provider.activeCount}',
                      Colors.orange,
                      Icons.pending_actions,
                    ),
                    _buildStatCard(
                      context,
                      '完成率',
                      '${(provider.progress * 100).toStringAsFixed(0)}%',
                      Colors.purple,
                      Icons.pie_chart_outline,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(BuildContext context, TodoProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('整体进度', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${(provider.progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: provider.progress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: TextStyle(color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}
