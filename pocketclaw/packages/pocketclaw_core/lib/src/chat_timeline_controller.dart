import 'package:gateway_adapter/gateway_adapter.dart';

import 'chat_timeline_item.dart';

final class ChatTimelineController {
  ChatTimelineController({
    Iterable<ChatTimelineItem> initialItems = const <ChatTimelineItem>[],
  }) : _items = List<ChatTimelineItem>.from(initialItems);

  final List<ChatTimelineItem> _items;
  final Map<String, int> _assistantIndexByRunId = <String, int>{};
  final Map<String, int> _runtimeIndexByKey = <String, int>{};

  List<ChatTimelineItem> get items => List<ChatTimelineItem>.unmodifiable(_items);

  void replaceAll(Iterable<ChatTimelineItem> items) {
    _items
      ..clear()
      ..addAll(items);
    _assistantIndexByRunId.clear();
    _runtimeIndexByKey.clear();
    for (var index = 0; index < _items.length; index += 1) {
      final updateKey = _items[index].updateKey;
      if (updateKey != null && updateKey.isNotEmpty) {
        _runtimeIndexByKey[updateKey] = index;
      }
    }
  }

  void replaceHistory(Iterable<ChatMessage> messages) {
    replaceAll(
      messages.map((message) {
        return ChatTimelineItem(
          role: switch (message.role) {
            ChatMessageRole.system => ChatTimelineRole.system,
            ChatMessageRole.user => ChatTimelineRole.user,
            ChatMessageRole.assistant => ChatTimelineRole.assistant,
          },
          text: message.text,
          createdAt: message.timestamp ?? DateTime.now().toUtc(),
        );
      }),
    );
  }

  void append(ChatTimelineItem item) {
    _items.add(item);
    final index = _items.length - 1;
    _rememberIndex(item.updateKey, index);
  }

  void appendMessage({
    required ChatTimelineRole role,
    required String text,
    DateTime? createdAt,
    String? title,
    String? status,
    String? details,
  }) {
    append(
      ChatTimelineItem(
        role: role,
        text: text,
        createdAt: createdAt ?? DateTime.now().toUtc(),
        title: title,
        status: status,
        details: details,
      ),
    );
  }

  void applyChatStreamEvent(ChatStreamEvent event) {
    switch (event.state) {
      case ChatStreamState.delta:
        _applyAssistantDelta(event);
        break;
      case ChatStreamState.finalMessage:
        _finalizeAssistantMessage(event);
        break;
      case ChatStreamState.aborted:
        _closeAssistantRun(
          event,
          status: 'aborted',
          fallbackSystemText: event.message?.text,
        );
        break;
      case ChatStreamState.error:
        _closeAssistantRun(
          event,
          status: 'error',
          details: event.errorMessage,
          fallbackSystemText: event.errorMessage ?? event.message?.text,
        );
        break;
    }
  }

  void applyRuntimeEvent(AgentRuntimeEvent event) {
    if (event.kind != AgentRuntimeEventKind.tool &&
        event.kind != AgentRuntimeEventKind.internal) {
      return;
    }

    final item = ChatTimelineItem(
      role: ChatTimelineRole.tool,
      text: event.summary,
      createdAt: event.timestamp,
      title: event.title,
      status: event.status,
      details: event.details,
      updateKey: event.timelineKey,
    );

    final updateKey = event.timelineKey;
    if (updateKey == null || updateKey.isEmpty) {
      append(item);
      return;
    }

    final existingIndex = _runtimeIndexByKey[updateKey];
    if (existingIndex == null || existingIndex < 0 || existingIndex >= _items.length) {
      append(item);
      return;
    }

    _items[existingIndex] = _items[existingIndex].copyWith(
      text: item.text,
      createdAt: item.createdAt,
      title: item.title,
      status: item.status,
      details: item.details,
      updateKey: item.updateKey,
    );
  }

  void _applyAssistantDelta(ChatStreamEvent event) {
    final message = event.message;
    if (message == null || message.text.isEmpty) {
      return;
    }

    final runId = event.runId;
    if (runId == null || runId.isEmpty) {
      append(
        ChatTimelineItem(
          role: ChatTimelineRole.assistant,
          text: message.text,
          createdAt: message.timestamp ?? DateTime.now().toUtc(),
          isStreaming: true,
        ),
      );
      return;
    }

    final existingIndex = _assistantIndexByRunId[runId];
    if (existingIndex == null || existingIndex < 0 || existingIndex >= _items.length) {
      final item = ChatTimelineItem(
        role: ChatTimelineRole.assistant,
        text: message.text,
        createdAt: message.timestamp ?? DateTime.now().toUtc(),
        isStreaming: true,
      );
      _items.add(item);
      _assistantIndexByRunId[runId] = _items.length - 1;
      return;
    }

    final existing = _items[existingIndex];
    _items[existingIndex] = existing.copyWith(
      text: _mergeStreamingText(existing.text, message.text),
      createdAt: message.timestamp ?? existing.createdAt,
      isStreaming: true,
    );
  }

