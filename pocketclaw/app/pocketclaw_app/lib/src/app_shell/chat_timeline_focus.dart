import 'package:pocketclaw_core/pocketclaw_core.dart';

int indexForLatestAssistantActivity(List<ChatTimelineItem> timeline) {
  for (var index = timeline.length - 1; index >= 0; index -= 1) {
    if (timeline[index].role == ChatTimelineRole.assistant) {
      return index;
    }
  }
  return timeline.isEmpty ? -1 : timeline.length - 1;
}
