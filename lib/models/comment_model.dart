class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String text;
  final String? imageUrl; // Optional image in comment
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.text,
    this.imageUrl,
    required this.timestamp,
  });

  factory CommentModel.fromMap(String id, Map<String, dynamic> data) {
    return CommentModel(
      id: id,
      userId: data['userId'],
      userName: data['userName'] ?? 'Usuario Anónimo',
      userImageUrl: data['userImageUrl'],
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}