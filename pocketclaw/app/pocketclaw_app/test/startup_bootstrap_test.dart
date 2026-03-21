import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/bootstrap/startup_bootstrap.dart';

void main() {
  test('SequentialBootstrapRunner runs tasks in order', () async {
    final visited = <String>[];
    final runner = const SequentialBootstrapRunner(
      stepTimeout: Duration(milliseconds: 20),
    );

    final results = await runner.run(<BootstrapTask>[
      BootstrapTask(
        label: 'first',
        action: () async {
          visited.add('first:start');
          await Future<void>.delayed(const Duration(milliseconds: 1));
          visited.add('first:end');
        },
      ),
      BootstrapTask(
        label: 'second',
        action: () async {
          visited.add('second:start');
          await Future<void>.delayed(const Duration(milliseconds: 1));
          visited.add('second:end');
        },
      ),
    ]);

    expect(visited, <String>[
      'first:start',
      'first:end',
      'second:start',
      'second:end',
    ]);
    expect(
      results.map((result) => result.status).toList(),
      <BootstrapTaskStatus>[
        BootstrapTaskStatus.completed,
        BootstrapTaskStatus.completed,
      ],
    );
  });

  test(
    'SequentialBootstrapRunner marks timed out tasks and continues',
    () async {
      final visited = <String>[];
      final completer = Completer<void>();
      final runner = const SequentialBootstrapRunner(
        stepTimeout: Duration(milliseconds: 10),
      );

      final results = await runner.run(<BootstrapTask>[
        BootstrapTask(
          label: 'stuck',
          action: () async {
            visited.add('stuck:start');
            await completer.future;
          },
        ),
        BootstrapTask(
          label: 'next',
          action: () async {
            visited.add('next:start');
          },
        ),
      ]);

      expect(visited, <String>['stuck:start', 'next:start']);
      expect(results.length, 2);
      expect(results.first.didTimeout, isTrue);
      expect(results.last.didTimeout, isFalse);
    },
  );
}
