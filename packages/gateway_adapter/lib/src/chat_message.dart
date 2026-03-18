enum ChatMessageRole {
  system,
  user,
  assistant,
}

final class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.timestamp,
  });

  final ChatMessageRole role;
  final String text;
  final DateTime? timestamp;

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    final roleRaw = json['role'];
    final role = switch (roleRaw) {
      'system' => ChatMessageRole.system,
      'assistant' => ChatMessageRole.assistant,
      _ => ChatMessageRole.user,
    };

    String text = '';
    final content = json['content'];
    if (content is List<Object?>) {
      final buffer = <String>[];
      for (final item in content) {
        if (item is Map<String, Object?> && item['type'] == 'text') {
          final value = item['text'];
          if (value is String) {
            buffer.add(value);
          }
        }
      }
      text = buffer.join('\n');
    } else if (json['text'] is String) {
      text = json['text'] as String;
    }

    final timestampRaw = json['timestamp'];
    final timestamp = timestampRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(timestampRaw, isUtc: true)
        : null;

    return ChatMessage(
      role: role,
      text: text,
      timestamp: timestamp,
    );
  }
}

final class ChatHistoryResult {
  const ChatHistoryResult({
    required this.messages,
    this.thinkingLevel,
  });

  final List<ChatMessage> messages;
  final String? thinkingLevel;
}
