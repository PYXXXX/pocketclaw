final class GatewayDeviceToken {
  const GatewayDeviceToken({
    required this.deviceId,
    required this.role,
    required this.token,
    this.scopes = const <String>[],
  });

  factory GatewayDeviceToken.fromJson(Map<String, Object?> json) {
    final rawScopes = json['scopes'] as List<Object?>?;
    return GatewayDeviceToken(
      deviceId: json['deviceId'] as String,
      role: json['role'] as String,
      token: json['token'] as String,
      scopes: rawScopes?.map((value) => value.toString()).toList() ??
          const <String>[],
    );
  }

  final String deviceId;
  final String role;
  final String token;
  final List<String> scopes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'deviceId': deviceId,
      'role': role,
      'token': token,
      'scopes': scopes,
    };
  }
}
