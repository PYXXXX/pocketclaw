import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/notifications/reply_notification_payload.dart';

void main() {
  test('ReplyNotificationPayload round-trips through json', () {
    const payload = ReplyNotificationPayload(
      sessionKey: 'agent:main:pc-home',
      sessionTitle: 'Daily Ops',
    );

    final parsed = ReplyNotificationPayload.tryParse(payload.toJsonString());
    expect(parsed?.sessionKey, 'agent:main:pc-home');
    expect(parsed?.sessionTitle, 'Daily Ops');
  });

  test('ReplyNotificationPayload rejects invalid payloads', () {
    expect(ReplyNotificationPayload.tryParse(null), isNull);
    expect(ReplyNotificationPayload.tryParse(''), isNull);
    expect(ReplyNotificationPayload.tryParse('{"sessionTitle":"x"}'), isNull);
    expect(ReplyNotificationPayload.tryParse('not-json'), isNull);
  });
}
