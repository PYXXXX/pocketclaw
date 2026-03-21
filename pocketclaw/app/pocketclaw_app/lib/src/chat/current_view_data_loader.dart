typedef ViewDataTaskAction = Future<void> Function();

final class ViewDataTask {
  const ViewDataTask({required this.label, required this.action});

  final String label;
  final ViewDataTaskAction action;
}

enum ViewDataTaskStatus { completed, failed }

final class ViewDataTaskResult {
  const ViewDataTaskResult({
    required this.label,
    required this.status,
    this.error,
  });

  final String label;
  final ViewDataTaskStatus status;
  final Object? error;

  bool get didFail => status == ViewDataTaskStatus.failed;
}

final class CurrentViewDataLoader {
  const CurrentViewDataLoader();

  Future<List<ViewDataTaskResult>> run(Iterable<ViewDataTask> tasks) async {
    final results = <ViewDataTaskResult>[];

    for (final task in tasks) {
      try {
        await task.action();
        results.add(
          ViewDataTaskResult(
            label: task.label,
            status: ViewDataTaskStatus.completed,
          ),
        );
      } catch (error) {
        results.add(
          ViewDataTaskResult(
            label: task.label,
            status: ViewDataTaskStatus.failed,
            error: error,
          ),
        );
      }
    }

    return results;
  }
}
