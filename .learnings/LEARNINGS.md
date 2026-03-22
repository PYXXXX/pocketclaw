# LEARNINGS

## [LRN-20260321-001] best_practice

**Logged**: 2026-03-21T13:20:00Z
**Priority**: high
**Status**: pending
**Area**: frontend

### Summary
Avoid `return` inside `finally` during PocketClaw startup/bootstrap flows.

### Details
`app/pocketclaw_app/lib/main.dart` had a `return` inside `_bootstrapLocalState()`'s `finally` block. Static analysis flagged it (`control_flow_in_finally`), and it makes startup-state handling less transparent because `finally` control flow can obscure failures or lifecycle transitions. In a screen that toggles `_isBootstrapping`, this can surface as the app feeling "stuck" or hard to reason about during restore.

### Suggested Action
Prefer `if (mounted) { ... }` guards inside `finally` and keep the state transition explicit. Remove dead helpers when cleaning the same area so `dart analyze` stays quiet.

### Metadata
- Source: error
- Related Files: pocketclaw/app/pocketclaw_app/lib/main.dart
- Tags: flutter, bootstrap, lifecycle, analyze

---

## [LRN-20260321-002] correction

**Logged**: 2026-03-21T13:36:00Z
**Priority**: high
**Status**: pending
**Area**: frontend

### Summary
Do not assume PocketClaw Android WebSocket failures with `Unsupported URL scheme ""` are fixed by appending `/` to the root URL.

### Details
During PocketClaw connection debugging, `ws://bot.bilirec.com` clearly failed because the edge redirected to HTTPS, and `wss://bot.bilirec.com` worked from host-side Node and Dart probes, including receipt of `connect.challenge`. A follow-up hypothesis blamed missing root path normalization (`wss://host` vs `wss://host/`), but the user confirmed Android still failed even after manually entering `wss://bot.bilirec.com/`. The more reliable diagnosis path is: verify the exact URL shown in-app, confirm host-side `wss://` handshake succeeds, then treat on-device `Unsupported URL scheme ""` as a likely Android/device-network/redirect quirk rather than a simple slash-normalization issue.

### Suggested Action
When this error appears again, first distinguish between:
1. bad configured scheme (`ws://` on an HTTPS-only edge),
2. server/proxy redirect at the edge, and
3. device-specific redirect/interception or Android runtime behavior.
Add better client-side instrumentation/preflight so PocketClaw can surface the actual redirect/HTTP status instead of the opaque `Unsupported URL scheme ""` message.

### Metadata
- Source: user_feedback
- Related Files: pocketclaw/packages/gateway_adapter/lib/src/gateway_connection_config.dart, pocketclaw/packages/gateway_adapter/lib/src/gateway_error_guidance.dart
- Tags: flutter, android, websocket, redirect, diagnosis

---
## [LRN-20260322-001] best_practice

**Logged**: 2026-03-22T09:15:00Z
**Priority**: high
**Status**: pending
**Area**: frontend

### Summary
PocketClaw connection settings must not update visible saved state before the live Gateway client swap finishes.

### Details
A long-running bug made PocketClaw show a saved Gateway URL in the UI while `Connect` could still use the old `_gatewayClient` created from an empty profile. The root cause was a race: `_applyGatewayConfiguration()` updated `_gatewayProfile` and the UI immediately, but `_replaceGatewayClient(_buildGatewayClient(profile))` completed later. Users could tap Connect during that window, so the websocket layer appeared to receive an empty URL even though the screen showed a populated one.

### Suggested Action
Keep a single in-flight gateway configuration apply operation, disable Connect while it runs, and have `_connect()` await any pending apply before opening the websocket.

### Metadata
- Source: conversation
- Related Files: pocketclaw/app/pocketclaw_app/lib/main.dart, pocketclaw/app/pocketclaw_app/lib/src/app_shell/connect_surface.dart
- Tags: pocketclaw, gateway, race-condition, configuration, websocket
- Pattern-Key: harden.gateway-config-apply-race

---
