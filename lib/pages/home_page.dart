import 'package:flutter/material.dart';
import '../services/mock_service.dart';
import '../models/todo.dart';
import '../widgets/todo_list_tile.dart';
import 'form_page.dart';

// -------------------------------------------------------------------------
// 知识点：综合页面布局 & 异步 UI 更新
// -------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 列表数据
  List<Todo> _todos = [];
  // 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // 初始化时加载数据
  }

  // 知识点：异步加载数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final todos = await MockService.getTodos();
      setState(() {
        _todos = todos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载失败: $e')));
    }
  }

  // 切换任务状态
  Future<void> _toggleTodo(String id) async {
    // 知识点：乐观更新 (Optimistic UI Update)
    // 先在界面上更新状态，感觉很快，然后再发送网络请求。
    // 如果请求失败，再回滚状态（这里简化处理，只演示基本逻辑）
    await MockService.toggleTodoStatus(id);
    _loadData(); // 重新加载列表（或者也可以直接修改本地 list）
  }

  // 删除任务
  Future<void> _deleteTodo(String id) async {
    // 知识点：弹出确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除?'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await MockService.deleteTodo(id);
      _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除成功')));
    }
  }

  // 跳转到添加页面
  void _navigateToAddPage() async {
    // 知识点：等待页面返回结果
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormPage()),
    );

    // 如果返回 true，说明添加成功，刷新列表
    if (result == true) {
      _loadData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('添加成功')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 企业级实战'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      // 知识点：处理不同的 UI 状态 (Loading, Empty, Data)
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '没有任务，去添加一个吧！',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              // 知识点：ListView.builder 性能优化
              // 仅渲染屏幕可见的元素
              padding: const EdgeInsets.only(bottom: 80), // 底部留白给 FAB
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return TodoListTile(
                  todo: todo,
                  onToggle: () => _toggleTodo(todo.id),
                  onDelete: () => _deleteTodo(todo.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddPage,
        label: const Text('新建任务'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
