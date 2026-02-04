import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

// -------------------------------------------------------------------------
// 知识点：Provider 状态管理 & SQLite 集成
// -------------------------------------------------------------------------

class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];
  bool _isLoading = false;
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  String? _userId; // 当前用户ID

  // 构造函数支持传入 userId
  TodoProvider([this._userId]) {
    if (_userId != null) loadTodos();
  }

  // Setter 更新用户 ID (当 AuthProvider 变化时)
  void updateUserId(String? userId) {
    _userId = userId;
    if (_userId != null) {
      loadTodos();
    } else {
      _todos = [];
      notifyListeners();
    }
  }

  // Getter 获取数据
  List<Todo> get todos => _todos;
  bool get isLoading => _isLoading;

  int get totalCount => _todos.length;
  int get completedCount => _todos.where((todo) => todo.isCompleted).length;
  int get activeCount => totalCount - completedCount;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  // 初始化加载数据
  Future<void> loadTodos() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      _todos = await _dbService.getTodos(_userId!);
    } catch (e) {
      debugPrint("Load Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 添加任务
  Future<void> addTodo(Todo todo) async {
    if (_userId == null) return;
    try {
      await _dbService.insertTodo(todo);
      
      // 设置提醒
      if (todo.reminderTime != null) {
        await _notificationService.scheduleNotification(
          todo.id.hashCode,
          '待办提醒: ${todo.title}',
          todo.description.isNotEmpty ? todo.description : '记得完成你的任务哦！',
          todo.reminderTime!,
        );
      }

      // 重新加载以确保顺序正确
      await loadTodos();
    } catch (e) {
      debugPrint("Add Error: $e");
      rethrow;
    }
  }

  // 切换状态
  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final oldTodo = _todos[index];
      final newTodo = oldTodo.copyWith(isCompleted: !oldTodo.isCompleted);
      
      // 如果完成了任务，取消提醒；如果恢复未完成且时间在未来，重设提醒 (简化逻辑：仅取消)
      if (newTodo.isCompleted) {
        await _notificationService.cancelNotification(id.hashCode);
      }

      // 乐观更新
      _todos[index] = newTodo;
      notifyListeners();

      try {
        await _dbService.updateTodo(newTodo);
      } catch (e) {
        _todos[index] = oldTodo; // 回滚
        notifyListeners();
      }
    }
  }

  // 删除任务
  Future<void> deleteTodo(String id) async {
    if (_userId == null) return;
    try {
      await _dbService.deleteTodo(id);
      await _notificationService.cancelNotification(id.hashCode); // 取消提醒
      _todos.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // 搜索过滤
  List<Todo> search(String query) {
    if (query.isEmpty) return _todos;
    return _todos.where((todo) {
      return todo.title.toLowerCase().contains(query.toLowerCase()) ||
             todo.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
