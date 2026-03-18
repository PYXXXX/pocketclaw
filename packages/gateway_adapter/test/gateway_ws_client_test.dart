import 'dart:async';
import 'dart:convert';

import 'package:gateway_adapter/gateway_adapter.dart';
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
        channelFactory: (_) => fakeChannel,
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
        channelFactory: (_) => fakeChannel,
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
