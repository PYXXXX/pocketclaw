import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/app_shell/current_session_header_view_data.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

void main() {
  LocalSessionEntry localSession({String draftText = ''}) {
    return LocalSessionEntry(
      sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
      title: 'Home',
      draftText: draftText,
    );
  }

  LocalSessionEntry gatewaySession({String draftText = ''}) {
    return LocalSessionEntry(
      sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-2'),
      title: 'Second',
      draftText: draftText,
      origin: LocalSessionOrigin.gateway,
      gatewayLabel: 'Remote Second',
    );
  }

  test('CurrentSessionHeaderViewData describes local sessions', () {
    final viewData = CurrentSessionHeaderViewData.from(
      localSession(draftText: 'hello'),
      canForgetCurrentSession: true,
    );

    expect(viewData.sessionKeyText, 'Session key: agent:main:pc-home');
    expect(viewData.sourceLabel, 'Local PocketClaw session');
    expect(viewData.isGatewayBacked, isFalse);
    expect(viewData.gatewayLabel, isNull);
    expect(viewData.hasLocalDraft, isTrue);
    expect(viewData.draftStatusLabel, 'Draft saved locally');
    expect(viewData.forgetActionLabel, 'Remove from phone');
    expect(viewData.forgetDialogTitle, 'Remove this local session?');
    expect(viewData.forgetConfirmLabel, 'Remove');
    expect(viewData.cannotForgetHint, isNull);
  });

  test('CurrentSessionHeaderViewData describes gateway shortcuts', () {
    final viewData = CurrentSessionHeaderViewData.from(
      gatewaySession(),
      canForgetCurrentSession: true,
    );

    expect(viewData.sourceLabel, 'Gateway session');
    expect(viewData.isGatewayBacked, isTrue);
    expect(viewData.gatewayLabel, 'Remote Second');
    expect(viewData.hasLocalDraft, isFalse);
    expect(viewData.draftStatusLabel, 'No local draft');
    expect(viewData.forgetActionLabel, 'Forget local shortcut');
    expect(viewData.forgetDialogTitle, 'Forget this Gateway shortcut?');
    expect(viewData.forgetConfirmLabel, 'Forget shortcut');
  });

  test('CurrentSessionHeaderViewData reports keep-one-session hint', () {
    final viewData = CurrentSessionHeaderViewData.from(
      localSession(),
      canForgetCurrentSession: false,
    );

    expect(viewData.cannotForgetHint, 'Keep at least one session on this device.');
  });
}
