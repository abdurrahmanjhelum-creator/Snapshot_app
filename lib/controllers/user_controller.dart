import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class UserController extends ChangeNotifier {
  User? _profileUser; // for other user's profile
  List<User> _followers = [];
  List<User> _following = [];
  bool _isLoading = false;

  User? get profileUser => _profileUser;
  List<User> get followers => _followers;
  List<User> get following => _following;
  bool get isLoading => _isLoading;

  // Get any user's profile
  Future<void> fetchUserProfile(String userId) async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    try {
      final res = await ApiService.getUserProfile(userId);

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (e) {
        throw const FormatException('Invalid server response format');
      }

      if (res.statusCode == 200) {
        _profileUser = User.fromJson(data['user']);
      } else {
        debugPrint('Fetch profile error: ${data['message']}');
      }
    } on FormatException catch (e) {
      debugPrint('Profile FormatException: ${e.message}');
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  // Update own profile
  Future<String?> updateProfile({
    String? username,
    String? bio,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    try {
      final res = await ApiService.updateProfile(
        username: username,
        bio: bio,
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
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      if (res.statusCode == 200) {
        return null;
      } else {
        return data['error'] ?? data['message'] ?? 'Update failed';
      }
    } on FormatException catch (e) {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      return e.message;
    } catch (e) {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  // Follow / Unfollow
  Future<void> followUser(String userId, {String? currentUserId}) async {
    try {
      await ApiService.followUser(userId);
      await fetchUserProfile(userId);
      // Also refresh current user's profile to update following list
      if (currentUserId != null && currentUserId != userId) {
        await fetchUserProfile(currentUserId);
      }
    } catch (e) {
      debugPrint('Follow error: $e');
    }
  }

  Future<void> unfollowUser(String userId, {String? currentUserId}) async {
    try {
      await ApiService.unfollowUser(userId);
      await fetchUserProfile(userId);
      // Also refresh current user's profile to update following list
      if (currentUserId != null && currentUserId != userId) {
        await fetchUserProfile(currentUserId);
      }
    } catch (e) {
      debugPrint('Unfollow error: $e');
    }
  }

  // Get followers list
  Future<void> fetchFollowers(String userId) async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    try {
      final res = await ApiService.getFollowers(userId);

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (e) {
        throw const FormatException('Invalid server response format');
      }

      if (res.statusCode == 200) {
        List<dynamic> list = data['followers'] ?? [];
        _followers = list.map((e) => User.fromJson(e)).toList();
      }
    } on FormatException catch (e) {
      debugPrint('Followers FormatException: ${e.message}');
    } catch (e) {
      debugPrint('Fetch followers error: $e');
    }
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  // Get following list
  Future<void> fetchFollowing(String userId) async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    try {
      final res = await ApiService.getFollowing(userId);

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (e) {
        throw const FormatException('Invalid server response format');
      }

      if (res.statusCode == 200) {
        List<dynamic> list = data['following'] ?? [];
        _following = list.map((e) => User.fromJson(e)).toList();
      }
    } on FormatException catch (e) {
      debugPrint('Following FormatException: ${e.message}');
    } catch (e) {
      debugPrint('Fetch following error: $e');
    }
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }
}
