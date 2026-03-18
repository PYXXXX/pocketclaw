import 'package:gateway_transport/gateway_transport.dart';

abstract interface class GatewayClient {
  Stream<GatewayEvent> get events;

  Future<GatewayResponse> request(
    GatewayRequest request,
  );
}
