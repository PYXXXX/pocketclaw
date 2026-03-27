# OpenClaw Codex Responses compatibility patch

This workspace keeps a local patch for:

- `openclaw/node_modules/@mariozechner/pi-ai/dist/providers/openai-codex-responses.js`

## What the patch changes

The patch makes the Codex Responses request logic conditional on the configured base URL:

1. `extractAccountId()` accepts `baseUrl`
2. `buildHeaders()` accepts `baseUrl`
3. `chatgpt-account-id` is only sent when an account ID exists
4. `OpenAI-Beta: responses=experimental` is only sent for official OpenAI/ChatGPT hosts
5. call sites pass `model.baseUrl`

## Why this exists

The upstream file assumes official Codex/OpenAI-style hosts. In this environment we need compatibility with non-official base URLs as well, so the request logic must avoid forcing official-only headers when a custom endpoint is configured.

## Scripts

- `scripts/restore-openai-codex-responses-compat.sh`
  - Applies the patch to an installed target file
  - Default target is the currently installed global OpenClaw package
  - Can also patch an explicit file path

- `scripts/check-openclaw-latest-codex-patch.sh`
  - Installs `openclaw@latest` into a temporary directory
  - Verifies that the patch still applies cleanly before touching the real install

- `scripts/openclaw-update-with-codexlbresponses-compat.sh`
  - Runs the preflight check
  - Backs up the current installed file
  - Updates OpenClaw globally
  - Reapplies the patch
  - Restarts the gateway

## Expected workflow

When asked to update OpenClaw:

1. Run the preflight checker first
2. If the patch no longer applies, adapt `restore-openai-codex-responses-compat.sh` to the new upstream file
3. Re-run the preflight checker until it passes
4. Run the update script

## Notes

This patch is currently maintained as a deterministic post-install patch instead of a forked dependency, because it is small and localized.