  void _closeAssistantRun(
    ChatStreamEvent event, {
    required String status,
    String? details,
    String? fallbackSystemText,
  }) {
    final message = event.message;
    final runId = event.runId;
    final existingIndex = runId == null || runId.isEmpty
        ? null
        : _assistantIndexByRunId.remove(runId);

    if (existingIndex != null &&
        existingIndex >= 0 &&
        existingIndex < _items.length) {
      final existing = _items[existingIndex];
      final nextText = message != null && message.text.trim().isNotEmpty
          ? _preferTerminalText(existing.text, message.text)
          : existing.text;
      _items[existingIndex] = existing.copyWith(
        text: nextText,
        createdAt: message?.timestamp ?? existing.createdAt,
        isStreaming: false,
        status: status,
        details: details ?? existing.details,
      );
      if (status == 'error' &&
          fallbackSystemText != null &&
          fallbackSystemText.trim().isNotEmpty) {
        appendMessage(
          role: ChatTimelineRole.system,
          text: fallbackSystemText,
          createdAt: message?.timestamp,
        );
      }
      return;
    }

    if (message != null && message.text.trim().isNotEmpty) {
      append(
        ChatTimelineItem(
          role: ChatTimelineRole.assistant,
          text: message.text,
          createdAt: message.timestamp ?? DateTime.now().toUtc(),
          isStreaming: false,
          status: status,
          details: details,
        ),
      );
      if (status == 'error' &&
          fallbackSystemText != null &&
          fallbackSystemText.trim().isNotEmpty &&
          fallbackSystemText.trim() != message.text.trim()) {
        appendMessage(
          role: ChatTimelineRole.system,
          text: fallbackSystemText,
          createdAt: message.timestamp,
        );
      }
      return;
    }

    if (fallbackSystemText != null && fallbackSystemText.trim().isNotEmpty) {
      appendMessage(
        role: ChatTimelineRole.system,
        text: fallbackSystemText,
      );
    }
  }

  void _finalizeAssistantMessage(ChatStreamEvent event) {
    final message = event.message;
    if (message == null) {
      _assistantIndexByRunId.remove(event.runId);
      return;
    }

    final runId = event.runId;
    if (runId == null || runId.isEmpty) {
      append(
        ChatTimelineItem(
          role: ChatTimelineRole.assistant,
          text: message.text,
          createdAt: message.timestamp ?? DateTime.now().toUtc(),
        ),
      );
      return;
    }

    final existingIndex = _assistantIndexByRunId.remove(runId);
    if (existingIndex == null || existingIndex < 0 || existingIndex >= _items.length) {
      append(
        ChatTimelineItem(
          role: ChatTimelineRole.assistant,
          text: message.text,
          createdAt: message.timestamp ?? DateTime.now().toUtc(),
        ),
      );
      return;
    }

    final existing = _items[existingIndex];
    final finalizedText = message.text.isEmpty
        ? existing.text
        : _preferFinalText(existing.text, message.text);
    _items[existingIndex] = existing.copyWith(
      text: finalizedText,
      createdAt: message.timestamp ?? existing.createdAt,
      isStreaming: false,
    );
  }

  void _rememberIndex(String? updateKey, int index) {
    if (updateKey == null || updateKey.isEmpty) {
      return;
    }
    _runtimeIndexByKey[updateKey] = index;
  }

  String _mergeStreamingText(String existing, String incoming) {
    if (existing.isEmpty) {
      return incoming;
    }
    if (incoming.isEmpty) {
      return existing;
    }
    if (incoming.startsWith(existing)) {
      return incoming;
    }
    if (existing.endsWith(incoming)) {
      return existing;
    }
    return '$existing$incoming';
  }

  String _preferFinalText(String existing, String incoming) {
    if (incoming.startsWith(existing) || existing.isEmpty) {
      return incoming;
    }
    return incoming;
  }

  String _preferTerminalText(String existing, String incoming) {
    if (incoming.isEmpty) {
      return existing;
    }
    if (incoming.startsWith(existing) || existing.isEmpty) {
      return incoming;
    }
    if (existing.startsWith(incoming)) {
      return existing;
    }
    return incoming;
  }
}
