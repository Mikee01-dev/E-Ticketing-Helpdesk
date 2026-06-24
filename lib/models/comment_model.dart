class CommentModel {
  final String id;
  final String ticketId;
  final String userId;
  final String message;
  final String? imageUrl;
  final String? avatarUrl;
  final String? userName;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    this.imageUrl,
    this.avatarUrl,
    this.userName,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    final String? userName = map['user_name'];
    final String? avatarUrl = map['avatar_url'];

    DateTime createdAt;
    try {
      final raw = map['created_at'];
      if (raw != null) {
        createdAt = DateTime.parse(raw).toLocal();
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    return CommentModel(
      id: map['id'] ?? '',
      ticketId: map['ticket_id'] ?? '',
      userId: map['user_id'] ?? '',
      message: map['message'] ?? '',
      imageUrl: map['image_url'],
      avatarUrl: avatarUrl,
      userName: userName,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'user_id': userId,
      'message': message,
      'image_url': imageUrl,
    };
  }

  bool isFromCurrentUser(String currentUserId) {
    return userId == currentUserId;
  }
}