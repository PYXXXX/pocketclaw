enum ChatTimelineRole {
  system,
  user,
  assistant,
  tool,
}

final class ChatTimelineItem {
  const ChatTimelineItem({
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final ChatTimelineRole role;
  final String text;
  final DateTime createdAt;
}
