String effectiveGatewayUrlInput({
  required String draftUrl,
  required String savedUrl,
}) {
  final trimmedDraft = draftUrl.trim();
  if (trimmedDraft.isNotEmpty) {
    return trimmedDraft;
  }
  return savedUrl;
}
