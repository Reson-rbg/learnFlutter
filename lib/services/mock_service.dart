import 'dart:async';
import '../models/todo.dart';

// -------------------------------------------------------------------------
// 知识点：服务层 (Service/Repository Pattern)
// -------------------------------------------------------------------------
// 将数据获取逻辑与 UI 分离。
// 这里使用 Future.delayed 模拟真实的网络请求延迟。

class MockService {
  // 单例模式（可选），这里直接使用静态方法简单演示

  static final List<Todo> _mockDatabase = [
    Todo(
      id: '1',
      userId: 'mock_user',
      title: '学习 Flutter 基础',
      description: '掌握 Widget, Layout, State 的基本概念',
      isCompleted: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Todo(
      id: '2',
      userId: 'mock_user',
      title: '实战企业级 Demo',
      description: '学习目录结构、MVVM 分层、异步编程',
      isCompleted: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  // 模拟：获取列表 (GET 请求)
  static Future<List<Todo>> getTodos() async {
    // 模拟网络延迟 1秒
    await Future.delayed(const Duration(seconds: 1));
    // 模拟有时可能会失败
    // if (DateTime.now().second % 10 == 0) throw Exception("模拟网络错误");
    return List.from(_mockDatabase); // 返回副本
  }

  // 模拟：添加任务 (POST 请求)
  static Future<void> addTodo(Todo todo) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockDatabase.add(todo);
  }

  // 模拟：更新状态 (PUT/PATCH 请求)
  static Future<void> toggleTodoStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockDatabase.indexWhere((element) => element.id == id);
    if (index != -1) {
      final old = _mockDatabase[index];
      _mockDatabase[index] = old.copyWith(isCompleted: !old.isCompleted);
    }
  }

  // 模拟：删除任务 (DELETE 请求)
  static Future<void> deleteTodo(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockDatabase.removeWhere((element) => element.id == id);
  }
}
