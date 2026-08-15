import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static String? currentUserId;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void setCurrentUserId(String? userId) {
    currentUserId = userId;
  }

  static String buildAlertMessage(String senderName, String type) {
    final safeSender = senderName.trim().isEmpty ? 'Someone' : senderName.trim();

    switch (type) {
      case 'like':
        return '$safeSender liked your post';
      case 'comment':
        return '$safeSender commented on your post';
      case 'post':
        return '$safeSender shared a new post';
      default:
        return '$safeSender interacted with your post';
    }
  }

  static bool shouldTriggerLocalAlert({
    required String? currentUserId,
    required String? recipientId,
  }) {
    if (currentUserId == null || recipientId == null) return false;
    return currentUserId == recipientId;
  }

  Future<void> initialize() async {
    // Android configuration
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS configuration with permission handling
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Request iOS notification permissions
    await _requestIOSPermissions();

    // Create Android notification channel
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'socialsnap_notifications',
        'SocialSnap Notifications',
        description: 'Alerts for likes, comments and new posts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    debugPrint('✅ Notification service initialized successfully');
  }

  Future<void> _requestIOSPermissions() async {
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (granted != null && granted) {
        debugPrint('✅ iOS notification permissions granted');
      } else {
        debugPrint('⚠️ iOS notification permissions denied or not requested');
      }
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Android notification configuration
    final androidDetails = AndroidNotificationDetails(
      'socialsnap_notifications',
      'SocialSnap Notifications',
      channelDescription: 'Notification channel for app alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'SocialSnap notification',
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    // iOS notification configuration
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      threadIdentifier: 'socialsnap_notifications',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        payload: 'socialsnap_notification',
        notificationDetails: notificationDetails,
      );
      debugPrint('✅ Notification displayed: $title - $body');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  Future<void> triggerInteractionAlert({
    required String senderName,
    required String type,
    String? recipientId,
  }) async {
    final shouldTrigger = shouldTriggerLocalAlert(
      currentUserId: NotificationService.currentUserId,
      recipientId: recipientId ?? NotificationService.currentUserId,
    );

    if (!shouldTrigger) return;

    final message = buildAlertMessage(senderName, type);

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'New notification',
      body: message,
    );
  }

  Future<void> showLikeOrCommentAlert({
    required String senderName,
    required String type,
    String? recipientId,
  }) async {
    await triggerInteractionAlert(
      senderName: senderName,
      type: type,
      recipientId: recipientId,
    );
  }
}
