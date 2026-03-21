import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/app_shell/current_session_forget_plan.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

void main() {
  LocalSessionEntry session(String clientKey) {
    return LocalSessionEntry(
      sessionKey: SessionKey.forClient(agentId: 'main', clientKey: clientKey),
      title: clientKey,
    );
  }

  test(
    'CurrentSessionForgetPlan returns null when only one session exists',
    () {
      final plan = CurrentSessionForgetPlan.forCurrentSession(
        sessions: <LocalSessionEntry>[session('pc-home')],
        currentSessionKey: 'agent:main:pc-home',
      );

      expect(plan, isNull);
    },
  );

  test(
    'CurrentSessionForgetPlan picks the next session when removing first',
    () {
      final sessions = <LocalSessionEntry>[
        session('pc-home'),
        session('pc-2'),
        session('pc-3'),
      ];

      final plan = CurrentSessionForgetPlan.forCurrentSession(
        sessions: sessions,
        currentSessionKey: 'agent:main:pc-home',
      );

      expect(plan, isNotNull);
      expect(plan!.removedSession.sessionKey.value, 'agent:main:pc-home');
      expect(plan.nextSession.sessionKey.value, 'agent:main:pc-2');
    },
  );

  test(
    'CurrentSessionForgetPlan picks previous session when removing middle or last',
    () {
      final sessions = <LocalSessionEntry>[
        session('pc-home'),
        session('pc-2'),
        session('pc-3'),
      ];

      final middlePlan = CurrentSessionForgetPlan.forCurrentSession(
        sessions: sessions,
        currentSessionKey: 'agent:main:pc-2',
      );
      final lastPlan = CurrentSessionForgetPlan.forCurrentSession(
        sessions: sessions,
        currentSessionKey: 'agent:main:pc-3',
      );

      expect(middlePlan, isNotNull);
      expect(middlePlan!.nextSession.sessionKey.value, 'agent:main:pc-home');

      expect(lastPlan, isNotNull);
      expect(lastPlan!.nextSession.sessionKey.value, 'agent:main:pc-2');
    },
  );
}
