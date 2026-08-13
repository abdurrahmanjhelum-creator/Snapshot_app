import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthController extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  // Login
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.login(email, password);

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (e) {
        throw const FormatException('Invalid server response format');
      }

      if (res.statusCode == 200) {
        final accessToken = data['accessToken'];
        await ApiService.saveAccessToken(accessToken);
        _user = User.fromJson(data['user']);
        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        _isLoading = false;
        notifyListeners();
        return data['message'] ?? 'Login failed';
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

  // Register
  Future<String?> register(
    String username,
    String email,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.register(username, email, password);

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (e) {
        throw const FormatException('Invalid server response format');
      }

      _isLoading = false;
      notifyListeners();
      if (res.statusCode == 201) {
        return null;
      } else {
        return data['message'] ?? 'Registration failed';
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

  // Fetch/Refresh current user data
  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final res = await ApiService.getUserProfile(_user!.id);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _user = User.fromJson(data['user']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh user error: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }

  // Auto-login check
  Future<void> tryAutoLogin() async {
    final token = await ApiService.getAccessToken();
    if (token != null) {
      // Logic for fetching profile with token can be added here
    }
  }
}
