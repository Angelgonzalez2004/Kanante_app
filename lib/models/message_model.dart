enum MessageType { text, image, audio, file }

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String content; // For text messages or URLs for files/images/audio
  final DateTime timestamp;
  final bool deletedForSender;
  final List<String> readBy; // New field

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.deletedForSender = false,
    this.readBy = const [], // Initialize as empty list
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: _stringToMessageType(data['type']),
      content: data['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      deletedForSender: data['deletedForSender'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []), // Parse new field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'type': type.name,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deletedForSender': deletedForSender,
      'readBy': readBy, // Include new field
    };
  }

  static MessageType _stringToMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      case 'text':
      default:
        return MessageType.text;
    }
  }
}
