class SessionKey {
  const SessionKey._(this.value);

  final String value;

  static SessionKey forClient({
    required String agentId,
    required String clientKey,
  }) {
    return SessionKey._('agent:$agentId:$clientKey');
  }

  static SessionKey value(String value) {
    return SessionKey._(value);
  }
}

final class SessionKeyFactory {
  const SessionKeyFactory();

  SessionKey createTimestamped({
    required String agentId,
    String prefix = 'pc',
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now().toUtc())
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('.', '')
        .toLowerCase();

    return SessionKey.forClient(
      agentId: agentId,
      clientKey: '$prefix-$timestamp',
    );
  }
}
