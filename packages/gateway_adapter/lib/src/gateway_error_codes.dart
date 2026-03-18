abstract final class GatewayErrorCodes {
  static const String authRequired = 'AUTH_REQUIRED';
  static const String authUnauthorized = 'AUTH_UNAUTHORIZED';
  static const String authTokenMissing = 'AUTH_TOKEN_MISSING';
  static const String authTokenMismatch = 'AUTH_TOKEN_MISMATCH';
  static const String authTokenNotConfigured = 'AUTH_TOKEN_NOT_CONFIGURED';
  static const String authPasswordMissing = 'AUTH_PASSWORD_MISSING';
  static const String authPasswordMismatch = 'AUTH_PASSWORD_MISMATCH';
  static const String authPasswordNotConfigured = 'AUTH_PASSWORD_NOT_CONFIGURED';
  static const String authBootstrapTokenInvalid = 'AUTH_BOOTSTRAP_TOKEN_INVALID';
  static const String authDeviceTokenMismatch = 'AUTH_DEVICE_TOKEN_MISMATCH';
  static const String authRateLimited = 'AUTH_RATE_LIMITED';
  static const String controlUiOriginNotAllowed = 'CONTROL_UI_ORIGIN_NOT_ALLOWED';
  static const String controlUiDeviceIdentityRequired =
      'CONTROL_UI_DEVICE_IDENTITY_REQUIRED';
  static const String deviceIdentityRequired = 'DEVICE_IDENTITY_REQUIRED';
  static const String pairingRequired = 'PAIRING_REQUIRED';
}
