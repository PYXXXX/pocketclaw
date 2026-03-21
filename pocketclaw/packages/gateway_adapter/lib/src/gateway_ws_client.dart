import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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

final class WebSocketHandshakeTarget {
  const WebSocketHandshakeTarget({
    required this.uri,
    required this.headers,
    required this.preflightSummary,
  });

  final Uri uri;
  final Map<String, String> headers;
  final String preflightSummary;
}

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
    final challenge = _lastChallenge;
    if (challenge == null) {
      throw StateError('Missing connect challenge from Gateway.');
    }

    final role = config.connectRequest.role;
    String? deviceId;
    Map<String, Object?>? deviceAuth;
    if (config.deviceAuthProvider != null) {
      deviceAuth = await config.deviceAuthProvider!.buildDeviceAuth(
        challenge: challenge,
        connectRequest: config.connectRequest,
      );
      final rawId = deviceAuth['id'];
      if (rawId is String && rawId.trim().isNotEmpty) {
        deviceId = rawId.trim();
      }
    }

    GatewayDeviceToken? storedDeviceToken;
    if (deviceId != null && config.deviceTokenStore != null) {
      storedDeviceToken = await config.deviceTokenStore!.read(
        deviceId: deviceId,
        role: role,
      );
    }

    final auth = <String, Object?>{
      ...?config.connectRequest.auth,
      if (storedDeviceToken != null &&
          storedDeviceToken.token.trim().isNotEmpty)
        'deviceToken': storedDeviceToken.token,
    };

    final request = config.connectRequest.copyWith(
      auth: auth.isEmpty ? null : auth,
      device: deviceAuth,
    );

    return _PreparedConnectAttempt(
      request: request,
      deviceId: deviceId,
      usedStoredDeviceToken: storedDeviceToken != null,
      hasBootstrapAuth: _hasBootstrapAuth(config.connectRequest.auth),
    );
  }

  Future<GatewayResponse> _connectWithFallbackIfNeeded(
    _PreparedConnectAttempt attempt,
  ) async {
    try {
      return await _sendConnect(attempt.request);
    } on GatewayRequestError catch (error) {
      final code = error.detailsCode ?? error.code;
      final shouldRetryWithoutDeviceToken =
          code == GatewayErrorCodes.authDeviceTokenMismatch &&
              attempt.usedStoredDeviceToken &&
              attempt.hasBootstrapAuth;
      if (!shouldRetryWithoutDeviceToken) {
        rethrow;
      }

      final auth = Map<String, Object?>.from(
          config.connectRequest.auth ?? const <String, Object?>{});
      final retryRequest = attempt.request.copyWith(
        auth: auth.isEmpty ? null : auth,
      );
      return _sendConnect(retryRequest);
    }
  }

  Future<GatewayResponse> _sendConnect(ConnectRequest request) {
    final gatewayRequest = GatewayRequest(
      id: _nextRequestId('connect'),
      method: 'connect',
      params: request.toParams(),
    );
    return this.request(gatewayRequest);
  }

  Future<void> _persistDeviceTokenIfPresent(
    Map<String, Object?>? payload,
    String? deviceId,
    String role,
  ) async {
    final tokenStore = config.deviceTokenStore;
    if (tokenStore == null || deviceId == null || deviceId.isEmpty) {
      return;
    }

    final auth = payload?['auth'];
    if (auth is! Map) {
      return;
    }

    final authMap = Map<String, Object?>.from(auth);
    final token = authMap['deviceToken'];
    if (token is! String || token.trim().isEmpty) {
      return;
    }

    await tokenStore.write(
      GatewayDeviceToken(
        deviceId: deviceId,
        role: role,
        token: token.trim(),
        scopes: (authMap['scopes'] as List?)?.whereType<String>().toList() ??
            const <String>[],
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
    final target = await prepareWebSocketHandshakeTarget(uri, headers);
    try {
      return await _connectWithControlledHandshake(target);
    } catch (error) {
      throw StateError(
        'WebSocket connect failed. Configured URI: $uri; '
        'effective URI: ${target.uri}; '
        'preflight: ${target.preflightSummary}; '
        'original error: $error',
      );
    }
  }

  static Future<WebSocketChannel> _connectWithControlledHandshake(
    WebSocketHandshakeTarget target,
  ) async {
    final client = HttpClient();
    final cookies = <String, String>{
      ..._parseCookieHeader(target.headers[HttpHeaders.cookieHeader]),
    };
    var currentWebSocketUri = _normalizeWebSocketRedirectUri(target.uri);

    try {
      for (var redirects = 0; redirects <= 5; redirects += 1) {
        final httpUri = _webSocketToHttpUri(currentWebSocketUri);
        final request = await client.getUrl(httpUri);
        request.followRedirects = false;

        for (final entry in target.headers.entries) {
          if (entry.key.toLowerCase() == HttpHeaders.cookieHeader) {
            continue;
          }
          request.headers.set(entry.key, entry.value);
        }

        final cookieHeader = _formatCookieHeader(cookies);
        if (cookieHeader.isNotEmpty) {
          request.headers.set(HttpHeaders.cookieHeader, cookieHeader);
        }

        final nonce = _generateWebSocketKey();
        request.headers
          ..set(HttpHeaders.connectionHeader, 'Upgrade')
          ..set(HttpHeaders.upgradeHeader, 'websocket')
          ..set('Sec-WebSocket-Key', nonce)
          ..set(HttpHeaders.cacheControlHeader, 'no-cache')
          ..set('Sec-WebSocket-Version', '13');

        final response = await request.close();
        for (final cookie in response.cookies) {
          cookies[cookie.name] = cookie.value;
        }

        final location = response.headers.value(HttpHeaders.locationHeader);
        final isRedirect =
            response.statusCode >= 300 && response.statusCode < 400;
        if (isRedirect) {
          if (location == null || location.trim().isEmpty) {
            throw StateError(
              'The WebSocket upgrade was redirected, but the response did not '
              'include a Location header. Upgrade GET $httpUri returned '
              'HTTP ${response.statusCode}.',
            );
          }

          final resolvedLocation = httpUri.resolve(location.trim());
          currentWebSocketUri = _httpToWebSocketUri(resolvedLocation);

          if (redirects == 5) {
            throw StateError(
              'The WebSocket upgrade followed too many redirects before '
              'connecting. Last redirect target: $currentWebSocketUri.',
            );
          }
          continue;
        }

        _ensureSuccessfulWebSocketUpgrade(response, nonce, httpUri);
        final socket = await response.detachSocket();
        final protocol = response.headers.value('Sec-WebSocket-Protocol');
        final webSocket = WebSocket.fromUpgradedSocket(
          socket,
          protocol: protocol,
          serverSide: false,
        );
        return IOWebSocketChannel(webSocket);
      }
    } finally {
      client.close(force: true);
    }

    throw StateError(
      'The WebSocket upgrade could not complete for an unknown reason.',
    );
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
}

Future<WebSocketHandshakeTarget> prepareWebSocketHandshakeTarget(
  Uri uri,
  Map<String, String> headers,
) async {
  if (uri.scheme != 'ws' && uri.scheme != 'wss') {
    return WebSocketHandshakeTarget(
      uri: uri,
      headers: Map<String, String>.from(headers),
      preflightSummary: 'skipped (non-websocket scheme)',
    );
  }

  final initialPreflightUri = uri.replace(
    scheme: uri.scheme == 'wss' ? 'https' : 'http',
    path: uri.path.isEmpty ? '/' : uri.path,
  );

  final client = HttpClient();
  final cookies = <String, String>{
    ..._parseCookieHeader(headers['Cookie']),
  };
  final visited = <Uri>[initialPreflightUri];
  var currentPreflightUri = initialPreflightUri;
  HttpClientResponse? lastResponse;

  try {
    for (var redirects = 0; redirects <= 5; redirects += 1) {
      final request = await client.getUrl(currentPreflightUri);
      request.followRedirects = false;
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == 'cookie') {
          continue;
        }
        request.headers.set(entry.key, entry.value);
      }
      final cookieHeader = _formatCookieHeader(cookies);
      if (cookieHeader.isNotEmpty) {
        request.headers.set(HttpHeaders.cookieHeader, cookieHeader);
      }

      final response = await request.close();
      lastResponse = response;
      for (final cookie in response.cookies) {
        cookies[cookie.name] = cookie.value;
      }

      final location = response.headers.value(HttpHeaders.locationHeader);
      final isRedirect =
          response.statusCode >= 300 && response.statusCode < 400;
      if (!isRedirect) {
        if (response.statusCode == HttpStatus.forbidden &&
            _hasCloudflareAccessHeadersForPreflight(headers)) {
          throw StateError(
            'Cloudflare Access rejected the provided service token before the WebSocket upgrade. '
            'Preflight GET $currentPreflightUri returned HTTP ${response.statusCode}.',
          );
        }
        break;
      }

      if (location == null || location.trim().isEmpty) {
        throw StateError(
          'The WebSocket preflight was redirected before connecting, but the '
          'response did not include a Location header. '
          'Preflight GET $currentPreflightUri returned HTTP ${response.statusCode}.',
        );
      }

      final resolvedLocation = currentPreflightUri.resolve(location.trim());
      if (resolvedLocation.host
          .toLowerCase()
          .contains('cloudflareaccess.com')) {
        throw StateError(
          'Cloudflare Access redirected the request to an interactive login flow before the WebSocket upgrade. '
          'Preflight GET $currentPreflightUri returned HTTP ${response.statusCode} '
          'with Location: $resolvedLocation. Verify the service token policy or exempt this host/path from Access.',
        );
      }

      currentPreflightUri = _normalizePreflightRedirectUri(resolvedLocation);
      visited.add(currentPreflightUri);

      if (redirects == 5) {
        throw StateError(
          'The WebSocket preflight followed too many redirects before connecting. '
          'Last redirect target: $currentPreflightUri.',
        );
      }
    }
  } finally {
    client.close(force: true);
  }

  final effectiveHeaders = Map<String, String>.from(headers);
  final effectiveCookieHeader = _formatCookieHeader(cookies);
  if (effectiveCookieHeader.isNotEmpty) {
    effectiveHeaders[HttpHeaders.cookieHeader] = effectiveCookieHeader;
  }

  final effectiveUri = currentPreflightUri.replace(
    scheme: currentPreflightUri.scheme == 'https' ? 'wss' : 'ws',
  );

  return WebSocketHandshakeTarget(
    uri: effectiveUri,
    headers: effectiveHeaders,
    preflightSummary: _buildPreflightSummary(
      visited: visited,
      statusCode: lastResponse?.statusCode,
      finalUri: currentPreflightUri,
      cookieNames: cookies.keys.toList(),
    ),
  );
}

