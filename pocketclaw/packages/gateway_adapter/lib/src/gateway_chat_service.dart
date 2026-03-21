import 'dart:async';

import 'package:gateway_transport/gateway_transport.dart';

import 'chat_message.dart';
import 'chat_models.dart';
import 'chat_stream_event.dart';
import 'gateway_client.dart';
import 'gateway_method_names.dart';

final class GatewayChatService {
  GatewayChatService(this._client);

  final GatewayClient _client;
  int _requestCounter = 0;

  Stream<ChatStreamEvent> get stream async* {
    await for (final event in _client.events) {
      if (event.event != 'chat') {
        continue;
      }
      yield ChatStreamEvent.fromGatewayEvent(event.payload);
    }
  }

  Future<ChatHistoryResult> loadHistory({
    required String sessionKey,
    int limit = 200,
  }) async {
    final response = await _client.request(
      GatewayRequest(
        id: _nextRequestId('history'),
        method: GatewayMethodNames.chatHistory,
        params: ChatHistoryParams(
          sessionKey: sessionKey,
          limit: limit,
        ).toJson(),
      ),
    );

    final payload = response.payload ?? const <String, Object?>{};
    final rawMessages = payload['messages'];
    final messages = <ChatMessage>[];

    if (rawMessages is List<Object?>) {
      for (final item in rawMessages) {
        if (item is Map<String, Object?>) {
          messages.add(ChatMessage.fromJson(item));
        }
      }
    }

    return ChatHistoryResult(
      messages: messages,
      thinkingLevel: payload['thinkingLevel'] as String?,
    );
  }

  Future<GatewayResponse> send({
    required String sessionKey,
    required String message,
    List<Object?>? attachments,
  }) {
    return _client.request(
      GatewayRequest(
        id: _nextRequestId('send'),
        method: GatewayMethodNames.chatSend,
        params: ChatSendParams(
          sessionKey: sessionKey,
          message: message,
          attachments: attachments,
          idempotencyKey: _nextRequestId('run'),
        ).toJson(),
      ),
    );
  }

  Future<GatewayResponse> abort({required String sessionKey, String? runId}) {
    return _client.request(
      GatewayRequest(
        id: _nextRequestId('abort'),
        method: GatewayMethodNames.chatAbort,
        params: ChatAbortParams(sessionKey: sessionKey, runId: runId).toJson(),
      ),
    );
  }

  String _nextRequestId(String prefix) {
    _requestCounter += 1;
    return '$prefix-${_requestCounter.toString().padLeft(4, '0')}';
  }
}
