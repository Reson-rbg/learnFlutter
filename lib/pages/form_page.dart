import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; 
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../providers/auth_provider.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
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
      initialTime: now,
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
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);

      final newTodo = Todo(
        id: const Uuid().v4(), // 使用 UUID
        userId: auth.userId ?? '', // 传入 userId
        title: _titleController.text,
        description: _descController.text,
        createdAt: DateTime.now(),
        reminderTime: reminderTime,
      );

      // 使用 Provider 添加
      try {
        await Provider.of<TodoProvider>(context, listen: false).addTodo(newTodo);
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增任务')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '任务标题',
                  hintText: '请输入要做的事情',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '标题不能为空';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: '详细描述',
                  hintText: '描述一下细节...',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) return '描述也是必填的哦';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // 提醒时间选择器
              ListTile(
                title: Text(_selectedDate == null 
                  ? '设置提醒时间 (可选)' 
                  : '提醒: ${DateFormat('yyyy-MM-dd HH:mm').format(
                      DateTime(
                        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
                        _selectedTime?.hour ?? 0, _selectedTime?.minute ?? 0
                      )
                    )}'),
                leading: Icon(Icons.alarm, 
                  color: _selectedDate == null ? Colors.grey : Colors.blue),
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
                      }
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
                  )
                ),
                child: _isSubmitting 
                  ? const SizedBox(
                      width: 24, height: 24, 
                      child: CircularProgressIndicator(strokeWidth: 2)
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
