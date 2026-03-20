final class GatewayProfile {
  const GatewayProfile({
    this.url = '',
    this.token = '',
    this.password = '',
    this.cloudflareAccessClientId = '',
    this.cloudflareAccessClientSecret = '',
    this.defaultAgentId = 'main',
    this.defaultSessionKey = 'agent:main:pc-home',
  });

  factory GatewayProfile.fromJson(Map<String, Object?> json) {
    return GatewayProfile(
      url: json['url'] as String? ?? '',
      token: json['token'] as String? ?? '',
      password: json['password'] as String? ?? '',
      cloudflareAccessClientId:
          json['cloudflareAccessClientId'] as String? ?? '',
      cloudflareAccessClientSecret:
          json['cloudflareAccessClientSecret'] as String? ?? '',
      defaultAgentId: json['defaultAgentId'] as String? ?? 'main',
      defaultSessionKey:
          json['defaultSessionKey'] as String? ?? 'agent:main:pc-home',
    );
  }

  final String url;
  final String token;
  final String password;
  final String cloudflareAccessClientId;
  final String cloudflareAccessClientSecret;
  final String defaultAgentId;
  final String defaultSessionKey;

  Map<String, String> get webSocketHeaders {
    final headers = <String, String>{};
    if (cloudflareAccessClientId.trim().isNotEmpty) {
      headers['CF-Access-Client-Id'] = cloudflareAccessClientId.trim();
    }
    if (cloudflareAccessClientSecret.trim().isNotEmpty) {
      headers['CF-Access-Client-Secret'] =
          cloudflareAccessClientSecret.trim();
    }
    return headers;
  }

  GatewayProfile copyWith({
    String? url,
    String? token,
    String? password,
    String? cloudflareAccessClientId,
    String? cloudflareAccessClientSecret,
    String? defaultAgentId,
    String? defaultSessionKey,
  }) {
    return GatewayProfile(
      url: url ?? this.url,
      token: token ?? this.token,
      password: password ?? this.password,
      cloudflareAccessClientId:
          cloudflareAccessClientId ?? this.cloudflareAccessClientId,
      cloudflareAccessClientSecret:
          cloudflareAccessClientSecret ?? this.cloudflareAccessClientSecret,
      defaultAgentId: defaultAgentId ?? this.defaultAgentId,
      defaultSessionKey: defaultSessionKey ?? this.defaultSessionKey,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'url': url,
      'token': token,
      'password': password,
      'cloudflareAccessClientId': cloudflareAccessClientId,
      'cloudflareAccessClientSecret': cloudflareAccessClientSecret,
      'defaultAgentId': defaultAgentId,
      'defaultSessionKey': defaultSessionKey,
    };
  }
}
