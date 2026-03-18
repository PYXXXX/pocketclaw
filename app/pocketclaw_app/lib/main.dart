import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

import 'src/storage/connect_flow_preferences_store.dart';
import 'src/storage/local_session_registry_store.dart';
import 'src/storage/secure_gateway_device_identity_store.dart';
import 'src/storage/secure_gateway_device_token_store.dart';
import 'src/storage/secure_gateway_profile_store.dart';
import 'src/storage/secure_key_value_store.dart';

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

enum ConnectMethod {
  manual,
  setupCode,
}

enum ConnectFlowStage {
  welcome,
  chooseMethod,
  manualConfig,
  authPending,
  pairingPending,
  ready,
  error,
}

class _ConnectFlowSnapshot {
  const _ConnectFlowSnapshot({
    required this.stage,
    required this.title,
    required this.description,
    this.requiresAttention = false,
  });

  final ConnectFlowStage stage;
  final String title;
  final String description;
  final bool requiresAttention;
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
  final SecureKeyValueStore _secureStore = FlutterSecureKeyValueStore();

  late final GatewayProfileStore _profileStore =
      SecureGatewayProfileStore(_secureStore);
  late final GatewayDeviceIdentityStore _deviceIdentityStore =
      SecureGatewayDeviceIdentityStore(_secureStore);
  late final GatewayDeviceTokenStore _deviceTokenStore =
      SecureGatewayDeviceTokenStore(_secureStore);
  late final LocalSessionRegistryStore _sessionRegistryStore =
      SharedPreferencesLocalSessionRegistryStore();
  late final ConnectFlowPreferencesStore _connectFlowPreferencesStore =
      SharedPreferencesConnectFlowPreferencesStore();

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
  Timer? _draftPersistTimer;

  GatewayConnectionState _connectionState = const GatewayConnectionState(
    phase: GatewayConnectionPhase.disconnected,
  );
  List<ChatTimelineItem> _timeline = <ChatTimelineItem>[];
  List<ModelInfo> _models = const <ModelInfo>[];
  AgentIdentity? _assistantIdentity;
  SessionInfo? _currentSessionInfo;
  String? _activeRunId;
  String? _lastError;
  GatewayErrorGuidance? _lastGuidance;
  bool _applyingComposerDraft = false;
  bool _onboardingCompleted = false;
  bool _isBootstrapping = true;
  ConnectMethod _connectMethod = ConnectMethod.manual;
  ConnectFlowStage _connectFlowStage = ConnectFlowStage.welcome;

