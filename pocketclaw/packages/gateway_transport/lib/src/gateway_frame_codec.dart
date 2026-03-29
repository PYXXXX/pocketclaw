import 'dart:convert';

import 'gateway_message.dart';
import 'gateway_parser.dart';
import 'gateway_protocol_exception.dart';
import 'gateway_request.dart';

final class GatewayFrameCodec {
  GatewayFrameCodec({GatewayParser? parser})
    : _parser = parser ?? const GatewayParser();

  final GatewayParser _parser;

  String encodeRequest(GatewayRequest request) {
    return jsonEncode(request.toJson());
  }

  GatewayMessage decodeFrame(String rawFrame) {
    final decoded = jsonDecode(rawFrame);
    if (decoded is! Map<String, Object?>) {
      throw const GatewayProtocolException(
        'Gateway frame must decode to a JSON object.',
      );
    }

    return _parser.parseFrame(decoded);
  }
}
