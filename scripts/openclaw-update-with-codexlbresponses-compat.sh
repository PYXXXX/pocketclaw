#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/root/.openclaw/workspace"
RESTORE_SCRIPT="$WORKSPACE/scripts/restore-openai-codex-responses-compat.sh"
CHECK_SCRIPT="$WORKSPACE/scripts/check-openclaw-latest-codex-patch.sh"

if [[ ! -x "$RESTORE_SCRIPT" ]]; then
  echo "restore script missing or not executable: $RESTORE_SCRIPT" >&2
  exit 1
fi
if [[ ! -x "$CHECK_SCRIPT" ]]; then
  echo "check script missing or not executable: $CHECK_SCRIPT" >&2
  exit 1
fi

log() {
  printf '[codexlbresponses-update] %s\n' "$*"
}

GLOBAL_NPM_ROOT="$(npm root -g)"
OPENCLAW_DIR="$GLOBAL_NPM_ROOT/openclaw"
TARGET="$OPENCLAW_DIR/node_modules/@mariozechner/pi-ai/dist/providers/openai-codex-responses.js"
BACKUP_DIR="$WORKSPACE/tmp/openclaw-patch-backups"
mkdir -p "$BACKUP_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_FILE="$BACKUP_DIR/openai-codex-responses.$STAMP.js"

log 'preflight: checking whether the patch still applies to latest openclaw@latest'
"$CHECK_SCRIPT"

log "backing up current patched file to $BACKUP_FILE"
cp -a "$TARGET" "$BACKUP_FILE"

log 'updating OpenClaw package'
npm install -g openclaw@latest

NEW_GLOBAL_NPM_ROOT="$(npm root -g)"
NEW_OPENCLAW_DIR="$NEW_GLOBAL_NPM_ROOT/openclaw"
NEW_TARGET="$NEW_OPENCLAW_DIR/node_modules/@mariozechner/pi-ai/dist/providers/openai-codex-responses.js"
log "re-applying codex-lb responses compatibility patch to $NEW_TARGET"
"$RESTORE_SCRIPT" "$NEW_TARGET"

log 'validating OpenClaw install'
openclaw --version
if command -v openclaw >/dev/null 2>&1 && openclaw help >/dev/null 2>&1; then
  :
fi

log 'restarting gateway'
if openclaw gateway restart >/tmp/openclaw-gateway-restart.log 2>&1; then
  cat /tmp/openclaw-gateway-restart.log
else
  cat /tmp/openclaw-gateway-restart.log >&2 || true
  log 'gateway restart returned non-zero; this can happen if the CLI disconnects during daemon restart'
fi

log 'done'
