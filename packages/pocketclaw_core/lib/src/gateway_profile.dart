final class GatewayProfile {
  const GatewayProfile({
    this.url = 'ws://127.0.0.1:18789',
    this.token = '',
    this.password = '',
    this.defaultAgentId = 'main',
    this.defaultSessionKey = 'agent:main:pc-home',
  });

  final String url;
  final String token;
  final String password;
  final String defaultAgentId;
  final String defaultSessionKey;

  GatewayProfile copyWith({
    String? url,
    String? token,
    String? password,
    String? defaultAgentId,
    String? defaultSessionKey,
  }) {
    return GatewayProfile(
      url: url ?? this.url,
      token: token ?? this.token,
      password: password ?? this.password,
      defaultAgentId: defaultAgentId ?? this.defaultAgentId,
      defaultSessionKey: defaultSessionKey ?? this.defaultSessionKey,
    );
  }
}
