import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

import '../chat/pending_image_attachment.dart';
import 'agent_session_card_view_data.dart';
import 'app_strings.dart';
import 'current_session_header.dart';
import 'session_info_view_data.dart';

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
    required this.onForgetCurrentSession,
    required this.onSelectModel,
    required this.onSelectThinking,
    required this.onSelectVerbose,
    required this.onToggleFastMode,
    required this.onClearFastModeOverride,
    required this.notificationsEnabled,
    required this.showNotificationBody,
    required this.currentSessionNotificationsMuted,
    required this.onSetNotificationsEnabled,
    required this.onSetShowNotificationBody,
    required this.onToggleCurrentSessionNotificationMute,
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
  final Future<void> Function() onForgetCurrentSession;
  final Future<void> Function(String? modelId) onSelectModel;
  final Future<void> Function(String? thinkingLevel) onSelectThinking;
  final Future<void> Function(String? verboseLevel) onSelectVerbose;
  final Future<void> Function(bool enabled) onToggleFastMode;
  final Future<void> Function() onClearFastModeOverride;
  final bool notificationsEnabled;
  final bool showNotificationBody;
  final bool currentSessionNotificationsMuted;
  final Future<void> Function(bool enabled) onSetNotificationsEnabled;
  final Future<void> Function(bool enabled) onSetShowNotificationBody;
  final Future<void> Function(bool muted)
      onToggleCurrentSessionNotificationMute;
  final Future<void> Function() onPickImages;
  final void Function(String id) onRemoveAttachment;
  final Future<void> Function() onSendMessage;
  final Future<void> Function() onAbortRun;
  final ChatRoleIconBuilder iconForRole;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final selectedSessionIndex = sessions.indexWhere(
      (session) => session.sessionKey.value == currentSession.sessionKey.value,
    );
    final canForgetCurrentSession = sessions.length > 1;
    final agentSessionCardViewData = AgentSessionCardViewData.from(
      strings: strings,
      agents: agents,
      selectedAgentId: selectedAgentId,
      gatewaySessions: gatewaySessions,
      currentSessionKey: currentSession.sessionKey.value,
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
                  initialValue:
                      selectedSessionIndex >= 0 ? selectedSessionIndex : 0,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: strings.sessionLabel,
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
              CurrentSessionHeader(
                currentSession: currentSession,
                canForgetCurrentSession: canForgetCurrentSession,
                sessionTitleController: sessionTitleController,
                onSessionTitleSubmitted: onSessionTitleSubmitted,
                onForgetCurrentSession: onForgetCurrentSession,
              ),
              const SizedBox(height: 12),
              AgentSessionCard(
                viewData: agentSessionCardViewData,
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
                onClearFastModeOverride: onClearFastModeOverride,
              ),
              const SizedBox(height: 12),
              NotificationSettingsCard(
                notificationsEnabled: notificationsEnabled,
                showNotificationBody: showNotificationBody,
                currentSessionNotificationsMuted:
                    currentSessionNotificationsMuted,
                onSetNotificationsEnabled: onSetNotificationsEnabled,
                onSetShowNotificationBody: onSetShowNotificationBody,
                onToggleCurrentSessionNotificationMute:
                    onToggleCurrentSessionNotificationMute,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: timeline.isEmpty
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: Text(strings.timelineEmpty),
                          )
                        : ListView.separated(
                            itemCount: timeline.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
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
                        ? strings.sendMessageHint
                        : strings.sendImagesHint,
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
                      onPressed: connectionState.phase ==
                              GatewayConnectionPhase.connected
                          ? () => unawaited(onPickImages())
                          : null,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(strings.image),
                    ),
                    FilledButton(
                      onPressed: connectionState.phase ==
                              GatewayConnectionPhase.connected
                          ? onSendMessage
                          : null,
                      child: Text(strings.send),
                    ),
                    OutlinedButton(
                      onPressed: activeRunId != null ? onAbortRun : null,
                      child: Text(strings.stop),
                    ),
                  ],
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: connectionState.phase ==
                              GatewayConnectionPhase.connected
                          ? () => unawaited(onPickImages())
                          : null,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      tooltip: strings.addImage,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: pendingAttachments.isEmpty
                              ? strings.sendMessageHint
                              : strings.sendImagesHint,
                        ),
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => unawaited(onSendMessage()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: connectionState.phase ==
                              GatewayConnectionPhase.connected
                          ? onSendMessage
                          : null,
                      child: Text(strings.send),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: activeRunId != null ? onAbortRun : null,
                      child: Text(strings.stop),
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
              selectedIndex:
                  selectedSessionIndex >= 0 ? selectedSessionIndex : 0,
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
    required this.viewData,
    required this.onSelectAgent,
    required this.onOpenGatewaySession,
  });

  final AgentSessionCardViewData viewData;
  final Future<void> Function(String agentId) onSelectAgent;
  final Future<void> Function(SessionInfo session) onOpenGatewaySession;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.agentSessionSourceTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final agent in viewData.agents)
                  ChoiceChip(
                    label: Text(agent.label),
                    selected: agent.selected,
                    onSelected: (_) => unawaited(onSelectAgent(agent.id)),
                  ),
              ],
            ),
            if (viewData.hasGatewaySessions) ...[
              const SizedBox(height: 12),
              Text(
                strings.existingGatewaySessions,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                strings.existingGatewaySessionsDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final session in viewData.gatewaySessions)
                    ActionChip(
                      avatar: Icon(
                        session.isCurrent
                            ? Icons.check_circle_outline
                            : Icons.history,
                        size: 18,
                      ),
                      label: Text(session.label),
                      onPressed: session.isCurrent
                          ? null
                          : () => unawaited(
                                onOpenGatewaySession(session.session),
                              ),
                    ),
                ],
              ),
              if (viewData.hiddenGatewaySessionCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  strings.moreGatewaySessionsNotShown(
                    viewData.hiddenGatewaySessionCount,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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
    final strings = AppStrings.of(context);
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
          ChatTimelineRole.system => strings.systemTitle,
          ChatTimelineRole.user => strings.youTitle,
          ChatTimelineRole.assistant => strings.assistantTitle,
          ChatTimelineRole.tool => strings.toolTitle,
        };
    final badgeLabel = item.status != null
        ? strings.timelineStatus(item.status!)
        : item.isStreaming
            ? strings.streaming
            : null;

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
                _formatTimestamp(item.createdAt),
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
                    strings.detailsTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                    ),
                  ),
                  iconColor: foregroundColor,
                  collapsedIconColor: foregroundColor,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          item.details!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: foregroundColor,
                            fontFamily: 'monospace',
                            height: 1.35,
                          ),
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

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
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
      avatar: Icon(inherited ? Icons.keyboard_return : Icons.tune, size: 18),
      label: Text('$label: $value'),
    );
  }
}

