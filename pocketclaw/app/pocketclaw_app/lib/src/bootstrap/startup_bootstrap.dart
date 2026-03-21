import 'dart:async';

typedef BootstrapAction = Future<void> Function();

final class BootstrapTask {
  const BootstrapTask({
    required this.label,
    required this.action,
  });

  final String label;
  final BootstrapAction action;
}

enum BootstrapTaskStatus {
  completed,
  timedOut,
}

final class BootstrapTaskResult {
  const BootstrapTaskResult({
    required this.label,
    required this.status,
  });

  final String label;
  final BootstrapTaskStatus status;

  bool get didTimeout => status == BootstrapTaskStatus.timedOut;
}

final class SequentialBootstrapRunner {
  const SequentialBootstrapRunner({
    this.stepTimeout = const Duration(seconds: 2),
  });

  final Duration stepTimeout;

  Future<List<BootstrapTaskResult>> run(
    Iterable<BootstrapTask> tasks,
  ) async {
    final results = <BootstrapTaskResult>[];

    for (final task in tasks) {
      try {
        await task.action().timeout(stepTimeout);
        results.add(
          BootstrapTaskResult(
            label: task.label,
            status: BootstrapTaskStatus.completed,
          ),
        );
      } on TimeoutException {
        results.add(
          BootstrapTaskResult(
            label: task.label,
            status: BootstrapTaskStatus.timedOut,
          ),
        );
      }
    }

    return results;
  }
}
