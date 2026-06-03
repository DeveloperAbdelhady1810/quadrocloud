class TicketModel {
  final int id;
  final String title;
  final String status;
  final String priority;
  final String createdAt;
  final List<TicketMessage> messages;

  const TicketModel({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.messages = const [],
  });

  factory TicketModel.fromJson(Map<String, dynamic> j) => TicketModel(
        id: j['id'],
        title: j['title'],
        status: j['status'],
        priority: j['priority'],
        createdAt: j['created_at'],
        messages: j['messages'] != null
            ? (j['messages'] as List).map((m) => TicketMessage.fromJson(m)).toList()
            : [],
      );
}

class TicketMessage {
  final int id;
  final String senderType;
  final String message;
  final String createdAt;

  const TicketMessage({
    required this.id,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  bool get isAdmin => senderType == 'admin';

  factory TicketMessage.fromJson(Map<String, dynamic> j) => TicketMessage(
        id: j['id'],
        senderType: j['sender_type'],
        message: j['message'],
        createdAt: j['created_at'],
      );
}
