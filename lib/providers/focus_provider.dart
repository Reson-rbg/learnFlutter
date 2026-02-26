import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/focus_session.dart';
import '../services/database_service.dart';

/// 专注计时 Provider - 管理番茄钟/专注计时器状态
class FocusProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  String? _userId;
  Timer? _timer;

  // 计时状态
  bool _isRunning = false;
  int _remainingSeconds = 25 * 60; // 默认25分钟
  int _totalSeconds = 25 * 60;
  String? _activeTodoId;
  DateTime? _sessionStart;

  // 历史数据
  List<FocusSession> _sessions = [];
  Map<String, dynamic> _weeklyStats = {};

  // Getters
  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  String? get activeTodoId => _activeTodoId;
  List<FocusSession> get sessions => _sessions;
  Map<String, dynamic> get weeklyStats => _weeklyStats;

  double get progress =>
      _totalSeconds > 0 ? 1 - (_remainingSeconds / _totalSeconds) : 0;

  String get displayTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void setUserId(String userId) {
    _userId = userId;
    loadSessions();
  }

  /// 设置时长 (分钟) 并可选绑定任务
  void configure({required int minutes, String? todoId}) {
    if (_isRunning) return;
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    _activeTodoId = todoId;
    notifyListeners();
  }

  /// 开始专注
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _sessionStart = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _finish();
      }
    });
    notifyListeners();
  }

  /// 暂停
  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  /// 恢复
  void resume() {
    if (_isRunning || _remainingSeconds <= 0) return;
    start();
  }

  /// 结束并保存
  Future<void> _finish() async {
    _timer?.cancel();
    _isRunning = false;
    final duration = (_totalSeconds - _remainingSeconds) ~/ 60;
    if (_userId != null && duration > 0) {
      final session = FocusSession(
        id: const Uuid().v4(),
        userId: _userId!,
        todoId: _activeTodoId,
        startTime: _sessionStart ?? DateTime.now(),
        endTime: DateTime.now(),
        duration: duration,
      );
      try {
        await _db.insertFocusSession(session);
        _sessions.insert(0, session);
        await _loadWeeklyStats();
      } catch (_) {}
    }
    notifyListeners();
  }

  /// 提前放弃 - 仍保存已经过的时间
  Future<void> abandon() async {
    await _finish();
    reset();
  }

  /// 重置计时器
  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = _totalSeconds;
    _activeTodoId = null;
    _sessionStart = null;
    notifyListeners();
  }

  Future<void> loadSessions() async {
    if (_userId == null) return;
    _sessions = await _db.getFocusSessions(_userId!);
    await _loadWeeklyStats();
    notifyListeners();
  }

  Future<void> _loadWeeklyStats() async {
    if (_userId == null) return;
    _weeklyStats = await _db.getFocusWeeklyStats(_userId!);
  }

  int get todayMinutes {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _sessions
        .where((s) => s.startTime.isAfter(todayStart))
        .fold(0, (sum, s) => sum + s.duration);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
