# Documentation Map

This folder is the **repository-facing documentation surface** for PocketClaw.
It should stay small, current, and useful to someone landing on the repo for the first time.

## What belongs here

Use root `docs/` for documents that explain:

- project direction
- architecture boundaries
- compatibility promises
- MVP scope
- contributor-facing planning context

## What does not belong here

Avoid turning root `docs/` into a general notebook dump.
Ad-hoc deployment notes, one-off experiments, and local operator records should live outside the public product docs surface unless they are directly useful to PocketClaw contributors.

## Public docs index

| Document | Purpose |
| --- | --- |
| [`architecture.md`](./architecture.md) | client layering and module direction |
| [`roadmap.md`](./roadmap.md) | near-term and medium-term direction |
| [`mvp-scope.md`](./mvp-scope.md) | current chat MVP boundary |
| [`compatibility.md`](./compatibility.md) | current compatibility constraints with OpenClaw Gateway |
| [`session-key-strategy.md`](./session-key-strategy.md) | multi-session approach via client-controlled keys |
| [`gateway-surface-map.md`](./gateway-surface-map.md) | Gateway methods and assumptions currently wrapped by the client |
| [`connect-flow-plan.md`](./connect-flow-plan.md) | mobile connection and pairing UX planning |
| [`development-workflow.md`](./development-workflow.md) | development principles for the repo |
| [`official-android-reference.md`](./official-android-reference.md) | reference notes from the official Android surface |
| [`zh-CN/`](./zh-CN/) | selected Simplified Chinese companion docs |

## About `pocketclaw/docs/`

The actual Flutter/Dart workspace lives in [`../pocketclaw/`](../pocketclaw/).
Its `pocketclaw/docs/` folder can contain more implementation-facing notes such as local setup, CI/CD details, and next-step planning.

A practical rule of thumb:

- **root `docs/`** = public repository explanation
- **`pocketclaw/docs/`** = workspace implementation notes
