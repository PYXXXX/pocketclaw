import 'package:shared_preferences/shared_preferences.dart';

final class NotificationPreferences {
  const NotificationPreferences({
    required this.notificationsEnabled,
    required this.showReplyBody,
    required this.mutedSessionKeys,
  });

  final bool notificationsEnabled;
  final bool showReplyBody;
  final List<String> mutedSessionKeys;
}

abstract interface class NotificationPreferencesStore {
  Future<NotificationPreferences> read();

  Future<void> write({
    required bool notificationsEnabled,
    required bool showReplyBody,
    required List<String> mutedSessionKeys,
  });
}

final class SharedPreferencesNotificationPreferencesStore
    implements NotificationPreferencesStore {
  SharedPreferencesNotificationPreferencesStore({
    Future<SharedPreferences>? sharedPreferences,
  }) : _sharedPreferencesFuture =
            sharedPreferences ?? SharedPreferences.getInstance();

  static const String notificationsEnabledKey =
      'pocketclaw.notifications.enabled';
  static const String showReplyBodyKey =
      'pocketclaw.notifications.show_reply_body';
  static const String mutedSessionKeysKey =
      'pocketclaw.notifications.muted_session_keys';

  final Future<SharedPreferences> _sharedPreferencesFuture;

  @override
  Future<NotificationPreferences> read() async {
    final prefs = await _sharedPreferencesFuture;
    return NotificationPreferences(
      notificationsEnabled: prefs.getBool(notificationsEnabledKey) ?? true,
      showReplyBody: prefs.getBool(showReplyBodyKey) ?? true,
      mutedSessionKeys: prefs.getStringList(mutedSessionKeysKey) ?? const [],
    );
  }

  @override
  Future<void> write({
    required bool notificationsEnabled,
    required bool showReplyBody,
    required List<String> mutedSessionKeys,
  }) async {
    final prefs = await _sharedPreferencesFuture;
    await prefs.setBool(notificationsEnabledKey, notificationsEnabled);
    await prefs.setBool(showReplyBodyKey, showReplyBody);
    await prefs.setStringList(
      mutedSessionKeysKey,
      mutedSessionKeys.toSet().toList()..sort(),
    );
  }
}
