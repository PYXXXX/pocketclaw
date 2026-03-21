import 'package:pocketclaw_core/pocketclaw_core.dart';

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
    required bool canForgetCurrentSession,
  }) {
    final gatewayLabel = session.gatewayLabel?.trim();
    final hasLocalDraft = session.draftText.trim().isNotEmpty;
    final isGatewayBacked = session.isGatewayBacked;

    return CurrentSessionHeaderViewData(
      sessionKeyText: 'Session key: ${session.sessionKey.value}',
      sourceLabel: isGatewayBacked
          ? 'Gateway session'
          : 'Local PocketClaw session',
      isGatewayBacked: isGatewayBacked,
      gatewayLabel: gatewayLabel != null && gatewayLabel.isNotEmpty
          ? gatewayLabel
          : null,
      hasLocalDraft: hasLocalDraft,
      draftStatusLabel: hasLocalDraft ? 'Draft saved locally' : 'No local draft',
      forgetActionLabel: isGatewayBacked
          ? 'Forget local shortcut'
          : 'Remove from phone',
      forgetDialogTitle: isGatewayBacked
          ? 'Forget this Gateway shortcut?'
          : 'Remove this local session?',
      forgetDialogMessage: isGatewayBacked
          ? 'PocketClaw will remove this session from the phone session list, but the Gateway conversation itself will remain available and can be reopened later.'
          : 'PocketClaw will remove this local session and its unsent draft from the phone. This does not delete anything on the Gateway unless the session already exists there.',
      forgetConfirmLabel: isGatewayBacked ? 'Forget shortcut' : 'Remove',
      cannotForgetHint: canForgetCurrentSession
          ? null
          : 'Keep at least one session on this device.',
    );
  }
}