Map<String, String> _parseCookieHeader(String? rawCookieHeader) {
  if (rawCookieHeader == null || rawCookieHeader.trim().isEmpty) {
    return const <String, String>{};
  }

  final result = <String, String>{};
  for (final segment in rawCookieHeader.split(';')) {
    final trimmed = segment.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final separator = trimmed.indexOf('=');
    if (separator <= 0) {
      continue;
    }
    result[trimmed.substring(0, separator).trim()] =
        trimmed.substring(separator + 1).trim();
  }
  return result;
}

bool _hasCloudflareAccessHeadersForPreflight(Map<String, String> headers) {
  return (headers['CF-Access-Client-Id']?.trim().isNotEmpty ?? false) &&
      (headers['CF-Access-Client-Secret']?.trim().isNotEmpty ?? false);
}

String _formatCookieHeader(Map<String, String> cookies) {
  if (cookies.isEmpty) {
    return '';
  }
  return cookies.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join('; ');
}

Uri _normalizePreflightRedirectUri(Uri uri) {
  if (uri.scheme == 'ws' || uri.scheme == 'wss') {
    return uri.replace(path: uri.path.isEmpty ? '/' : uri.path);
  }
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    return uri.replace(path: uri.path.isEmpty ? '/' : uri.path);
  }
  throw StateError(
    'The WebSocket preflight redirected to an unsupported scheme: ${uri.scheme}. '
    'Resolved redirect target: $uri.',
  );
}

