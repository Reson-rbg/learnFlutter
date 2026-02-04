// -------------------------------------------------------------------------
// 知识点：搜索代理 (SearchDelegate)
// -------------------------------------------------------------------------
// Flutter 提供了非常方便的标准搜索 UI 实现。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import 'todo_list_tile.dart';

class TodoSearchDelegate extends SearchDelegate {
  
  @override
  String get searchFieldLabel => '搜索任务...';

  // 搜索栏右侧的操作按钮（如清空）
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  // 搜索栏左侧的返回按钮
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  // 显示搜索结果
  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  // 显示搜索建议（这里为了简单，建议和结果用一样的列表）
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    // 获取 Provider 中的数据
    final provider = context.watch<TodoProvider>();
    final results = provider.search(query);

    if (results.isEmpty) {
      return const Center(
        child: Text('没有找到相关任务', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final todo = results[index];
        return TodoListTile(
          todo: todo,
          onToggle: () => provider.toggleTodo(todo.id),
          onDelete: () => provider.deleteTodo(todo.id),
        );
      },
    );
  }
}
