import 'dart:convert';

import 'dart:io';

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL auto-detect for platform

  static String get serverUrl {
    const liveUrl = 'https://snapshhot-backend-mocha.vercel.app';
    return liveUrl;
  }

  static String get baseUrl => '$serverUrl/api';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    if (path.startsWith('http')) return path;

    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    return '$serverUrl/$cleanPath';
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('accessToken');
  }

  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('accessToken', token);
  }

  static Future<void> removeAccessToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('accessToken');
  }

  static Future<Map<String, String>> _getHeaders({
    bool isMultipart = false,
  }) async {
    String? token = await getAccessToken();

    Map<String, String> headers = {};

    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Helper to handle response validation and logging

  static void _validateResponse(http.Response response) {
    debugPrint('Response status: ${response.statusCode}');

    debugPrint('Response body: ${response.body}');

    if (response.body.startsWith('<!DOCTYPE') ||
        response.body.startsWith('<html')) {
      throw const FormatException('Server returned HTML instead of JSON');
    }
  }

  // ⭐ Refresh Token - Call when access token expires

  static Future<bool> refreshToken() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh-token'),

            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      _validateResponse(response);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final newAccessToken = data['accessToken'];

        await saveAccessToken(newAccessToken);

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Refresh token error: $e');

      return false;
    }
  }

  // ⭐ Make authenticated request with auto-refresh

  static Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function() requestFunc,
  ) async {
    try {
      return await requestFunc();
    } catch (e) {
      // If 401 unauthorized, try to refresh token

      if (e.toString().contains('401')) {
        debugPrint('Access token expired, attempting refresh...');

        final refreshed = await refreshToken();

        if (refreshed) {
          debugPrint('Token refreshed, retrying request...');

          return await requestFunc();
        } else {
          throw Exception('Session expired. Please login again.');
        }
      }

      rethrow;
    }
  }

  // -------------------- Auth --------------------

  static Future<http.Response> register(
    String username,

    String email,

    String password, [

    String? otp,
  ]) async {
    try {
      final body = {'username': username, 'email': email, 'password': password};

      if (otp != null) {
        body['otp'] = otp;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      _validateResponse(response);

      return response;
    } on SocketException {
      throw Exception(
        'Cannot connect to server. Check internet and if server is running.',
      );
    } on TimeoutException {
      throw Exception('Connection timeout. Server took too long to respond.');
    } catch (e) {
      if (e is FormatException) rethrow;

      throw Exception('Network error: $e');
    }
  }

  static Future<http.Response> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      _validateResponse(response);

      return response;
    } on SocketException {
      throw Exception(
        'Cannot connect to server. Check internet and if server is running.',
      );
    } on TimeoutException {
      throw Exception('Connection timeout. Server took too long to respond.');
    } catch (e) {
      if (e is FormatException) rethrow;

      throw Exception('Network error: $e');
    }
  }

  static Future<void> logout() async {
    try {
      final url = Uri.parse('$baseUrl/auth/logout');

      final headers = await _getHeaders();

      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      _validateResponse(response);

      await removeAccessToken();
    } catch (e) {
      debugPrint('Logout error: $e');

      await removeAccessToken(); // Clear token anyway
    }
  }

  static Future<http.Response> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      _validateResponse(response);

      return response;
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } on TimeoutException {
      throw Exception('Connection timeout.');
    } catch (e) {
      if (e is FormatException) rethrow;

      throw Exception('Network error: $e');
    }
  }

  static Future<http.Response> resetPassword(
    String email,

    String otp,

    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({
              'email': email,

              'otp': otp,

              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      _validateResponse(response);

      return response;
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } on TimeoutException {
      throw Exception('Connection timeout.');
    } catch (e) {
      if (e is FormatException) rethrow;

      throw Exception('Network error: $e');
    }
  }

  // -------------------- OTP --------------------

  static Future<http.Response> verifyEmail(String email, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-email'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 30));

      _validateResponse(response);

      return response;
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } on TimeoutException {
      throw Exception('Connection timeout.');
    } catch (e) {
      if (e is FormatException) rethrow;

      throw Exception('Network error: $e');
    }
  }

  static Future<http.Response> resendOTP(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/resend-otp'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      _validateResponse(response);

      return response;
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } on TimeoutException {
      throw Exception('Connection timeout.');
    } catch (e) {
      if (e is FormatException) rethrow;

      throw Exception('Network error: $e');
    }
  }

  // -------------------- Posts --------------------

  static Future<http.Response> getFeed() async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .get(Uri.parse('$baseUrl/post/get'), headers: await _getHeaders())
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } on SocketException {
        throw Exception('Cannot connect to server.');
      } on TimeoutException {
        throw Exception('Connection timeout.');
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> createPost({
    required String title,

    String? description,

    required List<int> imageBytes,

    required String fileName,
  }) async {
    return _authenticatedRequest(() async {
      try {
        var request = http.MultipartRequest(
          'POST',

          Uri.parse('$baseUrl/post/create'),
        );

        final headers = await _getHeaders(isMultipart: true);

        request.headers.addAll(headers);

        request.fields['title'] = title;

        if (description != null) request.fields['description'] = description;

        request.fields['completed'] = 'false';

        request.files.add(
          http.MultipartFile.fromBytes('image', imageBytes, filename: fileName),
        );

        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 20),
        ); // Upload takes longer

        final response = await http.Response.fromStream(streamedResponse);

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Failed to upload post: $e');
      }
    });
  }

  static Future<http.Response> getMyPosts() async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/post/my-posts'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> deletePost(String postId) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .delete(
              Uri.parse('$baseUrl/post/delete/$postId'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  // -------------------- Likes --------------------

  static Future<http.Response> toggleLikePost(String postId, bool isLiked) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/posts/$postId/like'),
              headers: await _getHeaders(),
              body: jsonEncode({'liked': !isLiked}),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> likePost(String postId) async {
    return toggleLikePost(postId, false);
  }

  static Future<http.Response> unlikePost(String postId) async {
    return toggleLikePost(postId, true);
  }

  static Future<http.Response> getPostLikes(String postId) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/likes/$postId'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  // -------------------- Comments --------------------

  static Future<http.Response> addComment(String postId, String content) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/comments/add/$postId'),

              headers: await _getHeaders(),

              body: jsonEncode({'content': content}),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> getComments(String postId) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/posts/$postId/comments'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> deleteComment(String commentId) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .delete(
              Uri.parse('$baseUrl/comments/delete/$commentId'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> updateComment(
    String commentId,
    String content,
  ) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .put(
              Uri.parse('$baseUrl/comments/update/$commentId'),
              headers: await _getHeaders(),
              body: jsonEncode({'content': content}),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  // -------------------- User / Profile --------------------

  static Future<http.Response> getUserProfile(String userId) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/user/profile/$userId'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> updateProfile({
    String? username,

    String? bio,

    List<int>? imageBytes,

    String? fileName,
  }) async {
    return _authenticatedRequest(() async {
      try {
        var request = http.MultipartRequest(
          'PUT',

          Uri.parse('$baseUrl/user/update'),
        );

        final headers = await _getHeaders(isMultipart: true);

        request.headers.addAll(headers);

        if (username != null) request.fields['username'] = username;

        if (bio != null) request.fields['bio'] = bio;

        if (imageBytes != null && fileName != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',

              imageBytes,

              filename: fileName,
            ),
          );
        }

        final response = await http.Response.fromStream(
          await request.send().timeout(const Duration(seconds: 20)),
        );

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Update profile error: $e');
      }
    });
  }

  static Future<http.Response> getUserPosts(String userId) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/user/posts/$userId'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  // -------------------- Notifications --------------------

  static Future<http.Response> getNotifications() async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/notifications'),
              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);
        return response;
      } catch (e) {
        if (e is FormatException) rethrow;
        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> markNotificationsAsRead() async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .patch(
              Uri.parse('$baseUrl/notifications/read'),
              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);
        return response;
      } catch (e) {
        if (e is FormatException) rethrow;
        throw Exception('Network error: $e');
      }
    });
  }

  // -------------------- Search --------------------

  static Future<http.Response> searchPosts(String query) async {
    return _authenticatedRequest(() async {
      try {
        final encoded = Uri.encodeQueryComponent(query);
        final response = await http
            .get(
              Uri.parse('$baseUrl/post/search?query=$encoded'),
              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> followUser(String userId) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/user/follow/$userId'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> unfollowUser(String userId) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/user/unfollow/$userId'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> getFollowers(String userId) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/user/followers/$userId'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }

  static Future<http.Response> getFollowing(String userId) async {
    return _authenticatedRequest(() async {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/user/following/$userId'),

              headers: await _getHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        _validateResponse(response);

        return response;
      } catch (e) {
        if (e is FormatException) rethrow;

        throw Exception('Network error: $e');
      }
    });
  }
}
