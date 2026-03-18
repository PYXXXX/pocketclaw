import 'dart:convert';

import 'package:gateway_adapter/gateway_adapter.dart';

import 'secure_key_value_store.dart';

final class SecureGatewayDeviceIdentityStore
    implements GatewayDeviceIdentityStore {
  SecureGatewayDeviceIdentityStore(this._store);

  static const String storageKey = 'pocketclaw.gateway_device_identity';

  final SecureKeyValueStore _store;

  @override
  Future<GatewayDeviceIdentity?> read() async {
    final raw = await _store.read(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    return GatewayDeviceIdentity.fromJson(
      Map<String, Object?>.from(decoded as Map),
    );
  }

  @override
  Future<void> write(GatewayDeviceIdentity identity) {
    return _store.write(
      key: storageKey,
      value: jsonEncode(identity.toJson()),
    );
  }
}
