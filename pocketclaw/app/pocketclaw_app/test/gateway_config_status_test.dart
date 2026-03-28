import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/app_shell/gateway_config_status.dart';
import 'package:pocketclaw_app/src/app_shell/gateway_profile_draft.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

void main() {
  group('summarizeGatewayConfigStatus', () {
    test('reports the saved-url fallback when the draft field is empty', () {
      const savedProfile = GatewayProfile(url: 'wss://saved.example.com/');
      final draftProfile = draftGatewayProfile(
        savedProfile: savedProfile,
        draftUrl: '   ',
        token: '',
        password: '',
        cloudflareAccessClientId: '',
        cloudflareAccessClientSecret: '',
        customRequestHeadersText: '',
      );

      final status = summarizeGatewayConfigStatus(
        savedProfile: savedProfile,
        draftProfile: draftProfile,
        draftUrl: '   ',
      );

      expect(status.effectiveUrl, 'wss://saved.example.com/');
      expect(status.isUsingSavedUrlFallback, isTrue);
      expect(status.hasUnsavedChanges, isFalse);
    });

    test(
      'marks typed credential changes as unsaved even with saved-url fallback',
      () {
        const savedProfile = GatewayProfile(
          url: 'wss://saved.example.com/',
          token: 'saved-token',
        );
        final draftProfile = draftGatewayProfile(
          savedProfile: savedProfile,
          draftUrl: '',
          token: 'next-token',
          password: '',
          cloudflareAccessClientId: '',
          cloudflareAccessClientSecret: '',
          customRequestHeadersText: '',
        );

        final status = summarizeGatewayConfigStatus(
          savedProfile: savedProfile,
          draftProfile: draftProfile,
          draftUrl: '',
        );

        expect(status.isUsingSavedUrlFallback, isTrue);
        expect(status.hasUnsavedChanges, isTrue);
      },
    );

    test('uses the typed url once the user enters a new one', () {
      const savedProfile = GatewayProfile(url: 'wss://saved.example.com/');
      final draftProfile = draftGatewayProfile(
        savedProfile: savedProfile,
        draftUrl: 'https://next.example.com',
        token: '',
        password: '',
        cloudflareAccessClientId: '',
        cloudflareAccessClientSecret: '',
        customRequestHeadersText: '',
      );

      final status = summarizeGatewayConfigStatus(
        savedProfile: savedProfile,
        draftProfile: draftProfile,
        draftUrl: 'https://next.example.com',
      );

      expect(status.effectiveUrl, 'wss://next.example.com');
      expect(status.isUsingSavedUrlFallback, isFalse);
      expect(status.hasUnsavedChanges, isTrue);
    });
  });
}
