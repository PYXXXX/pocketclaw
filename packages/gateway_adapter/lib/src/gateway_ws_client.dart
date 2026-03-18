import 'dart:async';

import 'package:gateway_transport/gateway_transport.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connectable_gateway_client.dart';
import 'gateway_connection_config.dart';
import 'gateway_device_token.dart';
import 'gateway_request_error.dart';

typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

final class GatewayWsClient implements ConnectableGatewayClient {
  GatewayWsClient({
    required this.config,
    GatewayFrameCodec? codec,
    WebSocketChannelFactory? channelFactory,
  })  : _codec = codec ?? GatewayFrameCodec(),
        _parser = const GatewayParser(),
        _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final GatewayConnectionConfig config;
  final GatewayFrameCodec _codec;
  final GatewayParser _parser;
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
  ConnectChallenge? _lastChallenge;
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
    _lastChallenge = null;
    _channel = _channelFactory(config.uri);
    _socketSubscription = _channel!.stream.listen(
      _handleRawFrame,
      onError: _handleSocketError,
      onDone: _handleSocketDone,
      cancelOnError: false,
    );

    _connectTimeoutTimer = Timer(config.connectTimeout, () {
      if (_connectCompleter?.isCompleted == false) {
        const message = 'Timed out waiting for Gateway handshake.';
        _emitState(
          const GatewayConnectionState(
            phase: GatewayConnectionPhase.error,
            message: message,
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
    _lastChallenge = null;

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
        break;
    }
  }

  void _handleEvent(GatewayEvent event) {
    final challenge = _parser.parseConnectChallenge(event);
    if (challenge != null && !_connectRequestSent) {
      _lastChallenge = challenge;
      _emitState(
        const GatewayConnectionState(
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
      var connectRequest = config.connectRequest;
      final challenge = _lastChallenge;
      final deviceAuthProvider = config.deviceAuthProvider;

      Map<String, Object?>? device;
      if (challenge != null && deviceAuthProvider != null) {
        device = await deviceAuthProvider.buildDeviceAuth(
          challenge: challenge,
          connectRequest: connectRequest,
        );
      }

      final deviceId = device?['id'] as String?;
      if (deviceId != null && config.deviceTokenStore != null) {
        final stored = await config.deviceTokenStore!.read(
          deviceId: deviceId,
          role: connectRequest.role,
        );
        if (stored != null) {
          final auth = <String, Object?>{
            ...?connectRequest.auth,
            'deviceToken': stored.token,
          };
          connectRequest = connectRequest.copyWith(auth: auth);
        }
      }

      if (device != null) {
        connectRequest = connectRequest.copyWith(device: device);
      }

      final response = await request(
        GatewayRequest(
          id: _nextRequestId('connect'),
          method: 'connect',
          params: connectRequest.toParams(),
        ),
      );

      await _persistDeviceTokenIfPresent(response.payload, deviceId, connectRequest.role);

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

  Future<void> _persistDeviceTokenIfPresent(
    Map<String, Object?>? payload,
    String? deviceId,
    String requestedRole,
  ) async {
    final store = config.deviceTokenStore;
    if (store == null || payload == null || deviceId == null) {
      return;
    }

    final auth = payload['auth'];
    if (auth is! Map<String, Object?>) {
      return;
    }

    final deviceToken = auth['deviceToken'];
    if (deviceToken is! String || deviceToken.isEmpty) {
      return;
    }

    final role = auth['role'] as String? ?? requestedRole;
    final scopes = <String>[];
    final rawScopes = auth['scopes'];
    if (rawScopes is List<Object?>) {
      for (final item in rawScopes) {
        if (item is String) {
          scopes.add(item);
        }
      }
    }

    await store.write(
      GatewayDeviceToken(
        deviceId: deviceId,
        role: role,
        token: deviceToken,
        scopes: scopes,
      ),
    );
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
