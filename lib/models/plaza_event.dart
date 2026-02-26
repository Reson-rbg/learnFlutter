/// 广场事件模型 (匿名成就)
class PlazaEvent {
  final String id;
  final String anonymousName;
  final String eventType;
  final String eventDescription;
  final DateTime createdAt;

  PlazaEvent({
    required this.id,
    required this.anonymousName,
    required this.eventType,
    required this.eventDescription,
    required this.createdAt,
  });

  factory PlazaEvent.fromMap(Map<String, dynamic> map) => PlazaEvent(
    id: map['id'],
    anonymousName: map['anonymousName'] ?? '匿名用户',
    eventType: map['eventType'] ?? '',
    eventDescription: map['eventDescription'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
  );
}
