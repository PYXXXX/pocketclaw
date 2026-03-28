import 'package:shared_preferences/shared_preferences.dart';

final class ConnectFlowPreferences {
  const ConnectFlowPreferences({
    required this.onboardingCompleted,
    required this.lastConnectionMethod,
  });

  final bool onboardingCompleted;
  final String? lastConnectionMethod;
}

abstract interface class ConnectFlowPreferencesStore {
  Future<ConnectFlowPreferences> read();

  Future<void> write({
    required bool onboardingCompleted,
    required String? lastConnectionMethod,
  });
}

final class SharedPreferencesConnectFlowPreferencesStore
    implements ConnectFlowPreferencesStore {
  SharedPreferencesConnectFlowPreferencesStore({
    Future<SharedPreferences>? sharedPreferences,
  }) : _sharedPreferencesFuture =
           sharedPreferences ?? SharedPreferences.getInstance();

  static const String onboardingCompletedKey =
      'pocketclaw.connect.onboarding_completed';
  static const String lastConnectionMethodKey =
      'pocketclaw.connect.last_connection_method';

  final Future<SharedPreferences> _sharedPreferencesFuture;

  @override
  Future<ConnectFlowPreferences> read() async {
    final prefs = await _sharedPreferencesFuture;
    return ConnectFlowPreferences(
      onboardingCompleted: prefs.getBool(onboardingCompletedKey) ?? false,
      lastConnectionMethod: prefs.getString(lastConnectionMethodKey),
    );
  }

  @override
  Future<void> write({
    required bool onboardingCompleted,
    required String? lastConnectionMethod,
  }) async {
    final prefs = await _sharedPreferencesFuture;
    await prefs.setBool(onboardingCompletedKey, onboardingCompleted);
    if (lastConnectionMethod == null || lastConnectionMethod.isEmpty) {
      await prefs.remove(lastConnectionMethodKey);
      return;
    }
    await prefs.setString(lastConnectionMethodKey, lastConnectionMethod);
  }
}
