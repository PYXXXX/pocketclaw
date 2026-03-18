final class GatewayDeviceIdentity {
  const GatewayDeviceIdentity({
    required this.deviceId,
    required this.publicKey,
    required this.privateKey,
  });

  final String deviceId;
  final String publicKey;
  final String privateKey;
}
