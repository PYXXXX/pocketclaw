import 'session_key.dart';

final class LocalSessionEntry {
  const LocalSessionEntry({
    required this.sessionKey,
    required this.title,
  });

  final SessionKey sessionKey;
  final String title;
}

class LocalSessionRegistry {
  LocalSessionRegistry({List<LocalSessionEntry> initialSessions = const <LocalSessionEntry>[]})
      : _sessions = List<LocalSessionEntry>.from(initialSessions);

  final List<LocalSessionEntry> _sessions;

  List<LocalSessionEntry> get sessions =>
      List<LocalSessionEntry>.unmodifiable(_sessions);

  LocalSessionEntry create({
    required String agentId,
    required String clientKey,
    required String title,
  }) {
    final entry = LocalSessionEntry(
      sessionKey: SessionKey.forClient(agentId: agentId, clientKey: clientKey),
      title: title,
    );
    _sessions.add(entry);
    return entry;
  }

  void remember(LocalSessionEntry entry) {
    if (_sessions.any((item) => item.sessionKey.value == entry.sessionKey.value)) {
      return;
    }
    _sessions.add(entry);
  }
}
