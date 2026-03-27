import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/app_shell/chat_timeline_focus.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

void main() {
  test('indexForLatestAssistantActivity prefers the newest assistant item', () {
    final timeline = <ChatTimelineItem>[
      ChatTimelineItem(
        role: ChatTimelineRole.system,
        text: 'boot',
        createdAt: DateTime.utc(2026),
      ),
      ChatTimelineItem(
        role: ChatTimelineRole.assistant,
        text: 'first',
        createdAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
      ),
      ChatTimelineItem(
        role: ChatTimelineRole.user,
        text: 'next',
        createdAt: DateTime.utc(2026, 1, 1, 0, 0, 2),
      ),
      ChatTimelineItem(
        role: ChatTimelineRole.assistant,
        text: 'latest',
        createdAt: DateTime.utc(2026, 1, 1, 0, 0, 3),
      ),
    ];

    expect(indexForLatestAssistantActivity(timeline), 3);
  });

  test('indexForLatestAssistantActivity falls back to the last item', () {
    final timeline = <ChatTimelineItem>[
      ChatTimelineItem(
        role: ChatTimelineRole.system,
        text: 'boot',
        createdAt: DateTime.utc(2026),
      ),
      ChatTimelineItem(
        role: ChatTimelineRole.user,
        text: 'hello',
        createdAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
      ),
    ];

    expect(indexForLatestAssistantActivity(timeline), 1);
  });

  test('indexForLatestAssistantActivity returns -1 for an empty timeline', () {
    expect(indexForLatestAssistantActivity(const <ChatTimelineItem>[]), -1);
  });
}
