abstract interface class SessionApi {
  Future<Map<String, Object?>> list();

  Future<Map<String, Object?>> patch({
    required String key,
    String? model,
    String? thinkingLevel,
    bool? fastMode,
    String? verboseLevel,
  });
}
