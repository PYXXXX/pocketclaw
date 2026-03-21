import 'dart:convert';

import 'package:pocketclaw_core/pocketclaw_core.dart';

import 'secure_key_value_store.dart';

abstract interface class GatewayProfileStore {
  Future<GatewayProfile?> read();

  Future<void> write(GatewayProfile profile);

  Future<void> delete();
}

final class SecureGatewayProfileStore implements GatewayProfileStore {
  SecureGatewayProfileStore(this._store);

  static const String storageKey = 'pocketclaw.gateway_profile';

  final SecureKeyValueStore _store;

  @override
  Future<GatewayProfile?> read() async {
    final raw = await _store.read(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    return GatewayProfile.fromJson(_decodeMap(raw));
  }

  @override
  Future<void> write(GatewayProfile profile) {
    return _store.write(key: storageKey, value: jsonEncode(profile.toJson()));
  }

  @override
  Future<void> delete() {
    return _store.delete(storageKey);
  }

  Map<String, Object?> _decodeMap(String raw) {
    final decoded = jsonDecode(raw);
    return Map<String, Object?>.from(decoded as Map);
  }
}
