<div align="center">

# PocketClaw Workspace

**Flutter/Dart workspace for the PocketClaw mobile client.**

*If you are looking for the project overview, repository docs, contribution guide, or support entry points, start from the repository root instead.*

[Repo Overview](../README.md) · [简体中文](./README.zh-CN.md) · [Local Setup](./docs/local-setup.md) · [CI / CD](./docs/ci-cd.md) · [Architecture](./docs/architecture.md)

![Status](https://img.shields.io/badge/status-active%20prototype-7c3aed)
![Workspace](https://img.shields.io/badge/workspace-Flutter%20%2B%20Dart-02569B?logo=flutter&logoColor=white)
![Monorepo](https://img.shields.io/badge/managed%20with-Melos-4B32C3)

</div>

## What this README is for

This README is the **implementation-facing guide** for the code under `pocketclaw/`.

Use the **root README** for:

- project positioning
- repository-facing docs
- contribution and support entry points
- public collaboration guidance

Use this README for:

- local workspace setup
- package and app layout
- implementation-oriented docs
- Flutter/Dart validation commands

## Workspace quick start

```bash
cd pocketclaw
flutter pub get
~/.pub-cache/bin/melos run analyze
~/.pub-cache/bin/melos run test
```

If Flutter/Dart tooling is unavailable locally, rely on the repository GitHub Actions baseline documented in [`../docs/ci-cd.md`](../docs/ci-cd.md).

## Workspace layout

- `app/pocketclaw_app/` — Flutter application shell and app-facing UI code
- `packages/gateway_transport/` — Gateway transport primitives
- `packages/gateway_adapter/` — compatibility adapter around the current OpenClaw Gateway surface
- `packages/pocketclaw_core/` — shared domain logic and session-related primitives
- `docs/` — implementation-facing notes for setup, CI/CD, stack choices, and next steps
- `melos.yaml` — workspace scripts and package orchestration
- `pubspec.yaml` — Dart workspace definition

## Common workspace commands

```bash
cd pocketclaw
flutter pub get
~/.pub-cache/bin/melos run analyze
~/.pub-cache/bin/melos run test
```

Useful direct paths:

- app entry: `app/pocketclaw_app/lib/main.dart`
- app tests: `app/pocketclaw_app/test/`
- package tests: `packages/*/test/`

## Workspace documents

- [`docs/local-setup.md`](./docs/local-setup.md) — local development notes
- [`docs/ci-cd.md`](./docs/ci-cd.md) — workspace-facing CI/CD details
- [`docs/tech-stack.md`](./docs/tech-stack.md) — implementation stack choices
- [`docs/next-steps.md`](./docs/next-steps.md) — active implementation follow-ups
- [`docs/repo-plan.md`](./docs/repo-plan.md) — repo/workspace organization notes
- [`docs/architecture.md`](./docs/architecture.md) — client layering and module direction
- [`docs/roadmap.md`](./docs/roadmap.md) — roadmap context mirrored in the workspace

## Scope reminder

This workspace follows the same core project boundaries as the root repository:

- mobile-first OpenClaw client
- compatibility with today’s Gateway surface
- no custom backend by default
- small, reviewable changes over broad rewrites
