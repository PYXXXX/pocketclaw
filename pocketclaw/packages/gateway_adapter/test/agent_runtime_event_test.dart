import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:test/test.dart';

void main() {
  group('AgentRuntimeEvent', () {
    test('parses tool event payloads from gateway events', () {
      final event = GatewayEvent(
        event: 'agent',
        payload: const <String, Object?>{
          'runId': 'run-1',
          'seq': 7,
          'stream': 'tool.lifecycle',
          'ts': 1710000000000,
          'data': <String, Object?>{
            'callId': 'call-1',
            'toolName': 'web_fetch',
            'status': 'running',
            'summary': 'Fetching docs',
            'arguments': '{"url":"https://docs.openclaw.ai"}',
          },
        },
      );

      final parsed = AgentRuntimeEvent.tryParse(event);

      expect(parsed, isNotNull);
      expect(parsed!.kind, AgentRuntimeEventKind.tool);
      expect(parsed.toolName, 'web_fetch');
      expect(parsed.callId, 'call-1');
      expect(parsed.timelineKey, 'tool:run-1:call-1');
      expect(parsed.status, 'running');
      expect(parsed.summary, 'Fetching docs');
      expect(parsed.details, contains('arguments'));
    });

    test('returns null for unrelated gateway events', () {
      const event = GatewayEvent(
        event: 'tick',
        payload: <String, Object?>{'ts': 1710000000000},
      );

      expect(AgentRuntimeEvent.tryParse(event), isNull);
    });
  });
}
