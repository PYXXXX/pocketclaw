import 'package:pocketclaw_core/pocketclaw_core.dart';
import 'package:test/test.dart';

void main() {
  test('GatewayProfile defaults to an empty url', () {
    const profile = GatewayProfile();

    expect(profile.url, isEmpty);
  });

  test('GatewayProfile round-trips through json', () {
    const profile = GatewayProfile(
      url: 'wss://gateway.example/ws',
      token: 'token-123',
      password: 'password-456',
      defaultAgentId: 'coder',
      defaultSessionKey: 'agent:coder:mobile-home',
    );

    final decoded = GatewayProfile.fromJson(profile.toJson());

    expect(decoded.url, profile.url);
    expect(decoded.token, profile.token);
    expect(decoded.password, profile.password);
    expect(decoded.defaultAgentId, profile.defaultAgentId);
    expect(decoded.defaultSessionKey, profile.defaultSessionKey);
  });
}
