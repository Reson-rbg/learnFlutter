// -------------------------------------------------------------------------
// 知识点：数据模型与 SQLite 映射
// -------------------------------------------------------------------------
// 为了将对象存储到数据库，我们需要实现对象与 Map 的相互转换方法。

class User {
  final String id;
  final String username;
  final String password; // 实际项目中应存储哈希值，这里简化演示
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
