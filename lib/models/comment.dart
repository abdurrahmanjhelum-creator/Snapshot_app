class Comment {
  final String id;
  final String content;
  final String userId;
  final String? username; // from populated user
  final String? userAvatar;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    this.username,
    this.userAvatar,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      userId: json['userId'] is Map
          ? json['userId']['_id'] ?? ''
          : json['userId'] ?? '',
      username: json['userId'] is Map ? json['userId']['username'] : null,
      userAvatar: json['userId'] is Map
          ? json['userId']['avatar'] ?? json['userId']['profilePicture']
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Comment copyWith({
    String? id,
    String? content,
    String? userId,
    String? username,
    String? userAvatar,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
