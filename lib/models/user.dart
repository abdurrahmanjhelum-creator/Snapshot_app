class User {
  final String id;
  final String username;
  final String email;
  final String? avatar;
  final String? bio;
  final List<String> followers;
  final List<String> following;
  final int postCount; // ✅ Post count from backend
  final int followersCount; // ✅ Followers count from backend
  final int followingCount; // ✅ Following count from backend

  User({
    required this.id,
    required this.username,
    required this.email,
    this.avatar,
    this.bio,
    this.followers = const [],
    this.following = const [],
    this.postCount = 0, // ✅ Default value
    this.followersCount = 0, // ✅ Default value
    this.followingCount = 0, // ✅ Default value
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? json['image'] ?? '',
      bio: json['bio'] ?? '',
      followers: List<String>.from(
        json['followers']?.map((e) => e.toString()) ?? [],
      ),
      following: List<String>.from(
        json['following']?.map((e) => e.toString()) ?? [],
      ),
      postCount: json['postCount'] ?? 0, // ✅ Parse postCount from API
      followersCount:
          json['followersCount'] ?? 0, // ✅ Parse followersCount from API
      followingCount:
          json['followingCount'] ?? 0, // ✅ Parse followingCount from API
    );
  }
}
