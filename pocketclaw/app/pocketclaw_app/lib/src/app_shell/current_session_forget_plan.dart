import 'package:pocketclaw_core/pocketclaw_core.dart';

final class CurrentSessionForgetPlan {
  const CurrentSessionForgetPlan({
    required this.removedSession,
    required this.nextSession,
  });

  final LocalSessionEntry removedSession;
  final LocalSessionEntry nextSession;

  static CurrentSessionForgetPlan? forCurrentSession({
    required List<LocalSessionEntry> sessions,
    required String currentSessionKey,
  }) {
    if (sessions.length <= 1) {
      return null;
    }

    final currentIndex = sessions.indexWhere(
      (session) => session.sessionKey.value == currentSessionKey,
    );
    if (currentIndex < 0) {
      return null;
    }

    final nextIndex = currentIndex == 0 ? 1 : currentIndex - 1;
    return CurrentSessionForgetPlan(
      removedSession: sessions[currentIndex],
      nextSession: sessions[nextIndex],
    );
  }
}
