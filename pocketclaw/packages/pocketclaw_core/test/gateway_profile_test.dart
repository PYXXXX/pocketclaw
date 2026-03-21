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
      customRequestHeadersText: 'X-Test-Header: hello',
      defaultAgentId: 'coder',
      defaultSessionKey: 'agent:coder:mobile-home',
    );

    final decoded = GatewayProfile.fromJson(profile.toJson());

    expect(decoded.url, profile.url);
    expect(decoded.token, profile.token);
    expect(decoded.password, profile.password);
    expect(decoded.cloudflareAccessClientId, profile.cloudflareAccessClientId);
    expect(
      decoded.cloudflareAccessClientSecret,
      profile.cloudflareAccessClientSecret,
    );
    expect(decoded.customRequestHeadersText, profile.customRequestHeadersText);
    expect(decoded.defaultAgentId, profile.defaultAgentId);
    expect(decoded.defaultSessionKey, profile.defaultSessionKey);
    expect(decoded.webSocketHeaders['CF-Access-Client-Id'], 'id-123.access');
    expect(decoded.webSocketHeaders['CF-Access-Client-Secret'], 'secret-456');
    expect(decoded.webSocketHeaders['X-Test-Header'], 'hello');
  });

  test('parseGatewayRequestHeadersText parses multi-line headers', () {
    final headers = parseGatewayRequestHeadersText(
      'X-Test: one\n# comment\nAuthorization: Bearer abc:def\nX-Test: two',
    );

    expect(headers, <String, String>{
      'X-Test': 'two',
      'Authorization': 'Bearer abc:def',
    });
  });

  test(
    'parseGatewayRequestHeadersText throws in strict mode for invalid lines',
    () {
      expect(
        () => parseGatewayRequestHeadersText('not-a-header', strict: true),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('cloudflare shortcut fields override duplicate custom headers', () {
    const profile = GatewayProfile(
      cloudflareAccessClientId: 'shortcut-id',
      cloudflareAccessClientSecret: 'shortcut-secret',
      customRequestHeadersText:
          'CF-Access-Client-Id: raw-id\nCF-Access-Client-Secret: raw-secret\nX-Extra: yes',
    );

    expect(profile.webSocketHeaders, <String, String>{
      'CF-Access-Client-Id': 'shortcut-id',
      'CF-Access-Client-Secret': 'shortcut-secret',
      'X-Extra': 'yes',
    });
  });
}
