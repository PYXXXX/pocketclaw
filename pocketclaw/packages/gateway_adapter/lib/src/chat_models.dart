final class ChatHistoryParams {
  const ChatHistoryParams({required this.sessionKey, this.limit = 200});

  final String sessionKey;
  final int limit;

  Map<String, Object?> toJson() => <String, Object?>{
        'sessionKey': sessionKey,
        'limit': limit,
      };
}

final class ChatSendParams {
  const ChatSendParams({
    required this.sessionKey,
    required this.message,
    this.deliver = false,
    this.attachments,
    this.idempotencyKey,
  });

  final String sessionKey;
  final String message;
  final bool deliver;
  final List<Object?>? attachments;
  final String? idempotencyKey;

  Map<String, Object?> toJson() => <String, Object?>{
        'sessionKey': sessionKey,
        'message': message,
        'deliver': deliver,
        if (attachments != null && attachments!.isNotEmpty)
          'attachments': attachments,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      };
}

final class ChatAbortParams {
  const ChatAbortParams({required this.sessionKey, this.runId});

  final String sessionKey;
  final String? runId;

  Map<String, Object?> toJson() => <String, Object?>{
        'sessionKey': sessionKey,
        if (runId != null) 'runId': runId,
      };
}
