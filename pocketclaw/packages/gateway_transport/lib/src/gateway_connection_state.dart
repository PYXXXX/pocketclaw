enum GatewayConnectionPhase {
  disconnected,
  connecting,
  challengeReceived,
  connected,
  error,
}

final class GatewayConnectionState {
  const GatewayConnectionState({required this.phase, this.message});

  final GatewayConnectionPhase phase;
  final String? message;
}
