class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final String? referenceType;
  final int? referenceId;
  final bool sent;
  final String? sentAt;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.referenceType,
    this.referenceId,
    required this.sent,
    this.sentAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        id: j['id'],
        type: j['type'] ?? '',
        title: j['title'] ?? '',
        body: j['body'] ?? '',
        referenceType: j['reference_type'],
        referenceId: j['reference_id'],
        sent: j['sent'] == true,
        sentAt: j['sent_at'],
        createdAt: j['created_at'] ?? '',
      );
}
