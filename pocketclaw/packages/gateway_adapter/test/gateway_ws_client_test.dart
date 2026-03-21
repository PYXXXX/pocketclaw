import 'dart:async';
import 'dart:convert';

import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayWsClient', () {
    test('sends connect request after connect.challenge and resolves handshake', () async {
      final incoming = StreamController<Object?>();
      final outgoing = <String>[];
      final fakeChannel = _TestWebSocketChannel(
        stream: incoming.stream,
        onAdd: (data) => outgoing.add(data as String),
      );

      final client = GatewayWsClient(
        config: GatewayConnectionConfig(
          url: 'ws://127.0.0.1:18789',
          connectRequest: const GatewayConnectRequestFactory().build(token: 'abc'),
        ),
        channelFactory: (_, __) async => fakeChannel,
      );

      final connectFuture = client.connect();

      incoming.add(jsonEncode(<String, Object?>{
        'type': 'event',
        'event': 'connect.challenge',
        'payload': <String, Object?>{'nonce': 'nonce-1'},
      }));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(outgoing, isNotEmpty);

      final firstRequest = jsonDecode(outgoing.first) as Map<String, Object?>;
      expect(firstRequest['method'], 'connect');

      incoming.add(jsonEncode(<String, Object?>{
        'type': 'res',
        'id': firstRequest['id'] as String,
        'ok': true,
        'payload': <String, Object?>{
          'hello': true,
        },
      }));

      await connectFuture;
    });

    test('passes configured headers into websocket setup', () async {
      final incoming = StreamController<Object?>();
      final outgoing = <String>[];
      final fakeChannel = _TestWebSocketChannel(
        stream: incoming.stream,
        onAdd: (data) => outgoing.add(data as String),
      );
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;

      final client = GatewayWsClient(
        config: GatewayConnectionConfig(
          url: 'wss://bot.bilirec.com',
          connectRequest: const GatewayConnectRequestFactory().build(token: 'abc'),
          headers: const <String, String>{
            'CF-Access-Client-Id': 'client-id.access',
            'CF-Access-Client-Secret': 'client-secret',
          },
        ),
        channelFactory: (uri, headers) async {
          capturedUri = uri;
          capturedHeaders = headers;
          return fakeChannel;
        },
      );

      final connectFuture = client.connect();

      incoming.add(jsonEncode(<String, Object?>{
        'type': 'event',
        'event': 'connect.challenge',
        'payload': <String, Object?>{'nonce': 'nonce-1'},
      }));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final request = jsonDecode(outgoing.first) as Map<String, Object?>;

      incoming.add(jsonEncode(<String, Object?>{
        'type': 'res',
        'id': request['id'] as String,
        'ok': true,
        'payload': <String, Object?>{'hello': true},
      }));

      await connectFuture;

      expect(capturedUri.toString(), 'wss://bot.bilirec.com');
      expect(capturedHeaders?['CF-Access-Client-Id'], 'client-id.access');
      expect(capturedHeaders?['CF-Access-Client-Secret'], 'client-secret');
    });

    test('retries with bootstrap auth when stored device token is rejected', () async {
      final incoming = StreamController<Object?>();
      final outgoing = <String>[];
      final fakeChannel = _TestWebSocketChannel(
        stream: incoming.stream,
        onAdd: (data) => outgoing.add(data as String),
      );
      final tokenStore = MemoryGatewayDeviceTokenStore();
      await tokenStore.write(
        const GatewayDeviceToken(
          deviceId: 'device-1',
          role: 'operator',
          token: 'stale-device-token',
        ),
      );

      final client = GatewayWsClient(
        config: GatewayConnectionConfig(
          url: 'ws://127.0.0.1:18789',
          connectRequest: const GatewayConnectRequestFactory().build(token: 'bootstrap-token'),
          deviceAuthProvider: _StaticDeviceAuthProvider(),
          deviceTokenStore: tokenStore,
        ),
        channelFactory: (_, __) async => fakeChannel,
      );

      final connectFuture = client.connect();

      incoming.add(jsonEncode(<String, Object?>{
        'type': 'event',
        'event': 'connect.challenge',
        'payload': <String, Object?>{'nonce': 'nonce-1'},
      }));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final firstRequest = jsonDecode(outgoing.first) as Map<String, Object?>;
      expect(
        (firstRequest['params'] as Map<String, Object?>)['auth'],
        <String, Object?>{
          'token': 'bootstrap-token',
          'deviceToken': 'stale-device-token',
        },
      );

      incoming.add(jsonEncode(<String, Object?>{
        'type': 'res',
        'id': firstRequest['id'] as String,
        'ok': false,
        'error': <String, Object?>{
          'code': 'UNAVAILABLE',
          'message': 'request failed',
          'details': <String, Object?>{
            'code': GatewayErrorCodes.authDeviceTokenMismatch,
          },
        },
      }));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(outgoing, hasLength(2));
      final secondRequest = jsonDecode(outgoing[1]) as Map<String, Object?>;
      expect(
        (secondRequest['params'] as Map<String, Object?>)['auth'],
        <String, Object?>{
          'token': 'bootstrap-token',
        },
      );

      incoming.add(jsonEncode(<String, Object?>{
        'type': 'res',
        'id': secondRequest['id'] as String,
        'ok': true,
        'payload': <String, Object?>{'hello': true},
      }));

      await connectFuture;
    });

    test('persists issued device token from hello payload', () async {
      final incoming = StreamController<Object?>();
      final outgoing = <String>[];
      final fakeChannel = _TestWebSocketChannel(
        stream: incoming.stream,
        onAdd: (data) => outgoing.add(data as String),
      );
      final tokenStore = MemoryGatewayDeviceTokenStore();

      final client = GatewayWsClient(
        config: GatewayConnectionConfig(
          url: 'ws://127.0.0.1:18789',
          connectRequest: const GatewayConnectRequestFactory().build(token: 'abc'),
          deviceAuthProvider: _StaticDeviceAuthProvider(),
          deviceTokenStore: tokenStore,
        ),
        channelFactory: (_, __) async => fakeChannel,
      );

      final connectFuture = client.connect();

      incoming.add(jsonEncode(<String, Object?>{
        'type': 'event',
        'event': 'connect.challenge',
        'payload': <String, Object?>{'nonce': 'nonce-1'},
      }));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final request = jsonDecode(outgoing.first) as Map<String, Object?>;

      incoming.add(jsonEncode(<String, Object?>{
        'type': 'res',
        'id': request['id'] as String,
        'ok': true,
        'payload': <String, Object?>{
          'auth': <String, Object?>{
            'deviceToken': 'issued-device-token',
            'role': 'operator',
            'scopes': <String>['operator.admin'],
          },
        },
      }));

      await connectFuture;

      final stored = await tokenStore.read(
        deviceId: 'device-1',
        role: 'operator',
      );
      expect(stored?.token, 'issued-device-token');
    });
  });
}

class _TestWebSocketChannel implements WebSocketChannel {
  _TestWebSocketChannel({
    required this.stream,
    required void Function(Object? data) onAdd,
  }) : sink = _TestWebSocketSink(onAdd);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  final Stream<Object?> stream;

  @override
  final WebSocketSink sink;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  Future<void> get ready => Future<void>.value();
}

class _TestWebSocketSink implements WebSocketSink {
  _TestWebSocketSink(this._onAdd);

  final void Function(Object? data) _onAdd;

  @override
  void add(Object? data) => _onAdd(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream stream) => Future<void>.value();

  @override
  Future<void> close([int? closeCode, String? closeReason]) => Future<void>.value();

  @override
  Future<void> get done => Future<void>.value();
}

class _StaticDeviceAuthProvider implements GatewayDeviceAuthProvider {
  @override
  Future<Map<String, Object?>> buildDeviceAuth({
    required ConnectChallenge challenge,
    required ConnectRequest connectRequest,
  }) async {
    return <String, Object?>{
      'id': 'device-1',
      'publicKey': 'pub',
      'signature': 'sig',
      'signedAt': 1,
      'nonce': challenge.nonce,
    };
  }
}
