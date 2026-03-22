import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

import 'app_strings.dart';
import 'connect_flow_models.dart';
import 'gateway_connection_availability.dart';

class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    super.key,
    required this.snapshot,
    required this.connectionState,
    required this.savedGatewayUrl,
    required this.liveGatewayUrl,
    required this.hasBootstrapCredentials,
    required this.hasStoredDeviceIdentity,
    required this.hasStoredDeviceToken,
  });

  final ConnectFlowSnapshot snapshot;
  final GatewayConnectionState connectionState;
  final String savedGatewayUrl;
  final String liveGatewayUrl;
  final bool hasBootstrapCredentials;
  final bool hasStoredDeviceIdentity;
  final bool hasStoredDeviceToken;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasLiveGatewayUrl = liveGatewayUrl.trim().isNotEmpty;
    final liveGatewayLabel = hasLiveGatewayUrl
        ? liveGatewayUrl.trim()
        : strings.liveGatewayClientNotReady;
    final hasSavedGatewayUrl = savedGatewayUrl.trim().isNotEmpty;
    final savedGatewayLabel = hasSavedGatewayUrl
        ? savedGatewayUrl.trim()
        : strings.noGatewayConfigured;
    final bootstrapLabel =
        hasBootstrapCredentials ? strings.bootstrapSaved : strings.noBootstrap;
    final reconnectLabel = hasStoredDeviceToken
        ? strings.reconnectTokenAvailable
        : hasStoredDeviceIdentity
            ? strings.deviceIdentitySaved
            : strings.firstPairingLikely;
    final usesLoopback = gatewayUrlUsesLoopback(
      hasLiveGatewayUrl ? liveGatewayUrl : savedGatewayUrl,
    );

    return Card(
      color: snapshot.requiresAttention
          ? colorScheme.errorContainer
          : colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  snapshot.stage == ConnectFlowStage.ready
                      ? Icons.check_circle_outline
                      : Icons.hub_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    snapshot.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(snapshot.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.hub_outlined, size: 18),
                  label: Text(
                    '${strings.liveGatewayClientLabel}: $liveGatewayLabel',
                  ),
                ),
                if (hasSavedGatewayUrl && savedGatewayUrl != liveGatewayUrl)
                  Chip(
                    avatar: const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      '${strings.savedGatewayConfigLabel}: $savedGatewayLabel',
                    ),
                  ),
                Chip(
                  avatar: const Icon(Icons.sync_outlined, size: 18),
                  label: Text(
                    '${strings.stateLabel}: ${connectionState.phase.name}',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.key_outlined, size: 18),
                  label: Text(bootstrapLabel),
                ),
                Chip(
                  avatar: Icon(
                    hasStoredDeviceToken
                        ? Icons.verified_user_outlined
                        : Icons.phonelink_lock_outlined,
                    size: 18,
                  ),
                  label: Text(reconnectLabel),
                ),
                if (usesLoopback)
                  Chip(
                    avatar: const Icon(Icons.warning_amber_outlined, size: 18),
                    label: Text(strings.loopbackUrl),
                  ),
              ],
            ),
            if (usesLoopback) ...[
              const SizedBox(height: 8),
              Text(strings.loopbackWarning),
            ],
          ],
        ),
      ),
    );
  }
}

class ConnectFlowCard extends StatelessWidget {
  const ConnectFlowCard({
    super.key,
    required this.snapshot,
    required this.onboardingCompleted,
    required this.connectMethod,
    required this.onCompleteWelcome,
    required this.onSelectMethod,
  });

