# Contributing to PocketClaw

Thanks for helping improve PocketClaw.

PocketClaw is a **mobile-first OpenClaw client** with a deliberately narrow scope:

- native phone experience first
- compatibility with the current OpenClaw Gateway
- no custom backend
- small, reviewable changes over broad rewrites

This guide keeps contributions aligned with the repository’s current direction.

## Before you open a PR

Please first check:

- [`README.md`](./README.md) for the project overview
- [`SUPPORT.md`](./SUPPORT.md) for help paths and issue routing
- [`docs/architecture.md`](./docs/architecture.md) for layering and boundaries
- [`docs/compatibility.md`](./docs/compatibility.md) for hard constraints
- [`docs/mvp-scope.md`](./docs/mvp-scope.md) for current product scope
- [`docs/roadmap.md`](./docs/roadmap.md) for near-term direction
- [`docs/ci-cd.md`](./docs/ci-cd.md) for current validation and release expectations

If your change conflicts with those documents, update the docs as part of the same PR or explain why the existing docs should change.

For security-sensitive issues or disclosures, follow [`SECURITY.md`](./SECURITY.md) instead of posting raw secrets or private environment details in a PR.

## What kinds of contributions fit best

High-value contributions usually improve one of these areas:

- mobile UX clarity
- Gateway compatibility and robustness
- connect/auth/pairing flows
- chat timeline behavior and rendering
- repository documentation and contributor experience
- tests, analysis, and CI reliability

## What to avoid

Please avoid using this repository for:

- speculative backend features
- Gateway-side protocol inventions
- large architecture rewrites without a clear need
- broad cosmetic churn with no maintenance benefit
- repo-wide renames or moves unrelated to the current MVP

## Repository layout

The repository has two important layers:

### Repository root

Contains the public repository surface:

- `README.md` / `README.zh-CN.md`
- `docs/`
- `.github/`
- `assets/`

### `pocketclaw/`

Contains the actual Flutter/Dart workspace:

- `app/pocketclaw_app/` — Flutter application
- `packages/gateway_transport/` — transport primitives
- `packages/gateway_adapter/` — Gateway compatibility adapter
- `packages/pocketclaw_core/` — shared domain logic

## Local development

PocketClaw uses a Flutter/Dart workspace inside `pocketclaw/`.

Typical commands:

```bash
cd pocketclaw
flutter pub get
~/.pub-cache/bin/melos run analyze
~/.pub-cache/bin/melos run test
```

If Flutter tooling is unavailable locally, prefer opening a focused PR and using GitHub Actions as the validation baseline.

## Documentation expectations

Docs are part of the product surface.

When changing behavior or project direction, update the relevant docs in the same PR, especially when touching:

- architecture boundaries
- compatibility assumptions
- MVP scope
- setup or workflow instructions

Prefer small, accurate updates over large “future vision” rewrites.

## Pull request checklist

A good PR for PocketClaw usually:

- has a clear, narrow goal
- matches the current project scope
- avoids unrelated cleanup
- updates docs when behavior or assumptions changed
- includes tests when practical
- keeps naming and wording consistent with existing repo language

## Commit style

Conventional-style prefixes are welcome when they help, for example:

- `docs(pocketclaw): ...`
- `fix(pocketclaw): ...`
- `feat(pocketclaw): ...`
- `ci(pocketclaw): ...`
- `refactor(pocketclaw): ...`

This is a preference, not a hard rule.

## Need to discuss first?

If a change is likely to affect project direction, repository structure, or compatibility promises, open an issue or draft PR before implementing the full change.

## Conduct

Please keep collaboration respectful, specific, and scoped.
See [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md).
