/// 任务模板模型
class TaskTemplate {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> tags;
  final bool isFocus;
  final DateTime createdAt;

  TaskTemplate({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.tags = const [],
    this.isFocus = false,
    required this.createdAt,
  });

  factory TaskTemplate.fromMap(Map<String, dynamic> map) => TaskTemplate(
    id: map['id'],
    userId: map['userId'],
    title: map['title'],
    description: map['description'] ?? '',
    tags: map['tags'] is List
        ? (map['tags'] as List).map((e) => e.toString()).toList()
        : (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
    isFocus: map['isFocus'] == true || map['isFocus'] == 1,
    createdAt: DateTime.parse(map['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'description': description,
    'tags': tags,
    'isFocus': isFocus,
  };
}
