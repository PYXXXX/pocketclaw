import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayChatService', () {
    test('loads fake history', () async {
      final service = GatewayChatService(FakeGatewayClient());
      final history = await service.loadHistory(sessionKey: 'agent:main:pc-home');

      expect(history.messages, isNotEmpty);
      expect(history.messages.first.role, ChatMessageRole.assistant);
    });
  });
}
