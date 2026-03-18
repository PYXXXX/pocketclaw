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
  });
}
