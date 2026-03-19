import 'package:flutter/material.dart';

enum ConnectMethod {
  manual,
  setupCode,
}

enum ConnectFlowStage {
  welcome,
  chooseMethod,
  manualConfig,
  authPending,
  pairingPending,
  ready,
  error,
}

enum AppDestination {
  chat,
  connect,
}

@immutable
class ConnectFlowSnapshot {
  const ConnectFlowSnapshot({
    required this.stage,
    required this.title,
    required this.description,
    this.requiresAttention = false,
  });

  final ConnectFlowStage stage;
  final String title;
  final String description;
  final bool requiresAttention;
}
