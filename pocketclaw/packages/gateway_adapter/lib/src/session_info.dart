final class SessionInfo {
  const SessionInfo({
    required this.key,
    this.label,
    this.model,
    this.thinkingLevel,
    this.fastMode,
    this.verboseLevel,
  });

  final String key;
  final String? label;
  final String? model;
  final String? thinkingLevel;
  final bool? fastMode;
  final String? verboseLevel;

  factory SessionInfo.fromJson(Map<String, Object?> json) {
    return SessionInfo(
      key: json['key'] as String? ?? 'unknown',
      label: json['label'] as String?,
      model: json['model'] as String?,
      thinkingLevel: json['thinkingLevel'] as String?,
      fastMode: json['fastMode'] as bool?,
      verboseLevel: json['verboseLevel'] as String?,
    );
  }
}

final class SessionDefaults {
  const SessionDefaults({
    this.model,
    this.thinkingLevel,
    this.fastMode,
    this.verboseLevel,
  });

  final String? model;
  final String? thinkingLevel;
  final bool? fastMode;
  final String? verboseLevel;

  factory SessionDefaults.fromJson(Map<String, Object?> json) {
    return SessionDefaults(
      model: json['model'] as String?,
      thinkingLevel: json['thinkingLevel'] as String?,
      fastMode: json['fastMode'] as bool?,
      verboseLevel: json['verboseLevel'] as String?,
    );
  }
}

final class SessionsListResult {
  const SessionsListResult({
    required this.sessions,
    this.defaults,
  });

  final List<SessionInfo> sessions;
  final SessionDefaults? defaults;
}
