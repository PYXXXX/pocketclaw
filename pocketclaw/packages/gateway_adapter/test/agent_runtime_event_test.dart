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
      expect(parsed.details, contains('Arguments'));
      expect(parsed.details, contains('https://docs.openclaw.ai'));
    });

    test('builds useful tool summary from structured arguments and result', () {
      final running = AgentRuntimeEvent.tryParse(
        const GatewayEvent(
          event: 'agent',
          payload: <String, Object?>{
            'runId': 'run-42',
            'seq': 2,
            'stream': 'tool.lifecycle',
            'ts': 1710000000000,
            'data': <String, Object?>{
              'callId': 'call-42',
              'toolName': 'web_search',
              'status': 'running',
              'arguments': <String, Object?>{
                'query': 'openclaw docs',
                'count': 5,
              },
            },
          },
        ),
      );
      final completed = AgentRuntimeEvent.tryParse(
        const GatewayEvent(
          event: 'agent',
          payload: <String, Object?>{
            'runId': 'run-42',
            'seq': 3,
            'stream': 'tool.lifecycle',
            'ts': 1710000001000,
            'data': <String, Object?>{
              'callId': 'call-42',
              'toolName': 'web_search',
              'status': 'completed',
              'result': <String, Object?>{
                'topHit': 'https://docs.openclaw.ai',
                'count': 5,
              },
              'latencyMs': 812,
            },
          },
        ),
      );

      expect(running, isNotNull);
      expect(running!.summary, contains('Calling web_search'));
      expect(running.summary, contains('openclaw docs'));
      expect(running.details, contains('Arguments'));
      expect(running.details, contains('query'));

      expect(completed, isNotNull);
      expect(completed!.summary, contains('Completed web_search'));
      expect(completed.summary, contains('docs.openclaw.ai'));
      expect(completed.details, contains('Result'));
      expect(completed.details, contains('Metadata'));
      expect(completed.details, contains('latencyMs'));
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