  final ConnectFlowSnapshot snapshot;
  final bool onboardingCompleted;
  final ConnectMethod connectMethod;
  final Future<void> Function() onCompleteWelcome;
  final Future<void> Function(ConnectMethod method) onSelectMethod;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: snapshot.requiresAttention
          ? colorScheme.surfaceContainerHighest
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(snapshot.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(snapshot.description),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onboardingCompleted ? null : onCompleteWelcome,
                  child: Text(
                    onboardingCompleted
                        ? strings.onboardingComplete
                        : strings.startSetup,
                  ),
                ),
                ChoiceChip(
                  label: Text(strings.manualConnect),
                  selected: connectMethod == ConnectMethod.manual,
                  onSelected: (_) =>
                      unawaited(onSelectMethod(ConnectMethod.manual)),
                ),
                ChoiceChip(
                  label: Text(strings.setupCodeLater),
                  selected: connectMethod == ConnectMethod.setupCode,
                  onSelected: (_) =>
                      unawaited(onSelectMethod(ConnectMethod.setupCode)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GatewayConfigCard extends StatelessWidget {
  const GatewayConfigCard({
    super.key,
    required this.gatewayUrlController,
    required this.tokenController,
    required this.passwordController,
    required this.cloudflareAccessClientIdController,
    required this.cloudflareAccessClientSecretController,
    required this.customRequestHeadersController,
    required this.isApplyingConfiguration,
    required this.onApply,
  });

  final TextEditingController gatewayUrlController;
  final TextEditingController tokenController;
  final TextEditingController passwordController;
  final TextEditingController cloudflareAccessClientIdController;
  final TextEditingController cloudflareAccessClientSecretController;
  final TextEditingController customRequestHeadersController;
  final bool isApplyingConfiguration;
  final Future<void> Function() onApply;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final showAdvancedOptions =
        cloudflareAccessClientIdController.text.trim().isNotEmpty ||
            cloudflareAccessClientSecretController.text.trim().isNotEmpty ||
            customRequestHeadersController.text.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.gatewayConfiguration,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(strings.gatewayIntro),
            const SizedBox(height: 12),
            TextField(
              controller: gatewayUrlController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: strings.gatewayUrlLabel,
                hintText: strings.gatewayUrlHint,
                helperText: strings.gatewayUrlHelp,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tokenController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: strings.token,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: strings.password,
                    ),
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card.outlined(
              margin: EdgeInsets.zero,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                initiallyExpanded: showAdvancedOptions,
                title: Text(strings.moreOptions),
                subtitle: Text(strings.moreOptionsHelp),
                children: [
                  TextField(
                    controller: cloudflareAccessClientIdController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: strings.cfAccessClientId,
                      helperText: strings.cfAccessHelp,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cloudflareAccessClientSecretController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: strings.cfAccessClientSecret,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customRequestHeadersController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: strings.customRequestHeaders,
                      hintText: strings.customRequestHeadersHint,
                      helperText: strings.customRequestHeadersHelp,
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isApplyingConfiguration ? null : onApply,
              child: Text(
                isApplyingConfiguration
                    ? strings.applyingConnectionSettings
                    : strings.saveConnectionSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({
    super.key,
    required this.state,
    required this.connectFlowStage,
    required this.isBootstrapping,
    required this.isApplyingConfiguration,
    required this.isRefreshingClient,
    required this.onConnect,
    required this.onDisconnect,
  });

  final GatewayConnectionState state;
  final ConnectFlowStage connectFlowStage;
  final bool isBootstrapping;
  final bool isApplyingConfiguration;
  final bool isRefreshingClient;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final canConnect = canAttemptGatewayConnect(
      phase: state.phase,
      isBootstrapping: isBootstrapping,
      isApplyingConfiguration: isApplyingConfiguration,
      isRefreshingClient: isRefreshingClient,
    );
    final canDisconnect = state.phase != GatewayConnectionPhase.disconnected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.gatewayState(state.phase.name),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(strings.flowStage(connectFlowStage.name)),
            if (state.message != null) ...[
              const SizedBox(height: 8),
              Text(state.message!),
            ],
            if (isBootstrapping) ...[
              const SizedBox(height: 8),
              Text(strings.restoringSavedConfigurationHelp),
            ],
            if (isRefreshingClient) ...[
              const SizedBox(height: 8),
              Text(strings.refreshingLiveConnectionClientHelp),
            ],
            if (isApplyingConfiguration) ...[
              const SizedBox(height: 8),
              Text(strings.applyingConnectionSettingsHelp),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: canConnect ? onConnect : null,
                  child: Text(strings.connect),
                ),
                OutlinedButton(
                  onPressed: canDisconnect ? onDisconnect : null,
                  child: Text(strings.disconnect),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GuidanceCard extends StatelessWidget {
  const GuidanceCard({super.key, required this.guidance});

  final GatewayErrorGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final payload = <String>[
      guidance.summary,
      if (guidance.action != null) guidance.action!,
      if (guidance.code != null) '${strings.codeLabel}: ${guidance.code}',
    ].join('\n\n');

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: payload));
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(strings.copied)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                guidance.summary,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (guidance.action != null) ...[
                const SizedBox(height: 8),
                SelectableText(guidance.action!),
              ],
              if (guidance.code != null) ...[
                const SizedBox(height: 8),
                SelectableText('${strings.codeLabel}: ${guidance.code}'),
              ],
              const SizedBox(height: 8),
              Text(
                strings.longPressToCopy,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatLockedPlaceholder extends StatelessWidget {
  const ChatLockedPlaceholder({super.key, this.onOpenConnect});

  final VoidCallback? onOpenConnect;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 42,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              strings.finishConnectionFlowFirst,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(strings.chatLockedDescription, textAlign: TextAlign.center),
            if (onOpenConnect != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onOpenConnect,
                icon: const Icon(Icons.hub_outlined),
                label: Text(strings.openConnect),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
