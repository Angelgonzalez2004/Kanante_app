class ChatConversation {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime timestamp;

  // Populated after fetching the other user's details
  String? otherParticipantName;
  String? otherParticipantImageUrl;

  ChatConversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.timestamp,
    this.otherParticipantName,
    this.otherParticipantImageUrl,
  });

  factory ChatConversation.fromMap(String id, Map<String, dynamic> data) {
    final participantsMap = data['participants'] as Map<String, dynamic>?;
    final participantsList = participantsMap?.keys.toList() ?? [];

    return ChatConversation(
      id: id,
      participants: participantsList,
      lastMessage: data['lastMessage'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
    );
  }
}
