class Publication {
  final String id;
  final String title;
  final List<dynamic> content;
  final List<String> attachments;
  final String professionalUid;
  final DateTime createdAt;
  final DateTime? updatedAt;

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
    );
  }

  // Helper to get plain text from rich text content for previews
  String get contentAsPlainText {
    if (content.isEmpty) return '';
    try {
      return content.map((e) => e['insert'].toString()).join();
    } catch (e) {
      return 'Contenido no disponible';
    }
  }
}
