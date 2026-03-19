import 'package:gateway_transport/gateway_transport.dart';

import 'gateway_client.dart';
import 'gateway_method_names.dart';
import 'session_info.dart';
import 'session_models.dart';

final class GatewaySessionService {
  GatewaySessionService(this._client);

  final GatewayClient _client;
  int _requestCounter = 0;

  Future<SessionsListResult> list({SessionsListParams params = const SessionsListParams()}) async {
    final response = await _client.request(
      GatewayRequest(
        id: _nextRequestId('sessions'),
        method: GatewayMethodNames.sessionsList,
        params: params.toJson(),
      ),
    );

    final payload = response.payload ?? const <String, Object?>{};
    final rawSessions = payload['sessions'];
    final sessions = <SessionInfo>[];
    if (rawSessions is List<Object?>) {
      for (final item in rawSessions) {
        if (item is Map<String, Object?>) {
          sessions.add(SessionInfo.fromJson(item));
        }
      }
    }

    final defaults = payload['defaults'];
    return SessionsListResult(
      sessions: sessions,
      defaults: defaults is Map<String, Object?>
          ? SessionDefaults.fromJson(defaults)
          : null,
    );
  }

  Future<GatewayResponse> patch(SessionPatchParams params) {
    return _client.request(
      GatewayRequest(
        id: _nextRequestId('session-patch'),
        method: GatewayMethodNames.sessionsPatch,
        params: params.toJson(),
      ),
    );
  }

  String _nextRequestId(String prefix) {
    _requestCounter += 1;
    return '$prefix-${_requestCounter.toString().padLeft(4, '0')}';
  }
}
