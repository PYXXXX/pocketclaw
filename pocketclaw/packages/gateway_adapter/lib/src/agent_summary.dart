final class AgentSummary {
  const AgentSummary({
    required this.id,
    this.name,
    this.identityName,
    this.emoji,
    this.avatar,
    this.avatarUrl,
  });

  factory AgentSummary.fromJson(Map<String, Object?> json) {
    final identity = json['identity'];
    final identityMap =
        identity is Map<String, Object?> ? identity : const <String, Object?>{};

    return AgentSummary(
      id: json['id'] as String? ?? 'main',
      name: json['name'] as String?,
      identityName: identityMap['name'] as String?,
      emoji: identityMap['emoji'] as String?,
      avatar: identityMap['avatar'] as String?,
      avatarUrl: identityMap['avatarUrl'] as String?,
    );
  }

  final String id;
  final String? name;
  final String? identityName;
  final String? emoji;
  final String? avatar;
  final String? avatarUrl;

  String get displayName => identityName ?? name ?? id;
}

final class AgentsListResult {
  const AgentsListResult({
    required this.defaultId,
    required this.mainKey,
    required this.scope,
    required this.agents,
  });

  final String defaultId;
  final String mainKey;
  final String scope;
  final List<AgentSummary> agents;
}
