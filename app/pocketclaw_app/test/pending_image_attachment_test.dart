import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/chat/pending_image_attachment.dart';

void main() {
  test('pending image attachment converts to gateway image payload', () {
    const attachment = PendingImageAttachment(
      id: 'att-1',
      name: 'demo.png',
      mimeType: 'image/png',
      base64Content: 'aGVsbG8=',
    );

    expect(
      attachment.toGatewayAttachment(),
      <String, Object?>{
        'type': 'image',
        'mimeType': 'image/png',
        'content': 'aGVsbG8=',
      },
    );
    expect(
      attachment.dataUrl,
      'data:image/png;base64,aGVsbG8=',
    );
  });
}
