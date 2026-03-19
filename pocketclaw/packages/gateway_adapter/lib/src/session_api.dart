abstract interface class SessionApi {
  Future<Map<String, Object?>> list();

  Future<Map<String, Object?>> patch({
    required String key,
    String? model,
    bool clearModel = false,
    String? thinkingLevel,
    bool clearThinkingLevel = false,
    bool? fastMode,
    String? verboseLevel,
    bool clearVerboseLevel = false,
  });
}
