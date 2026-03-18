import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocketclaw_app/src/storage/connect_flow_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('connect flow preferences default to welcome/manual state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = SharedPreferencesConnectFlowPreferencesStore();

    final result = await store.read();

    expect(result.onboardingCompleted, isFalse);
    expect(result.lastConnectionMethod, isNull);
  });

  test('connect flow preferences persist onboarding and method', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = SharedPreferencesConnectFlowPreferencesStore();

    await store.write(
      onboardingCompleted: true,
      lastConnectionMethod: 'manual',
    );

    final result = await store.read();

    expect(result.onboardingCompleted, isTrue);
    expect(result.lastConnectionMethod, 'manual');
  });
}
