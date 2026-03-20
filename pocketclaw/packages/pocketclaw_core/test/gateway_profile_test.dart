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
      cloudflareAccessClientId: 'id-123.access',
      cloudflareAccessClientSecret: 'secret-456',
      defaultAgentId: 'coder',
      defaultSessionKey: 'agent:coder:mobile-home',
    );

    final decoded = GatewayProfile.fromJson(profile.toJson());

    expect(decoded.url, profile.url);
    expect(decoded.token, profile.token);
    expect(decoded.password, profile.password);
    expect(
      decoded.cloudflareAccessClientId,
      profile.cloudflareAccessClientId,
    );
    expect(
      decoded.cloudflareAccessClientSecret,
      profile.cloudflareAccessClientSecret,
    );
    expect(decoded.defaultAgentId, profile.defaultAgentId);
    expect(decoded.defaultSessionKey, profile.defaultSessionKey);
    expect(decoded.webSocketHeaders['CF-Access-Client-Id'], 'id-123.access');
    expect(decoded.webSocketHeaders['CF-Access-Client-Secret'], 'secret-456');
  });
}
