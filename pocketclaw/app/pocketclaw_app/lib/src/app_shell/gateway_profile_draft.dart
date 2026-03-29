import 'package:pocketclaw_core/pocketclaw_core.dart';

import 'gateway_url_input.dart';

GatewayProfile draftGatewayProfile({
  required GatewayProfile savedProfile,
  required String draftUrl,
  required String token,
  required String password,
  required String cloudflareAccessClientId,
  required String cloudflareAccessClientSecret,
  required String customRequestHeadersText,
}) {
  return savedProfile.copyWith(
    url: normalizeGatewayUrl(
      effectiveGatewayUrlInput(draftUrl: draftUrl, savedUrl: savedProfile.url),
    ),
    token: token,
    password: password,
    cloudflareAccessClientId: cloudflareAccessClientId.trim(),
    cloudflareAccessClientSecret: cloudflareAccessClientSecret.trim(),
    customRequestHeadersText: customRequestHeadersText,
  );
}

bool hasUnsavedGatewayConfiguration({
  required GatewayProfile savedProfile,
  required GatewayProfile draftProfile,
}) {
  return draftProfile.url != savedProfile.url ||
      draftProfile.token != savedProfile.token ||
      draftProfile.password != savedProfile.password ||
      draftProfile.cloudflareAccessClientId !=
          savedProfile.cloudflareAccessClientId ||
      draftProfile.cloudflareAccessClientSecret !=
          savedProfile.cloudflareAccessClientSecret ||
      draftProfile.customRequestHeadersText !=
          savedProfile.customRequestHeadersText;
}
