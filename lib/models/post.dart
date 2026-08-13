class Post {
  final String id;
  final String title;
  final String? description;
  final String? image;
  final bool completed;
  final String userId;
  final String? username; // from populated user
  final String? userAvatar; // profile picture
  final DateTime createdAt;
  final int likesCount; // total number of likes
  final bool isLiked; // whether current user liked this post
  final int commentsCount; // total number of comments

  Post({
    required this.id,
    required this.title,
    this.description,
    this.image,
    required this.completed,
    required this.userId,
    this.username,
    this.userAvatar,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.commentsCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final likes = (json['likes'] as List?) ?? const [];
    final likesCount = json['likesCount'] ?? likes.length ?? 0;
    final isLiked = json['isLiked'] == true;
    final commentsCount =
        json['commentsCount'] ?? json['comments']?.length ?? 0;

    return Post(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      image: json['image'],
      completed: json['completed'] ?? false,
      userId: json['userId'] is Map
          ? json['userId']['_id'] ?? ''
          : json['userId'] ?? '',
      username: json['userId'] is Map ? json['userId']['username'] : null,
      userAvatar: json['userId'] is Map
          ? json['userId']['profilePicture'] ?? json['userId']['avatar']
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      likesCount: likesCount is int ? likesCount : 0,
      isLiked: isLiked,
      commentsCount: commentsCount is int ? commentsCount : 0,
    );
  }

  Post copyWith({
    String? id,
    String? title,
    String? description,
    String? image,
    bool? completed,
    String? userId,
    String? username,
    String? userAvatar,
    DateTime? createdAt,
    int? likesCount,
    bool? isLiked,
    int? commentsCount,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      completed: completed ?? this.completed,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}
