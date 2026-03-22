import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayConnectionConfig.uri', () {
    test('normalizes a missing path to root slash', () {
      final config = GatewayConnectionConfig(
        url: 'wss://gateway.example.com',
        connectRequest: const GatewayConnectRequestFactory().build(),
      );

      expect(config.uri.toString(), 'wss://gateway.example.com/');
    });

    test('rejects empty urls instead of turning them into /', () {
      final config = GatewayConnectionConfig(
        url: '',
        connectRequest: const GatewayConnectRequestFactory().build(),
      );

      expect(
        () => config.uri,
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Gateway URL is empty'),
          ),
        ),
      );
    });
  });
}
