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
  final FakeGatewayClient _gatewayClient = FakeGatewayClient();
  final TextEditingController _messageController = TextEditingController();

  late final GatewayChatService _chatService;
  late final LocalSessionRegistry _registry;
  late LocalSessionEntry _currentSession;
  StreamSubscription<GatewayConnectionState>? _connectionSubscription;
  StreamSubscription<GatewayEvent>? _eventSubscription;
  StreamSubscription<ChatStreamEvent>? _chatSubscription;
  GatewayConnectionState _connectionState = const GatewayConnectionState(
    phase: GatewayConnectionPhase.disconnected,
  );
  List<ChatTimelineItem> _timeline = <ChatTimelineItem>[];
  String? _activeRunId;

  @override
  void initState() {
    super.initState();
    _chatService = GatewayChatService(_gatewayClient);
    _registry = LocalSessionRegistry(
      initialSessions: <LocalSessionEntry>[
        LocalSessionEntry(
          sessionKey: SessionKey.forClient(agentId: 'main', clientKey: 'pc-home'),
          title: 'Home',
        ),
      ],
    );
    _currentSession = _registry.sessions.first;

    _connectionSubscription = _gatewayClient.connectionStates.listen((state) {
      setState(() {
        _connectionState = state;
      });
    });

    _eventSubscription = _gatewayClient.events.listen((event) {
      if (event.event == 'connect.challenge') {
        _appendTimeline(
          ChatTimelineRole.system,
          'Received connect.challenge (${event.payload['nonce']})',
        );
      }
    });

    _chatSubscription = _chatService.stream.listen(_handleChatStreamEvent);
    unawaited(_loadHistoryForCurrentSession());
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _eventSubscription?.cancel();
    _chatSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
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

    setState(() {
      _timeline = items;
    });
  }

  void _appendTimeline(ChatTimelineRole role, String text) {
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
    });
  }

  Future<void> _connect() async {
    await _gatewayClient.connect();
    await _loadHistoryForCurrentSession();
  }

  Future<void> _disconnect() async {
    await _gatewayClient.disconnect();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _appendTimeline(ChatTimelineRole.user, text);
    _messageController.clear();

    final response = await _chatService.send(
      sessionKey: _currentSession.sessionKey.value,
      message: text,
    );

    setState(() {
      _activeRunId = response.payload?['runId'] as String?;
    });
  }

  Future<void> _abortRun() async {
    await _chatService.abort(
      sessionKey: _currentSession.sessionKey.value,
      runId: _activeRunId,
    );
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
              unawaited(_loadHistoryForCurrentSession());
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
                  _ConnectionStatusCard(
                    state: _connectionState,
                    onConnect: _connect,
                    onDisconnect: _disconnect,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _timeline.isEmpty
                            ? const Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Timeline is empty. Connect and send a message to the fake Gateway client.',
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
                        onPressed: _sendMessage,
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
        ),
      ),
    );
  }
}
