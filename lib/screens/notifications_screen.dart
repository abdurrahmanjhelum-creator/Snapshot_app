import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<NotificationItem>> _fetchNotifications() async {
    try {
      final response = await ApiService.getNotifications();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notificationsList = data['notifications'] as List? ?? [];
        
        return notificationsList
            .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> _markAsRead() async {
    try {
      await ApiService.markNotificationsAsRead();
      setState(() {
        _notificationsFuture = _fetchNotifications();
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          FutureBuilder(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && (snapshot.data as List).isNotEmpty) {
                return TextButton(
                  onPressed: _markAsRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _notificationsFuture = _fetchNotifications();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "No notifications yet",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _notificationsFuture = _fetchNotifications();
              });
              await _notificationsFuture;
            },
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationTile(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    final backgroundColor = notification.read
        ? Colors.white
        : const Color(0xFFF0F0F0);

    final icon = _getNotificationIcon(notification.type);

    return Container(
      color: backgroundColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: notification.senderAvatar != null &&
                  notification.senderAvatar!.isNotEmpty
              ? NetworkImage(notification.senderAvatar!)
              : null,
          child: notification.senderAvatar == null ||
                  notification.senderAvatar!.isEmpty
              ? Icon(icon, size: 20, color: Colors.grey)
              : null,
        ),
        title: Text(
          notification.message ?? 'New notification',
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatTime(notification.createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: notification.postImage != null &&
                notification.postImage!.isNotEmpty
            ? Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(notification.postImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : null,
        onTap: () {
          // TODO: Navigate to post or profile
          debugPrint('Tapped notification: ${notification.id}');
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'post':
        return Icons.image;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
