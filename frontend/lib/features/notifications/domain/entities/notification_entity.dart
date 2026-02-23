/// Domain entity for a user notification.
class NotificationEntity {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.data,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String? ?? 'SYSTEM',
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  NotificationEntity copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationEntity(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      data: data,
    );
  }
}
