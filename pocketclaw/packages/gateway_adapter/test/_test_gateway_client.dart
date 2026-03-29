import 'dart:async';

import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';

final class TestGatewayClient implements GatewayClient {
  TestGatewayClient({
    required FutureOr<GatewayResponse> Function(GatewayRequest request)
    onRequest,
    Stream<GatewayEvent>? events,
  }) : _onRequest = onRequest,
       _events = events ?? const Stream<GatewayEvent>.empty();

  final FutureOr<GatewayResponse> Function(GatewayRequest request) _onRequest;
  final Stream<GatewayEvent> _events;

  @override
  Stream<GatewayEvent> get events => _events;

  @override
  Future<GatewayResponse> request(GatewayRequest request) async {
    return await _onRequest(request);
  }
}
