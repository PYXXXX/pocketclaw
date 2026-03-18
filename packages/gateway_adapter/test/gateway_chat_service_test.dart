import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:test/test.dart';

import '_test_gateway_client.dart';

void main() {
  group('GatewayChatService', () {
    test('loads chat history', () async {
      final client = TestGatewayClient(
        onRequest: (request) async {
          expect(request.method, GatewayMethodNames.chatHistory);
          return GatewayResponse(
            id: request.id,
            ok: true,
            payload: <String, Object?>{
              'messages': <Map<String, Object?>>[
                <String, Object?>{
                  'role': 'assistant',
                  'content': <Map<String, Object?>>[
                    <String, Object?>{'type': 'text', 'text': 'hello'},
                  ],
                },
              ],
              'thinkingLevel': 'off',
            },
          );
        },
      );

      final service = GatewayChatService(client);
      final history = await service.loadHistory(sessionKey: 'agent:main:pc-home');

      expect(history.messages, hasLength(1));
      expect(history.messages.first.text, 'hello');
      expect(history.messages.first.role, ChatMessageRole.assistant);
    });
  });
}
