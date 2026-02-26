import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/todo_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/achievement_provider.dart';

import 'services/notification_service.dart';
import 'pages/home_page.dart';
import 'pages/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库服务已移除 (现在使用 HTTP API)
  // await DatabaseService().database;

  // 初始化通知服务
  await NotificationService().init();
  await NotificationService().requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        ChangeNotifierProxyProvider<AuthProvider, TodoProvider>(
          create: (_) => TodoProvider(null),
          update: (context, auth, previousTodoProvider) {
            return previousTodoProvider != null
                ? (previousTodoProvider..updateUserId(auth.userId))
                : TodoProvider(auth.userId);
          },
        ),

        // V2.0 新增 Provider
        ChangeNotifierProxyProvider<AuthProvider, FocusProvider>(
          create: (_) => FocusProvider(),
          update: (context, auth, previous) {
            final fp = previous ?? FocusProvider();
            if (auth.userId != null) fp.setUserId(auth.userId!);
            return fp;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AchievementProvider>(
          create: (_) => AchievementProvider(),
          update: (context, auth, previous) {
            final ap = previous ?? AchievementProvider();
            if (auth.userId != null) ap.setUserId(auth.userId!);
            return ap;
          },
        ),
      ],
      // 监听 ThemeProvider
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Flutter Advanced Todo',
            theme: themeProvider.currentThemeData, // 使用动态主题
            debugShowCheckedModeBanner: false,
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return auth.isLoggedIn ? const HomePage() : const AuthPage();
              },
            ),
          );
        },
      ),
    );
  }
}
