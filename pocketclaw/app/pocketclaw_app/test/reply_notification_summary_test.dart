import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:pocketclaw_app/src/notifications/reply_notification_summary.dart';

void main() {
  group('shouldNotifyForReply', () {
    const assistantFinal = ChatStreamEvent(
      sessionKey: 'agent:main:pc-home',
      state: ChatStreamState.finalMessage,
      message: ChatMessage(
        role: ChatMessageRole.assistant,
        text: 'Hello from OpenClaw',
      ),
    );

    test('does not notify while the app is resumed', () {
      expect(
        shouldNotifyForReply(
          event: assistantFinal,
          appLifecycleState: AppLifecycleState.resumed,
        ),
        isFalse,
      );
    });

    test('notifies for final assistant replies while the app is backgrounded',
        () {
      expect(
        shouldNotifyForReply(
          event: assistantFinal,
          appLifecycleState: AppLifecycleState.paused,
        ),
        isTrue,
      );
    });

    test('ignores non-assistant or empty final events', () {
      expect(
        shouldNotifyForReply(
          event: const ChatStreamEvent(
            sessionKey: 'agent:main:pc-home',
            state: ChatStreamState.finalMessage,
            message: ChatMessage(role: ChatMessageRole.user, text: 'echo'),
          ),
          appLifecycleState: AppLifecycleState.paused,
        ),
        isFalse,
      );
      expect(
        shouldNotifyForReply(
          event: const ChatStreamEvent(
            sessionKey: 'agent:main:pc-home',
            state: ChatStreamState.finalMessage,
            message: ChatMessage(role: ChatMessageRole.assistant, text: ' \n '),
          ),
          appLifecycleState: AppLifecycleState.paused,
        ),
        isFalse,
      );
    });
  });

  group('buildReplyNotificationSummary', () {
    test('uses session and agent names in the title', () {
      final summary = buildReplyNotificationSummary(
        sessionKey: 'agent:main:pc-home',
        sessionTitle: 'Daily Ops',
        agentName: 'Main Agent',
        replyText: 'Done.',
        runId: 'run-1',
      );

      expect(summary.title, 'Daily Ops · Main Agent');
      expect(summary.body, 'Done.');
      expect(summary.id, isNonZero);
      expect(summary.payload.sessionKey, 'agent:main:pc-home');
      expect(summary.payload.sessionTitle, 'Daily Ops');
    });

    test('normalizes multiline reply text for the notification body', () {
      final summary = buildReplyNotificationSummary(
        sessionKey: 'agent:main:pc-home',
        sessionTitle: 'Daily Ops',
        agentName: 'Main Agent',
        replyText: '  Line 1\n\n   Line 2   \n',
      );

      expect(summary.body, 'Line 1\nLine 2');
    });
  });
}
