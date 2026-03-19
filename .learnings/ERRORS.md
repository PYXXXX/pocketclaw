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
