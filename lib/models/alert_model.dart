class AlertModel {
  final String id;
  final String senderId; // Admin ID
  final String recipientId; // User or Professional ID
  final String title;
  final String message;
  final DateTime timestamp;
  String status; // e.g., 'unread', 'read', 'replied'
  String? recipientReply; // If recipient can reply
  DateTime? replyTimestamp;

  AlertModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.status = 'unread',
    this.recipientReply,
    this.replyTimestamp,
  });

  factory AlertModel.fromMap(String id, Map<String, dynamic> data) {
    return AlertModel(
      id: id,
      senderId: data['senderId'],
      recipientId: data['recipientId'],
      title: data['title'],
      message: data['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
      status: data['status'] ?? 'unread',
      recipientReply: data['recipientReply'],
      replyTimestamp: data['replyTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['replyTimestamp'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'recipientReply': recipientReply,
      'replyTimestamp': replyTimestamp?.millisecondsSinceEpoch,
    };
  }
}