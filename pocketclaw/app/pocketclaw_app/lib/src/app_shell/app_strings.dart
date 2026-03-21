import 'package:flutter/material.dart';

final class AppStrings {
  AppStrings._(this._isZh);

  final bool _isZh;

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings._(locale.languageCode.toLowerCase().startsWith('zh'));
  }

  static AppStrings fromLocale(Locale locale) {
    return AppStrings._(locale.languageCode.toLowerCase().startsWith('zh'));
  }

  String get appTitle => 'PocketClaw';
  String get copied => _isZh ? '已复制到剪贴板' : 'Copied to clipboard';
  String get longPressToCopy => _isZh ? '长按可复制' : 'Long press to copy';
  String get noGatewayConfigured =>
      _isZh ? '尚未配置 Gateway' : 'No Gateway configured yet';
  String get bootstrapSaved =>
      _isZh ? '已保存引导凭据' : 'Bootstrap credentials saved';
  String get noBootstrap => _isZh ? '未配置引导凭据' : 'No bootstrap credentials';
  String get reconnectTokenAvailable =>
      _isZh ? '可用重连令牌' : 'Reconnect token available';
  String get deviceIdentitySaved => _isZh ? '设备身份已保存' : 'Device identity saved';
  String get firstPairingLikely =>
      _isZh ? '可能需要首次配对' : 'First pairing likely needed';
  String get loopbackUrl => _isZh ? '本机回环地址' : 'Loopback URL';
  String get loopbackWarning => _isZh
      ? '在真机上，127.0.0.1 / localhost 指向的是手机自己。请改用 Gateway 所在主机的 IP、局域网主机名、Tailscale 名称或公网域名。'
      : '127.0.0.1 / localhost points to the phone itself on a real device. Use your Gateway host IP, LAN hostname, Tailscale name, or public domain instead.';
  String get startSetup => _isZh ? '开始设置' : 'Start setup';
  String get onboardingComplete => _isZh ? '初始化已完成' : 'Onboarding complete';
  String get manualConnect => _isZh ? '手动连接' : 'Manual connect';
  String get setupCodeLater => _isZh ? '配置码（稍后）' : 'Setup code (later)';
  String get gatewayConfiguration =>
      _isZh ? 'Gateway 配置' : 'Gateway configuration';
  String get gatewayIntro => _isZh
      ? '手动连接是基础路径。Token 和密码是可选的引导凭据。首次成功批准后，可复用的设备认证会保留在手机本地。需要特殊请求头时，可在“更多选项”里展开配置。'
      : 'Manual connect is the baseline path. Token and password are optional bootstrap credentials. Reusable device auth should stay local after the first successful approval. If you need special request headers, expand More options below.';
  String get gatewayUrlLabel => _isZh ? 'Gateway 地址' : 'Gateway URL';
  String get gatewayUrlHint => _isZh
      ? '例如 https://gateway.example.com 或 192.168.1.20:18789'
      : 'https://gateway.example.com or 192.168.1.20:18789';
  String get gatewayUrlHelp => _isZh
      ? '可以粘贴 http(s) 或 ws(s)。在真机上，除非 Gateway 就运行在同一台设备上，否则不要使用 127.0.0.1 / localhost。'
      : 'You can paste http(s) or ws(s). On a real phone, do not use 127.0.0.1 / localhost unless the Gateway runs on that same device.';
  String get token => 'Token';
  String get password => _isZh ? '密码' : 'Password';
  String get cfAccessClientId => _isZh
      ? 'Cloudflare Access Client ID（可选）'
      : 'Cloudflare Access Client ID (optional)';
  String get cfAccessClientSecret => _isZh
      ? 'Cloudflare Access Client Secret（可选）'
      : 'Cloudflare Access Client Secret (optional)';
  String get cfAccessHelp => _isZh
      ? '仅当 Gateway 域名受 Cloudflare Access service token 策略保护时使用。'
      : 'Use this only when the Gateway host is protected by Cloudflare Access service-token policies.';
  String get moreOptions => _isZh ? '更多选项' : 'More options';
  String get moreOptionsHelp => _isZh
      ? '把 Cloudflare Access 与自定义请求头折叠到这里，降低普通用户的操作压力。'
      : 'Cloudflare Access and custom request headers live here so the default connect flow stays simple.';
  String get customRequestHeaders =>
      _isZh ? '自定义请求头（可选）' : 'Custom request headers (optional)';
  String get customRequestHeadersHint => _isZh
      ? '每行一条，例如\nX-Custom-Auth: value\nCF-Access-Client-Id: ...'
      : 'One per line, for example\nX-Custom-Auth: value\nCF-Access-Client-Id: ...';
  String get customRequestHeadersHelp => _isZh
      ? '用于 Cloudflare、Zero Trust、反向代理等场景。格式必须是“Header-Name: value”，空行和 # 注释会被忽略。'
      : 'Use this for Cloudflare, Zero Trust, reverse proxies, or other edge cases. Each line must be "Header-Name: value". Blank lines and # comments are ignored.';
  String get saveConnectionSettings =>
      _isZh ? '保存连接设置' : 'Save connection settings';
  String gatewayState(String state) => _isZh
      ? 'Gateway 状态：${connectionPhase(state)}'
      : 'Gateway state: ${connectionPhase(state)}';
  String connectionPhase(String phase) => switch (phase) {
        'connected' => _isZh ? '已连接' : 'connected',
        'disconnected' => _isZh ? '未连接' : 'disconnected',
        'connecting' => _isZh ? '连接中' : 'connecting',
        'error' => _isZh ? '错误' : 'error',
        'challengeReceived' => _isZh ? '收到挑战' : 'challenge received',
        _ => phase,
      };
  String flowStage(String stage) {
    final label = switch (stage) {
      'welcome' => _isZh ? '欢迎' : 'Welcome',
      'chooseMethod' => _isZh ? '选择连接方式' : 'Choose method',
      'manualConfig' => _isZh ? '手动配置' : 'Manual config',
      'authPending' => _isZh ? '正在认证' : 'Authenticating',
      'authRequired' => _isZh ? '需要认证' : 'Authentication required',
      'pairingPending' => _isZh ? '等待配对批准' : 'Pairing pending',
      'ready' => _isZh ? '已就绪' : 'Ready',
      'error' => _isZh ? '错误' : 'Error',
      _ => stage,
    };
    return _isZh ? '流程阶段：$label' : 'Flow stage: $label';
  }

  String get connect => _isZh ? '连接' : 'Connect';
  String get disconnect => _isZh ? '断开连接' : 'Disconnect';
  String get chat => _isZh ? '聊天' : 'Chat';
  String get finishConnectionFlowFirst =>
      _isZh ? '请先完成连接流程' : 'Finish the connection flow first';
  String get chatLockedDescription => _isZh
      ? 'PocketClaw 会在连接可用后再开放聊天界面，避免在尚未稳定连接前看起来像调试页面。'
      : 'PocketClaw keeps the chat shell behind a usable Gateway setup so the app does not feel like a debug screen before it can reconnect cleanly.';
  String get openConnect => _isZh ? '打开连接页' : 'Open connect';
  String get rawErrorTitle => _isZh ? '原始错误' : 'Raw error';
  String get stateLabel => _isZh ? '状态' : 'State';
  String get welcomeTitle => _isZh ? '欢迎' : 'Welcome';
  String get welcomeDescription => _isZh
      ? 'PocketClaw 用于连接现有的 OpenClaw Gateway。先完成快速初始化，再选择这台手机的连接方式。'
      : 'PocketClaw connects to an existing OpenClaw Gateway. Finish the quick onboarding, then choose how this phone should connect.';
  String get chooseMethodTitle => _isZh ? '选择连接方式' : 'Choose connection method';
  String get chooseMethodDescription => _isZh
      ? '手动连接是基础路径，应始终可用。配置码流程可以在客户端路径成熟后再补。'
      : 'Manual connect is the baseline flow and should always work. Setup code can be added later when the client path is ready.';
  String get manualConnectionTitle => _isZh ? '手动连接' : 'Manual connection';
  String get manualConnectionDescription => _isZh
      ? '输入 Gateway 地址和可选引导凭据。PocketClaw 会把可复用认证保存在本地，方便下次重连。'
      : 'Enter the Gateway URL and optional bootstrap credentials. PocketClaw will store reusable auth locally so reconnect can work next time.';
  String get authenticatingTitle => _isZh ? '正在认证' : 'Authenticating';
  String get authenticatingDescription => _isZh
      ? '应用正在尝试引导凭据或应答设备认证挑战。如果需要在别处批准，请保持此页面打开并批准该设备。'
      : 'The app is trying bootstrap credentials or answering device-auth challenges. If approval is needed elsewhere, keep this screen open and approve the device.';
  String get authenticationRequiredTitle =>
      _isZh ? '需要认证' : 'Authentication required';
  String get authenticationRequiredDescription => _isZh
      ? 'Gateway 已返回明确的认证阻塞。请检查 token / 密码 / 设备认证状态，或先完成设备批准后再重试。'
      : 'The Gateway reported an explicit authentication blocker. Check the token, password, or device-auth state, or approve this device before retrying.';
  String get pairingPendingTitle => _isZh ? '等待配对批准' : 'Pairing pending';
  String get pairingPendingDescription => _isZh
      ? 'Gateway 仍需要设备批准或配对。一旦批准，PocketClaw 应该能自动复用下发的 device token。'
      : 'The Gateway still needs device approval or pairing. Once approved, PocketClaw should be able to reuse the issued device token automatically.';
  String get readyToChatTitle => _isZh ? '可以开始聊天' : 'Ready to chat';
  String get readyToChatDescription => _isZh
      ? '连接已经可用。现在可以进入聊天界面，之后重连也会更轻量。'
      : 'Connection setup is usable. You can enter the chat shell now, and reconnect should be much lighter next time.';
  String get needsAttentionTitle => _isZh ? '需要处理' : 'Needs attention';
  String get needsAttentionDescription => _isZh
      ? '连接流程被某些问题阻塞了。请查看下方指引，必要时调整配置后重试。'
      : 'Something blocked the connection flow. Review the guidance below, adjust the config if needed, then try again.';

  String get sessionLabel => _isZh ? '会话' : 'Session';
  String get sessionTitleLabel => _isZh ? '会话标题' : 'Session title';
  String sessionKey(String key) => _isZh ? '会话键：$key' : 'Session key: $key';
  String get gatewaySession => _isZh ? 'Gateway 会话' : 'Gateway session';
  String get localPocketClawSession =>
      _isZh ? '本地 PocketClaw 会话' : 'Local PocketClaw session';
  String get draftSavedLocally => _isZh ? '草稿已保存在本地' : 'Draft saved locally';
  String get noLocalDraft => _isZh ? '没有本地草稿' : 'No local draft';
  String get forgetLocalShortcut =>
      _isZh ? '忘记本地快捷入口' : 'Forget local shortcut';
  String get removeFromPhone => _isZh ? '从手机中移除' : 'Remove from phone';
  String get forgetGatewayShortcutTitle =>
      _isZh ? '要忘记这个 Gateway 快捷入口吗？' : 'Forget this Gateway shortcut?';
  String get removeLocalSessionTitle =>
      _isZh ? '要移除这个本地会话吗？' : 'Remove this local session?';
  String get forgetGatewayShortcutMessage => _isZh
      ? 'PocketClaw 会把这个会话从手机上的会话列表中移除，但 Gateway 端的真实对话仍然保留，之后可以重新打开。'
      : 'PocketClaw will remove this session from the phone session list, but the Gateway conversation itself will remain available and can be reopened later.';
  String get removeLocalSessionMessage => _isZh
      ? 'PocketClaw 会把这个本地会话及其未发送草稿从手机中移除。这不会删除 Gateway 上的内容，除非该会话本来就已经存在于 Gateway 端。'
      : 'PocketClaw will remove this local session and its unsent draft from the phone. This does not delete anything on the Gateway unless the session already exists there.';
  String get forgetShortcut => _isZh ? '忘记快捷入口' : 'Forget shortcut';
  String get remove => _isZh ? '移除' : 'Remove';
  String get cancel => _isZh ? '取消' : 'Cancel';
  String get codeLabel => _isZh ? '代码' : 'Code';
  String get keepAtLeastOneSession =>
      _isZh ? '请至少在这台设备上保留一个会话。' : 'Keep at least one session on this device.';
  String get home => _isZh ? '主页' : 'Home';
  String agentHomeTitle(String displayName) =>
      _isZh ? '$displayName · 主页' : '$displayName · Home';

  String get timelineEmpty => _isZh ? '时间线为空。' : 'Timeline is empty.';
  String get sendMessageHint => _isZh ? '发送一条消息' : 'Send a message';
  String get sendImagesHint =>
      _isZh ? '添加说明，或直接发送图片' : 'Add a caption or send images directly';
  String get image => _isZh ? '图片' : 'Image';
  String get send => _isZh ? '发送' : 'Send';
  String get stop => _isZh ? '停止' : 'Stop';
  String get addImage => _isZh ? '添加图片' : 'Add image';
  String get createSession => _isZh ? '创建会话' : 'Create session';

  String get agentSessionSourceTitle =>
      _isZh ? 'Agent 与会话来源' : 'Agent & session source';
  String get existingGatewaySessions =>
      _isZh ? '已有 Gateway 会话' : 'Existing Gateway sessions';
  String get existingGatewaySessionsDescription => _isZh
      ? '如果你想继续一个 Gateway 端可见的原有线程，可以直接打开它，这会更接近当前 Web UI 的使用路径。'
      : 'Open an existing session when you want to continue a Gateway-visible thread, matching the current Web UI flow more closely.';
  String moreGatewaySessionsNotShown(int count) => _isZh
      ? '还有 $count 个 Gateway 会话暂未在这里展开。'
      : '+$count more Gateway sessions not shown here yet.';
  String get mainAgentLabel => _isZh ? '主助手' : 'Main';

  String get systemTitle => _isZh ? '系统' : 'System';
  String get youTitle => _isZh ? '你' : 'You';
  String get assistantTitle => _isZh ? '助手' : 'Assistant';
  String get toolTitle => _isZh ? '工具' : 'Tool';
  String get detailsTitle => _isZh ? '详情' : 'Details';
  String get streaming => _isZh ? '流式返回中' : 'streaming';
  String timelineStatus(String status) => switch (status) {
        'sending' => _isZh ? '发送中' : 'sending',
        'warning' => _isZh ? '警告' : 'warning',
        _ => status,
      };

  String get model => _isZh ? '模型' : 'Model';
  String get thinking => _isZh ? '思考强度' : 'Thinking';
  String get verbose => _isZh ? '详细度' : 'Verbose';
  String get fastMode => _isZh ? '快速模式' : 'Fast mode';
  String get assistantFallback => _isZh ? '助手' : 'Assistant';
  String get gatewayDefault => _isZh ? 'Gateway 默认值' : 'gateway default';
  String defaultInherit(String defaultLabel) =>
      _isZh ? '默认（继承：$defaultLabel）' : 'Default (inherit: $defaultLabel)';
  String defaultValue(String defaultLabel) =>
      _isZh ? '默认（$defaultLabel）' : 'Default ($defaultLabel)';
  String currentValue(String value) =>
      _isZh ? '$value（当前）' : '$value (current)';
  String boolLabel(bool value) {
    if (_isZh) {
      return value ? '开' : '关';
    }
    return value ? 'on' : 'off';
  }

  String inheritingDefault(String label) =>
      _isZh ? '继承默认值 · $label' : 'Inheriting default · $label';
  String overrideActive(bool enabled) => _isZh
      ? '已覆盖 · ${boolLabel(enabled)}'
      : 'Override active · ${boolLabel(enabled)}';
  String useDefaultFastMode(String label) =>
      _isZh ? '使用默认快速模式（$label）' : 'Use default fast mode ($label)';
  String fastModeMapsTo(String summary) => _isZh
      ? '对应 sessions.patch fastMode · $summary'
      : 'Maps to sessions.patch fastMode · $summary';

  String get startupReadyMessage => _isZh
      ? 'PocketClaw 已准备好连接真实 Gateway。先完成连接流程，应用能稳定重连后再进入聊天界面。'
      : 'PocketClaw is ready for a real Gateway. Start with the connect flow, then enter chat when the app is ready to reconnect.';
  String restoreTimedOut(String label) => _isZh
      ? '$label 在启动时超时了。PocketClaw 已跳过该恢复步骤，以保证应用仍能正常打开。'
      : '$label timed out during startup. PocketClaw skipped that restore step so the app can still open.';
  String taskFailed(String label) => _isZh ? '$label 失败' : '$label failed';
  String get savedGatewayConfigurationRestore =>
      _isZh ? '恢复已保存的 Gateway 配置' : 'Saved Gateway configuration restore';
  String get localSessionRestore => _isZh ? '恢复本地会话' : 'Local session restore';
  String get connectFlowPreferenceRestore =>
      _isZh ? '恢复连接流程偏好' : 'Connect flow preference restore';
  String get storedDeviceAuthRefresh =>
      _isZh ? '刷新已保存的设备认证状态' : 'Stored device auth refresh';
  String get receivedDeviceAuthChallenge => _isZh
      ? '已收到设备认证挑战。如果本地已有设备身份，PocketClaw 会自动尝试应答。'
      : 'Received device-auth challenge. PocketClaw will answer it automatically when local device identity is available.';
  String get chatHistoryLoad => _isZh ? '聊天历史' : 'Chat history';
  String get assistantIdentityLoad => _isZh ? '助手身份' : 'Assistant identity';
  String get modelListLoad => _isZh ? '模型列表' : 'Model list';
  String get sessionInfoLoad => _isZh ? '会话信息' : 'Session info';
  String get agentListLoad => _isZh ? 'Agent 列表' : 'Agent list';
  String loadIssue(String label, Object error) =>
      _isZh ? '加载问题：$label：$error' : 'Load issue: $label: $error';
  String loadFailed(String label, String summary) =>
      _isZh ? '$label 加载失败。$summary' : '$label failed to load. $summary';

  String get secureConfigurationRestoreFailed =>
      _isZh ? '恢复安全配置失败' : 'Secure configuration restore failed';
  String get localSessionRestoreFailed =>
      _isZh ? '恢复本地会话失败' : 'Local session restore failed';
  String get connectFlowRestoreFailed =>
      _isZh ? '恢复连接流程偏好失败' : 'Connect flow restore failed';
  String get storedDeviceAuthRefreshFailed =>
      _isZh ? '刷新已保存设备认证状态失败' : 'Stored device auth refresh failed';
  String get savingLocalSessionsFailed =>
      _isZh ? '保存本地会话失败' : 'Saving local sessions failed';
  String get savingConnectFlowPreferencesFailed =>
      _isZh ? '保存连接流程偏好失败' : 'Saving connect flow preferences failed';
  String get renameFailed => _isZh ? '重命名失败' : 'Rename failed';
  String get gatewayConfigurationInvalid =>
      _isZh ? 'Gateway 配置无效' : 'Gateway configuration is invalid';
  String get savingEncryptedGatewayConfigurationFailed => _isZh
      ? '保存加密的 Gateway 配置失败'
      : 'Saving encrypted Gateway configuration failed';
  String get imagePickFailed => _isZh ? '选择图片失败' : 'Image pick failed';
  String get connectFailed => _isZh ? '连接失败' : 'Connect failed';
  String get sendFailed => _isZh ? '发送失败' : 'Send failed';
  String get abortFailed => _isZh ? '中止失败' : 'Abort failed';
  String get modelUpdateFailed => _isZh ? '模型更新失败' : 'Model update failed';
  String get thinkingUpdateFailed =>
      _isZh ? '思考强度更新失败' : 'Thinking update failed';
  String get verboseUpdateFailed =>
      _isZh ? 'Verbose 更新失败' : 'Verbose update failed';
  String get fastModeUpdateFailed =>
      _isZh ? '快速模式更新失败' : 'Fast mode update failed';
  String get fastModeResetFailed =>
      _isZh ? '快速模式重置失败' : 'Fast mode reset failed';

  String appliedGatewayConfiguration(String url) => _isZh
      ? '已应用 $url 的 Gateway 配置。Token 和密码仍为可选引导凭据；若设备身份与 device token 可复用，它们会保留在手机本地。'
      : 'Applied Gateway configuration for $url. Token and password remain optional. Device identity and device token reuse stay local on the phone when available.';
  String get loopbackWarningMessage => _isZh
      ? '警告：在真机上，127.0.0.1 / localhost 指向的是手机自己。请改用 Gateway 所在主机的 IP、局域网主机名、Tailscale 名称或公网域名。'
      : 'Warning: 127.0.0.1 / localhost points to the phone itself on a real device. Use your Gateway host IP, LAN hostname, Tailscale name, or public domain instead.';
  String createdLocalSession(String key) =>
      _isZh ? '已创建本地会话 $key' : 'Created local session $key';
  String forgotLocalShortcutFor(String key, String nextTitle) => _isZh
      ? '已忘记 $key 的本地快捷入口。正在加载 $nextTitle…'
      : 'Forgot local shortcut for $key. Loading $nextTitle…';
  String removedLocalSessionFromPhone(String key, String nextTitle) => _isZh
      ? '已从这台手机移除本地会话 $key。正在加载 $nextTitle…'
      : 'Removed local session $key from this phone. Loading $nextTitle…';
  String get noSupportedImageFilesAdded =>
      _isZh ? '没有添加受支持的图片文件。' : 'No supported image files were added.';
  String get enterGatewayUrlBeforeConnecting =>
      _isZh ? '请先输入 Gateway 地址再连接。' : 'Enter a Gateway URL before connecting.';
  String connectedTo(String url) => _isZh ? '已连接到 $url' : 'Connected to $url';
  String disconnectedFrom(String url) =>
      _isZh ? '已从 $url 断开连接' : 'Disconnected from $url';
  String get optimisticSingleImage => _isZh ? '[图片]' : '[Image]';
  String optimisticImages(int count) =>
      _isZh ? '[图片 × $count]' : '[Images × $count]';
}
