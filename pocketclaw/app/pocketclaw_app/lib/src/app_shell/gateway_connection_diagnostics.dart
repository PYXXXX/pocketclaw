String formatGatewayConnectionDiagnostics({
  required String draftUrl,
  required String savedUrl,
  required String liveClientUrl,
  required bool isBootstrapping,
  required bool isApplyingConfiguration,
  required bool isRefreshingClient,
  required bool hasDraftToken,
  required bool hasSavedToken,
  required bool hasLiveClientToken,
  required bool hasDraftPassword,
  required bool hasSavedPassword,
  required bool hasLiveClientPassword,
  required int draftHeaderCount,
  required int savedHeaderCount,
  required int liveClientHeaderCount,
}) {
  String valueOrPlaceholder(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '<empty>' : trimmed;
  }

  String boolLabel(bool value) => value ? 'yes' : 'no';

  return <String>[
    'Gateway connection diagnostics',
    'draft.url=${valueOrPlaceholder(draftUrl)}',
    'saved.url=${valueOrPlaceholder(savedUrl)}',
    'live.url=${valueOrPlaceholder(liveClientUrl)}',
    'draft.hasToken=${boolLabel(hasDraftToken)}',
    'saved.hasToken=${boolLabel(hasSavedToken)}',
    'live.hasToken=${boolLabel(hasLiveClientToken)}',
    'draft.hasPassword=${boolLabel(hasDraftPassword)}',
    'saved.hasPassword=${boolLabel(hasSavedPassword)}',
    'live.hasPassword=${boolLabel(hasLiveClientPassword)}',
    'draft.headerCount=$draftHeaderCount',
    'saved.headerCount=$savedHeaderCount',
    'live.headerCount=$liveClientHeaderCount',
    'state.bootstrapping=${boolLabel(isBootstrapping)}',
    'state.applyingConfiguration=${boolLabel(isApplyingConfiguration)}',
    'state.refreshingClient=${boolLabel(isRefreshingClient)}',
  ].join('\n');
}
