import '../models/comment_model.dart'; // New import

class Publication {
  final String id;
  final String title;
  final List<dynamic> content;
  final List<String> attachments;
  final String professionalUid;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likes; // New field
  final List<String> likedBy; // New field
  final List<CommentModel> comments; // New field
  final String status; // New field: e.g., 'pending', 'published', 'unpublished', 'rejected'

  // Fields to be populated after fetching
  String? authorName;
  String? authorImageUrl;
  String? authorVerificationStatus;

  Publication({
    required this.id,
    required this.title,
    required this.content,
    required this.attachments,
    required this.professionalUid,
    required this.createdAt,
    this.updatedAt,
    this.likes = 0, // Default value
    this.likedBy = const [], // Default empty list
    this.comments = const [], // Default empty list
    this.status = 'pending', // Default status
    this.authorName,
    this.authorImageUrl,
    this.authorVerificationStatus,
  });

  factory Publication.fromMap(String id, Map<String, dynamic> data) {
    return Publication(
      id: id,
      title: data['title'] ?? 'Sin Título',
      // The content is stored as a List<dynamic> which is compatible with rich text editors
      content: data['content'] as List<dynamic>? ?? [],
      attachments: List<String>.from(data['attachments'] ?? []),
      professionalUid: data['professionalUid'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
          : null,
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      comments: data['comments'] is Map
          ? (data['comments'] as Map<String, dynamic>).entries.map((e) => CommentModel.fromMap(e.key, Map<String, dynamic>.from(e.value))).toList()
          : [],
      status: data['status'] ?? 'pending', // Parse new field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'attachments': attachments,
      'professionalUid': professionalUid,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'likes': likes,
      'likedBy': likedBy,
      'status': status, // Include new field
      // 'comments' are now a sub-collection, so we don't map them here.
    };
  }

  // Helper to get plain text from rich text content for previews
  String get contentAsPlainText {
    if (content.isEmpty) return '';
    try {
      // Assuming content is a list of maps, where each map has an 'insert' key
      // This might need adjustment based on actual Quill delta format
      return content.map((e) => e is Map && e.containsKey('insert') ? e['insert'].toString() : '').join();
    } catch (e) {
      return 'Contenido no disponible';
    }
  }
}