Uri _normalizeWebSocketRedirectUri(Uri uri) {
  if (uri.scheme == 'ws' || uri.scheme == 'wss') {
    return uri.replace(path: uri.path.isEmpty ? '/' : uri.path);
  }
  throw StateError(
    'The WebSocket handshake target used an unsupported scheme: ${uri.scheme}. '
    'Resolved target: $uri.',
  );
}

Uri _webSocketToHttpUri(Uri webSocketUri) {
  return webSocketUri.replace(
    scheme: webSocketUri.scheme == 'wss' ? 'https' : 'http',
    path: webSocketUri.path.isEmpty ? '/' : webSocketUri.path,
  );
}

Uri _httpToWebSocketUri(Uri uri) {
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    return uri.replace(
      scheme: uri.scheme == 'https' ? 'wss' : 'ws',
      path: uri.path.isEmpty ? '/' : uri.path,
    );
  }
  if (uri.scheme == 'ws' || uri.scheme == 'wss') {
    return uri.replace(path: uri.path.isEmpty ? '/' : uri.path);
  }
  throw StateError(
    'The WebSocket upgrade redirected to an unsupported scheme: ${uri.scheme}. '
    'Resolved redirect target: $uri.',
  );
}

String _generateWebSocketKey() {
  final random = Random.secure();
  final bytes = Uint8List(16);
  for (var index = 0; index < bytes.length; index += 1) {
    bytes[index] = random.nextInt(256);
  }
  return base64Encode(bytes);
}

