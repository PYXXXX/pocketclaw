import 'package:gateway_transport/gateway_transport.dart';

abstract interface class GatewayDeviceAuthProvider {
  Future<Map<String, Object?>> buildDeviceAuth({
    required ConnectChallenge challenge,
    required ConnectRequest connectRequest,
  });
}
