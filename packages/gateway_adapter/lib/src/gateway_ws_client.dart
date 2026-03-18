import 'dart:async';

import 'package:gateway_transport/gateway_transport.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connectable_gateway_client.dart';
import 'gateway_connection_config.dart';
import 'gateway_request_error.dart';

typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

final class GatewayWsClient implements ConnectableGatewayClient {
  GatewayWsClient({
    required this.config,
    GatewayFrameCodec? codec,
    WebSocketChannelFactory? channelFactory,
  })  : _codec = codec ?? GatewayFrameCodec(),
        _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final GatewayConnectionConfig config;
  final GatewayFrameCodec _codec;
  final WebSocketChannelFactory _channelFactory;
  final Map<String, Completer<GatewayResponse>> _pending =
      <String, Completer<GatewayResponse>>{};
  final StreamController<GatewayEvent> _eventController =
      StreamController<GatewayEvent>.broadcast();
  final StreamController<GatewayConnectionState> _connectionController =
      StreamController<GatewayConnectionState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _socketSubscription;
  GatewayConnectionState _state = const GatewayConnectionState(
    phase: GatewayConnectionPhase.disconnected,
  );
  Completer<void>? _connectCompleter;
  Timer? _connectTimeoutTimer;
  bool _connectRequestSent = false;
  int _requestCounter = 0;

  @override
  Stream<GatewayEvent> get events => _eventController.stream;

  @override
  Stream<GatewayConnectionState> get connectionStates async* {
    yield _state;
    yield* _connectionController.stream;
  }

  @override
  Future<void> connect() async {
    if (_channel != null) {
      return _connectCompleter?.future ?? Future<void>.value();
    }

    _emitState(
      const GatewayConnectionState(
        phase: GatewayConnectionPhase.connecting,
        message: 'Opening WebSocket…',
      ),
    );

    _connectCompleter = Completer<void>();
    _connectRequestSent = false;
    _channel = _channelFactory(config.uri);
    _socketSubscription = _channel!.stream.listen(
      _handleRawFrame,
      onError: _handleSocketError,
      onDone: _handleSocketDone,
      cancelOnError: false,
    );

    _connectTimeoutTimer = Timer(config.connectTimeout, () {
      if (_connectCompleter?.isCompleted == false) {
        final message = 'Timed out waiting for Gateway handshake.';
        _emitState(
          const GatewayConnectionState(
            phase: GatewayConnectionPhase.error,
            message: 'Timed out waiting for Gateway handshake.',
          ),
        );
        _connectCompleter?.completeError(StateError(message));
      }
    });

    return _connectCompleter!.future;
  }

  @override
  Future<void> disconnect() async {
    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = null;
    _connectRequestSent = false;

    final channel = _channel;
    _channel = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await channel?.sink.close();

    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Gateway client disconnected.'));
      }
    }
    _pending.clear();

    _emitState(
      const GatewayConnectionState(
        phase: GatewayConnectionPhase.disconnected,
        message: 'Disconnected',
      ),
    );
  }

  @override
  Future<GatewayResponse> request(GatewayRequest request) {
    final channel = _channel;
    if (channel == null) {
      return Future<GatewayResponse>.error(
        StateError('Gateway client is not connected.'),
      );
    }

    final completer = Completer<GatewayResponse>();
    _pending[request.id] = completer;
    channel.sink.add(_codec.encodeRequest(request));
    return completer.future;
  }

  void _handleRawFrame(Object? rawFrame) {
    if (rawFrame is! String) {
      return;
    }

    final message = _codec.decodeFrame(rawFrame);
    switch (message) {
      case GatewayEvent():
        _handleEvent(message);
      case GatewayResponse():
        _handleResponse(message);
      case GatewayRequest():
        // Client mode does not currently expect inbound request frames.
        break;
    }
  }

  void _handleEvent(GatewayEvent event) {
    final challenge = const GatewayParser().parseConnectChallenge(event);
    if (challenge != null && !_connectRequestSent) {
      _emitState(
        GatewayConnectionState(
          phase: GatewayConnectionPhase.challengeReceived,
          message: 'Received connect.challenge',
        ),
      );
      _connectRequestSent = true;
      unawaited(_sendConnectRequest());
    }

    _eventController.add(event);
  }

  Future<void> _sendConnectRequest() async {
    try {
      await request(
        GatewayRequest(
          id: _nextRequestId('connect'),
          method: 'connect',
          params: config.connectRequest.toParams(),
        ),
      );

      _connectTimeoutTimer?.cancel();
      _connectTimeoutTimer = null;
      _emitState(
        const GatewayConnectionState(
          phase: GatewayConnectionPhase.connected,
          message: 'Connected',
        ),
      );
      if (_connectCompleter?.isCompleted == false) {
        _connectCompleter?.complete();
      }
    } catch (error) {
      _emitState(
        GatewayConnectionState(
          phase: GatewayConnectionPhase.error,
          message: error.toString(),
        ),
      );
      if (_connectCompleter?.isCompleted == false) {
        _connectCompleter?.completeError(error);
      }
    }
  }

  void _handleResponse(GatewayResponse response) {
    final completer = _pending.remove(response.id);
    if (completer == null || completer.isCompleted) {
      return;
    }

    if (response.ok) {
      completer.complete(response);
      return;
    }

    completer.completeError(
      GatewayRequestError.fromPayload(response.error ?? const <String, Object?>{}),
    );
  }

  void _handleSocketError(Object error, StackTrace stackTrace) {
    _emitState(
      GatewayConnectionState(
        phase: GatewayConnectionPhase.error,
        message: error.toString(),
      ),
    );
    if (_connectCompleter?.isCompleted == false) {
      _connectCompleter?.completeError(error, stackTrace);
    }
  }

  void _handleSocketDone() {
    if (_state.phase != GatewayConnectionPhase.disconnected) {
      _emitState(
        const GatewayConnectionState(
          phase: GatewayConnectionPhase.disconnected,
          message: 'Socket closed',
        ),
      );
    }
  }

  void _emitState(GatewayConnectionState state) {
    _state = state;
    _connectionController.add(state);
  }

  String _nextRequestId(String prefix) {
    _requestCounter += 1;
    return '$prefix-${_requestCounter.toString().padLeft(4, '0')}';
  }
}
