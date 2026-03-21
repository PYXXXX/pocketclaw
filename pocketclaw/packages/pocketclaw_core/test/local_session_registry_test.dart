import 'package:pocketclaw_core/pocketclaw_core.dart';
import 'package:test/test.dart';

void main() {
  test('LocalSessionEntry round-trips through json', () {
    final entry = LocalSessionEntry(
      sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
      title: 'Home',
      origin: LocalSessionOrigin.gateway,
      gatewayLabel: 'Gateway Home',
    );

    final decoded = LocalSessionEntry.fromJson(entry.toJson());

    expect(decoded.sessionKey.value, entry.sessionKey.value);
    expect(decoded.title, entry.title);
    expect(decoded.origin, LocalSessionOrigin.gateway);
    expect(decoded.gatewayLabel, 'Gateway Home');
  });

  test('LocalSessionRegistry round-trips through json list', () {
    final registry = LocalSessionRegistry(
      initialSessions: <LocalSessionEntry>[
        LocalSessionEntry(
          sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
          title: 'Home',
          draftText: 'draft-1',
        ),
        LocalSessionEntry(
          sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-2'),
          title: 'Second',
          draftText: 'draft-2',
          origin: LocalSessionOrigin.gateway,
          gatewayLabel: 'Remote Second',
        ),
      ],
    );

    final decoded = LocalSessionRegistry.fromJsonList(registry.toJsonList());

    expect(decoded.sessions.length, 2);
    expect(decoded.sessions[0].sessionKey.value, 'agent:main:pc-home');
    expect(decoded.sessions[0].draftText, 'draft-1');
    expect(decoded.sessions[1].title, 'Second');
    expect(decoded.sessions[1].draftText, 'draft-2');
    expect(decoded.sessions[1].origin, LocalSessionOrigin.gateway);
    expect(decoded.sessions[1].gatewayLabel, 'Remote Second');
  });

  test('replace updates an existing session entry', () {
    final registry = LocalSessionRegistry(
      initialSessions: <LocalSessionEntry>[
        LocalSessionEntry(
          sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
          title: 'Home',
        ),
      ],
    );

    registry.replace(
      LocalSessionEntry(
        sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
        title: 'Home',
        draftText: 'updated draft',
        origin: LocalSessionOrigin.gateway,
        gatewayLabel: 'Gateway Home',
      ),
    );

    expect(registry.sessions.single.draftText, 'updated draft');
    expect(registry.sessions.single.origin, LocalSessionOrigin.gateway);
    expect(registry.sessions.single.gatewayLabel, 'Gateway Home');
  });

  test('findBySessionKey returns a matching entry', () {
    final registry = LocalSessionRegistry(
      initialSessions: <LocalSessionEntry>[
        LocalSessionEntry(
          sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
          title: 'Home',
        ),
      ],
    );

    final found = registry.findBySessionKey('agent:main:pc-home');

    expect(found, isNotNull);
    expect(found?.title, 'Home');
  });
}
