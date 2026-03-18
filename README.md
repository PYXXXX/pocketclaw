# PocketClaw

[English](./README.md) | [简体中文](./README.zh-CN.md)

PocketClaw is a native mobile client for existing OpenClaw Gateway deployments.

It is designed around one hard constraint: **compatibility with the Gateway as it exists today**.
The project does **not** require Gateway modifications, private patches, or new server-side APIs.

## Status

Early scaffold.

## Principles

- **Gateway-compatible first** — work with current OpenClaw Gateway behavior.
- **No custom backend** — connect directly to the Gateway transport surface.
- **Mobile-first** — optimize for phone use before expanding into broader control surfaces.
- **Encrypted local credentials** — keep connection profiles and device-issued auth material in OS-backed secure storage.
- **Multi-session by client-controlled session keys** — create and switch sessions without changing Gateway semantics.
- **Wearable-aware** — keep architecture adaptable for future watch-focused clients such as `WristClaw`.
- **Fully vibe coded** — the project intentionally embraces an AI-first, rapid-iteration development workflow.

## Scope

PocketClaw starts as a chat-focused client with a pragmatic control surface.

Initial priorities:

1. Connection, authentication, and pairing
2. Chat history and sending
3. Streaming assistant output
4. Tool call rendering
5. Session switching and client-created sessions
6. Image sending
7. Basic session overrides (`model`, `thinking`, `fast`, `verbose`)

## Non-goals

For the current phase, PocketClaw does not assume:

- Gateway-side feature development
- Private Gateway storage hacks
- Archive restore APIs
- A browser wrapper / WebView-first product strategy

## Repository layout

- `docs/` — product, architecture, compatibility, and planning documents
- `app/` — future mobile application code
- `packages/` — future reusable protocol, state, and adapter modules

## Key documents

- [`docs/architecture.md`](./docs/architecture.md)
- [`docs/mvp-scope.md`](./docs/mvp-scope.md)
- [`docs/compatibility.md`](./docs/compatibility.md)
- [`docs/session-key-strategy.md`](./docs/session-key-strategy.md)
- [`docs/gateway-surface-map.md`](./docs/gateway-surface-map.md)
- [`docs/development-workflow.md`](./docs/development-workflow.md)
- [`docs/official-android-reference.md`](./docs/official-android-reference.md)
- [`docs/connect-flow-plan.md`](./docs/connect-flow-plan.md)

## Language policy

English is the primary language for repository content.
Chinese versions may be added alongside English where useful.
