import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocketclaw_app/src/storage/notification_preferences_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'notification preferences default to enabled with visible body',
    () async {
      final store = SharedPreferencesNotificationPreferencesStore();

      final preferences = await store.read();

      expect(preferences.notificationsEnabled, isTrue);
      expect(preferences.showReplyBody, isTrue);
      expect(preferences.mutedSessionKeys, isEmpty);
    },
  );

  test('notification preferences persist mute list and toggles', () async {
    final store = SharedPreferencesNotificationPreferencesStore();

    await store.write(
      notificationsEnabled: false,
      showReplyBody: false,
      mutedSessionKeys: const [
        'agent:main:pc-home',
        'agent:main:ops',
        'agent:main:pc-home',
      ],
    );

    final preferences = await store.read();

    expect(preferences.notificationsEnabled, isFalse);
    expect(preferences.showReplyBody, isFalse);
    expect(
      preferences.mutedSessionKeys,
      orderedEquals(const ['agent:main:ops', 'agent:main:pc-home']),
    );
  });
}
