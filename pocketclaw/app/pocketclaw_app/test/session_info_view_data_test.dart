import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_adapter/gateway_adapter.dart';
import 'package:pocketclaw_app/src/app_shell/app_strings.dart';
import 'package:pocketclaw_app/src/app_shell/session_info_view_data.dart';

void main() {
  const en = Locale('en');
  const zh = Locale('zh');

  test('SessionInfoViewData exposes inherited defaults cleanly', () {
    final viewData = SessionInfoViewData.from(
      strings: AppStrings.fromLocale(en),
      identity: const AgentIdentity(agentId: 'main', name: 'PocketLobster'),
      sessionDefaults: const SessionDefaults(
        model: 'gpt-5.4',
        thinkingLevel: 'medium',
        fastMode: true,
        verboseLevel: 'low',
      ),
      models: const <ModelInfo>[
        ModelInfo(id: 'gpt-5.4'),
        ModelInfo(id: 'gpt-5.4-mini'),
      ],
    );

    expect(viewData.assistantName, 'PocketLobster');
    expect(viewData.model.displayValue, 'gpt-5.4');
    expect(viewData.model.inherited, isTrue);
    expect(viewData.model.selectedValue, SessionInfoViewData.defaultModelValue);
    expect(viewData.model.options.first.label, 'Default (inherit: gpt-5.4)');
    expect(viewData.fastMode, isTrue);
    expect(viewData.fastModeSummary, 'Inheriting default · on');
    expect(viewData.hasFastModeOverride, isFalse);
    expect(viewData.fastModeResetLabel, 'Use default fast mode (on)');
  });

  test('SessionInfoViewData keeps unknown override values selectable', () {
    final viewData = SessionInfoViewData.from(
      strings: AppStrings.fromLocale(en),
      sessionInfo: const SessionInfo(
        key: 'agent:main:pc-home',
        model: 'custom-model',
        thinkingLevel: 'ultra',
        verboseLevel: 'trace',
      ),
      sessionDefaults: const SessionDefaults(
        model: 'gpt-5.4',
        thinkingLevel: 'low',
        verboseLevel: 'medium',
      ),
      models: const <ModelInfo>[ModelInfo(id: 'gpt-5.4')],
    );

    expect(viewData.model.displayValue, 'custom-model');
    expect(viewData.model.inherited, isFalse);
    expect(viewData.model.options[1].label, 'custom-model (current)');

    expect(viewData.thinking.selectedValue, 'ultra');
    expect(viewData.thinking.displayValue, 'ultra');
    expect(viewData.thinking.options[1].label, 'ultra (current)');

    expect(viewData.verbose.selectedValue, 'trace');
    expect(viewData.verbose.displayValue, 'trace');
    expect(viewData.verbose.options[1].label, 'trace (current)');
  });

  test('SessionInfoViewData reports fast mode overrides and reset labels', () {
    final viewData = SessionInfoViewData.from(
      strings: AppStrings.fromLocale(en),
      sessionInfo: const SessionInfo(
        key: 'agent:main:pc-home',
        fastMode: false,
      ),
      sessionDefaults: const SessionDefaults(fastMode: true),
      models: const <ModelInfo>[],
    );

    expect(viewData.fastMode, isFalse);
    expect(viewData.fastModeSummary, 'Override active · off');
    expect(viewData.hasFastModeOverride, isTrue);
    expect(viewData.fastModeResetLabel, 'Use default fast mode (on)');
  });

  test('SessionInfoViewData supports zh summaries', () {
    final viewData = SessionInfoViewData.from(
      strings: AppStrings.fromLocale(zh),
      sessionDefaults: const SessionDefaults(
        model: 'gpt-5.4',
        thinkingLevel: 'medium',
        fastMode: true,
        verboseLevel: 'low',
      ),
      models: const <ModelInfo>[ModelInfo(id: 'gpt-5.4')],
    );

    expect(viewData.model.options.first.label, '默认（继承：gpt-5.4）');
    expect(viewData.fastModeSummary, '继承默认值 · 开');
    expect(viewData.fastModeResetLabel, '使用默认快速模式（开）');
  });
}
