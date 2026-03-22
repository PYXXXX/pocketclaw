import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/app_shell/gateway_configuration_apply_controller.dart';

void main() {
  group('GatewayConfigurationApplyController', () {
    test('reuses the same in-flight apply operation', () async {
      final controller = GatewayConfigurationApplyController();
      final completer = Completer<bool>();
      var runs = 0;

      Future<bool> start() {
        runs += 1;
        return completer.future;
      }

      final first = controller.run(start);
      final second = controller.run(start);

      expect(controller.isApplying, isTrue);
      expect(identical(first, second), isTrue);
      expect(runs, 1);

      completer.complete(true);
      await first;
      expect(controller.isApplying, isFalse);
    });
  });
}
