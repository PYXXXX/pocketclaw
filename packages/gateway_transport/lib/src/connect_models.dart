final class ConnectChallenge {
  const ConnectChallenge({required this.nonce, this.timestampMs});

  final String nonce;
  final int? timestampMs;
}

final class ConnectClientInfo {
  const ConnectClientInfo({
    required this.id,
    required this.version,
    required this.platform,
    required this.mode,
    this.instanceId,
  });

  final String id;
  final String version;
  final String platform;
  final String mode;
  final String? instanceId;
}

final class ConnectRequest {
  const ConnectRequest({
    required this.client,
    required this.role,
    required this.scopes,
    this.auth,
    this.caps = const <String>[],
    this.locale,
    this.userAgent,
  });

  final ConnectClientInfo client;
  final String role;
  final List<String> scopes;
  final Map<String, Object?>? auth;
  final List<String> caps;
  final String? locale;
  final String? userAgent;

  Map<String, Object?> toParams() => <String, Object?>{
        'minProtocol': 3,
        'maxProtocol': 3,
        'client': <String, Object?>{
          'id': client.id,
          'version': client.version,
          'platform': client.platform,
          'mode': client.mode,
          if (client.instanceId != null) 'instanceId': client.instanceId,
        },
        'role': role,
        'scopes': scopes,
        'caps': caps,
        if (auth != null) 'auth': auth,
        if (locale != null) 'locale': locale,
        if (userAgent != null) 'userAgent': userAgent,
      };
}
