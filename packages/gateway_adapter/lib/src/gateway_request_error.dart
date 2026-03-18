final class GatewayRequestError implements Exception {
  const GatewayRequestError({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Map<String, Object?>? details;

  factory GatewayRequestError.fromPayload(Map<String, Object?> payload) {
    return GatewayRequestError(
      code: payload['code'] as String? ?? 'UNAVAILABLE',
      message: payload['message'] as String? ?? 'request failed',
      details: payload['details'] as Map<String, Object?>?,
    );
  }

  @override
  String toString() => 'GatewayRequestError($code): $message';
}
