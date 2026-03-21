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

  String get appTitle => _isZh ? 'PocketClaw' : 'PocketClaw';
  String get copied => _isZh ? '已复制到剪贴板' : 'Copied to clipboard';
  String get longPressToCopy => _isZh ? '长按可复制' : 'Long press to copy';
  String get noGatewayConfigured =>
      _isZh ? '尚未配置 Gateway' : 'No Gateway configured yet';
  String get bootstrapSaved =>
      _isZh ? '已保存引导凭据' : 'Bootstrap credentials saved';
  String get noBootstrap =>
      _isZh ? '未配置引导凭据' : 'No bootstrap credentials';
  String get reconnectTokenAvailable =>
      _isZh ? '可用重连令牌' : 'Reconnect token available';
  String get deviceIdentitySaved =>
      _isZh ? '设备身份已保存' : 'Device identity saved';
  String get firstPairingLikely =>
      _isZh ? '可能需要首次配对' : 'First pairing likely needed';
  String get loopbackUrl => _isZh ? '本机回环地址' : 'Loopback URL';
  String get loopbackWarning => _isZh
      ? '在真机上，127.0.0.1 / localhost 指向的是手机自己。请改用 Gateway 所在主机的 IP、局域网主机名、Tailscale 名称或公网域名。'
      : '127.0.0.1 / localhost points to the phone itself on a real device. Use your Gateway host IP, LAN hostname, Tailscale name, or public domain instead.';
  String get startSetup => _isZh ? '开始设置' : 'Start setup';
  String get onboardingComplete =>
      _isZh ? '初始化已完成' : 'Onboarding complete';
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
  String get customRequestHeaders => _isZh
      ? '自定义请求头（可选）'
      : 'Custom request headers (optional)';
  String get customRequestHeadersHint => _isZh
      ? '每行一条，例如\nX-Custom-Auth: value\nCF-Access-Client-Id: ...'
      : 'One per line, for example\nX-Custom-Auth: value\nCF-Access-Client-Id: ...';
  String get customRequestHeadersHelp => _isZh
      ? '用于 Cloudflare、Zero Trust、反向代理等场景。格式必须是“Header-Name: value”，空行和 # 注释会被忽略。'
      : 'Use this for Cloudflare, Zero Trust, reverse proxies, or other edge cases. Each line must be "Header-Name: value". Blank lines and # comments are ignored.';
  String get saveConnectionSettings =>
      _isZh ? '保存连接设置' : 'Save connection settings';
  String gatewayState(String state) =>
      _isZh ? 'Gateway 状态：$state' : 'Gateway state: $state';
  String flowStage(String stage) =>
      _isZh ? '流程阶段：$stage' : 'Flow stage: $stage';
  String get connect => _isZh ? '连接' : 'Connect';
  String get disconnect => _isZh ? '断开连接' : 'Disconnect';
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
  String get chooseMethodTitle =>
      _isZh ? '选择连接方式' : 'Choose connection method';
  String get chooseMethodDescription => _isZh
      ? '手动连接是基础路径，应始终可用。配置码流程可以在客户端路径成熟后再补。'
      : 'Manual connect is the baseline flow and should always work. Setup code can be added later when the client path is ready.';
  String get manualConnectionTitle =>
      _isZh ? '手动连接' : 'Manual connection';
  String get manualConnectionDescription => _isZh
      ? '输入 Gateway 地址和可选引导凭据。PocketClaw 会把可复用认证保存在本地，方便下次重连。'
      : 'Enter the Gateway URL and optional bootstrap credentials. PocketClaw will store reusable auth locally so reconnect can work next time.';
  String get authenticatingTitle => _isZh ? '正在认证' : 'Authenticating';
  String get authenticatingDescription => _isZh
      ? '应用正在尝试引导凭据或应答设备认证挑战。如果需要在别处批准，请保持此页面打开并批准该设备。'
      : 'The app is trying bootstrap credentials or answering device-auth challenges. If approval is needed elsewhere, keep this screen open and approve the device.';
  String get pairingPendingTitle =>
      _isZh ? '等待配对批准' : 'Pairing pending';
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
}
