final class GatewayProfile {
  const GatewayProfile({
    this.url = '',
    this.token = '',
    this.password = '',
    this.defaultAgentId = 'main',
    this.defaultSessionKey = 'agent:main:pc-home',
  });

  factory GatewayProfile.fromJson(Map<String, Object?> json) {
    return GatewayProfile(
      url: json['url'] as String? ?? '',
      token: json['token'] as String? ?? '',
      password: json['password'] as String? ?? '',
      defaultAgentId: json['defaultAgentId'] as String? ?? 'main',
      defaultSessionKey:
          json['defaultSessionKey'] as String? ?? 'agent:main:pc-home',
    );
  }

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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'url': url,
      'token': token,
      'password': password,
      'defaultAgentId': defaultAgentId,
      'defaultSessionKey': defaultSessionKey,
    };
  }
}
