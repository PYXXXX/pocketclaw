final class GatewayDeviceIdentity {
  const GatewayDeviceIdentity({
    required this.deviceId,
    required this.publicKey,
    required this.privateKey,
  });

  factory GatewayDeviceIdentity.fromJson(Map<String, Object?> json) {
    return GatewayDeviceIdentity(
      deviceId: json['deviceId'] as String,
      publicKey: json['publicKey'] as String,
      privateKey: json['privateKey'] as String,
    );
  }

  final String deviceId;
  final String publicKey;
  final String privateKey;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'deviceId': deviceId,
      'publicKey': publicKey,
      'privateKey': privateKey,
    };
  }
}
