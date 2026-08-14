import 'package:flutter_test/flutter_test.dart';
import 'package:app_frontend/services/notification_service.dart';

void main() {
  test('builds a like notification message', () {
    expect(
      NotificationService.buildAlertMessage('Aisha', 'like'),
      'Aisha liked your post',
    );
  });

  test('builds a comment notification message', () {
    expect(
      NotificationService.buildAlertMessage('Aisha', 'comment'),
      'Aisha commented on your post',
    );
  });

  test('builds a new post notification message', () {
    expect(
      NotificationService.buildAlertMessage('Aisha', 'post'),
      'Aisha shared a new post',
    );
  });

  test('only triggers for the matching recipient user', () {
    expect(
      NotificationService.shouldTriggerLocalAlert(
        currentUserId: 'user-123',
        recipientId: 'user-123',
      ),
      isTrue,
    );

    expect(
      NotificationService.shouldTriggerLocalAlert(
        currentUserId: 'user-123',
        recipientId: 'user-456',
      ),
      isFalse,
    );
  });
}
