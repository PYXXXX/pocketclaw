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
      final history = await service.loadHistory(
        sessionKey: 'agent:main:pc-home',
      );

      expect(history.messages, hasLength(1));
      expect(history.messages.first.text, 'hello');
      expect(history.messages.first.role, ChatMessageRole.assistant);
    });

    test(
      'history parsing keeps image placeholders from content array',
      () async {
        final client = TestGatewayClient(
          onRequest: (request) async {
            expect(request.method, GatewayMethodNames.chatHistory);
            return GatewayResponse(
              id: request.id,
              ok: true,
              payload: <String, Object?>{
                'messages': <Map<String, Object?>>[
                  <String, Object?>{
                    'role': 'user',
                    'content': <Map<String, Object?>>[
                      <String, Object?>{'type': 'text', 'text': 'look'},
                      <String, Object?>{
                        'type': 'image',
                        'source': <String, Object?>{'type': 'base64'},
                      },
                    ],
                  },
                ],
              },
            );
          },
        );

        final service = GatewayChatService(client);
        final history = await service.loadHistory(
          sessionKey: 'agent:main:pc-home',
        );

        expect(history.messages, hasLength(1));
        expect(history.messages.first.text, 'look\n[Image]');
        expect(history.messages.first.role, ChatMessageRole.user);
      },
    );

    test('sends chat with optional attachments passthrough', () async {
      final client = TestGatewayClient(
        onRequest: (request) async {
          expect(request.method, GatewayMethodNames.chatSend);
          expect(request.params?['message'], 'see image');
          expect(request.params?['attachments'], isA<List<Object?>>());
          return GatewayResponse(
            id: request.id,
            ok: true,
            payload: const <String, Object?>{'runId': 'run-1'},
          );
        },
      );

      final service = GatewayChatService(client);
      final response = await service.send(
        sessionKey: 'agent:main:pc-home',
        message: 'see image',
        attachments: const <Object?>[
          <String, Object?>{
            'kind': 'image',
            'mimeType': 'image/png',
            'name': 'demo.png',
          },
        ],
      );

      expect(response.ok, isTrue);
      expect(response.payload?['runId'], 'run-1');
    });
  });
}
