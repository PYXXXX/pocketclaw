final class SessionsListParams {
  const SessionsListParams({
    this.includeGlobal = true,
    this.includeUnknown = true,
    this.activeMinutes,
    this.limit,
  });

  final bool includeGlobal;
  final bool includeUnknown;
  final int? activeMinutes;
  final int? limit;

  Map<String, Object?> toJson() => <String, Object?>{
        'includeGlobal': includeGlobal,
        'includeUnknown': includeUnknown,
        if (activeMinutes != null) 'activeMinutes': activeMinutes,
        if (limit != null) 'limit': limit,
      };
}

final class SessionPatchParams {
  const SessionPatchParams({
    required this.key,
    this.model,
    this.thinkingLevel,
    this.fastMode,
    this.verboseLevel,
  });

  final String key;
  final String? model;
  final String? thinkingLevel;
  final bool? fastMode;
  final String? verboseLevel;

  Map<String, Object?> toJson() => <String, Object?>{
        'key': key,
        if (model != null) 'model': model,
        if (thinkingLevel != null) 'thinkingLevel': thinkingLevel,
        if (fastMode != null) 'fastMode': fastMode,
        if (verboseLevel != null) 'verboseLevel': verboseLevel,
      };
}
