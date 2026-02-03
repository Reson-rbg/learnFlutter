import 'package:flutter/material.dart';

// -------------------------------------------------------------------------
// 知识点：主题管理 (Theming)
// -------------------------------------------------------------------------
// 将颜色、字体和组件样式集中管理，方便全局修改。

class AppTheme {
  // 私有构造，防止实例化
  AppTheme._();

  static const Color primaryColor = Colors.teal;
  static const Color secondaryColor = Colors.orangeAccent;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
      ),

      // 知识点：AppBar 统一样式
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, // 标题和图标颜色
      ),

      // Card 统一样式已移除，使用默认
      /*
      cardTheme: CardTheme(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      */

      // 知识点：Input 统一样式
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
