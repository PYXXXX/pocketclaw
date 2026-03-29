import 'package:flutter/widgets.dart';
import 'package:gateway_adapter/gateway_adapter.dart';

import 'reply_notification_payload.dart';

final class ReplyNotificationSummary {
  const ReplyNotificationSummary({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final ReplyNotificationPayload payload;
}

bool shouldNotifyForReply({
  required ChatStreamEvent event,
  required AppLifecycleState? appLifecycleState,
  required bool notificationsEnabled,
  required Set<String> mutedSessionKeys,
}) {
  if (!notificationsEnabled ||
      mutedSessionKeys.contains(event.sessionKey) ||
      appLifecycleState == null ||
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
  required String sessionKey,
  required String sessionTitle,
  required String agentName,
  required String replyText,
  required bool includeReplyBody,
  required String hiddenBodyText,
  String? runId,
}) {
  final effectiveSessionTitle = sessionTitle.trim();
  final effectiveAgentName = agentName.trim().isEmpty
      ? 'Assistant'
      : agentName.trim();
  final title = switch ((
    effectiveSessionTitle.isNotEmpty,
    effectiveAgentName.isNotEmpty,
  )) {
    (true, true) => '$effectiveSessionTitle · $effectiveAgentName',
    (true, false) => effectiveSessionTitle,
    (false, true) => effectiveAgentName,
    (false, false) => 'PocketClaw',
  };
  final normalizedReplyBody = normalizeReplyNotificationBody(replyText);
  final body = includeReplyBody ? normalizedReplyBody : hiddenBodyText.trim();
  return ReplyNotificationSummary(
    id: Object.hash(title, runId ?? body) & 0x7fffffff,
    title: title,
    body: body,
    payload: ReplyNotificationPayload(
      sessionKey: sessionKey,
      sessionTitle: effectiveSessionTitle,
    ),
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
