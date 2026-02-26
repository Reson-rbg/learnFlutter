import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/achievement_provider.dart';
import '../services/database_service.dart';
import '../models/task_template.dart';

/// 设置页面 - 主题/数据备份/模板管理/隐私设置
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseService _db = DatabaseService();
  List<TaskTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    final templates = await _db.getTemplates(userId);
    if (mounted) setState(() => _templates = templates);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 用户信息
          _buildSection('账号', [
            ListTile(
              leading: CircleAvatar(
                child: Text(auth.currentUser?.username.substring(0, 1).toUpperCase() ?? '?'),
              ),
              title: Text(auth.currentUser?.username ?? '未登录'),
              subtitle: const Text('已登录'),
            ),
          ]),

          // 外观
          _buildSection('外观', [
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('应用主题'),
              subtitle: Text(themeProvider.currentStyle == AppThemeStyle.simple ? '简洁模式' : '丰富模式'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemePicker(themeProvider),
            ),
          ]),

          // 任务模板
          _buildSection('任务模板', [
            ..._templates.map((t) => ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(t.title),
                  subtitle: Text(t.tags.isEmpty ? '无标签' : t.tags.join(', ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deleteTemplate(t.id),
                  ),
                )),
            if (_templates.isEmpty)
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('还没有模板'),
                subtitle: Text('在创建任务时可以保存为模板'),
              ),
          ]),

          // 数据管理
          _buildSection('数据管理', [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('导出数据'),
              subtitle: const Text('导出所有任务、打卡和专注记录'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportData(auth.userId),
            ),
          ]),

          // 关于
          _buildSection('关于', [
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('版本'),
              subtitle: Text('V2.0'),
            ),
          ]),

          // 退出
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('退出登录', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }

  void _showThemePicker(ThemeProvider tp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('简洁模式'),
              leading: Radio<AppThemeStyle>(
                value: AppThemeStyle.simple,
                groupValue: tp.currentStyle,
                onChanged: (_) {
                  tp.toggleTheme();
                  context.read<AchievementProvider>().checkAndUnlock(themeSwitched: true);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                if (tp.currentStyle != AppThemeStyle.simple) tp.toggleTheme();
                context.read<AchievementProvider>().checkAndUnlock(themeSwitched: true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('丰富模式'),
              leading: Radio<AppThemeStyle>(
                value: AppThemeStyle.rich,
                groupValue: tp.currentStyle,
                onChanged: (_) {
                  tp.toggleTheme();
                  context.read<AchievementProvider>().checkAndUnlock(themeSwitched: true);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                if (tp.currentStyle != AppThemeStyle.rich) tp.toggleTheme();
                context.read<AchievementProvider>().checkAndUnlock(themeSwitched: true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTemplate(String id) async {
    try {
      await _db.deleteTemplate(id);
      await _loadTemplates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Future<void> _exportData(String? userId) async {
    if (userId == null) return;
    try {
      final data = await _db.exportUserData(userId);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      // 触发数据导出成就
      if (mounted) {
        context.read<AchievementProvider>().checkAndUnlock(dataExported: true);
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('数据导出成功'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonStr,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }
}
