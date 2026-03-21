Map<String, String> parseGatewayRequestHeadersText(
  String raw, {
  bool strict = false,
}) {
  final headers = <String, String>{};
  final lines = raw.split('\n');

  for (var index = 0; index < lines.length; index += 1) {
    final rawLine = lines[index].replaceAll('\r', '');
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    final separatorIndex = rawLine.indexOf(':');
    if (separatorIndex <= 0) {
      if (strict) {
        throw FormatException(
          'Custom request headers must use "Name: value" on each line. Invalid line ${index + 1}: $rawLine',
        );
      }
      continue;
    }

    final name = rawLine.substring(0, separatorIndex).trim();
    if (name.isEmpty) {
      if (strict) {
        throw FormatException(
          'Custom request headers must use a non-empty header name. Invalid line ${index + 1}: $rawLine',
        );
      }
      continue;
    }

    final value = rawLine.substring(separatorIndex + 1).trim();
    headers[name] = value;
  }

  return headers;
}

final class GatewayProfile {
  const GatewayProfile({
    this.url = '',
    this.token = '',
    this.password = '',
    this.cloudflareAccessClientId = '',
    this.cloudflareAccessClientSecret = '',
    this.customRequestHeadersText = '',
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
      customRequestHeadersText:
          json['customRequestHeadersText'] as String? ?? '',
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
  final String customRequestHeadersText;
  final String defaultAgentId;
  final String defaultSessionKey;

  Map<String, String> get webSocketHeaders {
    final headers = parseGatewayRequestHeadersText(customRequestHeadersText);
    if (cloudflareAccessClientId.trim().isNotEmpty) {
      headers['CF-Access-Client-Id'] = cloudflareAccessClientId.trim();
    }
    if (cloudflareAccessClientSecret.trim().isNotEmpty) {
      headers['CF-Access-Client-Secret'] = cloudflareAccessClientSecret.trim();
    }
    return headers;
  }

  GatewayProfile copyWith({
    String? url,
    String? token,
    String? password,
    String? cloudflareAccessClientId,
    String? cloudflareAccessClientSecret,
    String? customRequestHeadersText,
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
      customRequestHeadersText:
          customRequestHeadersText ?? this.customRequestHeadersText,
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
      'customRequestHeadersText': customRequestHeadersText,
      'defaultAgentId': defaultAgentId,
      'defaultSessionKey': defaultSessionKey,
    };
  }
}
