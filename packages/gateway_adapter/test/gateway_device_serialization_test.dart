import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:test/test.dart';

void main() {
  test('GatewayDeviceIdentity round-trips through json', () {
    const identity = GatewayDeviceIdentity(
      deviceId: 'device-1',
      publicKey: 'public-key',
      privateKey: 'private-key',
    );

    final decoded = GatewayDeviceIdentity.fromJson(identity.toJson());

    expect(decoded.deviceId, identity.deviceId);
    expect(decoded.publicKey, identity.publicKey);
    expect(decoded.privateKey, identity.privateKey);
  });

  test('GatewayDeviceToken round-trips through json', () {
    const token = GatewayDeviceToken(
      deviceId: 'device-1',
      role: 'app',
      token: 'device-token',
      scopes: <String>['chat', 'sessions'],
    );

    final decoded = GatewayDeviceToken.fromJson(token.toJson());

    expect(decoded.deviceId, token.deviceId);
    expect(decoded.role, token.role);
    expect(decoded.token, token.token);
    expect(decoded.scopes, token.scopes);
  });
}
