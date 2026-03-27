import 'package:flutter/widgets.dart';
import 'package:gateway_adapter/gateway_adapter.dart';

final class ReplyNotificationSummary {
  const ReplyNotificationSummary({
    required this.id,
    required this.title,
    required this.body,
  });

  final int id;
  final String title;
  final String body;
}

bool shouldNotifyForReply({
  required ChatStreamEvent event,
  required AppLifecycleState? appLifecycleState,
}) {
  if (appLifecycleState == null ||
      appLifecycleState == AppLifecycleState.resumed) {
    return false;
  }
  final message = event.message;
  if (event.state != ChatStreamState.finalMessage || message == null) {
    return false;
  }
  if (message.role != ChatMessageRole.assistant) {
    return false;
  }
  return normalizeReplyNotificationBody(message.text).isNotEmpty;
}

ReplyNotificationSummary buildReplyNotificationSummary({
  required String sessionTitle,
  required String agentName,
  required String replyText,
  String? runId,
}) {
  final effectiveSessionTitle = sessionTitle.trim();
  final effectiveAgentName =
      agentName.trim().isEmpty ? 'Assistant' : agentName.trim();
  final title = switch ((
    effectiveSessionTitle.isNotEmpty,
    effectiveAgentName.isNotEmpty
  )) {
    (true, true) => '$effectiveSessionTitle · $effectiveAgentName',
    (true, false) => effectiveSessionTitle,
    (false, true) => effectiveAgentName,
    (false, false) => 'PocketClaw',
  };
  final body = normalizeReplyNotificationBody(replyText);
  return ReplyNotificationSummary(
    id: Object.hash(title, runId ?? body) & 0x7fffffff,
    title: title,
    body: body,
  );
}

String normalizeReplyNotificationBody(String text) {
  return text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n')
      .trim();
}
