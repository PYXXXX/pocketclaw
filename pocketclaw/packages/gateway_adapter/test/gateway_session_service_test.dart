import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:test/test.dart';

import '_test_gateway_client.dart';

void main() {
  group('GatewaySessionService', () {
    test('lists sessions with defaults', () async {
      final service = GatewaySessionService(
        TestGatewayClient(
          onRequest: (request) async {
            expect(request.method, GatewayMethodNames.sessionsList);
            return GatewayResponse(
              id: request.id,
              ok: true,
              payload: const <String, Object?>{
                'sessions': <Map<String, Object?>>[
                  <String, Object?>{
                    'key': 'agent:main:pc-home',
                    'model': 'codex-lb-responses/gpt-5.4',
                  },
                ],
                'defaults': <String, Object?>{
                  'model': 'codex-lb-responses/gpt-5.4',
                  'thinkingLevel': 'medium',
                  'fastMode': false,
                  'verboseLevel': 'low',
                },
              },
            );
          },
        ),
      );

      final result = await service.list();
      expect(result.sessions, hasLength(1));
      expect(result.defaults?.model, 'codex-lb-responses/gpt-5.4');
      expect(result.defaults?.thinkingLevel, 'medium');
      expect(result.defaults?.fastMode, isFalse);
      expect(result.defaults?.verboseLevel, 'low');
    });

    test('patches session state', () async {
      final service = GatewaySessionService(
        TestGatewayClient(
          onRequest: (request) async {
            expect(request.method, GatewayMethodNames.sessionsPatch);
            expect(request.params?['label'], 'Pocket main');
            expect(request.params?['model'], 'codex-lb/gpt-5.4');
            expect(request.params?['fastMode'], true);
            return GatewayResponse(
              id: request.id,
              ok: true,
              payload: const <String, Object?>{},
            );
          },
        ),
      );

      final response = await service.patch(const SessionPatchParams(
        key: 'agent:main:pc-home',
        label: 'Pocket main',
        model: 'codex-lb/gpt-5.4',
        fastMode: true,
      ));

      expect(response.ok, isTrue);
    });

    test('patch can clear explicit overrides with null payloads', () async {
      final service = GatewaySessionService(
        TestGatewayClient(
          onRequest: (request) async {
            expect(request.method, GatewayMethodNames.sessionsPatch);
            expect(request.params, containsPair('model', isNull));
            expect(request.params, containsPair('thinkingLevel', isNull));
            expect(request.params, containsPair('verboseLevel', isNull));
            return GatewayResponse(
              id: request.id,
              ok: true,
              payload: const <String, Object?>{},
            );
          },
        ),
      );

      final response = await service.patch(const SessionPatchParams(
        key: 'agent:main:pc-home',
        clearModel: true,
        clearThinkingLevel: true,
        clearVerboseLevel: true,
      ));

      expect(response.ok, isTrue);
    });
  });
}
