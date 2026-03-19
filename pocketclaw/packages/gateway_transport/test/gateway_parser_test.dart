import 'package:gateway_transport/gateway_transport.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayParser', () {
    const parser = GatewayParser();

    test('parses event frame', () {
      final message = parser.parseFrame(<String, Object?>{
        'type': 'event',
        'event': 'connect.challenge',
        'payload': <String, Object?>{'nonce': 'abc', 'ts': 1},
        'seq': 10,
      });

      expect(message, isA<GatewayEvent>());
      final event = message as GatewayEvent;
      expect(event.event, 'connect.challenge');
      expect(event.seq, 10);
    });

    test('parses connect challenge details', () {
      const event = GatewayEvent(
        event: 'connect.challenge',
        payload: <String, Object?>{'nonce': 'abc', 'ts': 123},
      );

      final challenge = parser.parseConnectChallenge(event);

      expect(challenge, isNotNull);
      expect(challenge?.nonce, 'abc');
      expect(challenge?.timestampMs, 123);
    });
  });
}
