## [ERR-20260319-001] flutter-dart-toolchain-missing

**Logged**: 2026-03-19T15:12:20Z
**Priority**: medium
**Status**: pending
**Area**: infra

### Summary
Local PocketClaw validation commands could not run because Dart, Flutter, and Melos are not installed in this workspace environment.

### Error
```text
/usr/bin/bash: line 1: dart: command not found
/usr/bin/bash: line 1: flutter: command not found
/usr/bin/bash: line 1: /root/.pub-cache/bin/melos: No such file or directory
```

### Context
- Commands attempted from `/root/.openclaw/workspace/pocketclaw`
- `dart --version`
- `flutter --version`
- `melos run analyze`
- `melos run test`

### Suggested Fix
Install Flutter and Dart in the host environment, then activate Melos before running repo validation.

### Metadata
- Reproducible: yes
- Related Files: pocketclaw/pubspec.yaml, pocketclaw/melos.yaml

---

## [ERR-20260319-002] grep-pattern-shell-quoting

**Logged**: 2026-03-19T16:18:00Z
**Priority**: low
**Status**: pending
**Area**: infra

### Summary
A quick verification command used `grep` with an unescaped `(` pattern and failed before returning the intended search results.

### Error
```text
grep: Unmatched ( or \(
```

### Context
- Command attempted from `/root/.openclaw/workspace`
- Verification step after PocketClaw app-shell refactor
- Pattern used: `grep -RIn "AppStatusBanner(" pocketclaw/app/pocketclaw_app/lib`

### Suggested Fix
Use `grep -F` for literal text searches or escape regex metacharacters when checking source code snippets from the shell.

### Metadata
- Reproducible: yes
- Related Files: pocketclaw/app/pocketclaw_app/lib/main.dart

---

## [ERR-20260320-003] pocketclaw-mobile-loopback-default

**Logged**: 2026-03-20T15:24:00Z
**Priority**: high
**Status**: in_progress
**Area**: frontend

### Summary
PocketClaw mobile testing hit `Connection refused` because the app defaulted users toward `127.0.0.1`, which points to the phone itself on real devices.

### Error
```text
WebSocketChannelException: SocketException: Connection refused (OS Error: Connection refused, errno = 111), address = 127.0.0.1
```

### Context
- Real-device PocketClaw test from CI artifact
- Default profile URL and connect hint suggested `ws://127.0.0.1:18789`
- Connect flow also allowed stale saved config to be used if the user edited the form but did not press Save before Connect
- CI uploaded debug APKs, which made tester download size look much worse than a realistic release build

### Suggested Fix
- Stop defaulting the mobile app to loopback
- Normalize and auto-apply the current connect form values on Connect
- Add loopback-specific guidance for connection failures
- Upload split release APKs in CI instead of debug artifacts for tester downloads

### Metadata
- Reproducible: yes
- Related Files: pocketclaw/packages/pocketclaw_core/lib/src/gateway_profile.dart, pocketclaw/app/pocketclaw_app/lib/main.dart, pocketclaw/app/pocketclaw_app/lib/src/app_shell/connect_surface.dart, .github/workflows/flutter-ci.yml

---

## [ERR-20260321-004] shell-printf-leading-dash

**Logged**: 2026-03-21T05:41:30Z
**Priority**: low
**Status**: pending
**Area**: infra

### Summary
A shell probe command failed because `printf` received a format string beginning with `--`, which bash treated as an invalid option in this environment.

### Error
```text
/usr/bin/bash: line 1: printf: --: invalid option
printf: usage: printf [-v var] format [arguments]
```

### Context
- Command attempted from `/root/.openclaw/workspace`
- Verification step for the PocketClaw Star History link
- Used `printf '--- star history image HEAD ---\n'` inside a shell pipeline

### Suggested Fix
Prefer `printf '%s\n' '--- label ---'` or `echo` when printing separator lines that begin with dashes.

### Metadata
- Reproducible: yes
- Related Files: .learnings/ERRORS.md

---

## [ERR-20260321-005] ripgrep-not-installed

**Logged**: 2026-03-21T11:28:00Z
**Priority**: low
**Status**: pending
**Area**: infra

### Summary
A source-search probe assumed `rg` was available, but this workspace image does not include ripgrep.

### Error
```text
/usr/bin/bash: line 1: rg: command not found
```

### Context
- Command attempted from `/root/.openclaw/workspace`
- Probe used while scanning PocketClaw TODOs and next steps
- Fallback tools available: `grep`, `find`, and `git grep`

### Suggested Fix
Prefer `git grep` or guarded `command -v rg >/dev/null || ...` fallbacks when searching this host.

### Metadata
- Reproducible: yes
- Related Files: .learnings/ERRORS.md, TOOLS.md

---
