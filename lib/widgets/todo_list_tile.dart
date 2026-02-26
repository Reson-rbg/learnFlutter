import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';

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
      elevation: todo.isFocus ? 4 : 1,
      shadowColor: todo.isFocus ? Colors.orange.withOpacity(0.5) : null,
      color: todo.isFocus ? Colors.orange.shade50 : null,
      child: ExpansionTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => onToggle(),
          activeColor: Theme.of(context).primaryColor,
          shape: const CircleBorder(), // 3.4.1 圆形复选框，更现代
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                todo.title,
                style: TextStyle(
                  decoration: todo.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: todo.isCompleted ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (todo.isFocus)
              const Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(todo.description),
            ],
            const SizedBox(height: 8),

            // Tags & Metadata Row
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Tags
                ...todo.tags.map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),

                // Reminder
                if (todo.reminderTime != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alarm,
                        size: 12,
                        color: todo.isCompleted
                            ? Colors.grey
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        todo.reminderTime.toString().substring(5, 16),
                        style: TextStyle(
                          fontSize: 10,
                          color: todo.isCompleted
                              ? Colors.grey
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),

                // Subtask Progress
                if (todo.subtasks.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.checklist, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        '${todo.subtasks.where((s) => s.isCompleted).length}/${todo.subtasks.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 20,
          ),
          onPressed: onDelete,
        ),
        children: [
          // Subtasks List
          if (todo.subtasks.isNotEmpty)
            ...todo.subtasks.asMap().entries.map((entry) {
              final index = entry.key;
              final subtask = entry.value;
              return ListTile(
                dense: true,
                leading: Checkbox(
                  value: subtask.isCompleted,
                  onChanged: (_) {
                    Provider.of<TodoProvider>(
                      context,
                      listen: false,
                    ).toggleSubtask(todo.id, index);
                  },
                  visualDensity: VisualDensity.compact,
                ),
                title: Text(
                  subtask.title,
                  style: TextStyle(
                    decoration: subtask.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
