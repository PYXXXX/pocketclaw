import 'package:flutter/foundation.dart';

@immutable
final class PendingImageAttachment {
  const PendingImageAttachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.base64Content,
  });

  final String id;
  final String name;
  final String mimeType;
  final String base64Content;

  String get dataUrl => 'data:$mimeType;base64,$base64Content';

  Map<String, Object?> toGatewayAttachment() {
    return <String, Object?>{
      'type': 'image',
      'name': name,
      'mimeType': mimeType,
      'content': base64Content,
    };
  }
}
