import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/post.dart';

class PostController extends ChangeNotifier {
  List<Post> _feedPosts = [];
  List<Post> _myPosts = [];
  bool _isLoading = false;
  final Set<String> _likingPosts =
      {}; // Track posts currently being liked/unliked
  final SocketService _socketService = SocketService();

  List<Post> get feedPosts => _feedPosts;
  List<Post> get myPosts => _myPosts;
  bool get isLoading => _isLoading;
  bool isLikingPost(String postId) => _likingPosts.contains(postId);

  PostController() {
    _initializeSocket();
  }

  void _initializeSocket() {
    _socketService.connect();

    // Listen for like added events
    _socketService.on('like-added', (data) {
      final postId = data['postId'] as String;

      // Update feed posts
      final feedIndex = _feedPosts.indexWhere((p) => p.id == postId);
      if (feedIndex != -1) {
        _feedPosts[feedIndex] = _feedPosts[feedIndex].copyWith(
          likesCount: _feedPosts[feedIndex].likesCount + 1,
        );
        notifyListeners();
      }

      // Update my posts
      final myPostsIndex = _myPosts.indexWhere((p) => p.id == postId);
      if (myPostsIndex != -1) {
        _myPosts[myPostsIndex] = _myPosts[myPostsIndex].copyWith(
          likesCount: _myPosts[myPostsIndex].likesCount + 1,
        );
        notifyListeners();
      }
    });

    // Listen for like removed events
    _socketService.on('like-removed', (data) {
      final postId = data['postId'] as String;

      // Update feed posts
      final feedIndex = _feedPosts.indexWhere((p) => p.id == postId);
      if (feedIndex != -1 && _feedPosts[feedIndex].likesCount > 0) {
        _feedPosts[feedIndex] = _feedPosts[feedIndex].copyWith(
          likesCount: _feedPosts[feedIndex].likesCount - 1,
        );
        notifyListeners();
      }

      // Update my posts
      final myPostsIndex = _myPosts.indexWhere((p) => p.id == postId);
      if (myPostsIndex != -1 && _myPosts[myPostsIndex].likesCount > 0) {
        _myPosts[myPostsIndex] = _myPosts[myPostsIndex].copyWith(
          likesCount: _myPosts[myPostsIndex].likesCount - 1,
        );
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _socketService.offAll();
    super.dispose();
  }

  // Feed fetch
  Future<void> fetchFeed() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.getFeed();

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (e) {
        throw const FormatException('Invalid server response format');
      }

      if (res.statusCode == 200) {
        List<dynamic> postsJson = data['posts'] ?? [];
        _feedPosts = postsJson.map((json) => Post.fromJson(json)).toList();
      } else {
        debugPrint('Feed error: ${data['message']}');
      }
    } on FormatException catch (e) {
      debugPrint('Feed FormatException: ${e.message}');
    } catch (e) {
      debugPrint('Feed fetch error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // My posts fetch
  Future<void> fetchMyPosts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.getMyPosts();

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (e) {
        throw const FormatException('Invalid server response format');
      }

      if (res.statusCode == 200) {
        List<dynamic> postsJson = data['posts'] ?? [];
        _myPosts = postsJson.map((json) => Post.fromJson(json)).toList();
      } else {
        debugPrint('My posts error: ${data['message']}');
      }
    } on FormatException catch (e) {
      debugPrint('My posts FormatException: ${e.message}');
    } catch (e) {
      debugPrint('My posts fetch error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // Create post
  Future<String?> createPost(
    String title,
    String? description,
    List<int> imageBytes,
    String fileName,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.createPost(
        title: title,
        description: description,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (e) {
        throw const FormatException('Invalid server response format');
      }

      _isLoading = false;
      notifyListeners();

      if (res.statusCode == 201) {
        await fetchFeed();
        return null;
      } else {
        return data['error'] ?? data['message'] ?? 'Failed to create post';
      }
    } on FormatException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      final res = await ApiService.deletePost(postId);
      if (res.statusCode == 200) {
        _feedPosts.removeWhere((p) => p.id == postId);
        _myPosts.removeWhere((p) => p.id == postId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  // Like post
  Future<void> toggleLike(String postId, bool isLiked) async {
    // Prevent multiple simultaneous like/unlike operations on same post
    if (_likingPosts.contains(postId)) {
      debugPrint('Already processing like/unlike for post $postId');
      return;
    }

    _likingPosts.add(postId);
    notifyListeners();

    try {
      // Update local state optimistically
      final feedIndex = _feedPosts.indexWhere((p) => p.id == postId);
      final myPostsIndex = _myPosts.indexWhere((p) => p.id == postId);

      if (feedIndex != -1) {
        _feedPosts[feedIndex] = _feedPosts[feedIndex].copyWith(
          isLiked: !isLiked,
          likesCount: isLiked
              ? _feedPosts[feedIndex].likesCount - 1
              : _feedPosts[feedIndex].likesCount + 1,
        );
        notifyListeners();
      }

      if (myPostsIndex != -1) {
        _myPosts[myPostsIndex] = _myPosts[myPostsIndex].copyWith(
          isLiked: !isLiked,
          likesCount: isLiked
              ? _myPosts[myPostsIndex].likesCount - 1
              : _myPosts[myPostsIndex].likesCount + 1,
        );
        notifyListeners();
      }

      // Make API call
      if (isLiked) {
        await ApiService.unlikePost(postId);
      } else {
        await ApiService.likePost(postId);
      }
    } catch (e) {
      debugPrint('Like error: $e');
      // Revert on error
      final feedIndex = _feedPosts.indexWhere((p) => p.id == postId);
      final myPostsIndex = _myPosts.indexWhere((p) => p.id == postId);

      if (feedIndex != -1) {
        _feedPosts[feedIndex] = _feedPosts[feedIndex].copyWith(
          isLiked: isLiked,
          likesCount: isLiked
              ? _feedPosts[feedIndex].likesCount + 1
              : _feedPosts[feedIndex].likesCount - 1,
        );
        notifyListeners();
      }

      if (myPostsIndex != -1) {
        _myPosts[myPostsIndex] = _myPosts[myPostsIndex].copyWith(
          isLiked: isLiked,
          likesCount: isLiked
              ? _myPosts[myPostsIndex].likesCount + 1
              : _myPosts[myPostsIndex].likesCount - 1,
        );
        notifyListeners();
      }
    } finally {
      _likingPosts.remove(postId);
      notifyListeners();
    }
  }
}
