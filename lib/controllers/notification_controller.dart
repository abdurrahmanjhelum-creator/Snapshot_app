import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationItem> _items = [];
  bool _loading = false;

  List<NotificationItem> get items => _items;
  bool get isLoading => _loading;

  Future<void> fetchNotifications() async {
    _loading = true;
    notifyListeners();

    try {
      final response = await ApiService.getNotifications();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['notifications'] as List? ?? const [];
        _items = list.map((n) => NotificationItem.fromJson(n)).toList();
      }
    } catch (e) {
      debugPrint('Notification fetch error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.markNotificationsAsRead();
      for (final item in _items) {
        final index = _items.indexOf(item);
        _items[index] = NotificationItem(
          id: item.id,
          type: item.type,
          read: true,
          message: item.message,
          senderName: item.senderName,
          senderAvatar: item.senderAvatar,
          postImage: item.postImage,
          postId: item.postId,
          createdAt: item.createdAt,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Mark notifications read error: $e');
    }
  }
}
