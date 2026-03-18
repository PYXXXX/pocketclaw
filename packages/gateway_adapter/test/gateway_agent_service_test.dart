import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:test/test.dart';

import '_test_gateway_client.dart';

void main() {
  group('GatewayAgentService', () {
    test('loads identity and models', () async {
      final service = GatewayAgentService(
        TestGatewayClient(
          onRequest: (request) async {
            if (request.method == GatewayMethodNames.agentIdentityGet) {
              return GatewayResponse(
                id: request.id,
                ok: true,
                payload: const <String, Object?>{
                  'agentId': 'main',
                  'name': 'Qingzhou Bot',
                },
              );
            }
            if (request.method == GatewayMethodNames.modelsList) {
              return GatewayResponse(
                id: request.id,
                ok: true,
                payload: const <String, Object?>{
                  'models': <Map<String, Object?>>[
                    <String, Object?>{
                      'id': 'codex-lb-responses/gpt-5.4',
                      'provider': 'codex-lb-responses',
                    },
                  ],
                },
              );
            }
            throw StateError('Unexpected method: ${request.method}');
          },
        ),
      );

      final identity = await service.getIdentity(sessionKey: 'agent:main:pc-home');
      final models = await service.listModels();

      expect(identity.name, 'Qingzhou Bot');
      expect(models, hasLength(1));
      expect(models.first.id, 'codex-lb-responses/gpt-5.4');
    });
  });
}
