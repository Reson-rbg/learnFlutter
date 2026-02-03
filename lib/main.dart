import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';

// -------------------------------------------------------------------------
// 入口文件：Main
// -------------------------------------------------------------------------
// 程序的入口

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 1. 设置应用标题
      title: 'Flutter Advanced Demo',

      // 2. 去除右上角 DEBUG 标签
      debugShowCheckedModeBanner: false,

      // 3. 应用自定义主题
      theme: AppTheme.lightTheme,

      // 4. 设置首页
      home: const HomePage(),
    );
  }
}
