import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayConnectRequestFactory', () {
    test('builds operator-style connect request with auth', () {
      const factory = GatewayConnectRequestFactory();
      final request = factory.build(
        token: 'test-token',
        password: 'test-password',
        locale: 'en-US',
      );

      expect(request.role, 'operator');
      expect(request.scopes, contains('operator.admin'));
      expect(request.caps, contains('tool-events'));
      expect(request.auth?['token'], 'test-token');
      expect(request.auth?['password'], 'test-password');
      expect(request.locale, 'en-US');
    });
  });
}
