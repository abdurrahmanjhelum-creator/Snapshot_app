import 'dart:convert';
import 'package:flutter/material.dart';
import '../screens/user_profile_screen.dart';
import '../services/api_service.dart';

class LikesScreen extends StatefulWidget {
  final String postId;
  const LikesScreen({super.key, required this.postId});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  List<Map<String, dynamic>> _likes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getPostLikes(widget.postId);

      if (res.statusCode == 200 && mounted) {
        final parsedData = jsonDecode(res.body);
        _likes = List<Map<String, dynamic>>.from(parsedData['likes'] ?? []);
      }
    } catch (e) {
      debugPrint('Error loading likes: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Likes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likes.isEmpty
          ? const Center(child: Text('No likes yet'))
          : ListView.builder(
              itemCount: _likes.length,
              itemBuilder: (ctx, i) {
                final like = _likes[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        like['avatar'] != null && like['avatar']!.isNotEmpty
                        ? NetworkImage(ApiService.getImageUrl(like['avatar']))
                        : null,
                    child: like['avatar'] == null || like['avatar']!.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(like['username'] ?? 'Unknown'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UserProfileScreen(userId: like['userId']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
