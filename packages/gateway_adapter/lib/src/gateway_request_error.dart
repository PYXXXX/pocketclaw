final class GatewayRequestError implements Exception {
  const GatewayRequestError({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Map<String, Object?>? details;

  String? get detailsCode {
    final value = details?['code'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  bool? get canRetryWithDeviceToken {
    final value = details?['canRetryWithDeviceToken'];
    return value is bool ? value : null;
  }

  String? get recommendedNextStep {
    final value = details?['recommendedNextStep'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  factory GatewayRequestError.fromPayload(Map<String, Object?> payload) {
    final rawDetails = payload['details'];
    return GatewayRequestError(
      code: payload['code'] as String? ?? 'UNAVAILABLE',
      message: payload['message'] as String? ?? 'request failed',
      details: rawDetails is Map<String, Object?> ? rawDetails : null,
    );
  }

  @override
  String toString() => 'GatewayRequestError($code): $message';
}
