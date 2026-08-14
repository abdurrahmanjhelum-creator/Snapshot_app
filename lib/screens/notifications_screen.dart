import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notification_controller.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().fetchNotifications();
    });
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'post':
        return Icons.image;
      default:
        return Icons.notifications;
    }
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'like':
        return Colors.pink;
      case 'comment':
        return Colors.blue;
      case 'post':
        return Colors.orange;
      default:
        return Colors.grey;
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
          Consumer<NotificationController>(
            builder: (context, controller, _) {
              if (controller.items.isEmpty) return const SizedBox();
              return TextButton(
                onPressed: () => controller.markAllAsRead(),
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 84, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.fetchNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: controller.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = controller.items[index];
                final avatarUrl = (item.senderAvatar ?? '').isNotEmpty
                    ? ApiService.getImageUrl(item.senderAvatar)
                    : '';
                final postUrl = (item.postImage ?? '').isNotEmpty
                    ? ApiService.getImageUrl(item.postImage)
                    : '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        backgroundColor: Colors.grey[200],
                        child: avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _notificationColor(item.type),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            _notificationIcon(item.type),
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    item.message ?? 'New activity',
                    style: TextStyle(
                      fontWeight: item.read ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(_timeAgo(item.createdAt)),
                  trailing: postUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            postUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(Icons.image_not_supported_outlined),
                            ),
                          ),
                        )
                      : const SizedBox(width: 48),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
