import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

import '../chat/pending_image_attachment.dart';

typedef ChatRoleIconBuilder = IconData Function(ChatTimelineRole role);

class ChatShell extends StatelessWidget {
  const ChatShell({
    super.key,
    required this.sessions,
    required this.currentSession,
    required this.timeline,
    required this.assistantIdentity,
    required this.sessionInfo,
    required this.sessionDefaults,
    required this.agents,
    required this.selectedAgentId,
    required this.gatewaySessions,
    required this.models,
    required this.connectionState,
    required this.activeRunId,
    required this.pendingAttachments,
    required this.sessionTitleController,
    required this.messageController,
    required this.onDestinationSelected,
    required this.onSessionTitleSubmitted,
    required this.onSelectAgent,
    required this.onOpenGatewaySession,
    required this.onSelectModel,
    required this.onSelectThinking,
    required this.onSelectVerbose,
    required this.onToggleFastMode,
    required this.onPickImages,
    required this.onRemoveAttachment,
    required this.onSendMessage,
    required this.onAbortRun,
    required this.iconForRole,
  });

  final List<LocalSessionEntry> sessions;
  final LocalSessionEntry currentSession;
  final List<ChatTimelineItem> timeline;
  final AgentIdentity? assistantIdentity;
  final SessionInfo? sessionInfo;
  final SessionDefaults? sessionDefaults;
  final List<AgentSummary> agents;
  final String selectedAgentId;
  final List<SessionInfo> gatewaySessions;
  final List<ModelInfo> models;
  final GatewayConnectionState connectionState;
  final String? activeRunId;
  final List<PendingImageAttachment> pendingAttachments;
  final TextEditingController sessionTitleController;
  final TextEditingController messageController;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<String> onSessionTitleSubmitted;
  final Future<void> Function(String agentId) onSelectAgent;
  final Future<void> Function(SessionInfo session) onOpenGatewaySession;
  final Future<void> Function(String? modelId) onSelectModel;
  final Future<void> Function(String? thinkingLevel) onSelectThinking;
  final Future<void> Function(String? verboseLevel) onSelectVerbose;
  final Future<void> Function(bool enabled) onToggleFastMode;
  final Future<void> Function() onPickImages;
  final void Function(String id) onRemoveAttachment;
  final Future<void> Function() onSendMessage;
  final Future<void> Function() onAbortRun;
  final ChatRoleIconBuilder iconForRole;

