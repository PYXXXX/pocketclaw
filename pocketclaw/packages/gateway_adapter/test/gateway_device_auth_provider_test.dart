import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('CryptographyDeviceAuthProvider', () {
    test('builds signed device auth payload', () async {
      final provider = CryptographyDeviceAuthProvider(
        store: MemoryGatewayDeviceIdentityStore(),
      );

      final device = await provider.buildDeviceAuth(
        challenge: const ConnectChallenge(nonce: 'nonce-1'),
        connectRequest: const GatewayConnectRequestFactory().build(token: 'abc'),
      );

      expect(device['id'], isA<String>());
      expect(device['publicKey'], isA<String>());
      expect(device['signature'], isA<String>());
      expect(device['signedAt'], isA<int>());
      expect(device['nonce'], 'nonce-1');
    });
  });
}
