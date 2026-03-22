import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/app_shell/gateway_connection_diagnostics.dart';

void main() {
  test('formatGatewayConnectionDiagnostics prints draft saved and live fields',
      () {
    final text = formatGatewayConnectionDiagnostics(
      draftUrl: 'wss://draft.example.com/',
      savedUrl: 'wss://saved.example.com/',
      liveClientUrl: 'wss://live.example.com/',
      isBootstrapping: false,
      isApplyingConfiguration: true,
      isRefreshingClient: false,
      hasDraftToken: true,
      hasSavedToken: false,
      hasLiveClientToken: true,
      hasDraftPassword: false,
      hasSavedPassword: false,
      hasLiveClientPassword: true,
      draftHeaderCount: 2,
      savedHeaderCount: 1,
      liveClientHeaderCount: 3,
    );

    expect(text, contains('draft.url=wss://draft.example.com/'));
    expect(text, contains('saved.url=wss://saved.example.com/'));
    expect(text, contains('live.url=wss://live.example.com/'));
    expect(text, contains('state.applyingConfiguration=yes'));
    expect(text, contains('live.headerCount=3'));
  });
}
