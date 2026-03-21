import 'gateway_message.dart';

final class GatewayRequest extends GatewayMessage {
  const GatewayRequest({required this.id, required this.method, this.params});

  final String id;
  final String method;
  final Map<String, Object?>? params;
}

extension GatewayRequestEncoding on GatewayRequest {
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'req',
    'id': id,
    'method': method,
    'params': params ?? const <String, Object?>{},
  };
}
