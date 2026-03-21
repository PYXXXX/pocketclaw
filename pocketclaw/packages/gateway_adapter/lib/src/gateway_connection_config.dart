import 'package:gateway_transport/gateway_transport.dart';

import 'gateway_device_auth_provider.dart';
import 'gateway_device_token_store.dart';

final class GatewayConnectionConfig {
  const GatewayConnectionConfig({
    required this.url,
    required this.connectRequest,
    this.headers = const <String, String>{},
    this.deviceAuthProvider,
    this.deviceTokenStore,
    this.connectTimeout = const Duration(seconds: 10),
  });

  final String url;
  final ConnectRequest connectRequest;
  final Map<String, String> headers;
  final GatewayDeviceAuthProvider? deviceAuthProvider;
  final GatewayDeviceTokenStore? deviceTokenStore;
  final Duration connectTimeout;

  Uri get uri {
    final parsed = Uri.parse(url);
    if (parsed.path.isEmpty) {
      return parsed.replace(path: '/');
    }
    return parsed;
  }
}
