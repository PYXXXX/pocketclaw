import 'gateway_device_identity.dart';

abstract interface class GatewayDeviceIdentityStore {
  Future<GatewayDeviceIdentity?> read();

  Future<void> write(GatewayDeviceIdentity identity);
}

final class MemoryGatewayDeviceIdentityStore
    implements GatewayDeviceIdentityStore {
  GatewayDeviceIdentity? _identity;

  @override
  Future<GatewayDeviceIdentity?> read() async => _identity;

  @override
  Future<void> write(GatewayDeviceIdentity identity) async {
    _identity = identity;
  }
}
