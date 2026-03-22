final class GatewayConfigurationApplyController {
  Future<bool>? _inFlight;

  bool get isApplying => _inFlight != null;

  Future<bool>? get inFlight => _inFlight;

  Future<bool> run(Future<bool> Function() operation) {
    final existing = _inFlight;
    if (existing != null) {
      return existing;
    }

    late final Future<bool> tracked;
    tracked = operation().whenComplete(() {
      if (identical(_inFlight, tracked)) {
        _inFlight = null;
      }
    });
    _inFlight = tracked;
    return tracked;
  }
}
