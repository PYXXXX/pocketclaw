import 'session_key.dart';

final class LocalSessionEntry {
  const LocalSessionEntry({
    required this.sessionKey,
    required this.title,
  });

  factory LocalSessionEntry.fromJson(Map<String, Object?> json) {
    return LocalSessionEntry(
      sessionKey: SessionKey.value(json['sessionKey'] as String),
      title: json['title'] as String? ?? 'Untitled',
    );
  }

  final SessionKey sessionKey;
  final String title;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sessionKey': sessionKey.value,
      'title': title,
    };
  }
}

class LocalSessionRegistry {
  LocalSessionRegistry({List<LocalSessionEntry> initialSessions = const <LocalSessionEntry>[]})
      : _sessions = List<LocalSessionEntry>.from(initialSessions);

  factory LocalSessionRegistry.fromJsonList(List<Object?> values) {
    return LocalSessionRegistry(
      initialSessions: values
          .whereType<Map<Object?, Object?>>()
          .map(
            (value) => LocalSessionEntry.fromJson(
              Map<String, Object?>.from(value),
            ),
          )
          .toList(),
    );
  }

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

  void replace(LocalSessionEntry entry) {
    for (var index = 0; index < _sessions.length; index += 1) {
      if (_sessions[index].sessionKey.value == entry.sessionKey.value) {
        _sessions[index] = entry;
        return;
      }
    }
    _sessions.add(entry);
  }

  List<Map<String, Object?>> toJsonList() {
    return _sessions.map((entry) => entry.toJson()).toList();
  }
}
_sessions.add(entry);
  }

  List<Map<String, Object?>> toJsonList() {
    return _sessions.map((entry) => entry.toJson()).toList();
  }
}
