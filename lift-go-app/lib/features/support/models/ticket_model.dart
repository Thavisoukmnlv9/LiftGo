class TicketMessage {
  final String id;
  final String body;
  final String createdAt;
  final bool isStaff;

  const TicketMessage({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.isStaff,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
        id: json['id']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
        isStaff: json['is_staff'] as bool? ?? false,
      );
}

class SupportTicket {
  final String id;
  final String subject;
  final String priority;
  final String status;
  final String createdAt;
  final List<TicketMessage> messages;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.messages,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final msgsRaw = json['messages'] as List<dynamic>? ?? [];
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'open',
      createdAt: json['created_at']?.toString() ?? '',
      messages: msgsRaw
          .map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  TicketMessage? get lastMessage =>
      messages.isNotEmpty ? messages.last : null;
}
