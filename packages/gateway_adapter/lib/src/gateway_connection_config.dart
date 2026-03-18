import 'package:gateway_transport/gateway_transport.dart';

final class GatewayConnectionConfig {
  const GatewayConnectionConfig({
    required this.url,
    required this.connectRequest,
    this.connectTimeout = const Duration(seconds: 10),
  });

  final String url;
  final ConnectRequest connectRequest;
  final Duration connectTimeout;

  Uri get uri => Uri.parse(url);
}
