import 'dart:convert';

import 'package:gateway_adapter/gateway_adapter.dart';

import 'secure_key_value_store.dart';

final class SecureGatewayDeviceTokenStore implements GatewayDeviceTokenStore {
  SecureGatewayDeviceTokenStore(this._store);

  final SecureKeyValueStore _store;

  @override
  Future<GatewayDeviceToken?> read({
    required String deviceId,
    required String role,
  }) async {
    final raw = await _store.read(_storageKey(deviceId: deviceId, role: role));
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    return GatewayDeviceToken.fromJson(
      Map<String, Object?>.from(decoded as Map),
    );
  }

  @override
  Future<void> write(GatewayDeviceToken token) {
    return _store.write(
      key: _storageKey(deviceId: token.deviceId, role: token.role),
      value: jsonEncode(token.toJson()),
    );
  }

  String _storageKey({required String deviceId, required String role}) {
    return 'pocketclaw.gateway_device_token.$deviceId.$role';
  }
}
