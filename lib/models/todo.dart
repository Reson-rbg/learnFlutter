// -------------------------------------------------------------------------
// 知识点：数据模型 (Model) - V2 升级版
// -------------------------------------------------------------------------

class SubTask {
  final String title;
  final bool isCompleted;

  SubTask({required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {'title': title, 'isCompleted': isCompleted};

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      title: json['title'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class Todo {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? reminderTime;

  // V2 新增字段
  final List<String> tags; // 任务标签
  final bool isFocus; // 是否为今日聚焦
  final List<SubTask> subtasks; // 子任务列表

  // 构造函数
  Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.reminderTime,
    this.tags = const [],
    this.isFocus = false,
    this.subtasks = const [],
  });

  // -------------------------------------------------------------------------
  // 知识点：命名构造函数与 JSON 序列化
  // -------------------------------------------------------------------------
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      userId: json['userId'] ?? '',
      title: json['title'],
      description: json['description'],
      isCompleted: (json['isCompleted'] is int)
          ? (json['isCompleted'] == 1)
          : (json['isCompleted'] ?? false),
      createdAt: DateTime.parse(json['createdAt']),
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'])
          : null,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      isFocus: (json['isFocus'] is int)
          ? (json['isFocus'] == 1)
          : (json['isFocus'] ?? false),
      subtasks:
          (json['subtasks'] as List<dynamic>?)
              ?.map((e) => SubTask.fromJson(e))
              .toList() ??
          [],
    );
  }

  // 兼容数据库操作命名
  factory Todo.fromMap(Map<String, dynamic> map) => Todo.fromJson(map);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'tags': tags,
      'isFocus': isFocus ? 1 : 0,
      'subtasks': subtasks.map((e) => e.toJson()).toList(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  // copyWith 模式
  Todo copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? reminderTime,
    List<String>? tags,
    bool? isFocus,
    List<SubTask>? subtasks,
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: reminderTime ?? this.reminderTime,
      tags: tags ?? this.tags,
      isFocus: isFocus ?? this.isFocus,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
