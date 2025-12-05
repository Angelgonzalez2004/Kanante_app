class SupportTicket {
  final String ticketId;
  final String? userId;
  final String? userName;
  final String? userRole;
  final String subject;
  final String message;
  final String status; // e.g., 'open', 'in_progress', 'closed'
  final DateTime createdAt;
  final String? adminResponse;
  final DateTime? respondedAt;

  SupportTicket({
    required this.ticketId,
    this.userId,
    this.userName,
    this.userRole,
    required this.subject,
    required this.message,
    this.status = 'open',
    required this.createdAt,
    this.adminResponse,
    this.respondedAt,
  });

  factory SupportTicket.fromMap(String ticketId, Map<String, dynamic> data) {
    return SupportTicket(
      ticketId: ticketId,
      userId: data['userId'],
      userName: data['userName'],
      userRole: data['userRole'],
      subject: data['subject'] ?? 'Sin Asunto',
      message: data['message'] ?? 'Sin Mensaje',
      status: data['status'] ?? 'open',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt']),
      adminResponse: data['adminResponse'],
      respondedAt: data['respondedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['respondedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'subject': subject,
      'message': message,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'adminResponse': adminResponse,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
    };
  }
}
