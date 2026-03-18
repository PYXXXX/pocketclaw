import 'dart:async';

import 'package:gateway_transport/gateway_transport.dart';

import 'connectable_gateway_client.dart';
import 'gateway_method_names.dart';

final class FakeGatewayClient implements ConnectableGatewayClient {
  FakeGatewayClient()
      : _messagesBySession = <String, List<Map<String, Object?>>>{
          'agent:main:pc-home': <Map<String, Object?>>[
            _message(
              role: 'assistant',
              text: 'PocketClaw scaffold is ready. Connect and start chatting.',
            ),
          ],
        },
        _sessionStateByKey = <String, Map<String, Object?>>{
          'agent:main:pc-home': <String, Object?>{
            'key': 'agent:main:pc-home',
            'label': 'Home',
            'model': 'codex-lb-responses/gpt-5.4',
            'thinkingLevel': 'off',
            'fastMode': false,
            'verboseLevel': 'off',
          },
        };

  final StreamController<GatewayEvent> _eventController =
      StreamController<GatewayEvent>.broadcast();
  final StreamController<GatewayConnectionState> _connectionController =
      StreamController<GatewayConnectionState>.broadcast();
  final Map<String, List<Map<String, Object?>>> _messagesBySession;
  final Map<String, Map<String, Object?>> _sessionStateByKey;

  GatewayConnectionState _state = const GatewayConnectionState(
    phase: GatewayConnectionPhase.disconnected,
  );
  String? _activeRunId;
  String? _activeSessionKey;
  Timer? _pendingFinalTimer;

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
    _pendingFinalTimer?.cancel();
    _pendingFinalTimer = null;
    _activeRunId = null;
    _activeSessionKey = null;
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
        return _chatHistory(request);
      case GatewayMethodNames.chatSend:
        return _chatSend(request);
      case GatewayMethodNames.chatAbort:
        return _chatAbort(request);
      case GatewayMethodNames.sessionsList:
        return _sessionsList(request);
      case GatewayMethodNames.sessionsPatch:
        return _sessionsPatch(request);
      case GatewayMethodNames.agentIdentityGet:
        return GatewayResponse(
          id: request.id,
          ok: true,
          payload: const <String, Object?>{
            'agentId': 'main',
            'name': 'Qingzhou Bot',
            'avatar': null,
          },
        );
      case GatewayMethodNames.modelsList:
        return GatewayResponse(
          id: request.id,
          ok: true,
          payload: const <String, Object?>{
            'models': <Map<String, Object?>>[
              <String, Object?>{
                'id': 'codex-lb-responses/gpt-5.4',
                'provider': 'codex-lb-responses',
              },
              <String, Object?>{
                'id': 'codex-lb/gpt-5.4',
                'provider': 'codex-lb',
              },
            ],
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

  GatewayResponse _chatHistory(GatewayRequest request) {
    final sessionKey = request.params?['sessionKey'] as String? ?? 'unknown';
    final messages = _messagesBySession[sessionKey] ?? const <Map<String, Object?>>[];
    final sessionState = _sessionStateByKey[sessionKey] ?? const <String, Object?>{};
    return GatewayResponse(
      id: request.id,
      ok: true,
      payload: <String, Object?>{
        'messages': messages,
        'thinkingLevel': sessionState['thinkingLevel'] ?? 'off',
      },
    );
  }

  GatewayResponse _chatSend(GatewayRequest request) {
    final sessionKey = request.params?['sessionKey'] as String? ?? 'unknown';
    final message = request.params?['message'] as String? ?? '';
    final runId = request.params?['idempotencyKey'] as String? ?? request.id;

    final messages = _messagesBySession.putIfAbsent(sessionKey, () => <Map<String, Object?>>[]);
    _sessionStateByKey.putIfAbsent(
      sessionKey,
      () => <String, Object?>{
        'key': sessionKey,
        'label': sessionKey.split(':').last,
        'model': 'codex-lb-responses/gpt-5.4',
        'thinkingLevel': 'off',
        'fastMode': false,
        'verboseLevel': 'off',
      },
    );
    messages.add(_message(role: 'user', text: message));

    _activeRunId = runId;
    _activeSessionKey = sessionKey;
    final reply = 'Echo from PocketClaw fake client: $message';

    _eventController.add(
      GatewayEvent(
        event: 'chat',
        payload: <String, Object?>{
          'sessionKey': sessionKey,
          'runId': runId,
          'state': 'delta',
          'message': _message(role: 'assistant', text: reply),
        },
      ),
    );

    _pendingFinalTimer?.cancel();
    _pendingFinalTimer = Timer(const Duration(milliseconds: 250), () {
      messages.add(_message(role: 'assistant', text: reply));
      _eventController.add(
        GatewayEvent(
          event: 'chat',
          payload: <String, Object?>{
            'sessionKey': sessionKey,
            'runId': runId,
            'state': 'final',
            'message': _message(role: 'assistant', text: reply),
          },
        ),
      );
      _activeRunId = null;
      _activeSessionKey = null;
      _pendingFinalTimer = null;
    });

    return GatewayResponse(
      id: request.id,
      ok: true,
      payload: <String, Object?>{
        'runId': runId,
        'status': 'started',
      },
    );
  }

  GatewayResponse _chatAbort(GatewayRequest request) {
    final sessionKey = request.params?['sessionKey'] as String? ?? _activeSessionKey ?? 'unknown';
    final runId = request.params?['runId'] as String? ?? _activeRunId;

    _pendingFinalTimer?.cancel();
    _pendingFinalTimer = null;

    if (runId != null) {
      _eventController.add(
        GatewayEvent(
          event: 'chat',
          payload: <String, Object?>{
            'sessionKey': sessionKey,
            'runId': runId,
            'state': 'aborted',
            'message': _message(role: 'assistant', text: 'Run aborted.'),
          },
        ),
      );
    }

    _activeRunId = null;
    _activeSessionKey = null;

    return GatewayResponse(
      id: request.id,
      ok: true,
      payload: const <String, Object?>{'aborted': true},
    );
  }

  GatewayResponse _sessionsList(GatewayRequest request) {
    return GatewayResponse(
      id: request.id,
      ok: true,
      payload: <String, Object?>{
        'sessions': _sessionStateByKey.values.toList(),
        'defaults': const <String, Object?>{
          'model': 'codex-lb-responses/gpt-5.4',
        },
      },
    );
  }

  GatewayResponse _sessionsPatch(GatewayRequest request) {
    final key = request.params?['key'] as String? ?? 'unknown';
    final state = _sessionStateByKey.putIfAbsent(
      key,
      () => <String, Object?>{'key': key},
    );

    for (final entry in request.params?.entries ?? const Iterable<MapEntry<String, Object?>>.empty()) {
      if (entry.key == 'key') {
        continue;
      }
      state[entry.key] = entry.value;
    }

    return GatewayResponse(
      id: request.id,
      ok: true,
      payload: state,
    );
  }

  void _emitState(GatewayConnectionState state) {
    _state = state;
    _connectionController.add(state);
  }

  static Map<String, Object?> _message({
    required String role,
    required String text,
  }) {
    return <String, Object?>{
      'role': role,
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
      'content': <Map<String, Object?>>[
        <String, Object?>{
          'type': 'text',
          'text': text,
        },
      ],
    };
  }
}
