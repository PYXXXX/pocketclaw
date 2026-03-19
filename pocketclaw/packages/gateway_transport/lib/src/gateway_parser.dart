import 'connect_models.dart';
import 'gateway_event.dart';
import 'gateway_protocol_exception.dart';
import 'gateway_request.dart';
import 'gateway_response.dart';

final class GatewayParser {
  const GatewayParser();

  GatewayMessage parseFrame(Map<String, Object?> json) {
    final type = json['type'];
    if (type is! String) {
      throw const GatewayProtocolException('Missing frame type.');
    }

    switch (type) {
      case 'req':
        return _parseRequest(json);
      case 'res':
        return _parseResponse(json);
      case 'event':
        return _parseEvent(json);
      default:
        throw GatewayProtocolException('Unsupported frame type: $type');
    }
  }

  ConnectChallenge? parseConnectChallenge(GatewayEvent event) {
    if (event.event != 'connect.challenge') {
      return null;
    }

    final nonce = event.payload['nonce'];
    if (nonce is! String || nonce.isEmpty) {
      throw const GatewayProtocolException('Invalid connect challenge nonce.');
    }

    final timestampMs = event.payload['ts'];
    return ConnectChallenge(
      nonce: nonce,
      timestampMs: timestampMs is int ? timestampMs : null,
    );
  }

  GatewayRequest _parseRequest(Map<String, Object?> json) {
    final id = json['id'];
    final method = json['method'];
    final params = json['params'];

    if (id is! String || method is! String) {
      throw const GatewayProtocolException('Invalid request frame.');
    }

    return GatewayRequest(
      id: id,
      method: method,
      params: params is Map<String, Object?> ? params : null,
    );
  }

  GatewayResponse _parseResponse(Map<String, Object?> json) {
    final id = json['id'];
    final ok = json['ok'];
    final payload = json['payload'];
    final error = json['error'];

    if (id is! String || ok is! bool) {
      throw const GatewayProtocolException('Invalid response frame.');
    }

    return GatewayResponse(
      id: id,
      ok: ok,
      payload: payload is Map<String, Object?> ? payload : null,
      error: error is Map<String, Object?> ? error : null,
    );
  }

  GatewayEvent _parseEvent(Map<String, Object?> json) {
    final event = json['event'];
    final payload = json['payload'];
    final seq = json['seq'];

    if (event is! String || payload is! Map<String, Object?>) {
      throw const GatewayProtocolException('Invalid event frame.');
    }

    return GatewayEvent(
      event: event,
      payload: payload,
      seq: seq is int ? seq : null,
    );
  }
}
