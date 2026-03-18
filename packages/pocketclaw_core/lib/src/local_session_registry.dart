import 'session_key.dart';

class LocalSessionRegistry {
  LocalSessionRegistry({List<SessionKey> initialSessions = const <SessionKey>[]})
      : _sessions = List<SessionKey>.from(initialSessions);

  final List<SessionKey> _sessions;

  List<SessionKey> get sessions => List<SessionKey>.unmodifiable(_sessions);

  SessionKey create({required String agentId, required String clientKey}) {
    final sessionKey = SessionKey.forClient(agentId: agentId, clientKey: clientKey);
    _sessions.add(sessionKey);
    return sessionKey;
  }

  void remember(SessionKey sessionKey) {
    if (_sessions.any((item) => item.value == sessionKey.value)) {
      return;
    }
    _sessions.add(sessionKey);
  }
}