void _ensureSuccessfulWebSocketUpgrade(
  HttpClientResponse response,
  String nonce,
  Uri httpUri,
) {
  final connectionHeader = response.headers[HttpHeaders.connectionHeader];
  final upgradeHeader = response.headers.value(HttpHeaders.upgradeHeader);
  final acceptHeader = response.headers.value('Sec-WebSocket-Accept');

  final isUpgradeResponse =
      response.statusCode == HttpStatus.switchingProtocols &&
          connectionHeader != null &&
          connectionHeader
              .any((value) => value.toLowerCase().contains('upgrade')) &&
          upgradeHeader != null &&
          upgradeHeader.toLowerCase() == 'websocket';

  if (!isUpgradeResponse) {
    throw StateError(
      'Connection to $httpUri was not upgraded to WebSocket. '
      'HTTP ${response.statusCode}; '
      'Connection: ${connectionHeader?.join(', ') ?? '<missing>'}; '
      'Upgrade: ${upgradeHeader ?? '<missing>'}.',
    );
  }

  final expectedAccept = WebSocketChannel.signKey(nonce);
  if (acceptHeader == null || acceptHeader != expectedAccept) {
    throw StateError(
      'The WebSocket upgrade response returned an invalid Sec-WebSocket-Accept '
      'header. Expected $expectedAccept but got ${acceptHeader ?? '<missing>'}.',
    );
  }
}

String _buildPreflightSummary({
  required List<Uri> visited,
  required int? statusCode,
  required Uri finalUri,
  required List<String> cookieNames,
}) {
  final parts = <String>[
    'GET ${visited.first}',
    if (visited.length > 1) 'redirects: ${visited.skip(1).join(' -> ')}',
    if (statusCode != null) 'finalStatus: $statusCode',
    'finalUri: $finalUri',
    if (cookieNames.isNotEmpty) 'cookies: ${cookieNames.join(', ')}',
  ];
  return parts.join('; ');
}
