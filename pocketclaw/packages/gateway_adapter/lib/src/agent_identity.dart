final class AgentIdentity {
  const AgentIdentity({
    required this.name,
    this.agentId,
    this.avatar,
  });

  final String name;
  final String? agentId;
  final String? avatar;

  factory AgentIdentity.fromJson(Map<String, Object?> json) {
    return AgentIdentity(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Assistant',
      agentId: json['agentId'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}
