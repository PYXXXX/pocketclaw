# CI / CD

## Strategy

PocketClaw prefers GitHub Actions as the primary validation and release environment.

This is intentional:

- local development hosts may not have enough resources for a full Flutter toolchain
- the repository should not depend on every contributor having identical local mobile build environments
- CI should become the consistent source of truth for analysis, tests, and release artifacts

## Validation goals

CI should eventually cover:

- workspace bootstrap
- static analysis
- unit tests
- app-level smoke builds

## Current release direction

Initial release automation is Android-first.

Why:

- Android release artifacts are practical to generate on GitHub-hosted runners
- iOS release automation requires additional signing and provisioning flows
- Android is the shortest path to a usable downloadable artifact for early testing

## Planned workflows

### `flutter-ci.yml`

Runs on pushes and pull requests.

Target responsibilities:

- install Flutter
- bootstrap the monorepo
- run analysis
- run tests where present
- build installable Android tester artifacts on CI

Tester artifacts should prefer release builds over debug builds so file size and runtime behavior are closer to what a phone user will actually install.
Where practical, Android APK outputs should use `--split-per-abi` to keep download size reasonable.

### `release-android.yml`

Runs on:

- version tags like `v0.1.0`
- manual `workflow_dispatch`

Target responsibilities:

- prepare the Flutter app scaffold
- build a release APK
- publish the APK as a GitHub release asset

## Notes

- Release automation should stay conservative until the app structure stabilizes.
- iOS release automation can be added later when signing requirements are explicitly defined.
