import 'gateway_device_token.dart';

abstract interface class GatewayDeviceTokenStore {
  Future<GatewayDeviceToken?> read({
    required String deviceId,
    required String role,
  });

  Future<void> write(GatewayDeviceToken token);
}

final class MemoryGatewayDeviceTokenStore implements GatewayDeviceTokenStore {
  final Map<String, GatewayDeviceToken> _tokens = <String, GatewayDeviceToken>{};

  @override
  Future<GatewayDeviceToken?> read({
    required String deviceId,
    required String role,
  }) async {
    return _tokens[_key(deviceId, role)];
  }

  @override
  Future<void> write(GatewayDeviceToken token) async {
    _tokens[_key(token.deviceId, token.role)] = token;
  }

  String _key(String deviceId, String role) => '$deviceId::$role';
}
