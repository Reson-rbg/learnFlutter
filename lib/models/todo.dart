// -------------------------------------------------------------------------
// 知识点：数据模型 (Model)
// -------------------------------------------------------------------------
// 在企业级开发中，我们通常会定义专门的类来表示数据。
// 这有助于代码的类型安全和逻辑解耦。

class Todo {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;

  // 构造函数
  Todo({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.createdAt,
  });

  // -------------------------------------------------------------------------
  // 知识点：命名构造函数与 JSON 序列化
  // -------------------------------------------------------------------------
  // 模拟从网络请求返回的 JSON 数据转为 Dart 对象
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // 知识点：copyWith 模式
  // Flutter 中通过不可变对象（Immutable）来管理状态是很常见的。
  // copyWith 用于创建一个新对象，但只修改部分属性。
  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
