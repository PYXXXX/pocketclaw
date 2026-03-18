import 'package:gateway_transport/gateway_transport.dart';

import 'gateway_device_auth_provider.dart';

final class GatewayConnectionConfig {
  const GatewayConnectionConfig({
    required this.url,
    required this.connectRequest,
    this.deviceAuthProvider,
    this.connectTimeout = const Duration(seconds: 10),
  });

  final String url;
  final ConnectRequest connectRequest;
  final GatewayDeviceAuthProvider? deviceAuthProvider;
  final Duration connectTimeout;

  Uri get uri => Uri.parse(url);
}
