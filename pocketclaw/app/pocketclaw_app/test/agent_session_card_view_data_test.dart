import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:pocketclaw_app/src/app_shell/agent_session_card_view_data.dart';
import 'package:pocketclaw_app/src/app_shell/app_strings.dart';

void main() {
  const en = Locale('en');
  const zh = Locale('zh');

  test('AgentSessionCardViewData falls back to main agent when list is empty', () {
    final viewData = AgentSessionCardViewData.from(
      strings: AppStrings.fromLocale(en),
      agents: const <AgentSummary>[],
      selectedAgentId: 'main',
      gatewaySessions: const <SessionInfo>[],
      currentSessionKey: 'agent:main:pc-home',
    );

    expect(viewData.agents, hasLength(1));
    expect(viewData.agents.single.id, 'main');
    expect(viewData.agents.single.label, 'Main');
    expect(viewData.agents.single.selected, isTrue);
    expect(viewData.hasGatewaySessions, isFalse);
  });

  test('AgentSessionCardViewData sorts current session first, then selected agent matches', () {
    final viewData = AgentSessionCardViewData.from(
      strings: AppStrings.fromLocale(en),
      agents: const <AgentSummary>[
        AgentSummary(id: 'main', identityName: 'Main'),
        AgentSummary(id: 'writer', identityName: 'Writer', emoji: '✍️'),
      ],
      selectedAgentId: 'writer',
      gatewaySessions: const <SessionInfo>[
        SessionInfo(key: 'agent:main:z-last', label: 'Z Last'),
        SessionInfo(key: 'agent:writer:b-task', label: 'B Task'),
        SessionInfo(key: 'agent:writer:a-current', label: 'A Current'),
        SessionInfo(key: 'agent:other:a-foreign', label: 'A Foreign'),
      ],
      currentSessionKey: 'agent:writer:a-current',
    );

    expect(viewData.agents, hasLength(2));
    expect(viewData.agents[1].label, '✍️ Writer');
    expect(viewData.agents[1].selected, isTrue);

    expect(
      viewData.gatewaySessions.map((item) => item.session.key).toList(),
      <String>[
        'agent:writer:a-current',
        'agent:writer:b-task',
        'agent:other:a-foreign',
        'agent:main:z-last',
      ],
    );
    expect(viewData.gatewaySessions.first.isCurrent, isTrue);
  });

  test('AgentSessionCardViewData reports hidden gateway session count after truncation', () {
    final gatewaySessions = List<SessionInfo>.generate(
      10,
      (index) => SessionInfo(
        key: 'agent:main:pc-$index',
        label: 'Session $index',
      ),
    );

    final viewData = AgentSessionCardViewData.from(
      strings: AppStrings.fromLocale(en),
      agents: const <AgentSummary>[AgentSummary(id: 'main', identityName: 'Main')],
      selectedAgentId: 'main',
      gatewaySessions: gatewaySessions,
      currentSessionKey: 'agent:main:pc-0',
    );

    expect(viewData.gatewaySessions, hasLength(8));
    expect(viewData.hiddenGatewaySessionCount, 2);
    expect(viewData.hasGatewaySessions, isTrue);
  });

  test('AgentSessionCardViewData supports zh fallback labels', () {
    final viewData = AgentSessionCardViewData.from(
      strings: AppStrings.fromLocale(zh),
      agents: const <AgentSummary>[],
      selectedAgentId: 'main',
      gatewaySessions: const <SessionInfo>[],
      currentSessionKey: 'agent:main:pc-home',
    );

    expect(viewData.agents.single.label, '主助手');
  });
}
