# CI / CD

This document explains **what the repository currently validates on GitHub Actions** and how contributors should read those signals.

For workspace-internal notes, see [`../pocketclaw/docs/ci-cd.md`](../pocketclaw/docs/ci-cd.md).

## Current stance

PocketClaw treats **GitHub Actions as the primary validation environment**.

This is intentional:

- some contributors will not have a full local Flutter/Dart toolchain
- the actual app workspace lives under `pocketclaw/`
- Android build output is currently the most practical downloadable artifact for early testing

## Current workflows

### `flutter-ci.yml`

Runs on:

- pushes to `main`
- pull requests

Current responsibilities:

- install Flutter, Dart, and Java on the runner
- bootstrap dependencies from `pocketclaw/`
- check Dart formatting for `app/` and `packages/`
- run static analysis through Melos
- run test suites through Melos
- generate Android release APKs for testers
- upload split-per-ABI APK artifacts

In practice, this workflow is the main answer to: **“Does this change still validate in the expected Flutter environment?”**

### `release-android.yml`

Runs on:

- version tags matching `v*`
- manual `workflow_dispatch`

Current responsibilities:

- prepare the Android app scaffold
- build split Android release APKs
- publish them as GitHub release assets

## What CI currently checks well

Today, contributors can reasonably expect GitHub Actions to cover:

- repository-integrated Flutter/Dart setup
- formatting drift in the main workspace
- static analysis across the workspace packages
- unit and package-level tests that are already present
- Android tester artifact generation

## What CI does **not** claim yet

The workflows should not be read as proof of all of the following:

- iOS release readiness
- end-to-end device behavior on real phones
- production signing or store-distribution readiness
- broad product completeness beyond the current MVP direction

## Contributor guidance

If you do have a local toolchain, common checks are:

```bash
cd pocketclaw
flutter pub get
~/.pub-cache/bin/melos run analyze
~/.pub-cache/bin/melos run test
```

If you do **not** have Flutter/Dart locally, keep the change focused and let GitHub Actions provide the baseline validation signal.

## Practical reading of failures

A failed workflow usually means one of these things:

- formatting drift
- analyzer breakage
- test regression
- build assumptions that no longer match the current workspace layout

When touching repo structure, README/docs wording, or workflow behavior, prefer updating the relevant documentation in the same pull request.
