#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(mktemp -d /tmp/openclaw-patch-check.XXXXXX)"
cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

log() {
  printf '[codex-patch-check] %s\n' "$*"
}

RESTORE_SCRIPT="/root/.openclaw/workspace/scripts/restore-openai-codex-responses-compat.sh"
if [[ ! -x "$RESTORE_SCRIPT" ]]; then
  echo "restore script missing or not executable: $RESTORE_SCRIPT" >&2
  exit 1
fi

log "staging latest openclaw into $WORKDIR"
npm install --prefix "$WORKDIR" --no-save --ignore-scripts openclaw@latest >/dev/null

TARGET="$(find "$WORKDIR/node_modules" -path '*/@mariozechner/pi-ai/dist/providers/openai-codex-responses.js' | head -n 1)"
if [[ -z "$TARGET" || ! -f "$TARGET" ]]; then
  echo "target not found in staged install under $WORKDIR/node_modules" >&2
  exit 1
fi

VERSION="$(npm view openclaw@latest version)"
PI_AI_PKG="$(find "$WORKDIR/node_modules" -path '*/@mariozechner/pi-ai/package.json' | head -n 1)"
if [[ -z "$PI_AI_PKG" || ! -f "$PI_AI_PKG" ]]; then
  echo "pi-ai package.json not found in staged install" >&2
  exit 1
fi
PI_AI_VERSION="$(node -p "require('$PI_AI_PKG').version")"
log "staged openclaw version: $VERSION"
log "staged pi-ai version: $PI_AI_VERSION"

BEFORE_HASH="$(sha256sum "$TARGET" | awk '{print $1}')"
log "target before patch: $BEFORE_HASH"
"$RESTORE_SCRIPT" "$TARGET"
AFTER_HASH="$(sha256sum "$TARGET" | awk '{print $1}')"
log "target after patch:  $AFTER_HASH"

if [[ "$BEFORE_HASH" == "$AFTER_HASH" ]]; then
  log "patch was already present in staged target or no-op"
else
  log "patch applies cleanly to latest staged target"
fi

printf 'OPENCLAW_VERSION=%s\n' "$VERSION"
printf 'PI_AI_VERSION=%s\n' "$PI_AI_VERSION"
printf 'TARGET=%s\n' "$TARGET"
