import 'package:gateway_transport/gateway_transport.dart';

import 'agent_identity.dart';
import 'gateway_client.dart';
import 'gateway_method_names.dart';
import 'model_info.dart';

final class GatewayAgentService {
  GatewayAgentService(this._client);

  final GatewayClient _client;
  int _requestCounter = 0;

  Future<AgentIdentity> getIdentity({String? sessionKey}) async {
    final response = await _client.request(
      GatewayRequest(
        id: _nextRequestId('identity'),
        method: GatewayMethodNames.agentIdentityGet,
        params: sessionKey == null
            ? const <String, Object?>{}
            : <String, Object?>{'sessionKey': sessionKey},
      ),
    );

    return AgentIdentity.fromJson(response.payload ?? const <String, Object?>{});
  }

  Future<List<ModelInfo>> listModels() async {
    final response = await _client.request(
      GatewayRequest(
        id: _nextRequestId('models'),
        method: GatewayMethodNames.modelsList,
        params: const <String, Object?>{},
      ),
    );

    final payload = response.payload ?? const <String, Object?>{};
    final rawModels = payload['models'];
    final models = <ModelInfo>[];
    if (rawModels is List<Object?>) {
      for (final item in rawModels) {
        if (item is Map<String, Object?>) {
          models.add(ModelInfo.fromJson(item));
        }
      }
    }
    return models;
  }

  String _nextRequestId(String prefix) {
    _requestCounter += 1;
    return '$prefix-${_requestCounter.toString().padLeft(4, '0')}';
  }
}
