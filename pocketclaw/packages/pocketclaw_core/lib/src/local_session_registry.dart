import 'session_key.dart';

enum LocalSessionOrigin { local, gateway }

final class LocalSessionEntry {
  const LocalSessionEntry({
    required this.sessionKey,
    required this.title,
    this.draftText = '',
    this.origin = LocalSessionOrigin.local,
    this.gatewayLabel,
  });

  factory LocalSessionEntry.fromJson(Map<String, Object?> json) {
    final originValue = json['origin'] as String?;
    return LocalSessionEntry(
      sessionKey: SessionKey.fromValue(json['sessionKey'] as String),
      title: json['title'] as String? ?? 'Untitled',
      draftText: json['draftText'] as String? ?? '',
      origin: switch (originValue) {
        'gateway' => LocalSessionOrigin.gateway,
        _ => LocalSessionOrigin.local,
      },
      gatewayLabel: json['gatewayLabel'] as String?,
    );
  }

  final SessionKey sessionKey;
  final String title;
  final String draftText;
  final LocalSessionOrigin origin;
  final String? gatewayLabel;

  bool get isGatewayBacked => origin == LocalSessionOrigin.gateway;

  LocalSessionEntry copyWith({
    SessionKey? sessionKey,
    String? title,
    String? draftText,
    LocalSessionOrigin? origin,
    String? gatewayLabel,
    bool clearGatewayLabel = false,
  }) {
    return LocalSessionEntry(
      sessionKey: sessionKey ?? this.sessionKey,
      title: title ?? this.title,
      draftText: draftText ?? this.draftText,
      origin: origin ?? this.origin,
      gatewayLabel:
          clearGatewayLabel ? null : (gatewayLabel ?? this.gatewayLabel),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sessionKey': sessionKey.value,
      'title': title,
      'draftText': draftText,
      'origin': origin.name,
      if (gatewayLabel != null) 'gatewayLabel': gatewayLabel,
    };
  }
}

class LocalSessionRegistry {
  LocalSessionRegistry({
    List<LocalSessionEntry> initialSessions = const <LocalSessionEntry>[],
  }) : _sessions = List<LocalSessionEntry>.from(initialSessions);

  factory LocalSessionRegistry.fromJsonList(List<Object?> values) {
    return LocalSessionRegistry(
      initialSessions: values
          .whereType<Map<Object?, Object?>>()
          .map(
            (value) =>
                LocalSessionEntry.fromJson(Map<String, Object?>.from(value)),
          )
          .toList(),
    );
  }

  final List<LocalSessionEntry> _sessions;

  List<LocalSessionEntry> get sessions =>
      List<LocalSessionEntry>.unmodifiable(_sessions);

  LocalSessionEntry? findBySessionKey(String sessionKey) {
    for (final session in _sessions) {
      if (session.sessionKey.value == sessionKey) {
        return session;
      }
    }
    return null;
  }

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
    if (_sessions.any(
      (item) => item.sessionKey.value == entry.sessionKey.value,
    )) {
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

  bool removeBySessionKey(String sessionKey) {
    for (var index = 0; index < _sessions.length; index += 1) {
      if (_sessions[index].sessionKey.value == sessionKey) {
        _sessions.removeAt(index);
        return true;
      }
    }
    return false;
  }

  List<Map<String, Object?>> toJsonList() {
    return _sessions.map((entry) => entry.toJson()).toList();
  }
}
