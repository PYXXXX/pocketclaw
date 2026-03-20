import 'gateway_error_codes.dart';
import 'gateway_request_error.dart';

final class GatewayErrorGuidance {
  const GatewayErrorGuidance({
    required this.summary,
    this.action,
    this.code,
  });

  final String summary;
  final String? action;
  final String? code;
}

GatewayErrorGuidance gatewayErrorGuidanceFor(
  Object error, {
  String? configuredUrl,
}) {
  if (error is GatewayRequestError) {
    final code = error.detailsCode ?? error.code;
    switch (code) {
      case GatewayErrorCodes.pairingRequired:
        return const GatewayErrorGuidance(
          code: GatewayErrorCodes.pairingRequired,
          summary: 'This device must be approved by the Gateway before it can connect.',
          action: 'Approve the pending device pairing request from an existing trusted OpenClaw operator session or on the Gateway host.',
        );
      case GatewayErrorCodes.authTokenMismatch:
      case GatewayErrorCodes.authTokenMissing:
      case GatewayErrorCodes.authTokenNotConfigured:
      case GatewayErrorCodes.authBootstrapTokenInvalid:
        return GatewayErrorGuidance(
          code: code,
          summary: 'Gateway token authentication failed.',
          action: error.canRetryWithDeviceToken == true
              ? 'A cached device token may be usable after this device is approved.'
              : 'Check the Gateway token or use another supported auth method such as password or an approved device token.',
        );
      case GatewayErrorCodes.authPasswordMismatch:
      case GatewayErrorCodes.authPasswordMissing:
      case GatewayErrorCodes.authPasswordNotConfigured:
        return const GatewayErrorGuidance(
          summary: 'Gateway password authentication failed.',
          action: 'Verify the password or switch to another supported auth path such as token or approved device token.',
        );
      case GatewayErrorCodes.authRateLimited:
        return const GatewayErrorGuidance(
          code: GatewayErrorCodes.authRateLimited,
          summary: 'Too many authentication attempts were rejected.',
          action: 'Wait briefly before retrying, then verify the configured auth method.',
        );
      case GatewayErrorCodes.controlUiOriginNotAllowed:
        return const GatewayErrorGuidance(
          code: GatewayErrorCodes.controlUiOriginNotAllowed,
          summary: 'The Gateway rejected this client origin.',
          action: 'Use the app from an allowed origin/network path or adjust Gateway origin policy on the host.',
        );
      case GatewayErrorCodes.controlUiDeviceIdentityRequired:
      case GatewayErrorCodes.deviceIdentityRequired:
        return const GatewayErrorGuidance(
          summary: 'This connection requires device identity signing.',
          action: 'Keep device auth enabled and ensure the app can persist a stable device identity.',
        );
      case GatewayErrorCodes.authUnauthorized:
      case GatewayErrorCodes.authRequired:
        return const GatewayErrorGuidance(
          summary: 'Gateway authentication is required.',
          action: 'Provide a valid token, password, or previously issued device token.',
        );
      case GatewayErrorCodes.authDeviceTokenMismatch:
        return const GatewayErrorGuidance(
          summary: 'The stored device token is no longer accepted.',
          action: 'Reconnect with another supported auth method and re-approve this device if necessary.',
        );
    }

    return GatewayErrorGuidance(
      code: code,
      summary: error.message,
      action: error.recommendedNextStep,
    );
  }

  final raw = error.toString();
  final lower = raw.toLowerCase();
  if (lower.contains('connection refused')) {
    if (_usesLoopback(configuredUrl)) {
      return const GatewayErrorGuidance(
        summary: 'The app tried to connect to localhost / loopback, which on a phone means the phone itself.',
        action: 'Use your Gateway host IP, LAN hostname, Tailscale name, or public domain instead of 127.0.0.1 / localhost.',
      );
    }
    return const GatewayErrorGuidance(
      summary: 'The Gateway socket refused the connection.',
      action: 'Check that the Gateway is running, the host and port are correct, and that this phone can reach that network path.',
    );
  }

  if (lower.contains('timed out')) {
    return const GatewayErrorGuidance(
      summary: 'The Gateway did not finish the WebSocket handshake in time.',
      action: 'Verify the URL, network reachability, and any reverse proxy or TLS configuration in front of the Gateway.',
    );
  }

  return GatewayErrorGuidance(summary: raw);
}

bool _usesLoopback(String? configuredUrl) {
  if (configuredUrl == null || configuredUrl.trim().isEmpty) {
    return false;
  }
  final uri = Uri.tryParse(configuredUrl.trim());
  if (uri == null) {
    return false;
  }
  final host = uri.host.toLowerCase();
  return host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '::1' ||
      host == '0.0.0.0';
}
