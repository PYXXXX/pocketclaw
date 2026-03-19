import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';

import 'connect_flow_models.dart';

class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    super.key,
    required this.snapshot,
    required this.connectionState,
    required this.gatewayUrl,
    required this.hasBootstrapCredentials,
    required this.hasStoredDeviceIdentity,
    required this.hasStoredDeviceToken,
  });

  final ConnectFlowSnapshot snapshot;
  final GatewayConnectionState connectionState;
  final String gatewayUrl;
  final bool hasBootstrapCredentials;
  final bool hasStoredDeviceIdentity;
  final bool hasStoredDeviceToken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasGatewayUrl = gatewayUrl.trim().isNotEmpty;
    final gatewayLabel = hasGatewayUrl ? gatewayUrl.trim() : 'No Gateway configured yet';
    final bootstrapLabel = hasBootstrapCredentials
        ? 'Bootstrap credentials saved'
        : 'No bootstrap credentials';
    final reconnectLabel = hasStoredDeviceToken
        ? 'Reconnect token available'
        : hasStoredDeviceIdentity
            ? 'Device identity saved'
            : 'First pairing likely needed';

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
                  label: Text(gatewayLabel),
                ),
                Chip(
                  avatar: const Icon(Icons.sync_outlined, size: 18),
                  label: Text('State: ${connectionState.phase.name}'),
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
              ],
            ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: snapshot.requiresAttention ? colorScheme.surfaceContainerHighest : null,
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
                  child: Text(onboardingCompleted ? 'Onboarding complete' : 'Start setup'),
                ),
                ChoiceChip(
                  label: const Text('Manual connect'),
                  selected: connectMethod == ConnectMethod.manual,
                  onSelected: (_) => unawaited(onSelectMethod(ConnectMethod.manual)),
                ),
                ChoiceChip(
                  label: const Text('Setup code (later)'),
                  selected: connectMethod == ConnectMethod.setupCode,
                  onSelected: (_) => unawaited(onSelectMethod(ConnectMethod.setupCode)),
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
    required this.onApply,
  });

  final TextEditingController gatewayUrlController;
  final TextEditingController tokenController;
  final TextEditingController passwordController;
  final Future<void> Function() onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gateway configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Manual connect is the baseline path. Token and password are optional bootstrap credentials. Reusable device auth should stay local after the first successful approval.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gatewayUrlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Gateway WebSocket URL',
                hintText: 'ws://127.0.0.1:18789',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tokenController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Token',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onApply,
              child: const Text('Save connection settings'),
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
    required this.onConnect,
    required this.onDisconnect,
  });

  final GatewayConnectionState state;
  final ConnectFlowStage connectFlowStage;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    final canConnect = state.phase == GatewayConnectionPhase.disconnected ||
        state.phase == GatewayConnectionPhase.error;
    final canDisconnect = state.phase != GatewayConnectionPhase.disconnected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gateway state: ${state.phase.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Flow stage: ${connectFlowStage.name}'),
            if (state.message != null) ...[
              const SizedBox(height: 8),
              Text(state.message!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: canConnect ? onConnect : null,
                  child: const Text('Connect'),
                ),
                OutlinedButton(
                  onPressed: canDisconnect ? onDisconnect : null,
                  child: const Text('Disconnect'),
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
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
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
              Text(guidance.action!),
            ],
            if (guidance.code != null) ...[
              const SizedBox(height: 8),
              Text('Code: ${guidance.code}'),
            ],
          ],
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
              'Finish the connection flow first',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'PocketClaw keeps the chat shell behind a usable Gateway setup so the app does not feel like a debug screen before it can reconnect cleanly.',
              textAlign: TextAlign.center,
            ),
            if (onOpenConnect != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onOpenConnect,
                icon: const Icon(Icons.hub_outlined),
                label: const Text('Open connect'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
