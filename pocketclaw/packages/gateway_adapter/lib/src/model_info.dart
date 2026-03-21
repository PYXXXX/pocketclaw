final class ModelInfo {
  const ModelInfo({required this.id, this.provider});

  final String id;
  final String? provider;

  factory ModelInfo.fromJson(Map<String, Object?> json) {
    return ModelInfo(
      id: json['id'] as String? ?? 'unknown',
      provider: json['provider'] as String?,
    );
  }
}
