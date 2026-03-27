import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'reply_notification_payload.dart';
import 'reply_notification_summary.dart';

final class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _replyChannelId = 'pocketclaw_replies';
  static const String _replyChannelName = 'PocketClaw replies';
  static const String _replyChannelDescription =
      'Assistant replies from the connected OpenClaw Gateway';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize({
    Future<void> Function(ReplyNotificationPayload payload)?
        onReplyNotificationTap,
  }) async {
    if (_initialized) {
      return;
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = ReplyNotificationPayload.tryParse(response.payload);
        if (payload == null || onReplyNotificationTap == null) {
          return;
        }
        await onReplyNotificationTap(payload);
      },
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchedPayload = ReplyNotificationPayload.tryParse(
      launchDetails?.notificationResponse?.payload,
    );
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchedPayload != null &&
        onReplyNotificationTap != null) {
      await onReplyNotificationTap(launchedPayload);
    }
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: false, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: false, sound: true);
  }

  Future<void> showReplyNotification(ReplyNotificationSummary summary) async {
    await initialize();
    await _plugin.show(
      summary.id,
      summary.title,
      summary.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _replyChannelId,
          _replyChannelName,
          channelDescription: _replyChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(summary.body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
        ),
      ),
      payload: summary.payload.toJsonString(),
    );
  }
}