  @override
  void initState() {
    super.initState();
    _gatewayProfile = const GatewayProfile();
    _applyProfileToControllers(_gatewayProfile);

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
        text:
            'PocketClaw is ready for a real Gateway. Start with the connect flow, then enter chat when the app is ready to reconnect.',
        createdAt: DateTime.now().toUtc(),
      ),
    ];

    _messageController.addListener(_handleComposerChanged);

    unawaited(_bootstrapLocalState());
  }

  @override
  void dispose() {
    _draftPersistTimer?.cancel();
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
        deviceTokenStore: _deviceTokenStore,
      ),
    );
  }

  Future<void> _bootstrapLocalState() async {
    try {
      await Future.wait<void>([
        _restorePersistedGatewayProfile(),
        _restorePersistedSessionRegistry(),
        _restoreConnectFlowPreferences(),
      ]);
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBootstrapping = false;
        _connectFlowStage = _deriveConnectFlowStage();
      });
    }
  }

  void _applyProfileToControllers(GatewayProfile profile) {
    _gatewayUrlController.text = profile.url;
    _tokenController.text = profile.token;
    _passwordController.text = profile.password;
  }

  Future<void> _restorePersistedGatewayProfile() async {
    try {
      final storedProfile = await _profileStore.read();
      if (storedProfile == null || !mounted) {
        return;
      }

      _applyProfileToControllers(storedProfile);
      setState(() {
        _gatewayProfile = storedProfile;
      });

      await _replaceGatewayClient(_buildGatewayClient(storedProfile));
    } catch (error) {
      _recordError(error, prefix: 'Secure configuration restore failed');
    }
  }

  Future<void> _restorePersistedSessionRegistry() async {
    try {
      final stored = await _sessionRegistryStore.read();
      if (stored == null || !mounted || stored.registry.sessions.isEmpty) {
        return;
      }

      final sessions = stored.registry.sessions;
      final currentSessionKey = stored.currentSessionKey;
      LocalSessionEntry? restoredCurrent;
      if (currentSessionKey != null) {
        for (final session in sessions) {
          if (session.sessionKey.value == currentSessionKey) {
            restoredCurrent = session;
            break;
          }
        }
      }

      setState(() {
        _registry = stored.registry;
        _currentSession = restoredCurrent ?? sessions.first;
      });
      _applyComposerDraft(_currentSession.draftText);
    } catch (error) {
      _recordError(error, prefix: 'Local session restore failed');
    }
  }

  Future<void> _restoreConnectFlowPreferences() async {
    try {
      final stored = await _connectFlowPreferencesStore.read();
      if (!mounted) {
        return;
      }
      setState(() {
        _onboardingCompleted = stored.onboardingCompleted;
        _connectMethod = switch (stored.lastConnectionMethod) {
          'setupCode' => ConnectMethod.setupCode,
          _ => ConnectMethod.manual,
        };
      });
    } catch (error) {
      _recordError(error, prefix: 'Connect flow restore failed');
    }
  }

  Future<void> _persistSessionRegistry() async {
    try {
      await _sessionRegistryStore.write(
        registry: _registry,
        currentSessionKey: _currentSession.sessionKey.value,
      );
    } catch (error) {
      _recordError(error, prefix: 'Saving local sessions failed');
    }
  }

  Future<void> _persistConnectFlowPreferences() async {
    try {
      await _connectFlowPreferencesStore.write(
        onboardingCompleted: _onboardingCompleted,
        lastConnectionMethod: _connectMethod.name,
      );
    } catch (error) {
      _recordError(error, prefix: 'Saving connect flow preferences failed');
    }
  }

  void _applyComposerDraft(String draftText) {
    _applyingComposerDraft = true;
    _messageController.value = TextEditingValue(
      text: draftText,
      selection: TextSelection.collapsed(offset: draftText.length),
    );
    _applyingComposerDraft = false;
  }

  void _syncCurrentSessionDraft({bool schedulePersist = true}) {
    final updated = _currentSession.copyWith(draftText: _messageController.text);
    _registry.replace(updated);
    _currentSession = updated;
    if (schedulePersist) {
      _scheduleSessionRegistryPersist();
    }
  }

  void _scheduleSessionRegistryPersist() {
    _draftPersistTimer?.cancel();
    _draftPersistTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(_persistSessionRegistry());
    });
  }

  void _handleComposerChanged() {
    if (_applyingComposerDraft) {
      return;
    }
    _syncCurrentSessionDraft();
  }

  void _attachClientSubscriptions() {
    _connectionSubscription = _gatewayClient.connectionStates.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connectionState = state;
        _connectFlowStage = _deriveConnectFlowStage();
      });
    });

    _eventSubscription = _gatewayClient.events.listen((event) {
      if (!mounted) {
        return;
      }
      if (event.event == 'connect.challenge') {
        _appendTimeline(
          ChatTimelineRole.system,
          'Received device-auth challenge. PocketClaw will answer it automatically when local device identity is available.',
        );
        setState(() {
          _connectFlowStage = ConnectFlowStage.authPending;
        });
        return;
      }
      if (event.event.contains('pair') || event.event.contains('device')) {
        setState(() {
          _connectFlowStage = ConnectFlowStage.pairingPending;
        });
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

    if (!mounted) {
      return;
    }
    setState(() {
      _connectFlowStage = _deriveConnectFlowStage();
    });
  }

  ConnectFlowStage _deriveConnectFlowStage() {
    if (_lastError != null) {
      return ConnectFlowStage.error;
    }
    if (!_onboardingCompleted) {
      return ConnectFlowStage.welcome;
    }
    final hasManualConfig = _gatewayUrlController.text.trim().isNotEmpty;
    if (_connectMethod == ConnectMethod.setupCode) {
      return ConnectFlowStage.chooseMethod;
    }
    switch (_connectionState.phase) {
      case GatewayConnectionPhase.connected:
        return ConnectFlowStage.ready;
      case GatewayConnectionPhase.connecting:
      case GatewayConnectionPhase.challengeReceived:
        return ConnectFlowStage.authPending;
      case GatewayConnectionPhase.error:
        return ConnectFlowStage.error;
      case GatewayConnectionPhase.disconnected:
        return hasManualConfig
            ? ConnectFlowStage.manualConfig
            : ConnectFlowStage.chooseMethod;
    }
  }

  _ConnectFlowSnapshot _snapshotForConnectFlow() {
    switch (_connectFlowStage) {
      case ConnectFlowStage.welcome:
        return const _ConnectFlowSnapshot(
          stage: ConnectFlowStage.welcome,
          title: 'Welcome',
          description:
              'PocketClaw connects to an existing OpenClaw Gateway. Finish the quick onboarding, then choose how this phone should connect.',
        );
      case ConnectFlowStage.chooseMethod:
        return const _ConnectFlowSnapshot(
          stage: ConnectFlowStage.chooseMethod,
          title: 'Choose connection method',
          description:
              'Manual connect is the baseline flow and should always work. Setup code can be added later when the client path is ready.',
        );
      case ConnectFlowStage.manualConfig:
        return const _ConnectFlowSnapshot(
          stage: ConnectFlowStage.manualConfig,
          title: 'Manual connection',
          description:
              'Enter the Gateway URL and optional bootstrap credentials. PocketClaw will store reusable auth locally so reconnect can work next time.',
        );
      case ConnectFlowStage.authPending:
        return const _ConnectFlowSnapshot(
          stage: ConnectFlowStage.authPending,
          title: 'Authenticating',
          description:
              'The app is trying bootstrap credentials or answering device-auth challenges. If approval is needed elsewhere, keep this screen open and approve the device.',
          requiresAttention: true,
        );
      case ConnectFlowStage.pairingPending:
        return const _ConnectFlowSnapshot(
          stage: ConnectFlowStage.pairingPending,
          title: 'Pairing pending',
          description:
              'The Gateway still needs device approval or pairing. Once approved, PocketClaw should be able to reuse the issued device token automatically.',
          requiresAttention: true,
        );
      case ConnectFlowStage.ready:
        return const _ConnectFlowSnapshot(
          stage: ConnectFlowStage.ready,
          title: 'Ready to chat',
          description:
              'Connection setup is usable. You can enter the chat shell now, and reconnect should be much lighter next time.',
        );
      case ConnectFlowStage.error:
        return const _ConnectFlowSnapshot(
          stage: ConnectFlowStage.error,
          title: 'Needs attention',
          description:
              'Something blocked the connection flow. Review the guidance below, adjust the config if needed, then try again.',
          requiresAttention: true,
        );
    }
  }

  Future<void> _completeWelcome() async {
    setState(() {
      _onboardingCompleted = true;
      _connectFlowStage = ConnectFlowStage.chooseMethod;
    });
    await _persistConnectFlowPreferences();
  }

  Future<void> _selectConnectMethod(ConnectMethod method) async {
    setState(() {
      _connectMethod = method;
      _connectFlowStage = method == ConnectMethod.manual
          ? ConnectFlowStage.manualConfig
          : ConnectFlowStage.chooseMethod;
    });
    await _persistConnectFlowPreferences();
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
      _lastGuidance = null;
      _assistantIdentity = null;
      _models = const <ModelInfo>[];
      _currentSessionInfo = null;
      _connectMethod = ConnectMethod.manual;
      _connectFlowStage = ConnectFlowStage.manualConfig;
      _timeline = <ChatTimelineItem>[
        ChatTimelineItem(
          role: ChatTimelineRole.system,
          text:
              'Applied Gateway configuration for ${profile.url}. Token and password remain optional. Device identity and device token reuse stay local on the phone when available.',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    });

    try {
      await _profileStore.write(profile);
    } catch (error) {
      _recordError(error, prefix: 'Saving encrypted Gateway configuration failed');
    }

    await _persistConnectFlowPreferences();
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
          _appendTimeline(
            ChatTimelineRole.assistant,
            '[streaming] ${event.message!.text}',
          );
        }
        break;
      case ChatStreamState.finalMessage:
        if (event.message != null) {
          _appendTimeline(ChatTimelineRole.assistant, event.message!.text);
        }
        _activeRunId = null;
        break;
      case ChatStreamState.aborted:
        if (event.message != null) {
          _appendTimeline(ChatTimelineRole.system, event.message!.text);
        }
        _activeRunId = null;
        break;
      case ChatStreamState.error:
        _appendTimeline(
          ChatTimelineRole.system,
          event.errorMessage ?? 'Chat error',
        );
        _activeRunId = null;
        break;
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
        _lastGuidance = null;
      });
    } catch (error) {
      _recordError(error, prefix: 'Load failed');
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

  void _recordError(Object error, {String? prefix}) {
    if (!mounted) {
      return;
    }
    final guidance = gatewayErrorGuidanceFor(error);
    setState(() {
      _lastError = prefix == null ? error.toString() : '$prefix: $error';
      _lastGuidance = guidance;
      _connectFlowStage = ConnectFlowStage.error;
    });
    _appendTimeline(
      ChatTimelineRole.system,
      prefix == null ? guidance.summary : '$prefix: ${guidance.summary}',
    );
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

    unawaited(_persistSessionRegistry());
  }

  Future<void> _connect() async {
    if (_gatewayProfile.url.trim().isEmpty) {
      _appendTimeline(
        ChatTimelineRole.system,
        'Enter a Gateway URL before connecting.',
      );
      setState(() {
        _connectFlowStage = ConnectFlowStage.manualConfig;
      });
      return;
    }

    setState(() {
      _lastError = null;
      _lastGuidance = null;
      _connectFlowStage = ConnectFlowStage.authPending;
    });

    try {
      await _gatewayClient.connect();
      if (!mounted) {
        return;
      }
      setState(() {
        _connectFlowStage = ConnectFlowStage.ready;
      });
      _appendTimeline(ChatTimelineRole.system, 'Connected to ${_gatewayProfile.url}');
      await _loadCurrentViewData();
    } catch (error) {
      _recordError(error, prefix: 'Connect failed');
    }
  }

  Future<void> _disconnect() async {
    await _gatewayClient.disconnect();
    if (!mounted) {
      return;
    }
    setState(() {
      _connectFlowStage = _deriveConnectFlowStage();
    });
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
        _lastGuidance = null;
      });

      await _loadSessionInfo();
    } catch (error) {
      _recordError(error, prefix: 'Send failed');
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
      _recordError(error, prefix: 'Abort failed');
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
      _recordError(error, prefix: 'Model update failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectSnapshot = _snapshotForConnectFlow();
    final sessions = _registry.sessions;
    final showChatShell = _connectFlowStage == ConnectFlowStage.ready;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketClaw'),
        actions: [
          IconButton(
            onPressed: showChatShell ? _createSession : null,
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Create session',
          ),
        ],
      ),
      body: _isBootstrapping
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 980;
                final connectPane = SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ConnectFlowCard(
                        snapshot: connectSnapshot,
                        onboardingCompleted: _onboardingCompleted,
                        connectMethod: _connectMethod,
                        onCompleteWelcome: _completeWelcome,
                        onSelectMethod: _selectConnectMethod,
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
                        connectFlowStage: _connectFlowStage,
                        onConnect: _connect,
                        onDisconnect: _disconnect,
                      ),
                      if (_lastGuidance != null) ...[
                        const SizedBox(height: 12),
                        _GuidanceCard(guidance: _lastGuidance!),
                      ],
                      if (_lastError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _lastError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                );

                final chatPane = _ChatShell(
                  sessions: sessions,
                  currentSession: _currentSession,
                  timeline: _timeline,
                  assistantIdentity: _assistantIdentity,
                  sessionInfo: _currentSessionInfo,
                  models: _models,
                  connectionState: _connectionState,
                  activeRunId: _activeRunId,
                  messageController: _messageController,
                  onDestinationSelected: (index) {
                    _syncCurrentSessionDraft(schedulePersist: false);
                    final nextSession = sessions[index];
                    setState(() {
                      _currentSession = nextSession;
                    });
                    _applyComposerDraft(nextSession.draftText);
                    _scheduleSessionRegistryPersist();
                    unawaited(_loadCurrentViewData());
                  },
                  onSelectModel: _applyModel,
                  onSendMessage: _sendMessage,
                  onAbortRun: _abortRun,
                  iconForRole: _iconForRole,
                );

                if (compact) {
                  return ListView(
                    children: [
                      connectPane,
                      const Divider(height: 1),
                      if (showChatShell)
                        SizedBox(height: 720, child: chatPane)
                      else
                        const _ChatLockedPlaceholder(),
                    ],
                  );
                }

                return Row(
                  children: [
                    SizedBox(width: 420, child: connectPane),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: showChatShell
                          ? chatPane
                          : const _ChatLockedPlaceholder(),
                    ),
                  ],
                );
              },
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

