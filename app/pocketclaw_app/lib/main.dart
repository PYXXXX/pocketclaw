import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

void main() {
  runApp(const PocketClawApp());
}

class PocketClawApp extends StatelessWidget {
  const PocketClawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketClaw',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const PocketClawHome(),
    );
  }
}

class PocketClawHome extends StatefulWidget {
  const PocketClawHome({super.key});

  @override
  State<PocketClawHome> createState() => _PocketClawHomeState();
}

class _PocketClawHomeState extends State<PocketClawHome> {
  final SessionKeyFactory _sessionKeyFactory = const SessionKeyFactory();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _gatewayUrlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GatewayConnectRequestFactory _connectRequestFactory =
      const GatewayConnectRequestFactory();
  final MemoryGatewayDeviceIdentityStore _deviceIdentityStore =
      MemoryGatewayDeviceIdentityStore();

  late LocalSessionRegistry _registry;
  late LocalSessionEntry _currentSession;
  late GatewayProfile _gatewayProfile;
  late ConnectableGatewayClient _gatewayClient;
  late GatewayChatService _chatService;
  late GatewaySessionService _sessionService;
  late GatewayAgentService _agentService;

  StreamSubscription<GatewayConnectionState>? _connectionSubscription;
  StreamSubscription<GatewayEvent>? _eventSubscription;
  StreamSubscription<ChatStreamEvent>? _chatSubscription;

  GatewayConnectionState _connectionState = const GatewayConnectionState(
    phase: GatewayConnectionPhase.disconnected,
  );
  List<ChatTimelineItem> _timeline = <ChatTimelineItem>[];
  List<ModelInfo> _models = const <ModelInfo>[];
  AgentIdentity? _assistantIdentity;
  SessionInfo? _currentSessionInfo;
  String? _activeRunId;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _gatewayProfile = const GatewayProfile();
    _gatewayUrlController.text = _gatewayProfile.url;
    _tokenController.text = _gatewayProfile.token;
    _passwordController.text = _gatewayProfile.password;

    _registry = LocalSessionRegistry(
      initialSessions: <LocalSessionEntry>[
        LocalSessionEntry(
          sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
          title: 'Home',
        ),
      ],
    );
    _currentSession = _registry.sessions.first;

    _gatewayClient = _buildGatewayClient(_gatewayProfile);
    _chatService = GatewayChatService(_gatewayClient);
    _sessionService = GatewaySessionService(_gatewayClient);
    _agentService = GatewayAgentService(_gatewayClient);
    _attachClientSubscriptions();

    _timeline = <ChatTimelineItem>[
      ChatTimelineItem(
        role: ChatTimelineRole.system,
        text: 'PocketClaw is configured for real Gateway usage. Apply connection settings and connect.',
        createdAt: DateTime.now().toUtc(),
      ),
    ];
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _eventSubscription?.cancel();
    _chatSubscription?.cancel();
    unawaited(_gatewayClient.disconnect());
    _messageController.dispose();
    _gatewayUrlController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  ConnectableGatewayClient _buildGatewayClient(GatewayProfile profile) {
    return GatewayWsClient(
      config: GatewayConnectionConfig(
        url: profile.url,
        connectRequest: _connectRequestFactory.build(
          token: profile.token,
          password: profile.password,
        ),
        deviceAuthProvider: CryptographyDeviceAuthProvider(
          store: _deviceIdentityStore,
        ),
      ),
    );
  }

