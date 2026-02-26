import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/todo.dart';
import '../models/check_in.dart';
import '../models/focus_session.dart';
import '../models/badge.dart';
import '../models/task_template.dart';
import '../models/plaza_event.dart';

// -------------------------------------------------------------------------
// 知识点：HTTP 服务封装 (替代原 SQLite)
// -------------------------------------------------------------------------

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  // 根据平台动态选择 URL
  static String get _baseUrl {
    if (kIsWeb ||
        (defaultTargetPlatform == TargetPlatform.windows) ||
        (defaultTargetPlatform == TargetPlatform.linux) ||
        (defaultTargetPlatform == TargetPlatform.macOS)) {
      return 'http://localhost:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api'; // iOS Simulator
    }
  }

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  // 这里的 database getter 已移除，因为不再使用 SQLite
  // 如果原有代码有初始化调用，请移除或修改

  // 由于不再需要初始化数据库文件，此方法可留空或移除
  Future<void> get database async {
    return;
  }

  // ---- User Operations ----
  Future<User> insertUser(User user) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': user.username, 'password': user.password}),
    );

    if (response.statusCode == 409) {
      throw Exception('用户已存在');
    } else if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // 后端返回了 id, username, createdAt
      // 我们需要返回一个新的 User 对象，使用后端生成的 ID
      return User(
        id: data['id'],
        username: data['username'],
        password: user.password, // 后端通常不返回密码，我们使用输入的密码
        createdAt: DateTime.parse(data['createdAt']),
      );
    } else {
      throw Exception('注册失败: ${response.body}');
    }
  }

  Future<User?> getUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return User.fromMap(jsonDecode(response.body));
    }
    return null;
  }

  // 模拟检查用户是否存在，实际通过注册接口处理了
  Future<bool> checkUserExists(String username) async {
    // 由于后端没有专门的 check 接口，我们暂时返回 false
    // 让 insertUser 去触发 409 错误
    return false;
  }

  // ---- Todo Operations ----
  Future<Todo> insertTodo(Todo todo) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/todos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(todo.toMap()), // 使用 toMap 自动处理所有字段
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Todo.fromJson(data);
    } else {
      throw Exception('创建任务失败');
    }
  }

  Future<List<Todo>> getTodos(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/todos?userId=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Todo.fromMap(e)).toList();
    }
    return [];
  }

  Future<void> updateTodo(Todo todo) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/todos/${todo.id}'),
      headers: {'Content-Type': 'application/json'},
      // 移除 userId 避免后端可能的安全校验问题，只传需要更新的字段
      body: jsonEncode({
        'title': todo.title,
        'description': todo.description,
        'isCompleted': todo.isCompleted,
        'reminderTime': todo.reminderTime?.toIso8601String(),
        'tags': todo.tags,
        'isFocus': todo.isFocus,
        'subtasks': todo.subtasks.map((e) => e.toJson()).toList(),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('更新失败');
    }
  }

  Future<void> deleteTodo(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/todos/$id'));
    if (response.statusCode != 200) {
      throw Exception('删除失败');
    }
  }

  // ---- CheckIn Operations ----
  Future<void> insertCheckIn(CheckIn checkIn) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/check-ins'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(checkIn.toMap()),
    );
    if (response.statusCode != 201) {
      throw Exception('打卡失败');
    }
  }

  Future<List<CheckIn>> getCheckIns(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/check-ins?userId=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => CheckIn.fromMap(e)).toList();
    }
    return [];
  }

  Future<bool> hasCheckedInToday(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/check-ins/today?userId=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hasCheckedIn'] == true;
    }
    return false;
  }

  // ---- Focus Session Operations ----
  Future<void> insertFocusSession(FocusSession session) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/focus-sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(session.toMap()),
    );
    if (response.statusCode != 201) {
      throw Exception('保存专注记录失败');
    }
  }

  Future<List<FocusSession>> getFocusSessions(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/focus-sessions?userId=$userId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => FocusSession.fromMap(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getFocusWeeklyStats(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/focus-sessions/weekly-stats?userId=$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'totalMinutes': 0, 'sessionCount': 0, 'topTodoId': null};
  }

  // ---- Badge Operations ----
  Future<List<UserBadge>> getUserBadges(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/badges?userId=$userId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => UserBadge.fromMap(e)).toList();
    }
    return [];
  }

  Future<void> unlockBadge(String userId, String badgeKey) async {
    await http.post(
      Uri.parse('$_baseUrl/badges'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'badgeKey': badgeKey}),
    );
  }

  // ---- Template Operations ----
  Future<List<TaskTemplate>> getTemplates(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/templates?userId=$userId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => TaskTemplate.fromMap(e)).toList();
    }
    return [];
  }

  Future<void> insertTemplate(TaskTemplate template) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/templates'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(template.toMap()),
    );
    if (response.statusCode != 201) {
      throw Exception('创建模板失败');
    }
  }

  Future<void> deleteTemplate(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/templates/$id'));
    if (response.statusCode != 200) {
      throw Exception('删除模板失败');
    }
  }

  // ---- Plaza Operations ----
  Future<List<PlazaEvent>> getPlazaEvents() async {
    final response = await http.get(Uri.parse('$_baseUrl/plaza'));
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => PlazaEvent.fromMap(e)).toList();
    }
    return [];
  }

  Future<void> publishPlazaEvent(String userId, String eventType, String eventDescription) async {
    await http.post(
      Uri.parse('$_baseUrl/plaza'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'eventType': eventType,
        'eventDescription': eventDescription,
      }),
    );
  }

  // ---- Settings Operations ----
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/plaza/settings?userId=$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'showOnPlaza': 0};
  }

  Future<void> updateUserSettings(String userId, bool showOnPlaza) async {
    await http.put(
      Uri.parse('$_baseUrl/plaza/settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'showOnPlaza': showOnPlaza}),
    );
  }

  // ---- Data Export ----
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/plaza/export?userId=$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('数据导出失败');
  }
}