class _ConnectFlowCard extends StatelessWidget {
  const _ConnectFlowCard({
    required this.snapshot,
    required this.onboardingCompleted,
    required this.connectMethod,
    required this.onCompleteWelcome,
    required this.onSelectMethod,
  });

  final _ConnectFlowSnapshot snapshot;
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

class _ConnectionStatusCard extends StatelessWidget {
  const _ConnectionStatusCard({
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

class _ChatShell extends StatelessWidget {
  const _ChatShell({
    required this.sessions,
    required this.currentSession,
    required this.timeline,
    required this.assistantIdentity,
    required this.sessionInfo,
    required this.models,
    required this.connectionState,
    required this.activeRunId,
    required this.messageController,
    required this.onDestinationSelected,
    required this.onSelectModel,
    required this.onSendMessage,
    required this.onAbortRun,
    required this.iconForRole,
  });

  final List<LocalSessionEntry> sessions;
  final LocalSessionEntry currentSession;
  final List<ChatTimelineItem> timeline;
  final AgentIdentity? assistantIdentity;
  final SessionInfo? sessionInfo;
  final List<ModelInfo> models;
  final GatewayConnectionState connectionState;
  final String? activeRunId;
  final TextEditingController messageController;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function(String modelId) onSelectModel;
  final Future<void> Function() onSendMessage;
  final Future<void> Function() onAbortRun;
  final IconData Function(ChatTimelineRole role) iconForRole;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: sessions.indexOf(currentSession),
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSession.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                SelectableText('Session key: ${currentSession.sessionKey.value}'),
                const SizedBox(height: 12),
                _SessionInfoCard(
                  identity: assistantIdentity,
                  sessionInfo: sessionInfo,
                  models: models,
                  onSelectModel: onSelectModel,
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
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final item = timeline[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(iconForRole(item.role)),
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
                        controller: messageController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Send a message',
                        ),
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
          ),
        ),
      ],
    );
  }
}

class _ChatLockedPlaceholder extends StatelessWidget {
  const _ChatLockedPlaceholder();

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
          ],
        ),
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
        ),
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.guidance});

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
