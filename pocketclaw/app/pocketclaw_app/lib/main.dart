import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:gateway_transport/gateway_transport.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

import 'src/app_shell/app_strings.dart';
import 'src/app_shell/chat_shell.dart';
import 'src/app_shell/connect_flow_models.dart';
import 'src/app_shell/current_session_forget_plan.dart';
import 'src/app_shell/connect_flow_stage_resolver.dart';
import 'src/app_shell/connect_surface.dart';
import 'src/bootstrap/startup_bootstrap.dart';
import 'src/chat/current_view_data_loader.dart';
import 'src/chat/pending_image_attachment.dart';
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
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale('zh'),
        Locale('zh', 'CN'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
  final TextEditingController _cloudflareAccessClientIdController =
      TextEditingController();
  final TextEditingController _cloudflareAccessClientSecretController =
      TextEditingController();
  final TextEditingController _customRequestHeadersController =
      TextEditingController();
  final TextEditingController _sessionTitleController = TextEditingController();
  late final GatewayConnectRequestFactory _connectRequestFactory =
      GatewayConnectRequestFactory(
    clientId: _gatewayClientIdForPlatform(defaultTargetPlatform),
    platform: _gatewayPlatformLabelForPlatform(defaultTargetPlatform),
    mode: 'ui',
  );
  final SecureKeyValueStore _secureStore = FlutterSecureKeyValueStore();
  final ChatTimelineController _timelineController = ChatTimelineController();

  late final GatewayProfileStore _profileStore = SecureGatewayProfileStore(
    _secureStore,
  );
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

  static String _gatewayClientIdForPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android => 'openclaw-android',
      TargetPlatform.iOS => 'openclaw-ios',
      TargetPlatform.macOS => 'openclaw-macos',
      _ => 'openclaw-android',
    };
  }

  static String _gatewayPlatformLabelForPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      TargetPlatform.windows => 'windows',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  StreamSubscription<GatewayConnectionState>? _connectionSubscription;
  StreamSubscription<GatewayEvent>? _eventSubscription;
  StreamSubscription<ChatStreamEvent>? _chatSubscription;
  Timer? _draftPersistTimer;

  GatewayConnectionState _connectionState = const GatewayConnectionState(
    phase: GatewayConnectionPhase.disconnected,
  );
  List<ChatTimelineItem> _timeline = <ChatTimelineItem>[];
  List<ModelInfo> _models = const <ModelInfo>[];
  List<AgentSummary> _agents = const <AgentSummary>[];
  List<SessionInfo> _gatewaySessions = const <SessionInfo>[];
  List<PendingImageAttachment> _pendingAttachments =
      const <PendingImageAttachment>[];
  final Map<String, List<PendingImageAttachment>> _attachmentDraftsBySession =
      <String, List<PendingImageAttachment>>{};
  AgentIdentity? _assistantIdentity;
  SessionInfo? _currentSessionInfo;
  SessionDefaults? _sessionDefaults;
  String? _activeRunId;
  String? _lastError;
  GatewayErrorGuidance? _lastGuidance;
  bool _applyingComposerDraft = false;
  bool _onboardingCompleted = false;
  bool _hasStoredDeviceIdentity = false;
  bool _hasStoredDeviceToken = false;
  bool _isBootstrapping = true;
  ConnectMethod _connectMethod = ConnectMethod.manual;
  ConnectFlowStage _connectFlowStage = ConnectFlowStage.welcome;
  AppDestination _selectedDestination = AppDestination.connect;
  String _selectedAgentId = 'main';

  @override
  void initState() {
    super.initState();
    _gatewayProfile = const GatewayProfile();
    _applyProfileToControllers(_gatewayProfile);

    _registry = LocalSessionRegistry(
      initialSessions: <LocalSessionEntry>[
        LocalSessionEntry(
          sessionKey: SessionKey.forClient(
            agentId: 'main',
            clientKey: 'pc-home',
          ),
          title: _strings.home,
        ),
      ],
    );
    _currentSession = _registry.sessions.first;
    _selectedAgentId = _agentIdForSession(_currentSession.sessionKey.value);
    _applySessionTitle(_currentSession.title);

    _gatewayClient = _buildGatewayClient(_gatewayProfile);
    _chatService = GatewayChatService(_gatewayClient);
    _sessionService = GatewaySessionService(_gatewayClient);
    _agentService = GatewayAgentService(_gatewayClient);
    _attachClientSubscriptions();

    _setTimelineItems(<ChatTimelineItem>[
      ChatTimelineItem(
        role: ChatTimelineRole.system,
        text: _strings.startupReadyMessage,
        createdAt: DateTime.now().toUtc(),
      ),
    ]);

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
    _cloudflareAccessClientIdController.dispose();
    _cloudflareAccessClientSecretController.dispose();
    _customRequestHeadersController.dispose();
    _sessionTitleController.dispose();
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
        headers: profile.webSocketHeaders,
        deviceAuthProvider: CryptographyDeviceAuthProvider(
          store: _deviceIdentityStore,
        ),
        deviceTokenStore: _deviceTokenStore,
      ),
    );
  }

  Future<void> _bootstrapLocalState() async {
    try {
      final results =
          await const SequentialBootstrapRunner().run(<BootstrapTask>[
        BootstrapTask(
          label: _strings.savedGatewayConfigurationRestore,
          action: _restorePersistedGatewayProfile,
        ),
        BootstrapTask(
          label: _strings.localSessionRestore,
          action: _restorePersistedSessionRegistry,
        ),
        BootstrapTask(
          label: _strings.connectFlowPreferenceRestore,
          action: _restoreConnectFlowPreferences,
        ),
        BootstrapTask(
          label: _strings.storedDeviceAuthRefresh,
          action: _refreshStoredDeviceAuthState,
        ),
      ]);

      if (!mounted) {
        return;
      }
      for (final result in results) {
        if (!result.didTimeout) {
          continue;
        }
        _appendTimeline(
          ChatTimelineRole.system,
          _strings.restoreTimedOut(result.label),
          status: 'warning',
        );
      }
    } finally {
      if (mounted) {
        final nextStage = _deriveConnectFlowStage();
        setState(() {
          _isBootstrapping = false;
          _connectFlowStage = nextStage;
          _selectedDestination = nextStage == ConnectFlowStage.ready
              ? AppDestination.chat
              : AppDestination.connect;
        });
      }
    }
  }

  void _applyProfileToControllers(GatewayProfile profile) {
    _gatewayUrlController.text = profile.url;
    _tokenController.text = profile.token;
    _passwordController.text = profile.password;
    _cloudflareAccessClientIdController.text = profile.cloudflareAccessClientId;
    _cloudflareAccessClientSecretController.text =
        profile.cloudflareAccessClientSecret;
    _customRequestHeadersController.text = profile.customRequestHeadersText;
  }

  String _agentIdForSession(String sessionKey) {
    final parts = sessionKey.split(':');
    if (parts.length >= 2 && parts.first == 'agent') {
      return parts[1];
    }
    return 'main';
  }

  void _applySessionTitle(String title) {
    _sessionTitleController.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );
  }

  void _setTimelineItems(Iterable<ChatTimelineItem> items) {
    _timelineController.replaceAll(items);
    _timeline = _timelineController.items;
  }

  void _appendTimelineItem(ChatTimelineItem item) {
    _timelineController.append(item);
    _timeline = _timelineController.items;
  }

  void _refreshTimelineFromController() {
    _timeline = _timelineController.items;
  }

  bool _updateTimelineItemByKey(
    String updateKey,
    ChatTimelineItem Function(ChatTimelineItem existing) transform,
  ) {
    final updated = _timelineController.updateByUpdateKey(updateKey, transform);
    if (updated) {
      _refreshTimelineFromController();
    }
    return updated;
  }

  bool _removeTimelineItemByKey(String updateKey) {
    final removed = _timelineController.removeByUpdateKey(updateKey);
    if (removed) {
      _refreshTimelineFromController();
    }
    return removed;
  }

  void _storeCurrentAttachmentDraft() {
    _attachmentDraftsBySession[_currentSession.sessionKey.value] =
        List<PendingImageAttachment>.from(_pendingAttachments);
  }

  void _restoreAttachmentDraftForCurrentSession() {
    _pendingAttachments = List<PendingImageAttachment>.from(
      _attachmentDraftsBySession[_currentSession.sessionKey.value] ??
          const <PendingImageAttachment>[],
    );
  }

  void _setPendingAttachments(List<PendingImageAttachment> attachments) {
    setState(() {
      _pendingAttachments = List<PendingImageAttachment>.from(attachments);
    });
    _storeCurrentAttachmentDraft();
  }

  String _displayNameForAgent(String agentId) {
    for (final agent in _agents) {
      if (agent.id == agentId) {
        return agent.displayName;
      }
    }
    return agentId;
  }

  AppStrings get _strings =>
      AppStrings.fromLocale(WidgetsBinding.instance.platformDispatcher.locale);

  LocalSessionEntry _localEntryForGatewaySession(
    SessionInfo session, {
    LocalSessionEntry? existing,
  }) {
    final label = session.label?.trim();
    final effectiveLabel = label != null && label.isNotEmpty ? label : null;
    return LocalSessionEntry(
      sessionKey: SessionKey.fromValue(session.key),
      title: effectiveLabel ?? existing?.title ?? session.key,
      draftText: existing?.draftText ?? '',
      origin: LocalSessionOrigin.gateway,
      gatewayLabel: effectiveLabel,
    );
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
      _recordError(error, prefix: _strings.secureConfigurationRestoreFailed);
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
        _selectedAgentId = _agentIdForSession(_currentSession.sessionKey.value);
      });
      _applyComposerDraft(_currentSession.draftText);
      _applySessionTitle(_currentSession.title);
    } catch (error) {
      _recordError(error, prefix: _strings.localSessionRestoreFailed);
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
      _recordError(error, prefix: _strings.connectFlowRestoreFailed);
    }
  }

  Future<void> _refreshStoredDeviceAuthState() async {
    try {
      final identity = await _deviceIdentityStore.read();
      final hasIdentity = identity != null;
      var hasToken = false;
      if (identity != null) {
        final token = await _deviceTokenStore.read(
          deviceId: identity.deviceId,
          role: _connectRequestFactory.role,
        );
        hasToken = token != null && token.token.trim().isNotEmpty;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _hasStoredDeviceIdentity = hasIdentity;
        _hasStoredDeviceToken = hasToken;
      });
    } catch (error) {
      _recordError(error, prefix: _strings.storedDeviceAuthRefreshFailed);
    }
  }

  Future<void> _persistSessionRegistry() async {
    try {
      await _sessionRegistryStore.write(
        registry: _registry,
        currentSessionKey: _currentSession.sessionKey.value,
      );
    } catch (error) {
      _recordError(error, prefix: _strings.savingLocalSessionsFailed);
    }
  }

  Future<void> _persistConnectFlowPreferences() async {
    try {
      await _connectFlowPreferencesStore.write(
        onboardingCompleted: _onboardingCompleted,
        lastConnectionMethod: _connectMethod.name,
      );
    } catch (error) {
      _recordError(error, prefix: _strings.savingConnectFlowPreferencesFailed);
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
    final updated = _currentSession.copyWith(
      draftText: _messageController.text,
    );
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

  Future<void> _selectCurrentSession(LocalSessionEntry session) async {
    _syncCurrentSessionDraft(schedulePersist: false);
    _storeCurrentAttachmentDraft();
    setState(() {
      _currentSession = session;
      _selectedAgentId = _agentIdForSession(session.sessionKey.value);
      _selectedDestination = AppDestination.chat;
      _restoreAttachmentDraftForCurrentSession();
    });
    _applyComposerDraft(session.draftText);
    _applySessionTitle(session.title);
    _scheduleSessionRegistryPersist();
    await _loadCurrentViewData();
  }

  Future<void> _renameCurrentSession(String title) async {
    final nextTitle = title.trim();
    if (nextTitle.isEmpty || nextTitle == _currentSession.title) {
      _applySessionTitle(_currentSession.title);
      return;
    }

    final updated = _currentSession.copyWith(title: nextTitle);
    setState(() {
      _registry.replace(updated);
      _currentSession = updated;
    });
    _applySessionTitle(nextTitle);
    await _persistSessionRegistry();

    if (_connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }
    try {
      await _sessionService.patch(
        SessionPatchParams(
          key: _currentSession.sessionKey.value,
          label: nextTitle,
        ),
      );
      await _loadSessionInfo();
    } catch (error) {
      _recordError(error, prefix: _strings.renameFailed);
    }
  }

  Future<void> _openOrCreateAgentHomeSession(String agentId) async {
    final homeKey = SessionKey.forClient(
      agentId: agentId,
      clientKey: 'pc-home',
    );
    for (final session in _registry.sessions) {
      if (session.sessionKey.value == homeKey.value) {
        await _selectCurrentSession(session);
        return;
      }
    }

    final title = _strings.agentHomeTitle(_displayNameForAgent(agentId));
    final entry = LocalSessionEntry(sessionKey: homeKey, title: title);
    setState(() {
      _registry.remember(entry);
    });
    await _persistSessionRegistry();
    await _selectCurrentSession(entry);
  }

  Future<void> _openGatewaySession(SessionInfo session) async {
    final existing = _registry.findBySessionKey(session.key);
    final entry = _localEntryForGatewaySession(session, existing: existing);
    _registry.replace(entry);
    await _persistSessionRegistry();
    await _selectCurrentSession(entry);
  }

  void _attachClientSubscriptions() {
    _connectionSubscription = _gatewayClient.connectionStates.listen((state) {
      if (!mounted) {
        return;
      }
      final nextStage = _deriveConnectFlowStageFor(state);
      setState(() {
        _connectionState = state;
        _connectFlowStage = nextStage;
        if (nextStage == ConnectFlowStage.ready) {
          if (_selectedDestination == AppDestination.connect) {
            _selectedDestination = AppDestination.chat;
          }
        } else {
          _selectedDestination = AppDestination.connect;
        }
      });
    });

    _eventSubscription = _gatewayClient.events.listen((event) {
      if (!mounted) {
        return;
      }

      final runtimeEvent = AgentRuntimeEvent.tryParse(event);
      if (runtimeEvent != null &&
          (_activeRunId == null || runtimeEvent.runId == _activeRunId)) {
        if (runtimeEvent.kind == AgentRuntimeEventKind.tool ||
            runtimeEvent.kind == AgentRuntimeEventKind.internal) {
          setState(() {
            _timelineController.applyRuntimeEvent(runtimeEvent);
            _timeline = _timelineController.items;
          });
        }
        return;
      }

      if (event.event == 'connect.challenge') {
        _appendTimeline(
          ChatTimelineRole.system,
          _strings.receivedDeviceAuthChallenge,
        );
        setState(() {
          _connectFlowStage = ConnectFlowStage.authPending;
          _selectedDestination = AppDestination.connect;
        });
        return;
      }
      if (event.event.contains('pair') || event.event.contains('device')) {
        setState(() {
          _connectFlowStage = ConnectFlowStage.pairingPending;
          _selectedDestination = AppDestination.connect;
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
    final nextStage = _deriveConnectFlowStage();
    setState(() {
      _connectFlowStage = nextStage;
      if (nextStage != ConnectFlowStage.ready) {
        _selectedDestination = AppDestination.connect;
      }
    });
  }

  ConnectFlowStage _deriveConnectFlowStage() {
    return _deriveConnectFlowStageFor(_connectionState);
  }

  ConnectFlowStage _deriveConnectFlowStageFor(GatewayConnectionState state) {
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
    switch (state.phase) {
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

  ConnectFlowSnapshot _snapshotForConnectFlow() {
    final strings = AppStrings.fromLocale(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
    switch (_connectFlowStage) {
      case ConnectFlowStage.welcome:
        return ConnectFlowSnapshot(
          stage: ConnectFlowStage.welcome,
          title: strings.welcomeTitle,
          description: strings.welcomeDescription,
        );
      case ConnectFlowStage.chooseMethod:
        return ConnectFlowSnapshot(
          stage: ConnectFlowStage.chooseMethod,
          title: strings.chooseMethodTitle,
          description: strings.chooseMethodDescription,
        );
      case ConnectFlowStage.manualConfig:
        return ConnectFlowSnapshot(
          stage: ConnectFlowStage.manualConfig,
          title: strings.manualConnectionTitle,
          description: strings.manualConnectionDescription,
        );
      case ConnectFlowStage.authPending:
        return ConnectFlowSnapshot(
          stage: ConnectFlowStage.authPending,
          title: strings.authenticatingTitle,
          description: strings.authenticatingDescription,
          requiresAttention: true,
        );
      case ConnectFlowStage.authRequired:
        return ConnectFlowSnapshot(
          stage: ConnectFlowStage.authRequired,
          title: strings.authenticationRequiredTitle,
          description: strings.authenticationRequiredDescription,
          requiresAttention: true,
        );
      case ConnectFlowStage.pairingPending:
        return ConnectFlowSnapshot(
          stage: ConnectFlowStage.pairingPending,
          title: strings.pairingPendingTitle,
          description: strings.pairingPendingDescription,
          requiresAttention: true,
        );
      case ConnectFlowStage.ready:
        return ConnectFlowSnapshot(
          stage: ConnectFlowStage.ready,
          title: strings.readyToChatTitle,
          description: strings.readyToChatDescription,
        );
      case ConnectFlowStage.error:
        return ConnectFlowSnapshot(
          stage: ConnectFlowStage.error,
          title: strings.needsAttentionTitle,
          description: strings.needsAttentionDescription,
          requiresAttention: true,
        );
    }
  }

  Future<void> _completeWelcome() async {
    setState(() {
      _onboardingCompleted = true;
      _connectFlowStage = ConnectFlowStage.chooseMethod;
      _selectedDestination = AppDestination.connect;
    });
    await _persistConnectFlowPreferences();
  }

  Future<void> _selectConnectMethod(ConnectMethod method) async {
    setState(() {
      _connectMethod = method;
      _connectFlowStage = method == ConnectMethod.manual
          ? ConnectFlowStage.manualConfig
          : ConnectFlowStage.chooseMethod;
      _selectedDestination = AppDestination.connect;
    });
    await _persistConnectFlowPreferences();
  }

  bool _hasUnsavedGatewayConfiguration() {
    return normalizeGatewayUrl(_gatewayUrlController.text) !=
            _gatewayProfile.url ||
        _tokenController.text != _gatewayProfile.token ||
        _passwordController.text != _gatewayProfile.password ||
        _cloudflareAccessClientIdController.text !=
            _gatewayProfile.cloudflareAccessClientId ||
        _cloudflareAccessClientSecretController.text !=
            _gatewayProfile.cloudflareAccessClientSecret ||
        _customRequestHeadersController.text !=
            _gatewayProfile.customRequestHeadersText;
  }

  Future<void> _applyGatewayConfiguration({bool announce = true}) async {
    try {
      parseGatewayRequestHeadersText(
        _customRequestHeadersController.text,
        strict: true,
      );
    } on FormatException catch (error) {
      _recordError(error, prefix: _strings.gatewayConfigurationInvalid);
      return;
    }

    final profile = _gatewayProfile.copyWith(
      url: normalizeGatewayUrl(_gatewayUrlController.text),
      token: _tokenController.text,
      password: _passwordController.text,
      cloudflareAccessClientId: _cloudflareAccessClientIdController.text.trim(),
      cloudflareAccessClientSecret:
          _cloudflareAccessClientSecretController.text.trim(),
      customRequestHeadersText: _customRequestHeadersController.text,
    );
    _applyProfileToControllers(profile);

    setState(() {
      _gatewayProfile = profile;
      _lastError = null;
      _lastGuidance = null;
      _assistantIdentity = null;
      _models = const <ModelInfo>[];
      _currentSessionInfo = null;
      _sessionDefaults = null;
      _connectMethod = ConnectMethod.manual;
      _connectFlowStage = ConnectFlowStage.manualConfig;
      _selectedDestination = AppDestination.connect;
      if (announce) {
        _setTimelineItems(<ChatTimelineItem>[
          ChatTimelineItem(
            role: ChatTimelineRole.system,
            text: _strings.appliedGatewayConfiguration(profile.url),
            createdAt: DateTime.now().toUtc(),
          ),
          if (gatewayUrlUsesLoopback(profile.url))
            ChatTimelineItem(
              role: ChatTimelineRole.system,
              text: _strings.loopbackWarningMessage,
              createdAt: DateTime.now().toUtc(),
              status: 'warning',
            ),
        ]);
      }
    });

    try {
      await _profileStore.write(profile);
    } catch (error) {
      _recordError(
        error,
        prefix: _strings.savingEncryptedGatewayConfigurationFailed,
      );
    }

    await _persistConnectFlowPreferences();
    await _replaceGatewayClient(_buildGatewayClient(profile));
  }

  void _handleChatStreamEvent(ChatStreamEvent event) {
    if (event.sessionKey != _currentSession.sessionKey.value || !mounted) {
      return;
    }

    setState(() {
      if (event.runId != null) {
        _activeRunId = event.runId;
      }
      _timelineController.applyChatStreamEvent(event);
      _timeline = _timelineController.items;
      if (event.state == ChatStreamState.finalMessage ||
          event.state == ChatStreamState.aborted ||
          event.state == ChatStreamState.error) {
        _activeRunId = null;
      }
    });
  }

  Future<void> _loadCurrentViewData() async {
    if (_connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    final results = await const CurrentViewDataLoader().run(<ViewDataTask>[
      ViewDataTask(
        label: _strings.chatHistoryLoad,
        action: _loadHistoryForCurrentSession,
      ),
      ViewDataTask(
        label: _strings.assistantIdentityLoad,
        action: _loadAssistantIdentity,
      ),
      ViewDataTask(label: _strings.modelListLoad, action: _loadModels),
      ViewDataTask(label: _strings.sessionInfoLoad, action: _loadSessionInfo),
      ViewDataTask(label: _strings.agentListLoad, action: _loadAgents),
    ]);

    if (!mounted) {
      return;
    }

    final failures = results.where((result) => result.didFail).toList();
    if (failures.isEmpty) {
      setState(() {
        _lastError = null;
        _lastGuidance = null;
      });
      return;
    }

    final firstFailure = failures.first;
    final firstError = firstFailure.error ??
        StateError(_strings.taskFailed(firstFailure.label));
    final guidance = gatewayErrorGuidanceFor(
      firstError,
      configuredUrl: _gatewayProfile.url,
    );

    setState(() {
      _lastError = _strings.loadIssue(firstFailure.label, firstError);
      _lastGuidance = guidance;
      if (_connectionState.phase == GatewayConnectionPhase.connected) {
        _connectFlowStage = ConnectFlowStage.ready;
      }
    });

    for (final failure in failures) {
      final error = failure.error;
      final summary = gatewayErrorGuidanceFor(
        error ?? StateError(_strings.taskFailed(failure.label)),
        configuredUrl: _gatewayProfile.url,
      ).summary;
      _appendTimeline(
        ChatTimelineRole.system,
        _strings.loadFailed(failure.label, summary),
        status: 'warning',
        details: error?.toString(),
      );
    }
  }

  Future<void> _loadHistoryForCurrentSession() async {
    final history = await _chatService.loadHistory(
      sessionKey: _currentSession.sessionKey.value,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _timelineController.replaceHistory(history.messages);
      _timeline = _timelineController.items;
    });
  }

  Future<void> _loadAssistantIdentity() async {
    final identity = await _agentService.getIdentity(
      sessionKey: _currentSession.sessionKey.value,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _assistantIdentity = identity;
    });
  }

  Future<void> _loadModels() async {
    final models = await _agentService.listModels();

    if (!mounted) {
      return;
    }
    setState(() {
      _models = models;
    });
  }

  Future<void> _loadSessionInfo() async {
    final result = await _sessionService.list();
    final targetKey = _currentSession.sessionKey.value;
    SessionInfo? info;
    var registryChanged = false;

    for (final session in result.sessions) {
      if (session.key == targetKey) {
        info = session;
      }
      final existing = _registry.findBySessionKey(session.key);
      if (existing == null || !existing.isGatewayBacked) {
        continue;
      }
      final synced = _localEntryForGatewaySession(session, existing: existing);
      if (synced.title != existing.title ||
          synced.gatewayLabel != existing.gatewayLabel ||
          synced.draftText != existing.draftText ||
          synced.origin != existing.origin) {
        _registry.replace(synced);
        if (_currentSession.sessionKey.value == synced.sessionKey.value) {
          _currentSession = synced;
          _applySessionTitle(synced.title);
        }
        registryChanged = true;
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _gatewaySessions = result.sessions;
      _currentSessionInfo = info;
      _sessionDefaults = result.defaults;
    });

    if (registryChanged) {
      await _persistSessionRegistry();
    }
  }

  Future<void> _loadAgents() async {
    final result = await _agentService.listAgents();
    if (!mounted) {
      return;
    }
    setState(() {
      _agents = result.agents;
      if (_selectedAgentId.isEmpty) {
        _selectedAgentId = result.defaultId;
      }
    });
  }

  void _recordError(Object error, {String? prefix}) {
    if (!mounted) {
      return;
    }
    final guidance = gatewayErrorGuidanceFor(
      error,
      configuredUrl: _gatewayProfile.url,
    );
    final nextStage = resolveConnectFlowStageForError(error);
    setState(() {
      _lastError = prefix == null ? error.toString() : '$prefix: $error';
      _lastGuidance = guidance;
      _connectFlowStage = nextStage;
      _selectedDestination = AppDestination.connect;
    });
    _appendTimeline(
      ChatTimelineRole.system,
      prefix == null ? guidance.summary : '$prefix: ${guidance.summary}',
      status: nextStage == ConnectFlowStage.error ? null : 'warning',
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    final strings = AppStrings.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.copied)));
  }

  void _appendTimeline(
    ChatTimelineRole role,
    String text, {
    String? title,
    String? status,
    String? details,
    DateTime? createdAt,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      _appendTimelineItem(
        ChatTimelineItem(
          role: role,
          text: text,
          createdAt: createdAt ?? DateTime.now().toUtc(),
          title: title,
          status: status,
          details: details,
        ),
      );
    });
  }

  void _createSession() {
    _storeCurrentAttachmentDraft();
    final sessionKey = _sessionKeyFactory.createTimestamped(
      agentId: _selectedAgentId,
    );
    final entry = LocalSessionEntry(
      sessionKey: sessionKey,
      title:
          '${_displayNameForAgent(_selectedAgentId)} ${_registry.sessions.length + 1}',
    );

    setState(() {
      _registry.remember(entry);
      _currentSession = entry;
      _selectedDestination = AppDestination.chat;
      _pendingAttachments = const <PendingImageAttachment>[];
      _setTimelineItems(<ChatTimelineItem>[
        ChatTimelineItem(
          role: ChatTimelineRole.system,
          text: _strings.createdLocalSession(entry.sessionKey.value),
          createdAt: DateTime.now().toUtc(),
        ),
      ]);
      _currentSessionInfo = null;
      _sessionDefaults = null;
    });

    _attachmentDraftsBySession[entry.sessionKey.value] =
        const <PendingImageAttachment>[];
    _applySessionTitle(entry.title);
    unawaited(_persistSessionRegistry());
  }

  Future<void> _forgetCurrentSession() async {
    final plan = CurrentSessionForgetPlan.forCurrentSession(
      sessions: _registry.sessions,
      currentSessionKey: _currentSession.sessionKey.value,
    );
    if (plan == null) {
      return;
    }

    _syncCurrentSessionDraft(schedulePersist: false);
    _storeCurrentAttachmentDraft();

    final removedSession = plan.removedSession;
    final nextSession = plan.nextSession;
    _attachmentDraftsBySession.remove(removedSession.sessionKey.value);

    setState(() {
      _registry.removeBySessionKey(removedSession.sessionKey.value);
      _currentSession = nextSession;
      _selectedAgentId = _agentIdForSession(nextSession.sessionKey.value);
      _selectedDestination = AppDestination.chat;
      _restoreAttachmentDraftForCurrentSession();
      _setTimelineItems(<ChatTimelineItem>[
        ChatTimelineItem(
          role: ChatTimelineRole.system,
          text: removedSession.isGatewayBacked
              ? _strings.forgotLocalShortcutFor(
                  removedSession.sessionKey.value,
                  nextSession.title,
                )
              : _strings.removedLocalSessionFromPhone(
                  removedSession.sessionKey.value,
                  nextSession.title,
                ),
          createdAt: DateTime.now().toUtc(),
        ),
      ]);
      _currentSessionInfo = null;
      _sessionDefaults = null;
    });

    _applyComposerDraft(nextSession.draftText);
    _applySessionTitle(nextSession.title);
    await _persistSessionRegistry();
    await _loadCurrentViewData();
  }

  String? _mimeTypeForImageName(String name) {
    final normalized = name.toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    if (normalized.endsWith('.gif')) {
      return 'image/gif';
    }
    if (normalized.endsWith('.bmp')) {
      return 'image/bmp';
    }
    if (normalized.endsWith('.heic')) {
      return 'image/heic';
    }
    if (normalized.endsWith('.heif')) {
      return 'image/heif';
    }
    return null;
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final next = <PendingImageAttachment>[..._pendingAttachments];
      for (final file in result.files) {
        final bytes = file.bytes;
        final name = file.name;
        final mimeType = _mimeTypeForImageName(name);
        if (bytes == null || mimeType == null) {
          continue;
        }
        next.add(
          PendingImageAttachment(
            id: '${DateTime.now().microsecondsSinceEpoch}-${next.length}',
            name: name,
            mimeType: mimeType,
            base64Content: base64Encode(bytes),
          ),
        );
      }

      if (next.length == _pendingAttachments.length) {
        _appendTimeline(
          ChatTimelineRole.system,
          _strings.noSupportedImageFilesAdded,
        );
        return;
      }
      _setPendingAttachments(next);
    } catch (error) {
      _recordError(error, prefix: _strings.imagePickFailed);
    }
  }

  void _removePendingAttachment(String id) {
    final next = _pendingAttachments.where((item) => item.id != id).toList();
    _setPendingAttachments(next);
  }

  Future<void> _connect() async {
    final configuredUrl = normalizeGatewayUrl(_gatewayUrlController.text);
    if (configuredUrl.isEmpty) {
      _appendTimeline(
        ChatTimelineRole.system,
        _strings.enterGatewayUrlBeforeConnecting,
      );
      setState(() {
        _connectFlowStage = ConnectFlowStage.manualConfig;
      });
      return;
    }

    if (_hasUnsavedGatewayConfiguration()) {
      await _applyGatewayConfiguration(announce: false);
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
        _selectedDestination = AppDestination.chat;
      });
      _appendTimeline(
        ChatTimelineRole.system,
        _strings.connectedTo(_gatewayProfile.url),
      );
      await _refreshStoredDeviceAuthState();
      await _loadCurrentViewData();
    } catch (error) {
      _recordError(error, prefix: _strings.connectFailed);
    }
  }

  Future<void> _disconnect() async {
    await _gatewayClient.disconnect();
    if (!mounted) {
      return;
    }
    final nextStage = _deriveConnectFlowStage();
    setState(() {
      _connectFlowStage = nextStage;
      if (nextStage != ConnectFlowStage.ready) {
        _selectedDestination = AppDestination.connect;
      }
    });
    _appendTimeline(
      ChatTimelineRole.system,
      _strings.disconnectedFrom(_gatewayProfile.url),
    );
  }

  Future<void> _sendMessage() async {
    final previousDraft = _messageController.text;
    final text = previousDraft.trim();
    final attachments = List<PendingImageAttachment>.from(_pendingAttachments);
    if ((text.isEmpty && attachments.isEmpty) ||
        _connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    final optimisticText = <String>[
      if (text.isNotEmpty) text,
      if (attachments.isNotEmpty)
        attachments.length == 1
            ? _strings.optimisticSingleImage
            : _strings.optimisticImages(attachments.length),
    ].join('\n');
    final optimisticKey =
        'optimistic:user:${DateTime.now().microsecondsSinceEpoch}';

    setState(() {
      _appendTimelineItem(
        ChatTimelineItem(
          role: ChatTimelineRole.user,
          text: optimisticText,
          createdAt: DateTime.now().toUtc(),
          status: 'sending',
          updateKey: optimisticKey,
        ),
      );
    });
    _messageController.clear();
    _setPendingAttachments(const <PendingImageAttachment>[]);

    try {
      final response = await _chatService.send(
        sessionKey: _currentSession.sessionKey.value,
        message: text,
        attachments: attachments
            .map((attachment) => attachment.toGatewayAttachment())
            .toList(),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _updateTimelineItemByKey(
          optimisticKey,
          (existing) => existing.copyWith(status: null),
        );
        _activeRunId = response.payload?['runId'] as String?;
        _lastError = null;
        _lastGuidance = null;
      });

      await _loadSessionInfo();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _removeTimelineItemByKey(optimisticKey);
      });
      _applyComposerDraft(previousDraft);
      _setPendingAttachments(attachments);
      _recordError(error, prefix: _strings.sendFailed);
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
      _recordError(error, prefix: _strings.abortFailed);
    }
  }

  Future<void> _applyModel(String? modelId) async {
    if (_connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    try {
      await _sessionService.patch(
        SessionPatchParams(
          key: _currentSession.sessionKey.value,
          model: modelId,
          clearModel: modelId == null,
        ),
      );
      await _loadSessionInfo();
    } catch (error) {
      _recordError(error, prefix: _strings.modelUpdateFailed);
    }
  }

  Future<void> _applyThinkingLevel(String? thinkingLevel) async {
    if (_connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    try {
      await _sessionService.patch(
        SessionPatchParams(
          key: _currentSession.sessionKey.value,
          thinkingLevel: thinkingLevel,
          clearThinkingLevel: thinkingLevel == null,
        ),
      );
      await _loadSessionInfo();
    } catch (error) {
      _recordError(error, prefix: _strings.thinkingUpdateFailed);
    }
  }

  Future<void> _applyVerboseLevel(String? verboseLevel) async {
    if (_connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    try {
      await _sessionService.patch(
        SessionPatchParams(
          key: _currentSession.sessionKey.value,
          verboseLevel: verboseLevel,
          clearVerboseLevel: verboseLevel == null,
        ),
      );
      await _loadSessionInfo();
    } catch (error) {
      _recordError(error, prefix: _strings.verboseUpdateFailed);
    }
  }

  Future<void> _toggleFastMode(bool enabled) async {
    if (_connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    try {
      await _sessionService.patch(
        SessionPatchParams(
          key: _currentSession.sessionKey.value,
          fastMode: enabled,
        ),
      );
      await _loadSessionInfo();
    } catch (error) {
      _recordError(error, prefix: _strings.fastModeUpdateFailed);
    }
  }

  Future<void> _clearFastModeOverride() async {
    if (_connectionState.phase != GatewayConnectionPhase.connected) {
      return;
    }

    try {
      await _sessionService.patch(
        SessionPatchParams(
          key: _currentSession.sessionKey.value,
          clearFastMode: true,
        ),
      );
      await _loadSessionInfo();
    } catch (error) {
      _recordError(error, prefix: _strings.fastModeResetFailed);
    }
  }

  void _selectDestination(AppDestination destination) {
    if (_selectedDestination == destination) {
      return;
    }
    setState(() {
      _selectedDestination = destination;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final connectSnapshot = _snapshotForConnectFlow();
    final sessions = _registry.sessions;
    final showChatShell = _connectFlowStage == ConnectFlowStage.ready;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        final connectPane = SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConnectFlowCard(
                snapshot: connectSnapshot,
                onboardingCompleted: _onboardingCompleted,
                connectMethod: _connectMethod,
                onCompleteWelcome: _completeWelcome,
                onSelectMethod: _selectConnectMethod,
              ),
              const SizedBox(height: 12),
              GatewayConfigCard(
                gatewayUrlController: _gatewayUrlController,
                tokenController: _tokenController,
                passwordController: _passwordController,
                cloudflareAccessClientIdController:
                    _cloudflareAccessClientIdController,
                cloudflareAccessClientSecretController:
                    _cloudflareAccessClientSecretController,
                customRequestHeadersController: _customRequestHeadersController,
                onApply: _applyGatewayConfiguration,
              ),
              const SizedBox(height: 12),
              ConnectionStatusCard(
                state: _connectionState,
                connectFlowStage: _connectFlowStage,
                onConnect: _connect,
                onDisconnect: _disconnect,
              ),
              if (_lastGuidance != null) ...[
                const SizedBox(height: 12),
                GuidanceCard(guidance: _lastGuidance!),
              ],
              if (_lastError != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onLongPress: () => unawaited(_copyToClipboard(_lastError!)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.rawErrorTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _lastError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.longPressToCopy,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

        final chatPane = ChatShell(
          sessions: sessions,
          currentSession: _currentSession,
          timeline: _timeline,
          assistantIdentity: _assistantIdentity,
          sessionInfo: _currentSessionInfo,
          sessionDefaults: _sessionDefaults,
          agents: _agents,
          selectedAgentId: _selectedAgentId,
          gatewaySessions: _gatewaySessions,
          models: _models,
          connectionState: _connectionState,
          activeRunId: _activeRunId,
          pendingAttachments: _pendingAttachments,
          sessionTitleController: _sessionTitleController,
          messageController: _messageController,
          onDestinationSelected: (index) {
            unawaited(_selectCurrentSession(sessions[index]));
          },
          onSessionTitleSubmitted: _renameCurrentSession,
          onSelectAgent: _openOrCreateAgentHomeSession,
          onOpenGatewaySession: _openGatewaySession,
          onForgetCurrentSession: _forgetCurrentSession,
          onSelectModel: _applyModel,
          onSelectThinking: _applyThinkingLevel,
          onSelectVerbose: _applyVerboseLevel,
          onToggleFastMode: _toggleFastMode,
          onClearFastModeOverride: _clearFastModeOverride,
          onPickImages: _pickImages,
          onRemoveAttachment: _removePendingAttachment,
          onSendMessage: _sendMessage,
          onAbortRun: _abortRun,
          iconForRole: _iconForRole,
        );

        final mobileBody = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: AppStatusBanner(
                snapshot: connectSnapshot,
                connectionState: _connectionState,
                gatewayUrl: _gatewayProfile.url,
                hasBootstrapCredentials:
                    _gatewayProfile.token.trim().isNotEmpty ||
                        _gatewayProfile.password.trim().isNotEmpty,
                hasStoredDeviceIdentity: _hasStoredDeviceIdentity,
                hasStoredDeviceToken: _hasStoredDeviceToken,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (_selectedDestination) {
                  AppDestination.connect => KeyedSubtree(
                      key: const ValueKey<String>('connect-pane'),
                      child: connectPane,
                    ),
                  AppDestination.chat when showChatShell => KeyedSubtree(
                      key: const ValueKey<String>('chat-pane'),
                      child: chatPane,
                    ),
                  AppDestination.chat => KeyedSubtree(
                      key: const ValueKey<String>('chat-locked'),
                      child: ChatLockedPlaceholder(
                        onOpenConnect: () =>
                            _selectDestination(AppDestination.connect),
                      ),
                    ),
                },
              ),
            ),
          ],
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(strings.appTitle),
            actions: [
              IconButton(
                onPressed: showChatShell ? _createSession : null,
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: strings.createSession,
              ),
            ],
          ),
          body: _isBootstrapping
              ? const Center(child: CircularProgressIndicator())
              : compact
                  ? mobileBody
                  : Row(
                      children: [
                        SizedBox(width: 420, child: connectPane),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: showChatShell
                              ? chatPane
                              : const ChatLockedPlaceholder(),
                        ),
                      ],
                    ),
          bottomNavigationBar: _isBootstrapping || !compact
              ? null
              : NavigationBar(
                  selectedIndex: _selectedDestination.index,
                  onDestinationSelected: (index) {
                    _selectDestination(AppDestination.values[index]);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.chat_bubble_outline),
                      selectedIcon: const Icon(Icons.chat_bubble),
                      label: strings.chat,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.hub_outlined),
                      selectedIcon: const Icon(Icons.hub),
                      label: strings.connect,
                    ),
                  ],
                ),
        );
      },
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
