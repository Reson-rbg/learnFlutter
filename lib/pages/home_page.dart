import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/todo_list_tile.dart';
import '../widgets/todo_search_delegate.dart';
import 'form_page.dart';
import 'statistics_page.dart';
import 'check_in_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TodoListView(), // 任务列表
    const StatisticsPage(), // 统计
    const CheckInPage(), // 打卡
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(['我的待办', '数据统计', '每日打卡'][_currentIndex]),
        actions: [
          // 搜索 (仅首页)
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: TodoSearchDelegate());
              },
            ),

          // 主题切换
          IconButton(
            tooltip: '切换主题',
            icon: Icon(
              themeProvider.currentStyle == AppThemeStyle.simple
                  ? Icons
                        .style_outlined // 简洁
                  : Icons.style, // 丰富
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),

          // 退出登录
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('退出登录'),
                  content: const Text('确定要退出当前账号吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        auth.logout();
                      },
                      child: const Text(
                        '退出',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: '列表'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: '统计'),
          NavigationDestination(icon: Icon(Icons.verified_user), label: '打卡'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FormPage()),
                );
                if (result == true) {
                  // 自动刷新由 Provider 监听处理
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  String _selectedTag = '全部';
  final List<String> _tags = ['全部', '工作', '学习', '生活', '健康'];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<TodoProvider>(context, listen: false).loadTodos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final focusTodos = provider.focusTodos;
        final filteredTodos = provider.getTodosByTag(_selectedTag);

        return Column(
          children: [
            // 1. 标签筛选器
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tag = _tags[index];
                  final isSelected = _selectedTag == tag;
                  return ChoiceChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTag = tag);
                    },
                  );
                },
              ),
            ),

            // 2. 今日聚焦看板 (仅当有数据且在全部标签下显示)
            if (_selectedTag == '全部' && focusTodos.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade100, Colors.orange.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          '今日聚焦',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...focusTodos.map(
                      (todo) => Card(
                        elevation: 0,
                        color: Colors.white.withOpacity(0.8),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          dense: true,
                          leading: Checkbox(
                            value: todo.isCompleted,
                            onChanged: (_) => provider.toggleTodo(todo.id),
                            activeColor: Colors.orange,
                          ),
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              // 移除聚焦状态
                              final updated = todo.copyWith(isFocus: false);
                              provider.updateTodo(updated);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. 任务列表
            Expanded(
              child: filteredTodos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            '没有相关任务',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredTodos.length,
                      itemBuilder: (context, index) {
                        final todo = filteredTodos[index];
                        return TodoListTile(
                          key: ValueKey(todo.id),
                          todo: todo,
                          onToggle: () => provider.toggleTodo(todo.id),
                          onDelete: () => provider.deleteTodo(todo.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
