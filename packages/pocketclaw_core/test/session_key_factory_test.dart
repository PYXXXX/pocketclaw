import 'package:pocketclaw_core/pocketclaw_core.dart';
import 'package:test/test.dart';

void main() {
  group('SessionKeyFactory', () {
    const factory = SessionKeyFactory();

    test('creates client-shaped session keys', () {
      final sessionKey = factory.createTimestamped(
        agentId: 'main',
        prefix: 'pc',
        now: DateTime.utc(2026, 3, 18, 16, 0, 0),
      );

      expect(sessionKey.value, startsWith('agent:main:pc-'));
    });
  });
}