class NotificationSettingsCard extends StatelessWidget {
  const NotificationSettingsCard({
    super.key,
    required this.notificationsEnabled,
    required this.showNotificationBody,
    required this.currentSessionNotificationsMuted,
    required this.onSetNotificationsEnabled,
    required this.onSetShowNotificationBody,
    required this.onToggleCurrentSessionNotificationMute,
  });

  final bool notificationsEnabled;
  final bool showNotificationBody;
  final bool currentSessionNotificationsMuted;
  final Future<void> Function(bool enabled) onSetNotificationsEnabled;
  final Future<void> Function(bool enabled) onSetShowNotificationBody;
  final Future<void> Function(bool muted)
      onToggleCurrentSessionNotificationMute;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.notificationSettingsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(strings.notificationSettingsDescription),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.replyNotificationsEnabled),
              subtitle: Text(strings.replyNotificationsEnabledHelp),
              value: notificationsEnabled,
              onChanged: (value) => unawaited(onSetNotificationsEnabled(value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.showReplyPreview),
              subtitle: Text(strings.showReplyPreviewHelp),
              value: showNotificationBody,
              onChanged: notificationsEnabled
                  ? (value) => unawaited(onSetShowNotificationBody(value))
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.muteCurrentSessionNotifications),
              subtitle: Text(strings.muteCurrentSessionNotificationsHelp),
              value: currentSessionNotificationsMuted,
              onChanged: notificationsEnabled
                  ? (value) =>
                      unawaited(onToggleCurrentSessionNotificationMute(value))
                  : null,
            ),
          ],
        ),
      ),
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
    required this.onClearFastModeOverride,
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
    final strings = AppStrings.of(context);
    final viewData = SessionInfoViewData.from(
      strings: strings,
      identity: identity,
      sessionInfo: sessionInfo,
      sessionDefaults: sessionDefaults,
      models: models,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              viewData.assistantName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SessionSettingChip(
                  label: strings.model,
                  value: viewData.model.displayValue,
                  inherited: viewData.model.inherited,
                ),
                _SessionSettingChip(
                  label: strings.thinking,
                  value: viewData.thinking.displayValue,
                  inherited: viewData.thinking.inherited,
                ),
                _SessionSettingChip(
                  label: strings.verbose,
                  value: viewData.verbose.displayValue,
                  inherited: viewData.verbose.inherited,
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
                    initialValue: viewData.model.selectedValue,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: strings.model,
                    ),
                    items: [
                      for (final option in viewData.model.options)
                        DropdownMenuItem<String>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      unawaited(
                        onSelectModel(
                          value == SessionInfoViewData.defaultModelValue
                              ? null
                              : value,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: viewData.thinking.selectedValue,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: strings.thinking,
                    ),
                    items: [
                      for (final option in viewData.thinking.options)
                        DropdownMenuItem<String>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      unawaited(
                        onSelectThinking(
                          value == SessionInfoViewData.defaultThinkingValue
                              ? null
                              : value,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: viewData.verbose.selectedValue,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: strings.verbose,
                    ),
                    items: [
                      for (final option in viewData.verbose.options)
                        DropdownMenuItem<String>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      unawaited(
                        onSelectVerbose(
                          value == SessionInfoViewData.defaultVerboseValue
                              ? null
                              : value,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.fastMode),
              subtitle: Text(strings.fastModeMapsTo(viewData.fastModeSummary)),
              value: viewData.fastMode,
              onChanged: (value) => unawaited(onToggleFastMode(value)),
            ),
            if (viewData.hasFastModeOverride)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => unawaited(onClearFastModeOverride()),
                  icon: const Icon(Icons.keyboard_return),
                  label: Text(viewData.fastModeResetLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
