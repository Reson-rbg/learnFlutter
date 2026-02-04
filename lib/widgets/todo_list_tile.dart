import 'package:flutter/material.dart';
import '../models/todo.dart';

// -------------------------------------------------------------------------
// 知识点：自定义 Widget (Custom Widget)
// -------------------------------------------------------------------------
// 将重复使用的 UI 拆分成独立的 Widget。
// 继承 StatelessWidget 是因为这个组件本身不维护状态，状态由父组件传入。

class TodoListTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoListTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // 由于我们在 AppTheme 中定义了 CardTheme，这里会自动应用样式
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => onToggle(),
          activeColor: Theme.of(context).primaryColor,
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? Colors.grey : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(todo.description),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '创建时间: ${todo.createdAt.toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (todo.reminderTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.alarm, size: 12, color: todo.isCompleted ? Colors.grey : Colors.redAccent),
                      const SizedBox(width: 2),
                      Text(
                        todo.reminderTime.toString().split('.')[0].substring(0, 16),
                        style: TextStyle(
                          fontSize: 10, 
                          color: todo.isCompleted ? Colors.grey : Colors.redAccent,
                          fontWeight: FontWeight.bold
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
