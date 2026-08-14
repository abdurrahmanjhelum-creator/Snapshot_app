class NotificationItem {
  final String id;
  final String type;
  final bool read;
  final String? message;
  final String? senderName;
  final String? senderAvatar;
  final String? postImage;
  final String? postId;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.read,
    this.message,
    this.senderName,
    this.senderAvatar,
    this.postImage,
    this.postId,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] is Map ? json['sender'] as Map<String, dynamic> : null;
    final post = json['post'] is Map ? json['post'] as Map<String, dynamic> : null;

    final senderName = sender?['username'] ?? 'Someone';
    final senderAvatar = sender?['avatar'] ?? '';
    final postImage = post?['image'] ?? '';
    final postId = post?['_id'] ?? '';

    final type = (json['type'] ?? '').toString();
    final message = _buildMessage(type, senderName);

    return NotificationItem(
      id: json['_id'] ?? '',
      type: type,
      read: json['read'] == true,
      message: message,
      senderName: senderName,
      senderAvatar: senderAvatar,
      postImage: postImage,
      postId: postId,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  static String _buildMessage(String type, String senderName) {
    switch (type) {
      case 'like':
        return '$senderName liked your post';
      case 'comment':
        return '$senderName commented on your post';
      case 'post':
        return '$senderName shared a new post';
      default:
        return '$senderName interacted with your post';
    }
  }
}
