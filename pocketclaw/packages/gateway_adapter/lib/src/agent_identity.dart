final class AgentIdentity {
  const AgentIdentity({required this.name, this.agentId, this.avatar});

  final String name;
  final String? agentId;
  final String? avatar;

  factory AgentIdentity.fromJson(Map<String, Object?> json) {
    final rawName = (json['name'] as String?)?.trim();
    return AgentIdentity(
      name: rawName != null && rawName.isNotEmpty ? rawName : 'Assistant',
      agentId: json['agentId'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}
