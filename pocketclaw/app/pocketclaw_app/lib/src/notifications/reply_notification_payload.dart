import 'dart:convert';

final class ReplyNotificationPayload {
  const ReplyNotificationPayload({
    required this.sessionKey,
    required this.sessionTitle,
  });

  final String sessionKey;
  final String sessionTitle;

  String toJsonString() {
    return jsonEncode(<String, Object?>{
      'sessionKey': sessionKey,
      'sessionTitle': sessionTitle,
    });
  }

  static ReplyNotificationPayload? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final map = Map<String, Object?>.from(decoded);
      final sessionKey = map['sessionKey'] as String?;
      if (sessionKey == null || sessionKey.trim().isEmpty) {
        return null;
      }
      return ReplyNotificationPayload(
        sessionKey: sessionKey,
        sessionTitle: (map['sessionTitle'] as String? ?? '').trim(),
      );
    } catch (_) {
      return null;
    }
  }
}
