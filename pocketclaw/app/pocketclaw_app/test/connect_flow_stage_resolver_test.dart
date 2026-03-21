import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:pocketclaw_app/src/app_shell/connect_flow_models.dart';
import 'package:pocketclaw_app/src/app_shell/connect_flow_stage_resolver.dart';

void main() {
  test(
    'resolveConnectFlowStageForError maps pairing required to pairingPending',
    () {
      final stage = resolveConnectFlowStageForError(
        const GatewayRequestError(
          code: 'UNAVAILABLE',
          message: 'pairing blocked',
          details: <String, Object?>{'code': GatewayErrorCodes.pairingRequired},
        ),
      );

      expect(stage, ConnectFlowStage.pairingPending);
    },
  );

  test(
    'resolveConnectFlowStageForError maps auth failures to authRequired',
    () {
      final stage = resolveConnectFlowStageForError(
        const GatewayRequestError(
          code: 'UNAVAILABLE',
          message: 'auth blocked',
          details: <String, Object?>{
            'code': GatewayErrorCodes.authTokenMismatch,
          },
        ),
      );

      expect(stage, ConnectFlowStage.authRequired);
    },
  );

  test('resolveConnectFlowStageForError keeps unknown failures as error', () {
    final stage = resolveConnectFlowStageForError(
      StateError('socket exploded'),
    );

    expect(stage, ConnectFlowStage.error);
  });
}
