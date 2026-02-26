import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../models/task_template.dart';
import '../providers/todo_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/achievement_provider.dart';
import '../services/database_service.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskController = TextEditingController(); // 子任务输入

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // V2 新增
  List<String> _selectedTags = [];
  bool _isFocus = false;
  List<SubTask> _subtasks = [];

  final List<String> _availableTags = ['工作', '学习', '生活', '健康'];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  // V2: 添加子任务
  void _addSubtask() {
    if (_subtaskController.text.trim().isNotEmpty) {
      if (_subtasks.length >= 5) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('最多添加5个子任务')));
        return;
      }
      setState(() {
        _subtasks.add(SubTask(title: _subtaskController.text.trim()));
        _subtaskController.clear();
      });
    }
  }

  // 选择日期
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      // 自动弹出时间选择
      if (mounted) _pickTime();
    }
  }

  // 选择时间
  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now.replacing(hour: now.hour + 1), // 默认选中一小时后
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // 计算提醒时间
      DateTime? reminderTime;
      if (_selectedDate != null && _selectedTime != null) {
        reminderTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      } else if (_titleController.text.contains("晚8点") ||
          _titleController.text.contains("晚上8点")) {
        // 简易的“智能输入辅助”演示
        final now = DateTime.now();
        reminderTime = DateTime(now.year, now.month, now.day, 20, 0);
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);

      final newTodo = Todo(
        id: const Uuid().v4(), // 使用 UUID
        userId: auth.userId ?? '', // 传入 userId
        title: _titleController.text,
        description: _descController.text,
        createdAt: DateTime.now(),
        reminderTime: reminderTime,
        tags: _selectedTags,
        isFocus: _isFocus,
        subtasks: _subtasks,
      );

      // 使用 Provider 添加
      try {
        await Provider.of<TodoProvider>(
          context,
          listen: false,
        ).addTodo(newTodo);
        if (!mounted) return;
        Navigator.pop(context, true);

        // 触发成就检查
        if (mounted) {
          final tp = context.read<TodoProvider>();
          final ap = context.read<AchievementProvider>();
        final totalCompleted = tp.todos.where((t) => t.isCompleted).length;
          await ap.checkAndUnlock(totalCompletedTasks: totalCompleted + 1);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('添加失败: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ---- 模板功能 ----
  Future<void> _importFromTemplate() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;
    final db = DatabaseService();
    final templates = await db.getTemplates(auth.userId!);
    if (!mounted) return;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('还没有保存的模板')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (_, i) {
          final t = templates[i];
          return ListTile(
            leading: const Icon(Icons.description),
            title: Text(t.title),
            subtitle: Text(t.tags.isEmpty ? '无标签' : t.tags.join(', ')),
            onTap: () {
              setState(() {
                _titleController.text = t.title;
                _descController.text = t.description;
                _selectedTags = List.from(t.tags);
                _isFocus = t.isFocus;
              });
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Future<void> _saveAsTemplate() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写任务标题')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;
    final db = DatabaseService();
    final template = TaskTemplate(
      id: const Uuid().v4(),
      userId: auth.userId!,
      title: _titleController.text,
      description: _descController.text,
      tags: _selectedTags,
      isFocus: _isFocus,
      createdAt: DateTime.now(),
    );
    try {
      await db.insertTemplate(template);
      if (mounted) {
        context.read<AchievementProvider>().checkAndUnlock(templateCreated: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 已保存为模板')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存模板失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增任务'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '从模板导入',
            onPressed: _importFromTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: '保存为模板',
            onPressed: _saveAsTemplate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 标题与智能提示
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '任务标题',
                  hintText: '例如：明天晚上8点去跑步 #运动',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value!.isEmpty ? '请输入标题' : null,
                onChanged: (val) {
                  // 简单的智能提示演示
                  if (val.contains("晚8点") && _selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('检测到时间关键词，是否设置提醒？'),
                        action: SnackBarAction(
                          label: '是',
                          onPressed: () {
                            final now = DateTime.now();
                            setState(() {
                              _selectedDate = now;
                              _selectedTime = const TimeOfDay(
                                hour: 20,
                                minute: 0,
                              );
                            });
                          },
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // 2. 描述
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // 3. 标签选择 (Chips)
              Text('选择标签', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.removeWhere((name) => name == tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 4. 今日聚焦开关
              SwitchListTile(
                title: const Text('设为今日聚焦'),
                subtitle: const Text('将在首页置顶展示'),
                value: _isFocus,
                onChanged: (val) => setState(() => _isFocus = val),
                secondary: const Icon(
                  Icons.center_focus_strong,
                  color: Colors.orange,
                ),
              ),
              const Divider(),

              // 5. 子任务列表
              Text(
                '子任务 (${_subtasks.length}/5)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (_subtasks.length < 5)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        decoration: const InputDecoration(
                          hintText: '输入步骤...',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: _addSubtask,
                    ),
                  ],
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subtasks.length,
                itemBuilder: (ctx, i) => ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.check_box_outline_blank, size: 18),
                  title: Text(_subtasks[i].title),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _subtasks.removeAt(i);
                      });
                    },
                  ),
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),

              // 6. 提醒时间选择器
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? '设置提醒时间 (可选)'
                      : '提醒: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime?.hour ?? 0, _selectedTime?.minute ?? 0))}',
                ),
                leading: Icon(
                  Icons.alarm,
                  color: _selectedDate == null ? Colors.grey : Colors.blue,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: _pickDate,
                trailing: _selectedDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                            _selectedTime = null;
                          });
                        },
                      )
                    : null,
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('立即创建', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
