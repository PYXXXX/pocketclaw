import 'dart:async';

import 'package:gateway_transport/gateway_transport.dart';

import 'connectable_gateway_client.dart';
import 'gateway_method_names.dart';

final class FakeGatewayClient implements ConnectableGatewayClient {
  FakeGatewayClient();

  final StreamController<GatewayEvent> _eventController =
      StreamController<GatewayEvent>.broadcast();
  final StreamController<GatewayConnectionState> _connectionController =
      StreamController<GatewayConnectionState>.broadcast();

  GatewayConnectionState _state = const GatewayConnectionState(
    phase: GatewayConnectionPhase.disconnected,
  );

  @override
  Stream<GatewayEvent> get events => _eventController.stream;

  @override
  Stream<GatewayConnectionState> get connectionStates async* {
    yield _state;
    yield* _connectionController.stream;
  }

  @override
  Future<void> connect() async {
    _emitState(
      const GatewayConnectionState(
        phase: GatewayConnectionPhase.connecting,
        message: 'Connecting to Gateway…',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 150));

    _emitState(
      const GatewayConnectionState(
        phase: GatewayConnectionPhase.challengeReceived,
        message: 'Received connect.challenge',
      ),
    );

    _eventController.add(
      const GatewayEvent(
        event: 'connect.challenge',
        payload: <String, Object?>{
          'nonce': 'fake-nonce',
          'ts': 1737264000000,
        },
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 150));

    _emitState(
      const GatewayConnectionState(
        phase: GatewayConnectionPhase.connected,
        message: 'Connected',
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    _emitState(
      const GatewayConnectionState(
        phase: GatewayConnectionPhase.disconnected,
        message: 'Disconnected',
      ),
    );
  }

  @override
  Future<GatewayResponse> request(GatewayRequest request) async {
    switch (request.method) {
      case GatewayMethodNames.chatHistory:
        return GatewayResponse(
          id: request.id,
          ok: true,
          payload: <String, Object?>{
            'messages': <Object?>[],
            'thinkingLevel': 'off',
          },
        );
      case GatewayMethodNames.sessionsList:
        return GatewayResponse(
          id: request.id,
          ok: true,
          payload: <String, Object?>{
            'sessions': <Object?>[],
          },
        );
      default:
        return GatewayResponse(
          id: request.id,
          ok: true,
          payload: const <String, Object?>{},
        );
    }
  }

  void _emitState(GatewayConnectionState state) {
    _state = state;
    _connectionController.add(state);
  }
}
