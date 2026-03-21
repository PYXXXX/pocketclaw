import 'package:flutter_test/flutter_test.dart';
import 'package:pocketclaw_app/src/chat/current_view_data_loader.dart';

void main() {
  test('CurrentViewDataLoader keeps loading after a failure', () async {
    final visited = <String>[];
    const loader = CurrentViewDataLoader();

    final results = await loader.run(<ViewDataTask>[
      ViewDataTask(
        label: 'history',
        action: () async {
          visited.add('history');
          throw StateError('history failed');
        },
      ),
      ViewDataTask(
        label: 'models',
        action: () async {
          visited.add('models');
        },
      ),
    ]);

    expect(visited, <String>['history', 'models']);
    expect(results.length, 2);
    expect(results.first.didFail, isTrue);
    expect(results.first.error, isA<StateError>());
    expect(results.last.didFail, isFalse);
  });

  test('CurrentViewDataLoader reports all-success batches cleanly', () async {
    const loader = CurrentViewDataLoader();

    final results = await loader.run(<ViewDataTask>[
      ViewDataTask(label: 'identity', action: () async {}),
      ViewDataTask(label: 'sessions', action: () async {}),
    ]);

    expect(results.every((result) => !result.didFail), isTrue);
  });
}
