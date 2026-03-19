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
    this.label,
    this.model,
    this.clearModel = false,
    this.thinkingLevel,
    this.clearThinkingLevel = false,
    this.fastMode,
    this.verboseLevel,
    this.clearVerboseLevel = false,
  }) : assert(!(clearModel && model != null)),
       assert(!(clearThinkingLevel && thinkingLevel != null)),
       assert(!(clearVerboseLevel && verboseLevel != null));

  final String key;
  final String? label;
  final String? model;
  final bool clearModel;
  final String? thinkingLevel;
  final bool clearThinkingLevel;
  final bool? fastMode;
  final String? verboseLevel;
  final bool clearVerboseLevel;

  Map<String, Object?> toJson() => <String, Object?>{
        'key': key,
        if (label != null) 'label': label,
        if (clearModel || model != null) 'model': model,
        if (clearThinkingLevel || thinkingLevel != null)
          'thinkingLevel': thinkingLevel,
        if (fastMode != null) 'fastMode': fastMode,
        if (clearVerboseLevel || verboseLevel != null)
          'verboseLevel': verboseLevel,
      };
}
