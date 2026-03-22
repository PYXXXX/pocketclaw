import 'package:gateway_transport/gateway_transport.dart';

bool canAttemptGatewayConnect({
  required GatewayConnectionPhase phase,
  required bool isBootstrapping,
  required bool isApplyingConfiguration,
  required bool isRefreshingClient,
}) {
  if (isBootstrapping || isApplyingConfiguration || isRefreshingClient) {
    return false;
  }
  return phase == GatewayConnectionPhase.disconnected ||
      phase == GatewayConnectionPhase.error;
}
