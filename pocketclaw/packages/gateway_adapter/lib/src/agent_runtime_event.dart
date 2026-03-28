import 'dart:convert';

import 'package:gateway_transport/gateway_transport.dart';

enum AgentRuntimeEventKind { tool, internal, status, unknown }

final class AgentRuntimeEvent {
  const AgentRuntimeEvent({
    required this.kind,
    required this.runId,
    required this.seq,
    required this.stream,
    required this.timestamp,
    required this.title,
    required this.summary,
    required this.rawData,
    this.toolName,
    this.callId,
    this.status,
    this.details,
  });

  final AgentRuntimeEventKind kind;
  final String runId;
  final int seq;
  final String stream;
  final DateTime timestamp;
  final String title;
  final String summary;
  final Map<String, Object?> rawData;
  final String? toolName;
  final String? callId;
  final String? status;
  final String? details;

  String? get timelineKey {
    if (kind != AgentRuntimeEventKind.tool) {
      return null;
    }
    final stableCallId = callId;
    if (stableCallId == null || stableCallId.isEmpty) {
      return null;
    }
    return 'tool:$runId:$stableCallId';
  }

  static AgentRuntimeEvent? tryParse(GatewayEvent event) {
    final payload = event.payload;
    final runId = payload['runId'] as String?;
    final seq = payload['seq'];
    final stream = payload['stream'] as String?;
    final ts = payload['ts'];
    final data = payload['data'];

    if (runId == null || stream == null || data is! Map<String, Object?>) {
      return null;
    }

    final timestamp = switch (ts) {
      int value => DateTime.fromMillisecondsSinceEpoch(value, isUtc: true),
      num value => DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
        isUtc: true,
      ),
      _ => DateTime.now().toUtc(),
    };

    final normalizedStream = stream.toLowerCase();
    final toolName = _firstString(data, const <String>[
      'toolName',
      'tool',
      'name',
      'displayName',
      'label',
    ]);
    final callId = _firstString(data, const <String>['callId', 'toolCallId']);
    final status = _firstString(data, const <String>[
      'status',
      'state',
      'phase',
      'event',
    ]);
    final argumentsPayload = _firstValue(data, const <String>[
      'arguments',
      'args',
      'input',
      'params',
      'request',
    ]);
    final resultPayload = _firstValue(data, const <String>[
      'result',
      'output',
      'response',
    ]);

    final isToolStream =
        normalizedStream.contains('tool') ||
        data.containsKey('toolName') ||
        data.containsKey('tool') ||
        data.containsKey('callId') ||
        data.containsKey('arguments') ||
        data.containsKey('result');
    final isInternal =
        normalizedStream.contains('internal') ||
        data['type'] == 'task_completion';

    final kind = isToolStream
        ? AgentRuntimeEventKind.tool
        : isInternal
        ? AgentRuntimeEventKind.internal
        : normalizedStream.contains('status')
        ? AgentRuntimeEventKind.status
        : AgentRuntimeEventKind.unknown;

    final summary = _summaryString(
      data: data,
      kind: kind,
      toolName: toolName,
      status: status,
      argumentsPayload: argumentsPayload,
      resultPayload: resultPayload,
    );
    final details = _detailsString(
      data: data,
      argumentsPayload: argumentsPayload,
      resultPayload: resultPayload,
    );

    final title = switch (kind) {
      AgentRuntimeEventKind.tool =>
        toolName == null || toolName.isEmpty
            ? 'Tool event'
            : 'Tool · $toolName',
      AgentRuntimeEventKind.internal => 'Internal event',
      AgentRuntimeEventKind.status => 'Run status',
      AgentRuntimeEventKind.unknown => stream,
    };

