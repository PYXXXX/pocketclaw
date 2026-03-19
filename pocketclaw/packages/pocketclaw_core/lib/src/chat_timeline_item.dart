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
    this.isStreaming = false,
    this.updateKey,
  });

  final ChatTimelineRole role;
  final String text;
  final DateTime createdAt;
  final String? title;
  final String? status;
  final String? details;
  final bool isStreaming;
  final String? updateKey;

  ChatTimelineItem copyWith({
    ChatTimelineRole? role,
    String? text,
    DateTime? createdAt,
    String? title,
    String? status,
    String? details,
    bool? isStreaming,
    String? updateKey,
  }) {
    return ChatTimelineItem(
      role: role ?? this.role,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      status: status ?? this.status,
      details: details ?? this.details,
      isStreaming: isStreaming ?? this.isStreaming,
      updateKey: updateKey ?? this.updateKey,
    );
  }
}
