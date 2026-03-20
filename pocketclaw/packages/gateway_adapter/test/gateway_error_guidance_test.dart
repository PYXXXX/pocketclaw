import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('gatewayErrorGuidanceFor', () {
    test('maps pairing required to a helpful summary', () {
      final guidance = gatewayErrorGuidanceFor(
        const GatewayRequestError(
          code: 'UNAVAILABLE',
          message: 'request failed',
          details: <String, Object?>{
            'code': GatewayErrorCodes.pairingRequired,
          },
        ),
      );

      expect(guidance.code, GatewayErrorCodes.pairingRequired);
      expect(guidance.summary, contains('approved'));
      expect(guidance.action, contains('pairing'));
    });

    test('maps token mismatch to auth guidance', () {
      final guidance = gatewayErrorGuidanceFor(
        const GatewayRequestError(
          code: 'UNAVAILABLE',
          message: 'request failed',
          details: <String, Object?>{
            'code': GatewayErrorCodes.authTokenMismatch,
            'canRetryWithDeviceToken': true,
          },
        ),
      );

      expect(guidance.summary, contains('token'));
      expect(guidance.action, contains('device token'));
    });

    test('explains loopback connection refused errors for phone usage', () {
      final guidance = gatewayErrorGuidanceFor(
        StateError('WebSocketChannelException: SocketException: Connection refused'),
        configuredUrl: 'ws://127.0.0.1:18789',
      );

      expect(guidance.summary, contains('localhost / loopback'));
      expect(guidance.action, contains('127.0.0.1 / localhost'));
    });

    test('explains 403 handshakes as likely access or proxy rejection', () {
      final guidance = gatewayErrorGuidanceFor(
        StateError('WebSocketChannelException: HandshakeException: Connection to server was not upgraded to websocket, HTTP status code: 403'),
        configuredUrl: 'wss://bot.bilirec.com',
      );

      expect(guidance.summary, contains('handshake was rejected'));
      expect(guidance.action, contains('Cloudflare Access'));
    });

    test('explains unsupported url scheme as a client-side connect issue', () {
      final guidance = gatewayErrorGuidanceFor(
        StateError('WebSocketException: Unsupported URL scheme "wss"'),
        configuredUrl: 'wss://bot.bilirec.com',
      );

      expect(guidance.summary, contains('rejected the configured WebSocket URL'));
      expect(guidance.action, contains('client-side compatibility bug'));
    });
  });
}
