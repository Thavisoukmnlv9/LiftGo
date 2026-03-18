class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String createdAt;
  final bool isRead;
  final String? entityType;
  final String? entityId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.entityType,
    this.entityId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ??
            json['message']?.toString() ??
            '',
        type: json['type']?.toString() ?? 'general',
        createdAt: json['created_at']?.toString() ?? '',
        isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
        entityType: json['entity_type']?.toString(),
        entityId: json['entity_id']?.toString(),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        entityType: entityType,
        entityId: entityId,
      );
}
