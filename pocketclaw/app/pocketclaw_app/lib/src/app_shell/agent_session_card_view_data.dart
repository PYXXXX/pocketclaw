import 'package:gateway_adapter/gateway_adapter.dart';

final class AgentSessionCardViewData {
  const AgentSessionCardViewData({
    required this.agents,
    required this.gatewaySessions,
    required this.hiddenGatewaySessionCount,
    required this.hasGatewaySessions,
  });

  final List<AgentChipViewData> agents;
  final List<GatewaySessionChipViewData> gatewaySessions;
  final int hiddenGatewaySessionCount;
  final bool hasGatewaySessions;

  factory AgentSessionCardViewData.from({
    required List<AgentSummary> agents,
    required String selectedAgentId,
    required List<SessionInfo> gatewaySessions,
    required String currentSessionKey,
    int maxGatewaySessions = 8,
  }) {
    final effectiveAgents = agents.isEmpty
        ? const <AgentSummary>[AgentSummary(id: 'main', name: 'Main')]
        : agents;

    final sortedGatewaySessions = [...gatewaySessions]
      ..sort((left, right) {
        final leftCurrent = left.key == currentSessionKey ? 1 : 0;
        final rightCurrent = right.key == currentSessionKey ? 1 : 0;
        if (leftCurrent != rightCurrent) {
          return rightCurrent.compareTo(leftCurrent);
        }

        final leftAgentMatch = left.key.startsWith('agent:$selectedAgentId:')
            ? 1
            : 0;
        final rightAgentMatch = right.key.startsWith('agent:$selectedAgentId:')
            ? 1
            : 0;
        if (leftAgentMatch != rightAgentMatch) {
          return rightAgentMatch.compareTo(leftAgentMatch);
        }

        final leftLabel = left.label?.trim() ?? left.key;
        final rightLabel = right.label?.trim() ?? right.key;
        return leftLabel.compareTo(rightLabel);
      });

    final visibleSessions = sortedGatewaySessions.take(maxGatewaySessions).toList();
    return AgentSessionCardViewData(
      agents: effectiveAgents
          .map(
            (agent) => AgentChipViewData(
              id: agent.id,
              label: agent.emoji == null
                  ? agent.displayName
                  : '${agent.emoji} ${agent.displayName}',
              selected: agent.id == selectedAgentId,
            ),
          )
          .toList(),
      gatewaySessions: visibleSessions
          .map(
            (session) => GatewaySessionChipViewData(
              session: session,
              label: session.label?.trim().isNotEmpty == true
                  ? session.label!.trim()
                  : session.key,
              isCurrent: session.key == currentSessionKey,
            ),
          )
          .toList(),
      hiddenGatewaySessionCount:
          sortedGatewaySessions.length > maxGatewaySessions
              ? sortedGatewaySessions.length - maxGatewaySessions
              : 0,
      hasGatewaySessions: sortedGatewaySessions.isNotEmpty,
    );
  }
}

final class AgentChipViewData {
  const AgentChipViewData({
    required this.id,
    required this.label,
    required this.selected,
  });

  final String id;
  final String label;
  final bool selected;
}

final class GatewaySessionChipViewData {
  const GatewaySessionChipViewData({
    required this.session,
    required this.label,
    required this.isCurrent,
  });

  final SessionInfo session;
  final String label;
  final bool isCurrent;
}
