// -------------------------------------------------------------------------
// 知识点：数据模型 (Model)
// -------------------------------------------------------------------------

class Todo {
  final String id;
  final String userId; // 新增：用户ID
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? reminderTime;

  // 构造函数
  Todo({
    required this.id,
    required this.userId, // 必填
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.reminderTime,
  });

  // -------------------------------------------------------------------------
  // 知识点：命名构造函数与 JSON 序列化
  // -------------------------------------------------------------------------
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      userId: json['userId'] ?? '', // 兼容处理，防止为空
      title: json['title'],
      description: json['description'],
      isCompleted: (json['isCompleted'] is int) 
          ? (json['isCompleted'] == 1) 
          : (json['isCompleted'] ?? false),
      createdAt: DateTime.parse(json['createdAt']),
      reminderTime: json['reminderTime'] != null ? DateTime.parse(json['reminderTime']) : null,
    );
  }

  // 兼容数据库操作命名
  factory Todo.fromMap(Map<String, dynamic> map) => Todo.fromJson(map);

  // copyWith 模式
  Todo copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? reminderTime,
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  // 将对象转换为 JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0, 
      'createdAt': createdAt.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
    };
  }
  
  Map<String, dynamic> toMap() => toJson();
}
