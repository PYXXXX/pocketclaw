import 'dart:async';
import 'dart:io';

import 'package:gateway_transport/gateway_transport.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connectable_gateway_client.dart';
import 'gateway_connection_config.dart';
import 'gateway_device_token.dart';
import 'gateway_error_codes.dart';
import 'gateway_request_error.dart';

typedef WebSocketChannelFactory = Future<WebSocketChannel> Function(
    Uri uri, Map<String, String> headers);

final class _PreparedConnectAttempt {
  const _PreparedConnectAttempt({
    required this.request,
    required this.deviceId,
    required this.usedStoredDeviceToken,
    required this.hasBootstrapAuth,
  });

  final ConnectRequest request;
  final String? deviceId;
  final bool usedStoredDeviceToken;
  final bool hasBootstrapAuth;
}

final class GatewayWsClient implements ConnectableGatewayClient {
  GatewayWsClient({
    required this.config,
    GatewayFrameCodec? codec,
    WebSocketChannelFactory? channelFactory,
  })  : _codec = codec ?? GatewayFrameCodec(),
        _parser = const GatewayParser(),
        _channelFactory = channelFactory ?? _defaultChannelFactory;

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

    try {
      _channel = await _channelFactory(config.uri, config.headers);
      _socketSubscription = _channel!.stream.listen(
        _handleRawFrame,
        onError: _handleSocketError,
        onDone: _handleSocketDone,
        cancelOnError: false,
      );
    } catch (error, stackTrace) {
      _connectTimeoutTimer?.cancel();
      _connectTimeoutTimer = null;
      _handleSocketError(error, stackTrace);
    }

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
      final attempt = await _prepareConnectAttempt();
      final response = await _connectWithFallbackIfNeeded(attempt);

      await _persistDeviceTokenIfPresent(
        response.payload,
        attempt.deviceId,
        attempt.request.role,
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

  Future<_PreparedConnectAttempt> _prepareConnectAttempt() async {
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

    GatewayDeviceToken? storedToken;
    final deviceId = device?['id'] as String?;
    if (deviceId != null && config.deviceTokenStore != null) {
      storedToken = await config.deviceTokenStore!.read(
        deviceId: deviceId,
        role: connectRequest.role,
      );
      if (storedToken != null) {
        final auth = <String, Object?>{
          ...?connectRequest.auth,
          'deviceToken': storedToken.token,
        };
        connectRequest = connectRequest.copyWith(auth: auth);
      }
    }

    if (device != null) {
      connectRequest = connectRequest.copyWith(device: device);
    }

    return _PreparedConnectAttempt(
      request: connectRequest,
      deviceId: deviceId,
      usedStoredDeviceToken: storedToken != null,
      hasBootstrapAuth: _hasBootstrapAuth(config.connectRequest.auth),
    );
  }

  Future<GatewayResponse> _performConnectRequest(
    ConnectRequest connectRequest,
  ) {
    return request(
      GatewayRequest(
        id: _nextRequestId('connect'),
        method: 'connect',
        params: connectRequest.toParams(),
      ),
    );
  }

  Future<GatewayResponse> _connectWithFallbackIfNeeded(
    _PreparedConnectAttempt attempt,
  ) async {
    try {
      return await _performConnectRequest(attempt.request);
    } on GatewayRequestError catch (error) {
      if (!_shouldRetryWithoutStoredDeviceToken(error, attempt)) {
        rethrow;
      }

      _emitState(
        const GatewayConnectionState(
          phase: GatewayConnectionPhase.connecting,
          message:
              'Stored device token was rejected. Retrying with bootstrap auth…',
        ),
      );

      final fallbackAuth = Map<String, Object?>.from(
        config.connectRequest.auth ?? const <String, Object?>{},
      );
      final fallbackRequest = attempt.request.copyWith(
        auth: fallbackAuth.isEmpty ? null : fallbackAuth,
      );
      return _performConnectRequest(fallbackRequest);
    }
  }

  bool _shouldRetryWithoutStoredDeviceToken(
    GatewayRequestError error,
    _PreparedConnectAttempt attempt,
  ) {
    final code = error.detailsCode ?? error.code;
    return attempt.usedStoredDeviceToken &&
        attempt.hasBootstrapAuth &&
        code == GatewayErrorCodes.authDeviceTokenMismatch;
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
      GatewayRequestError.fromPayload(
        response.error ?? const <String, Object?>{},
      ),
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

  static Future<WebSocketChannel> _defaultChannelFactory(
    Uri uri,
    Map<String, String> headers,
  ) async {
    final effectiveHeaders = await _prepareHandshakeHeaders(uri, headers);
    return IOWebSocketChannel.connect(
      uri.toString(),
      headers: effectiveHeaders.isEmpty ? null : effectiveHeaders,
    );
  }

  static Future<Map<String, String>> _prepareHandshakeHeaders(
    Uri uri,
    Map<String, String> headers,
  ) async {
    if (!_hasCloudflareAccessHeaders(headers)) {
      return headers;
    }

    final cookieHeader = await _preflightCloudflareAccessCookie(uri, headers);
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return headers;
    }

    final effective = Map<String, String>.from(headers);
    final existingCookie = effective['Cookie'];
    effective['Cookie'] = existingCookie == null || existingCookie.isEmpty
        ? cookieHeader
        : '$existingCookie; $cookieHeader';
    return effective;
  }

  static bool _hasCloudflareAccessHeaders(Map<String, String> headers) {
    return (headers['CF-Access-Client-Id']?.trim().isNotEmpty ?? false) &&
        (headers['CF-Access-Client-Secret']?.trim().isNotEmpty ?? false);
  }

  static bool _hasBootstrapAuth(Map<String, Object?>? auth) {
    if (auth == null) {
      return false;
    }
    final token = auth['token'];
    if (token is String && token.trim().isNotEmpty) {
      return true;
    }
    final password = auth['password'];
    if (password is String && password.trim().isNotEmpty) {
      return true;
    }
    return false;
  }

  static Future<String?> _preflightCloudflareAccessCookie(
    Uri uri,
    Map<String, String> headers,
  ) async {
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      return null;
    }

    final preflightUri = uri.replace(
      scheme: uri.scheme == 'wss' ? 'https' : 'http',
      path: uri.path.isEmpty ? '/' : uri.path,
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(preflightUri);
      request.followRedirects = false;
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }

      final response = await request.close();
      final location = response.headers.value(HttpHeaders.locationHeader);
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectLocation = location ?? '';
        if (redirectLocation.contains('cloudflareaccess.com')) {
          throw StateError(
            'Cloudflare Access redirected the request to an interactive login flow before the WebSocket upgrade. Verify the service token policy or exempt this host/path from Access.',
          );
        }
        throw StateError(
          'The WebSocket preflight was redirected before connecting. Check the reverse proxy and WebSocket upgrade path.',
        );
      }

      if (response.statusCode == HttpStatus.forbidden) {
        throw StateError(
          'Cloudflare Access rejected the provided service token before the WebSocket upgrade.',
        );
      }

      if (response.cookies.isEmpty) {
        return null;
      }
      return response.cookies
          .map((cookie) => '${cookie.name}=${cookie.value}')
          .join('; ');
    } finally {
      client.close(force: true);
    }
  }
}
