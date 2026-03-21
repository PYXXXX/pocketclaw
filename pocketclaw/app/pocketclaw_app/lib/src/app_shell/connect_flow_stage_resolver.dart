import 'package:gateway_adapter/gateway_adapter.dart';

import 'connect_flow_models.dart';

ConnectFlowStage resolveConnectFlowStageForError(Object error) {
  if (error is GatewayRequestError) {
    final code = error.detailsCode ?? error.code;
    switch (code) {
      case GatewayErrorCodes.pairingRequired:
        return ConnectFlowStage.pairingPending;
      case GatewayErrorCodes.authRequired:
      case GatewayErrorCodes.authUnauthorized:
      case GatewayErrorCodes.authTokenMissing:
      case GatewayErrorCodes.authTokenMismatch:
      case GatewayErrorCodes.authTokenNotConfigured:
      case GatewayErrorCodes.authPasswordMissing:
      case GatewayErrorCodes.authPasswordMismatch:
      case GatewayErrorCodes.authPasswordNotConfigured:
      case GatewayErrorCodes.authBootstrapTokenInvalid:
      case GatewayErrorCodes.authDeviceTokenMismatch:
      case GatewayErrorCodes.authRateLimited:
      case GatewayErrorCodes.controlUiDeviceIdentityRequired:
      case GatewayErrorCodes.deviceIdentityRequired:
        return ConnectFlowStage.authRequired;
      default:
        return ConnectFlowStage.error;
    }
  }

  return ConnectFlowStage.error;
}
