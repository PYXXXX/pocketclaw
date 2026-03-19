import 'gateway_message.dart';

final class GatewayEvent extends GatewayMessage {
  const GatewayEvent({
    required this.event,
    required this.payload,
    this.seq,
  });

  final String event;
  final Map<String, Object?> payload;
  final int? seq;
}
