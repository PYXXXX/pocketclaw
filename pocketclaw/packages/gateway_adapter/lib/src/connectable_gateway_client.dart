import 'package:gateway_transport/gateway_transport.dart';

import 'gateway_client.dart';

abstract interface class ConnectableGatewayClient implements GatewayClient {
  Stream<GatewayConnectionState> get connectionStates;

  Future<void> connect();

  Future<void> disconnect();
}
