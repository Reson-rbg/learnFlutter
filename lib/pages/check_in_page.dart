import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/check_in.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';

// -------------------------------------------------------------------------
// 知识点：每日打卡页面
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    
    final hasChecked = await _dbService.hasCheckedInToday(userId);
    final list = await _dbService.getCheckIns(userId);
    
    if (mounted) {
      setState(() {
        _hasCheckedInToday = hasChecked;
        _checkIns = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _doCheckIn() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    final newCheckIn = CheckIn(
      id: const Uuid().v4(),
      userId: userId,
      checkInTime: DateTime.now(),
      note: '早起打卡',
    );

    await _dbService.insertCheckIn(newCheckIn);
    await _loadData(); // 刷新
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('打卡成功！坚持就是胜利！')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 头部打卡区域
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Text(
                _hasCheckedInToday ? '今日已打卡' : '早起打卡',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _hasCheckedInToday ? null : _doCheckIn,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasCheckedInToday ? Colors.grey : Theme.of(context).primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: (_hasCheckedInToday ? Colors.grey : Theme.of(context).primaryColor).withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _hasCheckedInToday ? '已完成' : '打卡',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '连续打卡 ${_checkIns.length} 天', 
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        
        // 历史记录
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _checkIns.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final checkIn = _checkIns[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.access_time, size: 20),
                      ),
                      title: Text(
                        '${checkIn.checkInTime.month}月${checkIn.checkInTime.day}日',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '打卡时间: ${checkIn.checkInTime.hour.toString().padLeft(2,'0')}:${checkIn.checkInTime.minute.toString().padLeft(2,'0')}'
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
