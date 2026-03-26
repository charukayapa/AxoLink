import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return; // Not supported on web directly with this plugin

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings);
  }

  /// Request notification permission on first launch.
  /// On Android 13+ (API 33+) this shows the system permission dialog.
  /// On iOS this shows the notification permission dialog.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    // Use permission_handler for cross-platform permission request
    final status = await Permission.notification.request();
    if (status.isGranted) {
      return true;
    }

    // Fallback: also request via flutter_local_notifications for iOS
    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
    }

    return status.isGranted;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'axolink_alerts',
      'AxoLink Alerts',
      channelDescription: 'Important alerts for insulin cooler',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(id, title, body, details);
  }
}