  @override
  Widget build(BuildContext context) {
    final currentAgentGatewaySessions = gatewaySessions
        .where((session) => session.key.startsWith('agent:$selectedAgentId:'))
        .take(8)
        .toList();
    final selectedSessionIndex = sessions.indexWhere(
      (session) => session.sessionKey.value == currentSession.sessionKey.value,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;

        final content = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                DropdownButtonFormField<int>(
                  value: selectedSessionIndex >= 0 ? selectedSessionIndex : 0,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Session',
                  ),
                  items: [
                    for (var index = 0; index < sessions.length; index += 1)
                      DropdownMenuItem<int>(
                        value: index,
                        child: Text(sessions[index].title),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onDestinationSelected(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: sessionTitleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Session title',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: onSessionTitleSubmitted,
              ),
              const SizedBox(height: 12),
              SelectableText('Session key: ${currentSession.sessionKey.value}'),
              const SizedBox(height: 12),
              AgentSessionCard(
                agents: agents,
                selectedAgentId: selectedAgentId,
                gatewaySessions: currentAgentGatewaySessions,
                onSelectAgent: onSelectAgent,
                onOpenGatewaySession: onOpenGatewaySession,
              ),
              const SizedBox(height: 12),
              SessionInfoCard(
                identity: assistantIdentity,
                sessionInfo: sessionInfo,
                sessionDefaults: sessionDefaults,
                models: models,
                onSelectModel: onSelectModel,
                onSelectThinking: onSelectThinking,
                onSelectVerbose: onSelectVerbose,
                onToggleFastMode: onToggleFastMode,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: timeline.isEmpty
                        ? const Align(
                            alignment: Alignment.topLeft,
                            child: Text('Timeline is empty.'),
                          )
                        : ListView.separated(
                            itemCount: timeline.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = timeline[index];
                              return TimelineEntryCard(
                                item: item,
                                icon: iconForRole(item.role),
                                compact: compact,
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (pendingAttachments.isNotEmpty) ...[
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pendingAttachments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final attachment = pendingAttachments[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(attachment.base64Content),
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => onRemoveAttachment(attachment.id),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (compact) ...[
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: pendingAttachments.isEmpty
                        ? 'Send a message'
                        : 'Add a caption or send images directly',
                  ),
                  minLines: 1,
                  maxLines: 6,
                  onSubmitted: (_) => unawaited(onSendMessage()),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: connectionState.phase == GatewayConnectionPhase.connected
                          ? () => unawaited(onPickImages())
                          : null,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Image'),
                    ),
                    FilledButton(
                      onPressed: connectionState.phase == GatewayConnectionPhase.connected
                          ? onSendMessage
                          : null,
                      child: const Text('Send'),
                    ),
                    OutlinedButton(
                      onPressed: activeRunId != null ? onAbortRun : null,
                      child: const Text('Stop'),
                    ),
                  ],
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: connectionState.phase == GatewayConnectionPhase.connected
                          ? () => unawaited(onPickImages())
                          : null,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      tooltip: 'Add image',
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: pendingAttachments.isEmpty
                              ? 'Send a message'
                              : 'Add a caption or send images directly',
                        ),
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => unawaited(onSendMessage()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: connectionState.phase == GatewayConnectionPhase.connected
                          ? onSendMessage
                          : null,
                      child: const Text('Send'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: activeRunId != null ? onAbortRun : null,
                      child: const Text('Stop'),
                    ),
                  ],
                ),
            ],
          ),
        );

        if (compact) {
          return content;
        }

        return Row(
          children: [
            NavigationRail(
              selectedIndex: selectedSessionIndex >= 0 ? selectedSessionIndex : 0,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final session in sessions)
                  NavigationRailDestination(
                    icon: const Icon(Icons.chat_bubble_outline),
                    selectedIcon: const Icon(Icons.chat_bubble),
                    label: Text(session.title),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}

class AgentSessionCard extends StatelessWidget {
  const AgentSessionCard({
    super.key,
    required this.agents,
    required this.selectedAgentId,
    required this.gatewaySessions,
    required this.onSelectAgent,
    required this.onOpenGatewaySession,
  });

  final List<AgentSummary> agents;
  final String selectedAgentId;
  final List<SessionInfo> gatewaySessions;
  final Future<void> Function(String agentId) onSelectAgent;
  final Future<void> Function(SessionInfo session) onOpenGatewaySession;

  @override
  Widget build(BuildContext context) {
    final effectiveAgents = agents.isEmpty
        ? const <AgentSummary>[AgentSummary(id: 'main', name: 'Main')]
        : agents;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agent & session source',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final agent in effectiveAgents)
                  ChoiceChip(
                    label: Text(
                      agent.emoji == null
                          ? agent.displayName
                          : '${agent.emoji} ${agent.displayName}',
                    ),
                    selected: agent.id == selectedAgentId,
                    onSelected: (_) => unawaited(onSelectAgent(agent.id)),
                  ),
              ],
            ),
            if (gatewaySessions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Existing Gateway sessions',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final session in gatewaySessions)
                    ActionChip(
                      avatar: const Icon(Icons.history, size: 18),
                      label: Text(session.label ?? session.key),
                      onPressed: () => unawaited(onOpenGatewaySession(session)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TimelineEntryCard extends StatelessWidget {
  const TimelineEntryCard({
    super.key,
    required this.item,
    required this.icon,
    required this.compact,
  });

  final ChatTimelineItem item;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = item.role == ChatTimelineRole.user;
    final isTool = item.role == ChatTimelineRole.tool;
    final isSystem = item.role == ChatTimelineRole.system;

    final backgroundColor = isUser
        ? colorScheme.primaryContainer
        : isTool
            ? colorScheme.tertiaryContainer
            : isSystem
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerLow;
    final foregroundColor = isUser
        ? colorScheme.onPrimaryContainer
        : isTool
            ? colorScheme.onTertiaryContainer
            : isSystem
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final maxWidth = compact ? double.infinity : 560.0;
    final title = item.title ??
        switch (item.role) {
          ChatTimelineRole.system => 'System',
          ChatTimelineRole.user => 'You',
          ChatTimelineRole.assistant => 'Assistant',
          ChatTimelineRole.tool => 'Tool',
        };
    final badgeLabel = item.status ?? (item.isStreaming ? 'streaming' : null);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: foregroundColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (badgeLabel != null && badgeLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foregroundColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                item.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.createdAt.toIso8601String(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.8),
                ),
              ),
              if (item.details != null && item.details!.isNotEmpty) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'Details',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                    ),
                  ),
                  iconColor: foregroundColor,
                  collapsedIconColor: foregroundColor,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        item.details!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foregroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionSettingChip extends StatelessWidget {
  const _SessionSettingChip({
    required this.label,
    required this.value,
    required this.inherited,
  });

  final String label;
  final String value;
  final bool inherited;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        inherited ? Icons.keyboard_return : Icons.tune,
        size: 18,
      ),
      label: Text('$label: $value'),
    );
  }
}

class SessionInfoCard extends StatelessWidget {
  const SessionInfoCard({
    super.key,
    required this.identity,
    required this.sessionInfo,
    required this.sessionDefaults,
    required this.models,
    required this.onSelectModel,
    required this.onSelectThinking,
    required this.onSelectVerbose,
    required this.onToggleFastMode,
  });

  final AgentIdentity? identity;
  final SessionInfo? sessionInfo;
  final SessionDefaults? sessionDefaults;
  final List<ModelInfo> models;
  final Future<void> Function(String? modelId) onSelectModel;
  final Future<void> Function(String? thinkingLevel) onSelectThinking;
  final Future<void> Function(String? verboseLevel) onSelectVerbose;
  final Future<void> Function(bool enabled) onToggleFastMode;
  final Future<void> Function() onClearFastModeOverride;

  @override
  Widget build(BuildContext context) {
    const defaultModelValue = '__default_model__';
    const defaultThinkingValue = '__default_thinking__';
    const defaultVerboseValue = '__default_verbose__';
    const thinkingChoices = <String>['off', 'minimal', 'low', 'medium', 'high'];
    const verboseChoices = <String>['off', 'low', 'medium', 'high'];

    final currentModelOverride = sessionInfo?.model;
    final currentThinkingOverride = sessionInfo?.thinkingLevel;
    final currentVerboseOverride = sessionInfo?.verboseLevel;
    final inheritedModel = sessionDefaults?.model;
    final inheritedThinking = sessionDefaults?.thinkingLevel;
    final inheritedVerbose = sessionDefaults?.verboseLevel;
    final inheritedFastMode = sessionDefaults?.fastMode;
    final modelIds = models.map((model) => model.id).toSet();

    final currentModelValue = currentModelOverride == null
        ? defaultModelValue
        : currentModelOverride;
    final currentThinkingValue = currentThinkingOverride != null &&
            thinkingChoices.contains(currentThinkingOverride)
        ? currentThinkingOverride
        : defaultThinkingValue;
    final currentVerboseValue = currentVerboseOverride != null &&
            verboseChoices.contains(currentVerboseOverride)
        ? currentVerboseOverride
        : defaultVerboseValue;
    final fastMode = sessionInfo?.fastMode ?? inheritedFastMode ?? false;

    final modelDefaultLabel = inheritedModel ?? 'gateway default';
    final thinkingDefaultLabel = inheritedThinking ?? 'gateway default';
    final verboseDefaultLabel = inheritedVerbose ?? 'gateway default';
    final fastModeSummary = sessionInfo?.fastMode == null
        ? 'Inheriting default · ${inheritedFastMode == null ? 'gateway default' : inheritedFastMode ? 'on' : 'off'}'
        : 'Override active · ${fastMode ? 'on' : 'off'}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              identity?.name ?? 'Assistant',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SessionSettingChip(
                  label: 'Model',
                  value: currentModelOverride ?? modelDefaultLabel,
                  inherited: currentModelOverride == null,
                ),
                _SessionSettingChip(
                  label: 'Thinking',
                  value: currentThinkingOverride ?? thinkingDefaultLabel,
                  inherited: currentThinkingOverride == null,
                ),
                _SessionSettingChip(
                  label: 'Verbose',
                  value: currentVerboseOverride ?? verboseDefaultLabel,
                  inherited: currentVerboseOverride == null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: DropdownButtonFormField<String>(
                    initialValue: currentModelValue,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Model',
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: defaultModelValue,
                        child: Text('Default (inherit: $modelDefaultLabel)'),
                      ),
                      if (currentModelOverride != null &&
                          !modelIds.contains(currentModelOverride))
                        DropdownMenuItem<String>(
                          value: currentModelOverride,
                          child: Text('$currentModelOverride (current)'),
                        ),
                      for (final model in models)
                        DropdownMenuItem<String>(
                          value: model.id,
                          child: Text(model.id),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      unawaited(
                        onSelectModel(
                          value == defaultModelValue ? null : value,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: currentThinkingValue,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Thinking',
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: defaultThinkingValue,
                        child: Text('Default ($thinkingDefaultLabel)'),
                      ),
                      for (final value in thinkingChoices)
                        DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                    ],
                    onChanged: (value) => unawaited(
                      onSelectThinking(
                        value == defaultThinkingValue ? null : value,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: currentVerboseValue,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Verbose',
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: defaultVerboseValue,
                        child: Text('Default ($verboseDefaultLabel)'),
                      ),
                      for (final value in verboseChoices)
                        DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                    ],
                    onChanged: (value) => unawaited(
                      onSelectVerbose(
                        value == defaultVerboseValue ? null : value,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fast mode'),
              subtitle: Text('Maps to sessions.patch fastMode · $fastModeSummary'),
              value: fastMode,
              onChanged: (value) => unawaited(onToggleFastMode(value)),
            ),
            if (sessionInfo?.fastMode != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => unawaited(onClearFastModeOverride()),
                  icon: const Icon(Icons.keyboard_return),
                  label: Text(
                    'Use default fast mode (${inheritedFastMode == null ? 'gateway default' : inheritedFastMode ? 'on' : 'off'})',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
