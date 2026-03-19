import 'dart:convert';

import 'package:gateway_transport/gateway_transport.dart';

enum AgentRuntimeEventKind {
  tool,
  internal,
  status,
  unknown,
}

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
    final toolName = _firstString(data, <String>[
      'toolName',
      'tool',
      'name',
      'displayName',
      'label',
    ]);
    final callId = _firstString(data, <String>['callId', 'toolCallId']);
    final status = _firstString(data, <String>[
      'status',
      'state',
      'phase',
      'event',
    ]);
    final summary = _firstString(data, <String>[
          'summary',
          'message',
          'text',
          'delta',
          'outputText',
          'content',
        ]) ??
        _inlineJson(data);
    final details = _detailsString(data);

    final isToolStream = normalizedStream.contains('tool') ||
        data.containsKey('toolName') ||
        data.containsKey('tool') ||
        data.containsKey('callId') ||
        data.containsKey('arguments') ||
        data.containsKey('result');
    final isInternal = normalizedStream.contains('internal') ||
        data['type'] == 'task_completion';

    final kind = isToolStream
        ? AgentRuntimeEventKind.tool
        : isInternal
            ? AgentRuntimeEventKind.internal
            : normalizedStream.contains('status')
                ? AgentRuntimeEventKind.status
                : AgentRuntimeEventKind.unknown;

    final title = switch (kind) {
      AgentRuntimeEventKind.tool => toolName == null || toolName.isEmpty
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

  static String _inlineJson(Map<String, Object?> json) {
    try {
      return jsonEncode(json);
    } catch (_) {
      return json.toString();
    }
  }

  static String? _detailsString(Map<String, Object?> json) {
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
    };

    final remainder = <String, Object?>{};
    for (final entry in json.entries) {
      if (!simpleKeys.contains(entry.key)) {
        remainder[entry.key] = entry.value;
      }
    }
    if (remainder.isEmpty) {
      return null;
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(remainder);
    } catch (_) {
      return remainder.toString();
    }
  }
}
