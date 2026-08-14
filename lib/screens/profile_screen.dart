import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/post_grid_item.dart';
import 'edit_profile_screen.dart';
import 'followers_screen.dart';
import 'following_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onPostCreated;
  const ProfileScreen({super.key, required this.userId, this.onPostCreated});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  List<Post> _posts = [];
  bool _loadingPosts = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void refreshPosts() {
    _loadUserPosts(_getEffectiveUserId());
  }

  String _getEffectiveUserId() {
    final auth = context.read<AuthController>();
    if (widget.userId.isEmpty) {
      return auth.user?.id ?? "";
    }
    return widget.userId;
  }

  // Profile refresh function
  Future<void> _loadProfile() async {
    final userId = _getEffectiveUserId();

    // If userId changed, reload
    if (userId != _currentUserId) {
      _currentUserId = userId;
      if (!mounted || userId.isEmpty) return;

      // Fetch user profile data
      await context.read<UserController>().fetchUserProfile(userId);

      // Fetch user posts
      _loadUserPosts(userId);
    }
  }

  Future<void> _loadUserPosts(String userId) async {
    if (!mounted || userId.isEmpty) return;
    setState(() => _loadingPosts = true);
    try {
      final res = await ApiService.getUserPosts(userId);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && mounted) {
        List<dynamic> list = data['posts'] ?? [];
        setState(() {
          _posts = list.map((e) => Post.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading user posts: $e');
    }
    if (mounted) {
      setState(() => _loadingPosts = false);
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final authController = context.read<AuthController>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
          'Are you sure you want to log out from your account?',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Logout'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final navigator = Navigator.of(context);
    await authController.logout();

    if (!mounted) return;

    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final userCtrl = context.watch<UserController>();
    final auth = context.watch<AuthController>();
    final userId = widget.userId.isEmpty
        ? (auth.user?.id ?? "")
        : widget.userId;
    final isOwnProfile = auth.user?.id == userId;

    // Reload if userId changed
    if (userId != _currentUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProfile();
      });
    }

    // If no user is logged in, show login prompt
    if (userId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please login to view profile'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // For own profile, use auth.user data directly to ensure correct info
    final user = isOwnProfile ? auth.user : userCtrl.profileUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          user?.username ?? 'Profile',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isOwnProfile)
            PopupMenuButton<String>(
              tooltip: 'Profile options',
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                final navigator = Navigator.of(context);

                if (value == 'edit_profile') {
                  final result = await navigator.push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                  if (result == true && mounted) {
                    _loadProfile();
                  }
                  return;
                }

                if (value == 'logout') {
                  await _showLogoutDialog(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit_profile',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 12),
                      Text('Edit Profile'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Profile Header section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 50, // Radius 50 as requested
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                (user.avatar != null && user.avatar!.isNotEmpty)
                                ? NetworkImage(
                                    ApiService.getImageUrl(user.avatar),
                                  )
                                : null,
                            child: (user.avatar == null || user.avatar!.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey[700],
                                  ) // Grey700 icon
                                : null,
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStat('${user.postCount}', 'posts', () {}),
                                _buildStat(
                                  '${user.followersCount}',
                                  'followers',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            FollowersScreen(userId: user.id),
                                      ),
                                    );
                                  },
                                ),
                                _buildStat(
                                  '${user.followingCount}',
                                  'following',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            FollowingScreen(userId: user.id),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Username aur Bio
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (user.bio != null && user.bio!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(user.bio!),
                          ],
                        ],
                      ),
                    ),

                    // Follow/Unfollow button (agar apni profile nahi hai)
                    if (!isOwnProfile)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  user.followers.contains(auth.user?.id)
                                  ? Colors.grey[200]
                                  : Colors.blue,
                              foregroundColor:
                                  user.followers.contains(auth.user?.id)
                                  ? Colors.black
                                  : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final isFollowing = user.followers.contains(
                                auth.user?.id,
                              );
                              if (isFollowing) {
                                await context
                                    .read<UserController>()
                                    .unfollowUser(
                                      user.id,
                                      currentUserId: auth.user?.id,
                                    );
                              } else {
                                await context.read<UserController>().followUser(
                                  user.id,
                                  currentUserId: auth.user?.id,
                                );
                              }
                              // Refresh current user data in auth controller
                              await auth.refreshUser();
                            },
                            child: Text(
                              user.followers.contains(auth.user?.id)
                                  ? 'Unfollow'
                                  : 'Follow',
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),
                    const Divider(height: 1),

                    // User's Posts in Instagram-style 3-column grid
                    _loadingPosts
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(50.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                  childAspectRatio: 1,
                                ),
                            itemCount: _posts.length,
                            itemBuilder: (ctx, i) => PostGridItem(
                              post: _posts[i],
                              onPostDeleted: () =>
                                  _loadUserPosts(_getEffectiveUserId()),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStat(String count, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
