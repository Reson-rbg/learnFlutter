// -------------------------------------------------------------------------
// 知识点：每日打卡模型
// -------------------------------------------------------------------------

class CheckIn {
  final String id;
  final String userId;
  final DateTime checkInTime;
  final String note;
  final int? mood; // 0: Happy, 1: Neural, 2: Sad

  CheckIn({
    required this.id,
    required this.userId,
    required this.checkInTime,
    this.note = '',
    this.mood,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'checkInTime': checkInTime.toIso8601String(),
      'note': note,
      'mood': mood,
    };
  }

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      id: map['id'],
      userId: map['userId'],
      checkInTime: DateTime.parse(map['checkInTime']),
      note: map['note'],
      mood: map['mood'],
    );
  }
}
