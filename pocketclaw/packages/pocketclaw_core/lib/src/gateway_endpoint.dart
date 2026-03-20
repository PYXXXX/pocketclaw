bool gatewayUrlUsesLoopback(String rawUrl) {
  final normalized = normalizeGatewayUrl(rawUrl);
  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    return false;
  }

  final host = uri.host.toLowerCase();
  return host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '::1' ||
      host == '0.0.0.0';
}

String normalizeGatewayUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final candidate = _hasExplicitScheme(trimmed)
      ? trimmed
      : '${_defaultSchemeFor(trimmed)}://$trimmed';
  final uri = Uri.tryParse(candidate);
  if (uri == null) {
    return trimmed;
  }

  final normalizedScheme = switch (uri.scheme.toLowerCase()) {
    'http' => 'ws',
    'https' => 'wss',
    'ws' => 'ws',
    'wss' => 'wss',
    _ => uri.scheme,
  };

  return uri.replace(scheme: normalizedScheme).toString();
}

bool _hasExplicitScheme(String value) {
  return RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value);
}

String _defaultSchemeFor(String rawUrl) {
  final host = _extractHost(rawUrl).toLowerCase();
  return _looksLikeLocalAddress(host) ? 'ws' : 'wss';
}

String _extractHost(String rawUrl) {
  final withoutPath = rawUrl.split('/').first;
  if (withoutPath.startsWith('[')) {
    final end = withoutPath.indexOf(']');
    if (end > 0) {
      return withoutPath.substring(1, end);
    }
  }

  final lastColon = withoutPath.lastIndexOf(':');
  if (lastColon <= 0) {
    return withoutPath;
  }

  final hostCandidate = withoutPath.substring(0, lastColon);
  if (hostCandidate.contains(':')) {
    return withoutPath;
  }
  return hostCandidate;
}

bool _looksLikeLocalAddress(String host) {
  if (host.isEmpty) {
    return false;
  }
  if (host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '::1' ||
      host == '0.0.0.0') {
    return true;
  }
  if (host.endsWith('.local')) {
    return true;
  }

  final ipv4Match = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').firstMatch(host);
  if (ipv4Match == null) {
    return false;
  }

  final octets = host.split('.').map(int.tryParse).toList();
  if (octets.length != 4 || octets.any((octet) => octet == null)) {
    return false;
  }
  final a = octets[0]!;
  final b = octets[1]!;

  return a == 10 ||
      a == 127 ||
      (a == 192 && b == 168) ||
      (a == 172 && b >= 16 && b <= 31);
}
