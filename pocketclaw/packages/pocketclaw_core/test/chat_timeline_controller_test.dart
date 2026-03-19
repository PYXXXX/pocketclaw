import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChatTimelineController', () {
    test('merges assistant deltas into a single streaming item', () {
      final controller = ChatTimelineController();

      controller.applyChatStreamEvent(
        ChatStreamEvent(
          sessionKey: 'agent:main:pc-home',
          state: ChatStreamState.delta,
          runId: 'run-1',
          message: ChatMessage(
            role: ChatMessageRole.assistant,
            text: 'Hel',
          ),
        ),
      );
      controller.applyChatStreamEvent(
        ChatStreamEvent(
          sessionKey: 'agent:main:pc-home',
          state: ChatStreamState.delta,
          runId: 'run-1',
          message: ChatMessage(
            role: ChatMessageRole.assistant,
            text: 'lo',
          ),
        ),
      );
      controller.applyChatStreamEvent(
        ChatStreamEvent(
          sessionKey: 'agent:main:pc-home',
          state: ChatStreamState.finalMessage,
          runId: 'run-1',
          message: ChatMessage(
            role: ChatMessageRole.assistant,
            text: 'Hello',
          ),
        ),
      );

      expect(controller.items, hasLength(1));
      expect(controller.items.single.role, ChatTimelineRole.assistant);
      expect(controller.items.single.text, 'Hello');
      expect(controller.items.single.isStreaming, isFalse);
    });

    test('upserts tool lifecycle events when callId is available', () {
      final controller = ChatTimelineController();
      final started = AgentRuntimeEvent.tryParse(
        const GatewayEvent(
          event: 'agent',
          payload: <String, Object?>{
            'runId': 'run-1',
            'seq': 1,
            'stream': 'tool.lifecycle',
            'ts': 1710000000000,
            'data': <String, Object?>{
              'callId': 'call-1',
              'toolName': 'write',
              'status': 'running',
              'summary': 'Writing file',
            },
          },
        ),
      );
      final finished = AgentRuntimeEvent.tryParse(
        const GatewayEvent(
          event: 'agent',
          payload: <String, Object?>{
            'runId': 'run-1',
            'seq': 2,
            'stream': 'tool.lifecycle',
            'ts': 1710000001000,
            'data': <String, Object?>{
              'callId': 'call-1',
              'toolName': 'write',
              'status': 'completed',
              'summary': 'Wrote README.md',
              'result': 'ok',
            },
          },
        ),
      );

      controller.applyRuntimeEvent(started!);
      controller.applyRuntimeEvent(finished!);

      expect(controller.items, hasLength(1));
      expect(controller.items.single.role, ChatTimelineRole.tool);
      expect(controller.items.single.title, 'Tool · write');
      expect(controller.items.single.status, 'completed');
      expect(controller.items.single.text, 'Wrote README.md');
      expect(controller.items.single.details, contains('result'));
    });
  });
}
