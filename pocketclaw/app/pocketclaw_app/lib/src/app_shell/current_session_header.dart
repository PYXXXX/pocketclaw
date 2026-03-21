import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pocketclaw_core/pocketclaw_core.dart';

import 'current_session_header_view_data.dart';

class CurrentSessionHeader extends StatelessWidget {
  const CurrentSessionHeader({
    super.key,
    required this.currentSession,
    required this.canForgetCurrentSession,
    required this.sessionTitleController,
    required this.onSessionTitleSubmitted,
    required this.onForgetCurrentSession,
  });

  final LocalSessionEntry currentSession;
  final bool canForgetCurrentSession;
  final TextEditingController sessionTitleController;
  final ValueChanged<String> onSessionTitleSubmitted;
  final Future<void> Function() onForgetCurrentSession;

  @override
  Widget build(BuildContext context) {
    final viewData = CurrentSessionHeaderViewData.from(
      currentSession,
      canForgetCurrentSession: canForgetCurrentSession,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: sessionTitleController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Session title',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: onSessionTitleSubmitted,
        ),
        const SizedBox(height: 12),
        SelectableText(viewData.sessionKeyText),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: Icon(
                viewData.isGatewayBacked
                    ? Icons.cloud_done_outlined
                    : Icons.phone_android_outlined,
                size: 18,
              ),
              label: Text(viewData.sourceLabel),
            ),
            if (viewData.gatewayLabel != null)
              Chip(
                avatar: const Icon(Icons.label_outline, size: 18),
                label: Text(viewData.gatewayLabel!),
              ),
            Chip(
              avatar: Icon(
                viewData.hasLocalDraft
                    ? Icons.edit_note_outlined
                    : Icons.drafts_outlined,
                size: 18,
              ),
              label: Text(viewData.draftStatusLabel),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: canForgetCurrentSession
                  ? () => unawaited(
                        _confirmForgetCurrentSession(
                          context,
                          viewData: viewData,
                        ),
                      )
                  : null,
              icon: const Icon(Icons.delete_outline),
              label: Text(viewData.forgetActionLabel),
            ),
            if (viewData.cannotForgetHint != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  viewData.cannotForgetHint!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _confirmForgetCurrentSession(
    BuildContext context, {
    required CurrentSessionHeaderViewData viewData,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(viewData.forgetDialogTitle),
          content: Text(viewData.forgetDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(viewData.forgetConfirmLabel),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await onForgetCurrentSession();
    }
  }
}
