<div align="center">

# PocketClaw

**Connect to your OpenClaw lobster 🦞 from your phone.**

*A Flutter-built, mobile-first client for existing OpenClaw Gateway deployments — pure frontend, with no extra backend dependencies.*

[English](./README.md) · [简体中文](./README.zh-CN.md) · [Architecture](./docs/architecture.md) · [Roadmap](./docs/roadmap.md)

![Status](https://img.shields.io/badge/status-active%20prototype-7c3aed)
![Frontend](https://img.shields.io/badge/architecture-pure%20frontend-0f766e)
![Stack](https://img.shields.io/badge/built%20with-Flutter-02569B?logo=flutter&logoColor=white)
![Gateway](https://img.shields.io/badge/OpenClaw-compatible-black)

</div>

## Highlights

- **Native mobile first** — built for a real phone experience, not a browser wrapper.
- **Works with today’s Gateway** — no Gateway modifications, no private patches.
- **Pure frontend** — no custom backend, no extra service layer.
- **Multi-session aware** — switch or create sessions with client-controlled `sessionKey` values.
- **Future-friendly** — the core architecture can later extend toward compact and wearable surfaces.

## Preview direction

PocketClaw is being shaped as a **clean, compact, phone-native OpenClaw client**.
The intended UX direction is:

- fast connect flow
- readable streaming chat
- lightweight tool event rendering
- quick session switching
- compact controls that still feel native on small screens

> UI preview assets are coming as the app surface stabilizes.

## Why PocketClaw exists

OpenClaw already has a capable Gateway, but the existing surfaces are not designed first for a native mobile experience.
PocketClaw exists to make OpenClaw feel natural on a phone **without changing server-side behavior**.

The idea is deliberately simple:

- keep the deployment model unchanged
- keep the client truly mobile-native
- keep the architecture clean enough to scale beyond a one-off app shell

## Current status

> **Active prototype** — architecture and compatibility boundaries are in place.

The current focus is the **chat MVP**:

- connection, authentication, and pairing
- chat history and sending
- streaming assistant output
- tool call rendering
- session switching and client-created sessions
- image sending
- basic session overrides (`model`, `thinking`, `fast`, `verbose`)

## Design principles

- **Gateway-compatible first** — work with current OpenClaw Gateway behavior.
- **No custom backend** — connect directly to the Gateway transport surface.
- **Mobile-first** — optimize for phones before expanding into broader control surfaces.
- **Encrypted local credentials** — keep profiles and device auth material in OS-backed secure storage.
- **Client-controlled multi-session** — support multiple conversations without changing Gateway semantics.
- **Wearable-aware** — keep the core reusable for future watch-focused clients such as `WristClaw`.
- **Vibe coded, but disciplined** — move fast, keep compatibility strict.

## What PocketClaw is not

For the current phase, PocketClaw does **not** assume:

- Gateway-side feature development
- private storage hacks
- archive restore APIs
- a WebView-first product strategy

## FAQ

### Why not just wrap the web UI?

Because PocketClaw is meant to feel like a real mobile client.
A wrapper can be useful, but it is not the same as designing navigation, streaming, session switching, and compact controls specifically for phones.

### Why no custom backend?

Because the project is intentionally built around today’s OpenClaw Gateway surface.
Adding a separate backend would make deployment heavier and weaken the project’s core compatibility promise.

### Why Flutter?

Flutter is a pragmatic fit for shipping a polished mobile UI across platforms while keeping the app architecture and iteration loop tight.

### Is this trying to replace OpenClaw WebChat?

No.
PocketClaw is a mobile-first companion surface, not a claim that every OpenClaw interaction should move to a phone app.

## Architecture direction

PocketClaw keeps **protocol**, **state**, and **UI** concerns separate so the app does not collapse into Gateway-specific payload glue.

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
