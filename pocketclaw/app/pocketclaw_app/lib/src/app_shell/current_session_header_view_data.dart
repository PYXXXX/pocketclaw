import 'package:pocketclaw_core/pocketclaw_core.dart';

import 'app_strings.dart';

final class CurrentSessionHeaderViewData {
  const CurrentSessionHeaderViewData({
    required this.sessionKeyText,
    required this.sourceLabel,
    required this.isGatewayBacked,
    required this.gatewayLabel,
    required this.hasLocalDraft,
    required this.draftStatusLabel,
    required this.forgetActionLabel,
    required this.forgetDialogTitle,
    required this.forgetDialogMessage,
    required this.forgetConfirmLabel,
    required this.cannotForgetHint,
  });

  final String sessionKeyText;
  final String sourceLabel;
  final bool isGatewayBacked;
  final String? gatewayLabel;
  final bool hasLocalDraft;
  final String draftStatusLabel;
  final String forgetActionLabel;
  final String forgetDialogTitle;
  final String forgetDialogMessage;
  final String forgetConfirmLabel;
  final String? cannotForgetHint;

  factory CurrentSessionHeaderViewData.from(
    LocalSessionEntry session, {
    required AppStrings strings,
    required bool canForgetCurrentSession,
  }) {
    final gatewayLabel = session.gatewayLabel?.trim();
    final hasLocalDraft = session.draftText.trim().isNotEmpty;
    final isGatewayBacked = session.isGatewayBacked;

    return CurrentSessionHeaderViewData(
      sessionKeyText: strings.sessionKey(session.sessionKey.value),
      sourceLabel: isGatewayBacked
          ? strings.gatewaySession
          : strings.localPocketClawSession,
      isGatewayBacked: isGatewayBacked,
      gatewayLabel: gatewayLabel != null && gatewayLabel.isNotEmpty
          ? gatewayLabel
          : null,
      hasLocalDraft: hasLocalDraft,
      draftStatusLabel: hasLocalDraft
          ? strings.draftSavedLocally
          : strings.noLocalDraft,
      forgetActionLabel: isGatewayBacked
          ? strings.forgetLocalShortcut
          : strings.removeFromPhone,
      forgetDialogTitle: isGatewayBacked
          ? strings.forgetGatewayShortcutTitle
          : strings.removeLocalSessionTitle,
      forgetDialogMessage: isGatewayBacked
          ? strings.forgetGatewayShortcutMessage
          : strings.removeLocalSessionMessage,
      forgetConfirmLabel: isGatewayBacked
          ? strings.forgetShortcut
          : strings.remove,
      cannotForgetHint: canForgetCurrentSession
          ? null
          : strings.keepAtLeastOneSession,
    );
  }
}
