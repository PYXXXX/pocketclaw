import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('GatewaySessionService', () {
    test('lists fake sessions with defaults', () async {
      final service = GatewaySessionService(FakeGatewayClient());
      final result = await service.list();

      expect(result.sessions, isNotEmpty);
      expect(result.defaults?['model'], 'codex-lb-responses/gpt-5.4');
    });

    test('patches fake session state', () async {
      final client = FakeGatewayClient();
      final service = GatewaySessionService(client);

      await service.patch(const SessionPatchParams(
        key: 'agent:main:pc-home',
        model: 'codex-lb/gpt-5.4',
        fastMode: true,
      ));

      final result = await service.list();
      final session = result.sessions.firstWhere((item) => item.key == 'agent:main:pc-home');

      expect(session.model, 'codex-lb/gpt-5.4');
      expect(session.fastMode, isTrue);
    });
  });
}
