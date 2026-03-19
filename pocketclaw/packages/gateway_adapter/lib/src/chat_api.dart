abstract interface class ChatApi {
  Future<Map<String, Object?>> history({
    required String sessionKey,
    int limit = 200,
  });

  Future<Map<String, Object?>> send({
    required String sessionKey,
    required String message,
  });

  Future<Map<String, Object?>> abort({
    required String sessionKey,
    String? runId,
  });
}
