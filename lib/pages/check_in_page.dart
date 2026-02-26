import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/check_in.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';

// -------------------------------------------------------------------------
// 知识点：每日打卡页面 (Version 2.0 - 包含心情追踪和热力图)
// -------------------------------------------------------------------------

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final _dbService = DatabaseService();
  List<CheckIn> _checkIns = [];
  bool _hasCheckedInToday = false;
  bool _isLoading = true;

  // 连续打卡天数 (简单计算：倒序遍历)
  int get _streakDays {
    if (_checkIns.isEmpty) return 0;
    int streak = 0;
    DateTime date = DateTime.now();

    // 如果今天没打卡，从昨天算起；如果今天打卡了，从今天算起
    if (!_hasCheckedInToday) {
      date = date.subtract(const Duration(days: 1));
    }

    // 按天匹配
    for (int i = 0; i < 365; i++) {
      final dayStr = DateFormat('yyyy-MM-dd').format(date);
      // Check if any check-in exists for this day
      final hasRecord = _checkIns.any(
        (c) => DateFormat('yyyy-MM-dd').format(c.checkInTime) == dayStr,
      );
      if (hasRecord) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final hasChecked = await _dbService.hasCheckedInToday(userId);
      final list = await _dbService.getCheckIns(userId);

      if (mounted) {
        setState(() {
          _hasCheckedInToday = hasChecked;
          _checkIns = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading check-ins: $e');
    }
  }

  Future<void> _doCheckIn() async {
    final userId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.id;
    if (userId == null) return;

    // 弹出打卡对话框
    await showDialog(
      context: context,
      builder: (context) => _CheckInDialog(
        userId: userId,
        onSuccess: () async {
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('打卡成功！坚持就是胜利！')));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 头部打卡区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _hasCheckedInToday ? '今日已打卡' : '早起打卡',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '已连续打卡 $_streakDays 天',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _hasCheckedInToday ? null : _doCheckIn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasCheckedInToday
                              ? Icons.check_circle
                              : Icons.touch_app,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _hasCheckedInToday ? '任务达成' : '立即打卡',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 习惯日历热力图 (简单展示最近30天)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '过去30天记录',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildHeatMap(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              '详细记录',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _checkIns.length,
            itemBuilder: (context, index) {
              final item = _checkIns[index];
              return Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Text(_getMoodEmoji(item.mood)),
                  ),
                  title: Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(item.checkInTime),
                  ),
                  subtitle: Text(item.note.isNotEmpty ? item.note : '无备注'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(int? mood) {
    if (mood == 0) return '😊';
    if (mood == 1) return '😐';
    if (mood == 2) return '😫';
    return '📅';
  }

  Widget _buildHeatMap() {
    // 生成过去30天的日期
    final now = DateTime.now();
    final days = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 一周7天
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayStr = DateFormat('yyyy-MM-dd').format(day);

        // Find record for this day
        // Note: _checkIns is sorted by time DESC, but we just need to find one
        final records = _checkIns
            .where(
              (c) => DateFormat('yyyy-MM-dd').format(c.checkInTime) == dayStr,
            )
            .toList();
        final record = records.isNotEmpty ? records.first : null;
        final hasRecord = record != null;

        return Tooltip(
          message:
              '${DateFormat('MM-dd').format(day)}${hasRecord ? ': ${_getMoodEmoji(record?.mood)}' : ''}',
          child: Container(
            decoration: BoxDecoration(
              color: hasRecord ? _getMoodColor(record?.mood) : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 10,
                  color: hasRecord ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getMoodColor(int? mood) {
    if (mood == 0) return Colors.green.shade400; // Happy
    if (mood == 1) return Colors.orange.shade400; // Neutral
    if (mood == 2) return Colors.red.shade400; // Sad
    if (mood == null) return Colors.blue.shade300; // Just checkin
    return Colors.blue.shade300;
  }
}

class _CheckInDialog extends StatefulWidget {
  final String userId;
  final VoidCallback onSuccess;

  const _CheckInDialog({required this.userId, required this.onSuccess});

  @override
  State<_CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<_CheckInDialog> {
  final _noteController = TextEditingController();
  int _selectedMood = 0; // 默认开心
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('今日打卡'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('记录此刻心情:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MoodIcon(
                  icon: '😊',
                  label: '轻松',
                  isSelected: _selectedMood == 0,
                  onTap: () => setState(() => _selectedMood = 0),
                ),
                _MoodIcon(
                  icon: '😐',
                  label: '一般',
                  isSelected: _selectedMood == 1,
                  onTap: () => setState(() => _selectedMood = 1),
                ),
                _MoodIcon(
                  icon: '😫',
                  label: '艰难',
                  isSelected: _selectedMood == 2,
                  onTap: () => setState(() => _selectedMood = 2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '写句鼓励自己的话吧',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submitting
              ? null
              : () async {
                  setState(() => _submitting = true);
                  try {
                    final newCheckIn = CheckIn(
                      id: const Uuid().v4(),
                      userId: widget.userId,
                      checkInTime: DateTime.now(),
                      note: _noteController.text,
                      mood: _selectedMood,
                    );
                    await DatabaseService().insertCheckIn(newCheckIn);
                    Navigator.pop(context);
                    widget.onSuccess();
                  } catch (e) {
                    setState(() => _submitting = false);
                  }
                },
          child: _submitting
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Text('打卡'),
        ),
      ],
    );
  }
}

class _MoodIcon extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
