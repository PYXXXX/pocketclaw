import 'package:gateway_adapter/gateway_adapter.dart';

import 'app_strings.dart';

final class SessionInfoViewData {
  const SessionInfoViewData({
    required this.assistantName,
    required this.model,
    required this.thinking,
    required this.verbose,
    required this.fastMode,
    required this.fastModeSummary,
    required this.hasFastModeOverride,
    required this.fastModeResetLabel,
  });

  static const String defaultModelValue = '__default_model__';
  static const String defaultThinkingValue = '__default_thinking__';
  static const String defaultVerboseValue = '__default_verbose__';

  static const List<String> thinkingChoices = <String>[
    'off',
    'minimal',
    'low',
    'medium',
    'high',
  ];
  static const List<String> verboseChoices = <String>[
    'off',
    'low',
    'medium',
    'high',
  ];

  final String assistantName;
  final SessionSettingViewData model;
  final SessionSettingViewData thinking;
  final SessionSettingViewData verbose;
  final bool fastMode;
  final String fastModeSummary;
  final bool hasFastModeOverride;
  final String fastModeResetLabel;

  factory SessionInfoViewData.from({
    required AppStrings strings,
    AgentIdentity? identity,
    SessionInfo? sessionInfo,
    SessionDefaults? sessionDefaults,
    required List<ModelInfo> models,
  }) {
    final model = SessionSettingViewData.from(
      currentOverride: sessionInfo?.model,
      inheritedValue: sessionDefaults?.model,
      defaultValue: defaultModelValue,
      defaultLabelBuilder: strings.defaultInherit,
      currentLabelBuilder: strings.currentValue,
      gatewayDefaultLabel: strings.gatewayDefault,
      knownOptions: models
          .map((model) => SessionDropdownOption(value: model.id, label: model.id))
          .toList(),
    );

    final thinking = SessionSettingViewData.from(
      currentOverride: sessionInfo?.thinkingLevel,
      inheritedValue: sessionDefaults?.thinkingLevel,
      defaultValue: defaultThinkingValue,
      defaultLabelBuilder: strings.defaultValue,
      currentLabelBuilder: strings.currentValue,
      gatewayDefaultLabel: strings.gatewayDefault,
      knownOptions: thinkingChoices
          .map(
            (value) => SessionDropdownOption(value: value, label: value),
          )
          .toList(),
    );

    final verbose = SessionSettingViewData.from(
      currentOverride: sessionInfo?.verboseLevel,
      inheritedValue: sessionDefaults?.verboseLevel,
      defaultValue: defaultVerboseValue,
      defaultLabelBuilder: strings.defaultValue,
      currentLabelBuilder: strings.currentValue,
      gatewayDefaultLabel: strings.gatewayDefault,
      knownOptions: verboseChoices
          .map(
            (value) => SessionDropdownOption(value: value, label: value),
          )
          .toList(),
    );

    final inheritedFastMode = sessionDefaults?.fastMode;
    final effectiveFastMode = sessionInfo?.fastMode ?? inheritedFastMode ?? false;
    final fastModeDefaultLabel = inheritedFastMode == null
        ? strings.gatewayDefault
        : strings.boolLabel(inheritedFastMode);
    final fastModeSummary = sessionInfo?.fastMode == null
        ? strings.inheritingDefault(fastModeDefaultLabel)
        : strings.overrideActive(effectiveFastMode);

    return SessionInfoViewData(
      assistantName: identity?.name ?? strings.assistantFallback,
      model: model,
      thinking: thinking,
      verbose: verbose,
      fastMode: effectiveFastMode,
      fastModeSummary: fastModeSummary,
      hasFastModeOverride: sessionInfo?.fastMode != null,
      fastModeResetLabel: strings.useDefaultFastMode(fastModeDefaultLabel),
    );
  }
}

final class SessionSettingViewData {
  const SessionSettingViewData({
    required this.displayValue,
    required this.inherited,
    required this.selectedValue,
    required this.defaultLabel,
    required this.options,
  });

  final String displayValue;
  final bool inherited;
  final String selectedValue;
  final String defaultLabel;
  final List<SessionDropdownOption> options;

  factory SessionSettingViewData.from({
    required String? currentOverride,
    required String? inheritedValue,
    required String defaultValue,
    required String Function(String defaultLabel) defaultLabelBuilder,
    required String Function(String value) currentLabelBuilder,
    required String gatewayDefaultLabel,
    required List<SessionDropdownOption> knownOptions,
  }) {
    final fallbackLabel = inheritedValue ?? gatewayDefaultLabel;
    final knownValues = knownOptions.map((option) => option.value).toSet();

    return SessionSettingViewData(
      displayValue: currentOverride ?? fallbackLabel,
      inherited: currentOverride == null,
      selectedValue: currentOverride ?? defaultValue,
      defaultLabel: fallbackLabel,
      options: <SessionDropdownOption>[
        SessionDropdownOption(
          value: defaultValue,
          label: defaultLabelBuilder(fallbackLabel),
        ),
        if (currentOverride != null && !knownValues.contains(currentOverride))
          SessionDropdownOption(
            value: currentOverride,
            label: currentLabelBuilder(currentOverride),
          ),
        ...knownOptions,
      ],
    );
  }
}

final class SessionDropdownOption {
  const SessionDropdownOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}
