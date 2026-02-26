import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/plaza_event.dart';
import '../services/database_service.dart';

/// 匿名习惯广场页面
class PlazaPage extends StatefulWidget {
  const PlazaPage({super.key});

  @override
  State<PlazaPage> createState() => _PlazaPageState();
}

class _PlazaPageState extends State<PlazaPage> {
  final DatabaseService _db = DatabaseService();
  List<PlazaEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      _events = await _db.getPlazaEvents();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯广场'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '广场设置',
            onPressed: () => _showPlazaSettings(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (_, i) => _buildEventCard(_events[i], theme),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.public, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('广场还没有动态', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('开启"展示到广场"后，你的成就将匿名出现在这里',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEventCard(PlazaEvent event, ThemeData theme) {
    final icon = _getEventIcon(event.eventType);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(event.anonymousName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(event.eventDescription),
            const SizedBox(height: 4),
            Text(
              _formatTime(event.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _getEventIcon(String type) {
    switch (type) {
      case 'task_complete':
        return '✅';
      case 'checkin':
        return '📅';
      case 'focus':
        return '🧘';
      case 'badge':
        return '🏆';
      case 'streak':
        return '🔥';
      default:
        return '⭐';
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  void _showPlazaSettings(BuildContext context) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final settings = await _db.getUserSettings(userId);
    bool showOnPlaza = settings['showOnPlaza'] == 1;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('广场隐私设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('开启后，你的成就动态将匿名展示在广场。其他用户无法知道你的真实身份。'),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('展示到广场'),
                subtitle: const Text('默认关闭，保护隐私'),
                value: showOnPlaza,
                onChanged: (v) {
                  setDialogState(() => showOnPlaza = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await _db.updateUserSettings(userId, showOnPlaza);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
