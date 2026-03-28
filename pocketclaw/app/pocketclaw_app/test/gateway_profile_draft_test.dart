import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/app_shell/gateway_profile_draft.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

void main() {
  group('draftGatewayProfile', () {
    test('falls back to the saved url when the draft field is empty', () {
      const savedProfile = GatewayProfile(
        url: 'wss://saved.example.com/',
        token: 'saved-token',
      );

      final draftProfile = draftGatewayProfile(
        savedProfile: savedProfile,
        draftUrl: '   ',
        token: 'next-token',
        password: '',
        cloudflareAccessClientId: ' cf-id ',
        cloudflareAccessClientSecret: ' cf-secret ',
        customRequestHeadersText: 'X-Test: 1',
      );

      expect(draftProfile.url, 'wss://saved.example.com/');
      expect(draftProfile.token, 'next-token');
      expect(draftProfile.cloudflareAccessClientId, 'cf-id');
      expect(draftProfile.cloudflareAccessClientSecret, 'cf-secret');
      expect(draftProfile.customRequestHeadersText, 'X-Test: 1');
    });

    test('normalizes the typed draft url before comparing or saving', () {
      const savedProfile = GatewayProfile(url: 'wss://saved.example.com/');

      final draftProfile = draftGatewayProfile(
        savedProfile: savedProfile,
        draftUrl: 'bot.bilirec.com',
        token: '',
        password: '',
        cloudflareAccessClientId: '',
        cloudflareAccessClientSecret: '',
        customRequestHeadersText: '',
      );

      expect(draftProfile.url, 'wss://bot.bilirec.com');
    });
  });

  group('hasUnsavedGatewayConfiguration', () {
    test(
      'treats an empty draft url as unchanged when saved url still applies',
      () {
        const savedProfile = GatewayProfile(
          url: 'wss://saved.example.com/',
          token: 'saved-token',
        );
        final draftProfile = draftGatewayProfile(
          savedProfile: savedProfile,
          draftUrl: '   ',
          token: 'saved-token',
          password: '',
          cloudflareAccessClientId: '',
          cloudflareAccessClientSecret: '',
          customRequestHeadersText: '',
        );

        expect(
          hasUnsavedGatewayConfiguration(
            savedProfile: savedProfile,
            draftProfile: draftProfile,
          ),
          isFalse,
        );
      },
    );

    test(
      'detects token changes even when the url falls back to saved config',
      () {
        const savedProfile = GatewayProfile(
          url: 'wss://saved.example.com/',
          token: 'saved-token',
        );
        final draftProfile = draftGatewayProfile(
          savedProfile: savedProfile,
          draftUrl: '   ',
          token: 'next-token',
          password: '',
          cloudflareAccessClientId: '',
          cloudflareAccessClientSecret: '',
          customRequestHeadersText: '',
        );

        expect(
          hasUnsavedGatewayConfiguration(
            savedProfile: savedProfile,
            draftProfile: draftProfile,
          ),
          isTrue,
        );
      },
    );
  });
}
