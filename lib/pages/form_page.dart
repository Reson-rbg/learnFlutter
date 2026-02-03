import 'package:flutter/material.dart';
import 'dart:math';
import '../models/todo.dart';
import '../services/mock_service.dart';

// -------------------------------------------------------------------------
// 知识点：表单处理 (Forms) & 导航传值
// -------------------------------------------------------------------------

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  // 知识点：GlobalKey 用于获取 FormState，进行表单验证
  final _formKey = GlobalKey<FormState>();

  // 知识点：TextEditingController 用于获取输入框的内容
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    // 知识点：资源释放
    // Controller 使用完必须 dispose，否则会导致内存泄漏
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // 1. 验证表单
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // 2. 构造数据对象
      final newTodo = Todo(
        id: Random().nextInt(10000).toString(), // 简单模拟 ID
        title: _titleController.text,
        description: _descController.text,
        createdAt: DateTime.now(),
      );

      // 3. 调用服务层
      await MockService.addTodo(newTodo);

      if (!mounted) return; // 知识点：异步操作后检查页面是否还挂载

      // 4. 返回上一页并携带结果
      Navigator.pop(context, true); // true 表示添加成功
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
                ),
                // 知识点：验证逻辑
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '标题不能为空';
                  }
                  if (value.length < 2) {
                    return '标题太短了';
                  }
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
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '描述不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // 提交按钮
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSubmitting ? '保存中...' : '保存任务'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
