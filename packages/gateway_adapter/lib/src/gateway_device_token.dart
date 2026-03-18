final class GatewayDeviceToken {
  const GatewayDeviceToken({
    required this.deviceId,
    required this.role,
    required this.token,
    this.scopes = const <String>[],
  });

  final String deviceId;
  final String role;
  final String token;
  final List<String> scopes;
}
