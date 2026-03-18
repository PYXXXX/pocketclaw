final class GatewayProtocolException implements Exception {
  const GatewayProtocolException(this.message);

  final String message;

  @override
  String toString() => 'GatewayProtocolException: $message';
}
