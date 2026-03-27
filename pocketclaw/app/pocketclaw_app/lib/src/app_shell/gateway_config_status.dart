import 'package:pocketclaw_core/pocketclaw_core.dart';

import 'gateway_profile_draft.dart';

final class GatewayConfigStatus {
  const GatewayConfigStatus({
    required this.effectiveUrl,
    required this.isUsingSavedUrlFallback,
    required this.hasUnsavedChanges,
  });

  final String effectiveUrl;
  final bool isUsingSavedUrlFallback;
  final bool hasUnsavedChanges;
}

GatewayConfigStatus summarizeGatewayConfigStatus({
  required GatewayProfile savedProfile,
  required GatewayProfile draftProfile,
  required String draftUrl,
}) {
  return GatewayConfigStatus(
    effectiveUrl: draftProfile.url,
    isUsingSavedUrlFallback:
        draftUrl.trim().isEmpty && savedProfile.url.trim().isNotEmpty,
    hasUnsavedChanges: hasUnsavedGatewayConfiguration(
      savedProfile: savedProfile,
      draftProfile: draftProfile,
    ),
  );
}
