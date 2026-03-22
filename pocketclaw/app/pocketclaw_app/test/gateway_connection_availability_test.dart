import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:pocketclaw_app/src/app_shell/gateway_connection_availability.dart';

void main() {
  group('canAttemptGatewayConnect', () {
    test('allows connect only when transport is idle and setup is done', () {
      expect(
        canAttemptGatewayConnect(
          phase: GatewayConnectionPhase.disconnected,
          isBootstrapping: false,
          isApplyingConfiguration: false,
          isRefreshingClient: false,
        ),
        isTrue,
      );
    });

    test('blocks connect while bootstrapping or refreshing client', () {
      expect(
        canAttemptGatewayConnect(
          phase: GatewayConnectionPhase.disconnected,
          isBootstrapping: true,
          isApplyingConfiguration: false,
          isRefreshingClient: false,
        ),
        isFalse,
      );
      expect(
        canAttemptGatewayConnect(
          phase: GatewayConnectionPhase.disconnected,
          isBootstrapping: false,
          isApplyingConfiguration: false,
          isRefreshingClient: true,
        ),
        isFalse,
      );
    });
  });
}