    return AgentRuntimeEvent(
      kind: kind,
      runId: runId,
      seq: switch (seq) {
        int value => value,
        num value => value.toInt(),
        _ => event.seq ?? 0,
      },
      stream: stream,
      timestamp: timestamp,
      title: title,
      summary: summary,
      rawData: data,
      toolName: toolName,
      callId: callId,
      status: status,
      details: details,
    );
  }

  static String? _firstString(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static Object? _firstValue(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }
    return null;
  }

  static String _summaryString({
    required Map<String, Object?> data,
    required AgentRuntimeEventKind kind,
    required String? toolName,
    required String? status,
    required Object? argumentsPayload,
    required Object? resultPayload,
  }) {
    final explicit = _firstString(data, const <String>[
      'summary',
      'message',
      'text',
      'delta',
      'outputText',
      'content',
    ]);
    if (explicit != null) {
      return explicit;
    }

    if (kind == AgentRuntimeEventKind.tool) {
      final normalizedStatus = status?.toLowerCase();
      final toolLabel = toolName ?? 'tool';
      final previewSource = switch (normalizedStatus) {
        'completed' ||
        'complete' ||
        'done' ||
        'success' ||
        'succeeded' => resultPayload,
        _ => argumentsPayload,
      };
      final preview = _previewString(previewSource);
      final prefix = switch (normalizedStatus) {
        'queued' || 'pending' => 'Queued $toolLabel',
        'running' || 'started' || 'start' => 'Calling $toolLabel',
        'completed' ||
        'complete' ||
        'done' ||
        'success' ||
        'succeeded' => 'Completed $toolLabel',
        'failed' || 'error' => 'Failed $toolLabel',
        'cancelled' || 'canceled' => 'Cancelled $toolLabel',
        _ when normalizedStatus != null && normalizedStatus.isNotEmpty =>
          '${_capitalize(normalizedStatus)} $toolLabel',
        _ => 'Tool event · $toolLabel',
      };
      if (preview == null || preview.isEmpty) {
        return prefix;
      }
      return '$prefix · $preview';
    }

    return _inlineJson(data);
  }

  static String? _detailsString({
    required Map<String, Object?> data,
    required Object? argumentsPayload,
    required Object? resultPayload,
  }) {
    const simpleKeys = <String>{
      'summary',
      'message',
      'text',
      'delta',
      'outputText',
      'content',
      'status',
      'state',
      'phase',
      'event',
      'toolName',
      'tool',
      'name',
      'displayName',
      'label',
      'arguments',
      'args',
      'input',
      'params',
      'request',
      'result',
      'output',
      'response',
    };

    final sections = <String>[];

    final argumentsText = _multilineValue(argumentsPayload);
    if (argumentsText != null) {
      sections.add('Arguments\n$argumentsText');
    }

    final resultText = _multilineValue(resultPayload);
    if (resultText != null) {
      sections.add('Result\n$resultText');
    }

    final remainder = <String, Object?>{};
    for (final entry in data.entries) {
      if (!simpleKeys.contains(entry.key)) {
        remainder[entry.key] = entry.value;
      }
    }
    if (remainder.isNotEmpty) {
      sections.add('Metadata\n${_prettyJson(remainder)}');
    }

    if (sections.isEmpty) {
      return null;
    }
    return sections.join('\n\n');
  }

  static String? _previewString(Object? value) {
    final rendered = _singleLineValue(value);
    if (rendered == null) {
      return null;
    }
    if (rendered.length <= 96) {
      return rendered;
    }
    return '${rendered.substring(0, 93)}...';
  }

  static String? _singleLineValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return trimmed.replaceAll(RegExp(r'\s+'), ' ');
    }
    if (value is Map<String, Object?> || value is List<Object?>) {
      return _prettyJson(value).replaceAll(RegExp(r'\s+'), ' ');
    }
    return value.toString().trim();
  }

  static String? _multilineValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    }
    if (value is Map<String, Object?> || value is List<Object?>) {
      return _prettyJson(value);
    }
    final rendered = value.toString().trim();
    return rendered.isEmpty ? null : rendered;
  }

  static String _inlineJson(Map<String, Object?> json) {
    try {
      return jsonEncode(json);
    } catch (_) {
      return json.toString();
    }
  }

  static String _prettyJson(Object? value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
