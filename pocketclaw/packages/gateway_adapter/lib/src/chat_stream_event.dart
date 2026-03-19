enum ChatStreamState {
  delta,
  finalMessage,
  aborted,
  error,
}

final class ChatStreamEvent {
  const ChatStreamEvent({
    required this.sessionKey,
    required this.state,
    this.runId,
    this.message,
    this.errorMessage,
  });

  final String sessionKey;
  final ChatStreamState state;
  final String? runId;
  final ChatMessage? message;
  final String? errorMessage;

  factory ChatStreamEvent.fromGatewayEvent(Map<String, Object?> payload) {
    final stateRaw = payload['state'] as String? ?? 'error';
    final state = switch (stateRaw) {
      'delta' => ChatStreamState.delta,
      'final' => ChatStreamState.finalMessage,
      'aborted' => ChatStreamState.aborted,
      _ => ChatStreamState.error,
    };

    final sessionKey = payload['sessionKey'] as String? ?? 'unknown';
    final runId = payload['runId'] as String?;
    final errorMessage = payload['errorMessage'] as String?;

    ChatMessage? message;
    final rawMessage = payload['message'];
    if (rawMessage is Map<String, Object?>) {
      message = ChatMessage.fromJson(rawMessage);
    }

    return ChatStreamEvent(
      sessionKey: sessionKey,
      state: state,
      runId: runId,
      message: message,
      errorMessage: errorMessage,
    );
  }
}
