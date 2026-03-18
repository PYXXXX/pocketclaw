class SessionKey {
  const SessionKey._(this.value);

  final String value;

  static SessionKey forClient({
    required String agentId,
    required String clientKey,
  }) {
    return SessionKey._('agent:$agentId:$clientKey');
  }
}
