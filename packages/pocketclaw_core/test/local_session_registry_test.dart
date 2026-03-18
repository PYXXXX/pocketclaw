import 'package:pocketclaw_core/pocketclaw_core.dart';
import 'package:test/test.dart';

void main() {
  test('LocalSessionEntry round-trips through json', () {
    const entry = LocalSessionEntry(
      sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
      title: 'Home',
    );

    final decoded = LocalSessionEntry.fromJson(entry.toJson());

    expect(decoded.sessionKey.value, entry.sessionKey.value);
    expect(decoded.title, entry.title);
  });

  test('LocalSessionRegistry round-trips through json list', () {
    final registry = LocalSessionRegistry(
      initialSessions: const <LocalSessionEntry>[
        LocalSessionEntry(
          sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
          title: 'Home',
        ),
        LocalSessionEntry(
          sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-2'),
          title: 'Second',
        ),
      ],
    );

    final decoded = LocalSessionRegistry.fromJsonList(registry.toJsonList());

    expect(decoded.sessions.length, 2);
    expect(decoded.sessions[0].sessionKey.value, 'agent:main:pc-home');
    expect(decoded.sessions[0].draftText, 'draft-1');
    expect(decoded.sessions[1].title, 'Second');
    expect(decoded.sessions[1].draftText, 'draft-2');
  });

  test('replace updates an existing session entry', () {
    final registry = LocalSessionRegistry(
      initialSessions: const <LocalSessionEntry>[
        LocalSessionEntry(
          sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
          title: 'Home',
        ),
      ],
    );

    registry.replace(
      const LocalSessionEntry(
        sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
        title: 'Home',
        draftText: 'updated draft',
      ),
    );

    expect(registry.sessions.single.draftText, 'updated draft');
  });
}
