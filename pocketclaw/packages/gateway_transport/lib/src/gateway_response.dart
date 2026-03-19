final class GatewayResponse extends GatewayMessage {
  const GatewayResponse({
    required this.id,
    required this.ok,
    this.payload,
    this.error,
  });

  final String id;
  final bool ok;
  final Map<String, Object?>? payload;
  final Map<String, Object?>? error;
}
