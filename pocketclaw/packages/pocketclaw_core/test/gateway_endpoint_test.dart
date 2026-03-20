import 'package:pocketclaw_core/pocketclaw_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeGatewayUrl', () {
    test('keeps websocket urls as-is', () {
      expect(
        normalizeGatewayUrl('ws://192.168.1.20:18789'),
        'ws://192.168.1.20:18789',
      );
    });

    test('converts https urls to wss', () {
      expect(
        normalizeGatewayUrl('https://gateway.example.com'),
        'wss://gateway.example.com',
      );
    });

    test('defaults bare remote hostnames to wss', () {
      expect(
        normalizeGatewayUrl('gateway.example.com'),
        'wss://gateway.example.com',
      );
    });

    test('defaults bare local addresses to ws', () {
      expect(
        normalizeGatewayUrl('192.168.1.20:18789'),
        'ws://192.168.1.20:18789',
      );
    });
  });

  group('gatewayUrlUsesLoopback', () {
    test('detects localhost and loopback urls', () {
      expect(gatewayUrlUsesLoopback('ws://127.0.0.1:18789'), isTrue);
      expect(gatewayUrlUsesLoopback('http://localhost:18789'), isTrue);
      expect(gatewayUrlUsesLoopback('0.0.0.0:18789'), isTrue);
    });

    test('does not flag lan or remote hosts as loopback', () {
      expect(gatewayUrlUsesLoopback('192.168.1.20:18789'), isFalse);
      expect(gatewayUrlUsesLoopback('https://gateway.example.com'), isFalse);
    });
  });
}