  void _attachClientSubscriptions() {
    _connectionSubscription = _gatewayClient.connectionStates.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connectionState = state;
      });
    });

    _eventSubscription = _gatewayClient.events.listen((event) {
      if (!mounted) {
        return;
      }
      if (event.event == 'connect.challenge') {
        _appendTimeline(
          ChatTimelineRole.system,
          'Received connect.challenge (${event.payload['nonce']})',
        );
      }
    });

    _chatSubscription = _chatService.stream.listen(_handleChatStreamEvent);
  }

  Future<void> _replaceGatewayClient(ConnectableGatewayClient client) async {
    await _connectionSubscription?.cancel();
    await _eventSubscription?.cancel();
    await _chatSubscription?.cancel();
    await _gatewayClient.disconnect();

    _gatewayClient = client;
    _chatService = GatewayChatService(_gatewayClient);
    _sessionService = GatewaySessionService(_gatewayClient);
    _agentService = GatewayAgentService(_gatewayClient);
    _connectionState = const GatewayConnectionState(
      phase: GatewayConnectionPhase.disconnected,
    );
    _activeRunId = null;

    _attachClientSubscriptions();
  }

  Future<void> _applyGatewayConfiguration() async {
    final profile = _gatewayProfile.copyWith(
      url: _gatewayUrlController.text.trim(),
      token: _tokenController.text,
      password: _passwordController.text,
    );

    setState(() {
      _gatewayProfile = profile;
      _lastError = null;
      _assistantIdentity = null;
      _models = const <ModelInfo>[];
      _currentSessionInfo = null;
      _timeline = <ChatTimelineItem>[
        ChatTimelineItem(
          role: ChatTimelineRole.system,
          text: 'Applied real Gateway configuration for ${profile.url}',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    });

    await _replaceGatewayClient(_buildGatewayClient(profile));
  }

  void _handleChatStreamEvent(ChatStreamEvent event) {
    if (event.sessionKey != _currentSession.sessionKey.value) {
      return;
    }

    if (event.runId != null) {
      _activeRunId = event.runId;
    }

    switch (event.state) {
      case ChatStreamState.delta:
        if (event.message != null) {
          _appendTimeline(ChatTimelineRole.assistant, '[streaming] ${event.message!.text}');
        }
      case ChatStreamState.finalMessage:
        if (event.message != null) {
          _appendTimeline(ChatTimelineRole.assistant, event.message!.text);
        }
        _activeRunId = null;
      case ChatStreamState.aborted:
        if (event.message != null) {
          _appendTimeline(ChatTimelineRole.system, event.message!.text);
        }
        _activeRunId = null;
      case ChatStreamState.error:
        _appendTimeline(ChatTimelineRole.system, event.errorMessage ?? 'Chat error');
        _activeRunId = null;
    }
  }

  Future<void> _loadCurrentViewData() async {
    if (_connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    try {
      await Future.wait<void>([
        _loadHistoryForCurrentSession(),
        _loadAssistantAndModels(),
        _loadSessionInfo(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _lastError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastError = error.toString();
      });
      _appendTimeline(ChatTimelineRole.system, 'Load failed: $error');
    }
  }

  Future<void> _loadHistoryForCurrentSession() async {
    final history = await _chatService.loadHistory(
      sessionKey: _currentSession.sessionKey.value,
    );

    final items = history.messages.map((message) {
      return ChatTimelineItem(
        role: switch (message.role) {
          ChatMessageRole.system => ChatTimelineRole.system,
          ChatMessageRole.user => ChatTimelineRole.user,
          ChatMessageRole.assistant => ChatTimelineRole.assistant,
        },
        text: message.text,
        createdAt: message.timestamp ?? DateTime.now().toUtc(),
      );
    }).toList();

    if (!mounted) {
      return;
    }
    setState(() {
      _timeline = items;
    });
  }

  Future<void> _loadAssistantAndModels() async {
    final results = await Future.wait<Object?>([
      _agentService.getIdentity(sessionKey: _currentSession.sessionKey.value),
      _agentService.listModels(),
    ]);

    if (!mounted) {
      return;
    }
    setState(() {
      _assistantIdentity = results[0] as AgentIdentity;
      _models = results[1] as List<ModelInfo>;
    });
  }

  Future<void> _loadSessionInfo() async {
    final result = await _sessionService.list();
    final targetKey = _currentSession.sessionKey.value;
    SessionInfo? info;
    for (final session in result.sessions) {
      if (session.key == targetKey) {
        info = session;
        break;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _currentSessionInfo = info;
    });
  }

  void _appendTimeline(ChatTimelineRole role, String text) {
    if (!mounted) {
      return;
    }
    setState(() {
      _timeline = <ChatTimelineItem>[
        ..._timeline,
        ChatTimelineItem(
          role: role,
          text: text,
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    });
  }

  void _createSession() {
    final sessionKey = _sessionKeyFactory.createTimestamped(agentId: 'main');
    final entry = LocalSessionEntry(
      sessionKey: sessionKey,
      title: 'New session ${_registry.sessions.length + 1}',
    );

    setState(() {
      _registry.remember(entry);
      _currentSession = entry;
      _timeline = <ChatTimelineItem>[
        ChatTimelineItem(
          role: ChatTimelineRole.system,
          text: 'Created local session ${entry.sessionKey.value}',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
      _currentSessionInfo = null;
    });
  }

  Future<void> _connect() async {
    try {
      await _gatewayClient.connect();
      _appendTimeline(ChatTimelineRole.system, 'Connected to ${_gatewayProfile.url}');
      await _loadCurrentViewData();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastError = error.toString();
      });
      _appendTimeline(ChatTimelineRole.system, 'Connect failed: $error');
    }
  }

  Future<void> _disconnect() async {
    await _gatewayClient.disconnect();
    _appendTimeline(ChatTimelineRole.system, 'Disconnected from ${_gatewayProfile.url}');
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    _appendTimeline(ChatTimelineRole.user, text);
    _messageController.clear();

    try {
      final response = await _chatService.send(
        sessionKey: _currentSession.sessionKey.value,
        message: text,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _activeRunId = response.payload?['runId'] as String?;
        _lastError = null;
      });

      await _loadSessionInfo();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastError = error.toString();
      });
      _appendTimeline(ChatTimelineRole.system, 'Send failed: $error');
    }
  }

  Future<void> _abortRun() async {
    if (_connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    try {
      await _chatService.abort(
        sessionKey: _currentSession.sessionKey.value,
        runId: _activeRunId,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastError = error.toString();
      });
      _appendTimeline(ChatTimelineRole.system, 'Abort failed: $error');
    }
  }

  Future<void> _applyModel(String modelId) async {
    if (_connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    try {
      await _sessionService.patch(
        SessionPatchParams(
          key: _currentSession.sessionKey.value,
          model: modelId,
        ),
      );
      await _loadSessionInfo();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastError = error.toString();
      });
      _appendTimeline(ChatTimelineRole.system, 'Model update failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _registry.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketClaw'),
        actions: [
          IconButton(
            onPressed: _createSession,
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Create session',
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: sessions.indexOf(_currentSession),
            onDestinationSelected: (index) {
              setState(() {
                _currentSession = sessions[index];
              });
              unawaited(_loadCurrentViewData());
            },
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentSession.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Session key: ${_currentSession.sessionKey.value}',
                  ),
                  const SizedBox(height: 12),
                  _GatewayConfigCard(
                    gatewayUrlController: _gatewayUrlController,
                    tokenController: _tokenController,
                    passwordController: _passwordController,
                    onApply: _applyGatewayConfiguration,
                  ),
                  const SizedBox(height: 12),
                  _ConnectionStatusCard(
                    state: _connectionState,
                    onConnect: _connect,
                    onDisconnect: _disconnect,
                  ),
                  const SizedBox(height: 12),
                  _SessionInfoCard(
                    identity: _assistantIdentity,
                    sessionInfo: _currentSessionInfo,
                    models: _models,
                    onSelectModel: _applyModel,
                  ),
                  if (_lastError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _lastError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _timeline.isEmpty
                            ? const Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Timeline is empty. Apply connection settings, connect, and start chatting.',
                                ),
                              )
                            : ListView.separated(
                                itemCount: _timeline.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final item = _timeline[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(_iconForRole(item.role)),
                                    title: Text(item.text),
                                    subtitle: Text(item.createdAt.toIso8601String()),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Send a message',
                          ),
                          onSubmitted: (_) => unawaited(_sendMessage()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _connectionState.phase == GatewayConnectionPhase.connected
                            ? _sendMessage
                            : null,
                        child: const Text('Send'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _activeRunId != null ? _abortRun : null,
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForRole(ChatTimelineRole role) {
    switch (role) {
      case ChatTimelineRole.system:
        return Icons.settings_ethernet;
      case ChatTimelineRole.user:
        return Icons.person_outline;
      case ChatTimelineRole.assistant:
        return Icons.smart_toy_outlined;
      case ChatTimelineRole.tool:
        return Icons.handyman_outlined;
    }
  }
}

class _GatewayConfigCard extends StatelessWidget {
  const _GatewayConfigCard({
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
              'Gateway connection',
              style: Theme.of(context).textTheme.titleMedium,
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
              child: const Text('Apply real Gateway configuration'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  const _ConnectionStatusCard({
    required this.state,
    required this.onConnect,
    required this.onDisconnect,
  });

  final GatewayConnectionState state;
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
              'Connection state: ${state.phase.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
        ],
      ),
    );
  }
}

class _SessionInfoCard extends StatelessWidget {
  const _SessionInfoCard({
    required this.identity,
    required this.sessionInfo,
    required this.models,
    required this.onSelectModel,
  });

  final AgentIdentity? identity;
  final SessionInfo? sessionInfo;
  final List<ModelInfo> models;
  final Future<void> Function(String modelId) onSelectModel;

  @override
  Widget build(BuildContext context) {
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
            Text('Model: ${sessionInfo?.model ?? 'default'}'),
            Text('Thinking: ${sessionInfo?.thinkingLevel ?? 'off'}'),
            Text('Fast mode: ${sessionInfo?.fastMode == true ? 'on' : 'off'}'),
            Text('Verbose: ${sessionInfo?.verboseLevel ?? 'off'}'),
            if (models.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final model in models.take(4))
                    ActionChip(
                      label: Text(model.id),
                      onPressed: () => unawaited(onSelectModel(model.id)),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
