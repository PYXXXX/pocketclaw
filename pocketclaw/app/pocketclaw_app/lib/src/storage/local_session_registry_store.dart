import 'dart:convert';

import 'package:pocketclaw_core/pocketclaw_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class PersistedSessionRegistryState {
  const PersistedSessionRegistryState({
    required this.registry,
    required this.currentSessionKey,
  });

  final LocalSessionRegistry registry;
  final String? currentSessionKey;
}

abstract interface class LocalSessionRegistryStore {
  Future<PersistedSessionRegistryState?> read();

  Future<void> write({
    required LocalSessionRegistry registry,
    required String currentSessionKey,
  });

  Future<void> delete();
}

final class SharedPreferencesLocalSessionRegistryStore
    implements LocalSessionRegistryStore {
  SharedPreferencesLocalSessionRegistryStore({
    Future<SharedPreferences>? sharedPreferences,
  }) : _sharedPreferencesFuture =
           sharedPreferences ?? SharedPreferences.getInstance();

  static const String registryStorageKey = 'pocketclaw.local_session_registry';
  static const String currentSessionStorageKey =
      'pocketclaw.current_session_key';

  final Future<SharedPreferences> _sharedPreferencesFuture;

  @override
  Future<PersistedSessionRegistryState?> read() async {
    final prefs = await _sharedPreferencesFuture;
    final rawRegistry = prefs.getString(registryStorageKey);
    if (rawRegistry == null || rawRegistry.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawRegistry);
    final values = (decoded as List<Object?>?) ?? const <Object?>[];
    final registry = LocalSessionRegistry.fromJsonList(values);
    final currentSessionKey = prefs.getString(currentSessionStorageKey);

    return PersistedSessionRegistryState(
      registry: registry,
      currentSessionKey: currentSessionKey,
    );
  }

  @override
  Future<void> write({
    required LocalSessionRegistry registry,
    required String currentSessionKey,
  }) async {
    final prefs = await _sharedPreferencesFuture;
    await Future.wait(<Future<bool>>[
      prefs.setString(registryStorageKey, jsonEncode(registry.toJsonList())),
      prefs.setString(currentSessionStorageKey, currentSessionKey),
    ]);
  }

  @override
  Future<void> delete() async {
    final prefs = await _sharedPreferencesFuture;
    await prefs.remove(registryStorageKey);
    await prefs.remove(currentSessionStorageKey);
  }
}
