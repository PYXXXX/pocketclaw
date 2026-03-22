import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/app_shell/gateway_url_input.dart';

void main() {
  group('effectiveGatewayUrlInput', () {
    test('prefers the draft url when the field is populated', () {
      expect(
        effectiveGatewayUrlInput(
          draftUrl: 'wss://bot.bilirec.com/',
          savedUrl: 'wss://saved.example.com/',
        ),
        'wss://bot.bilirec.com/',
      );
    });

    test('falls back to the saved url when the field draft is empty', () {
      expect(
        effectiveGatewayUrlInput(
          draftUrl: '   ',
          savedUrl: 'wss://bot.bilirec.com/',
        ),
        'wss://bot.bilirec.com/',
      );
    });
  });
}
