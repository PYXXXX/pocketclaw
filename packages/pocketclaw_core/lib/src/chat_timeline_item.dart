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
    this.title,
    this.status,
    this.details,
  });

  final ChatTimelineRole role;
  final String text;
  final DateTime createdAt;
  final String? title;
  final String? status;
  final String? details;
}
