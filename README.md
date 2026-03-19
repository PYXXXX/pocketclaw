# PocketClaw

[English](./README.md) | [简体中文](./README.zh-CN.md)

> A native mobile client for OpenClaw Gateway deployments — built to work with the Gateway as it exists today.

PocketClaw is a phone-first OpenClaw client focused on chat, session control, and lightweight mobile operations.
It is built around one hard constraint: **no Gateway modifications, no private patches, and no custom backend**.

## Why PocketClaw

OpenClaw already has a capable Gateway, but the existing surfaces are not designed first for a native mobile experience.
PocketClaw exists to close that gap without changing server-side behavior.

It aims to feel like a real mobile client, not a browser wrapper and not a separate backend product.

## Status

**Active prototype.**

Architecture and compatibility direction are in place.
The current focus is the **chat MVP**:

- connection, authentication, and pairing
- chat history and sending
- streaming assistant output
- tool call rendering
- session switching and client-created sessions
- image sending
- basic session overrides (`model`, `thinking`, `fast`, `verbose`)

## Core principles

- **Gateway-compatible first** — work with current OpenClaw Gateway behavior.
- **No custom backend** — connect directly to the Gateway transport surface.
- **Mobile-first** — optimize for phone use before expanding into broader control surfaces.
- **Encrypted local credentials** — keep connection profiles and device-issued auth material in OS-backed secure storage.
- **Multi-session by client-controlled session keys** — create and switch sessions without changing Gateway semantics.
- **Wearable-aware** — keep architecture adaptable for future watch-focused clients such as `WristClaw`.
- **Fully vibe coded** — intentionally built with an AI-first, rapid-iteration workflow.

## What PocketClaw is not

For the current phase, PocketClaw does **not** assume:

- Gateway-side feature development
- private storage hacks
- archive restore APIs
- a WebView-first product strategy

## Architecture direction

PocketClaw keeps protocol, state, and UI concerns separate so the client can evolve without turning into Gateway-specific UI glue.

Suggested module direction:

```text
app/
  mobile_ui/
packages/
  gateway_transport/
  gateway_auth/
  gateway_adapter/
  pocketclaw_core/
```

Read more in [`docs/architecture.md`](./docs/architecture.md).

## Repository layout

- `docs/` — product, architecture, compatibility, and planning documents
- `app/` — mobile application code
- `packages/` — reusable protocol, state, and adapter modules

## Key documents

- [`docs/architecture.md`](./docs/architecture.md)
- [`docs/mvp-scope.md`](./docs/mvp-scope.md)
- [`docs/compatibility.md`](./docs/compatibility.md)
- [`docs/session-key-strategy.md`](./docs/session-key-strategy.md)
- [`docs/gateway-surface-map.md`](./docs/gateway-surface-map.md)
- [`docs/development-workflow.md`](./docs/development-workflow.md)
- [`docs/official-android-reference.md`](./docs/official-android-reference.md)
- [`docs/connect-flow-plan.md`](./docs/connect-flow-plan.md)
- [`docs/roadmap.md`](./docs/roadmap.md)

## Language policy

English is the primary language for repository content.
Chinese versions may be added alongside English where useful.
