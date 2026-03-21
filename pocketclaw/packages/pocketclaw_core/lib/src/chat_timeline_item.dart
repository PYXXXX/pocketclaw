const Object _chatTimelineUnset = Object();

enum ChatTimelineRole { system, user, assistant, tool }

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
    Object? title = _chatTimelineUnset,
    Object? status = _chatTimelineUnset,
    Object? details = _chatTimelineUnset,
    bool? isStreaming,
    Object? updateKey = _chatTimelineUnset,
  }) {
    return ChatTimelineItem(
      role: role ?? this.role,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      title:
          identical(title, _chatTimelineUnset) ? this.title : title as String?,
      status: identical(status, _chatTimelineUnset)
          ? this.status
          : status as String?,
      details: identical(details, _chatTimelineUnset)
          ? this.details
          : details as String?,
      isStreaming: isStreaming ?? this.isStreaming,
      updateKey: identical(updateKey, _chatTimelineUnset)
          ? this.updateKey
          : updateKey as String?,
    );
  }
}
