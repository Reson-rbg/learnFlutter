import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 主题枚举
enum AppThemeStyle {
  simple, // 简洁
  rich,   // 丰富/精致
}

class ThemeProvider with ChangeNotifier {
  AppThemeStyle _currentStyle = AppThemeStyle.simple;
  
  AppThemeStyle get currentStyle => _currentStyle;

  // 获取当前生效的 ThemeData
  ThemeData get currentThemeData {
    switch (_currentStyle) {
      case AppThemeStyle.simple:
        return _simpleTheme;
      case AppThemeStyle.rich:
        return _richTheme;
    }
  }

  // 1. 简洁主题 (Simple)
  // 干净、白/蓝配色、标准 MD3 风格
  final ThemeData _simpleTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    scaffoldBackgroundColor: Colors.grey[50], // 略带灰色的白
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent, // 透明 AppBar 配合内容滚动
      foregroundColor: Colors.black, // 黑色标题
    ),
    cardTheme: const CardThemeData( // 修改为 CardThemeData
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );

  // 2. 丰富主题 (Rich/Exquisite)
  // 深色系、渐变、高对比度、更圆润或特殊的形状
  final ThemeData _richTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
      primary: const Color(0xFF6200EA),
      secondary: const Color(0xFF00BFA5),
      surface: const Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: 'Georgia', // (如果有的话，没有会回退) 尝试用 serif 字体增加格调
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 4,
      backgroundColor: Color(0xFF311B92), // 深紫
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData( // 修改为 CardThemeData
      elevation: 8,
      shadowColor: Colors.purpleAccent.withOpacity(0.4),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.amber, // 金色点缀
      foregroundColor: Colors.black,
    ),
  );

  ThemeProvider() {
    _loadTheme();
  }

  // 切换主题
  Future<void> toggleTheme() async {
    _currentStyle = _currentStyle == AppThemeStyle.simple 
        ? AppThemeStyle.rich 
        : AppThemeStyle.simple;
    notifyListeners();
    _saveTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isRich = prefs.getBool('is_rich_theme') ?? false;
    _currentStyle = isRich ? AppThemeStyle.rich : AppThemeStyle.simple;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_rich_theme', _currentStyle == AppThemeStyle.rich);
  }
}
