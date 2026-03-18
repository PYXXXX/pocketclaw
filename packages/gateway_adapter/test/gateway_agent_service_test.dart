import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayAgentService', () {
    test('loads fake identity and models', () async {
      final service = GatewayAgentService(FakeGatewayClient());

      final identity = await service.getIdentity(sessionKey: 'agent:main:pc-home');
      final models = await service.listModels();

      expect(identity.name, 'Qingzhou Bot');
      expect(models, isNotEmpty);
      expect(models.first.id, 'codex-lb-responses/gpt-5.4');
    });
  });
}
