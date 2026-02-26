/// 专注会话模型
class FocusSession {
  final String id;
  final String userId;
  final String? todoId;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // 分钟

  FocusSession({
    required this.id,
    required this.userId,
    this.todoId,
    required this.startTime,
    this.endTime,
    this.duration = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'todoId': todoId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'duration': duration,
  };

  factory FocusSession.fromMap(Map<String, dynamic> map) => FocusSession(
    id: map['id'],
    userId: map['userId'],
    todoId: map['todoId'],
    startTime: DateTime.parse(map['startTime']),
    endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    duration: map['duration'] ?? 0,
  );
}
