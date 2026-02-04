import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../services/database_service.dart';

// -------------------------------------------------------------------------
// 知识点：认证状态管理
// -------------------------------------------------------------------------
// 管理用户的登录、注册、退出状态，持久化登录信息。

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  String? get userId => _currentUser?.id; // 新增 Getter
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  final DatabaseService _dbService = DatabaseService();

  // 尝试自动登录
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return;

    final userId = prefs.getString('userId');
    // 在实际后端中通过 Token 验证，这里只演示本地逻辑，不再重新查表简化流程
    // 或者将用户信息完整存入 prefs，但为了安全通常只存 Token
    // 这里我们假设如果本地有 ID，且 ID 存在于数据库，则视为登录
    // 为了简单，我们只做简单的状态恢复（生产环境需更严谨）
    if (userId != null) {
      // 在这里我们无法仅凭 ID 获取 USER（因为 DatabaseService 只写了通过账号密码获取）
      // 实际开发中应该有 getUserById
      // 简化处理：要求用户重新登录，演示完整流程
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 500)); // 模拟一点延迟

    try {
      final user = await _dbService.getUser(username, password);
      if (user != null) {
        _currentUser = user;
        // 保存登录状态
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.id);
        notifyListeners();
      } else {
        throw Exception('用户名或密码错误');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }

  Future<void> register(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final exists = await _dbService.checkUserExists(username);
      if (exists) {
        throw Exception('用户名已存在');
      }

      final newUser = User(
        id: const Uuid().v4(),
        username: username,
        password: password,
        createdAt: DateTime.now(),
      );

      await _dbService.insertUser(newUser);
      // 注册后自动登录
      _currentUser = newUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', newUser.id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
