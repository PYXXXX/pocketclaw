import 'package:gateway_transport/gateway_transport.dart';

final class GatewayConnectRequestFactory {
  const GatewayConnectRequestFactory({
    this.clientId = 'openclaw-android',
    this.clientVersion = '0.1.0-dev',
    this.platform = 'android',
    this.mode = 'ui',
    this.role = 'operator',
    this.scopes = const <String>[
      'operator.admin',
      'operator.approvals',
      'operator.pairing',
    ],
    this.caps = const <String>['tool-events'],
  });

  final String clientId;
  final String clientVersion;
  final String platform;
  final String mode;
  final String role;
  final List<String> scopes;
  final List<String> caps;

  ConnectRequest build({
    String? token,
    String? password,
    String? locale,
    String? instanceId,
  }) {
    final trimmedToken = token?.trim();
    final trimmedPassword = password?.trim();
    final auth = <String, Object?>{};
    if (trimmedToken != null && trimmedToken.isNotEmpty) {
      auth['token'] = trimmedToken;
    }
    if (trimmedPassword != null && trimmedPassword.isNotEmpty) {
      auth['password'] = trimmedPassword;
    }

    return ConnectRequest(
      client: ConnectClientInfo(
        id: clientId,
        version: clientVersion,
        platform: platform,
        mode: mode,
        instanceId: instanceId,
      ),
      role: role,
      scopes: scopes,
      caps: caps,
      auth: auth.isEmpty ? null : auth,
      locale: locale,
    );
  }
}
