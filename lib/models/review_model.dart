class Review {
  final String id;
  final String professionalId;
  final String userId;
  final double rating; // 1.0 to 5.0
  final String? comment;
  final DateTime timestamp;

  Review({
    required this.id,
    required this.professionalId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.timestamp,
  });

  factory Review.fromMap(String id, Map<String, dynamic> data) {
    return Review(
      id: id,
      professionalId: data['professionalId'] ?? '',
      userId: data['userId'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
