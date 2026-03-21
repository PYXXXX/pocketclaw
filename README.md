<div align="center">

# PocketClaw

<img src="./assets/pocketclaw-logo.svg" alt="PocketClaw logo" width="120" />

**Connect to your OpenClaw lobster 🦞 from your phone.**

*A Flutter-built, mobile-first client for existing OpenClaw Gateway deployments — pure frontend, with no extra backend dependencies.*

[English](./README.md) · [简体中文](./README.zh-CN.md) · [Docs](./docs/README.md) · [Architecture](./docs/architecture.md) · [Roadmap](./docs/roadmap.md) · [Contributing](./CONTRIBUTING.md) · [Support](./SUPPORT.md)

![PocketClaw banner](./assets/pocketclaw-banner.svg)

![Status](https://img.shields.io/badge/status-active%20prototype-7c3aed)
![Frontend](https://img.shields.io/badge/architecture-pure%20frontend-0f766e)
![Stack](https://img.shields.io/badge/built%20with-Flutter-02569B?logo=flutter&logoColor=white)
![Gateway](https://img.shields.io/badge/OpenClaw-compatible-black)

</div>

## At a glance

- **Phone-native on purpose** — built for a real mobile experience, not a browser wrapper.
- **Compatible with today’s Gateway** — no Gateway modifications, no private patches.
- **Pure frontend** — no custom backend, no extra service layer.
- **Chat MVP first** — focused on connect, chat, streaming, tools, and session switching.
- **Structured to grow carefully** — the core can later extend toward compact and wearable surfaces.

## Preview direction

PocketClaw is being shaped as a **clean, compact, phone-native OpenClaw client**.
The intended UX direction is:

- fast connect flow
- readable streaming chat
- lightweight tool event rendering
- quick session switching
- compact controls that still feel native on small screens

![PocketClaw UI mockup](./assets/pocketclaw-ui-mockup.svg)

> UI preview assets are evolving as the app surface stabilizes.

## Why PocketClaw exists

OpenClaw already has a capable Gateway, but the existing surfaces are not designed first for a native mobile experience.
PocketClaw exists to make OpenClaw feel natural on a phone **without changing server-side behavior**.

The idea is deliberately simple:

- keep the deployment model unchanged
- keep the client truly mobile-native
- keep the architecture clean enough to scale beyond a one-off app shell

## Current status

> **Active prototype** — the architecture direction is set, and the current work is about making the mobile chat surface practical.

Current Chat MVP focus:

- connection, authentication, and pairing
- chat history and sending
- streaming assistant output
- tool call rendering
- session switching and client-created sessions
- image sending
- basic session overrides (`model`, `thinking`, `fast`, `verbose`)

## Design principles

- **Compatibility first** — work with current OpenClaw Gateway behavior rather than inventing new server assumptions.
- **No custom backend** — connect directly to the Gateway transport surface.
- **Mobile-first** — optimize for phones before expanding into broader control surfaces.
- **Secure local credentials** — keep profiles and device auth material in OS-backed secure storage.
- **Client-controlled sessions** — support multiple conversations without changing Gateway semantics.
- **Move fast, stay disciplined** — keep iteration quick without letting compatibility boundaries drift.

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

## Project map

If you only need the main entry points, start here:

- [`docs/README.md`](./docs/README.md) — full documentation map
- [`CHANGELOG.md`](./CHANGELOG.md) — curated summary of notable repository-facing changes
- [`pocketclaw/README.md`](./pocketclaw/README.md) — workspace guide for local development and implementation notes

Core product and repository docs:

- [`docs/architecture.md`](./docs/architecture.md) · [中文](./docs/zh-CN/architecture.md)
- [`docs/roadmap.md`](./docs/roadmap.md) · [中文](./docs/zh-CN/roadmap.md)
- [`docs/mvp-scope.md`](./docs/mvp-scope.md)
- [`docs/compatibility.md`](./docs/compatibility.md)

Implementation and contributor context:

- [`docs/session-key-strategy.md`](./docs/session-key-strategy.md)
- [`docs/gateway-surface-map.md`](./docs/gateway-surface-map.md)
- [`docs/connect-flow-plan.md`](./docs/connect-flow-plan.md)
- [`docs/development-workflow.md`](./docs/development-workflow.md)
- [`docs/ci-cd.md`](./docs/ci-cd.md)
- [`docs/official-android-reference.md`](./docs/official-android-reference.md)

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

## What PocketClaw is not

For the current phase, PocketClaw does **not** assume:

- Gateway-side feature development
- private storage hacks
- archive restore APIs
- a WebView-first product strategy

## Community

[![GitHub Repo stars](https://img.shields.io/github/stars/PYXXXX/pocketclaw?style=social)](https://github.com/PYXXXX/pocketclaw/stargazers)

See the full timeline on [Star History](https://www.star-history.com/#PYXXXX/pocketclaw&Date).

## Repository layout

- `assets/` — repository banner, UI mockups, and social preview artwork
- `docs/` — repository-facing product, architecture, compatibility, and planning documents
- `pocketclaw/` — the actual Flutter/Dart workspace for the project
  - [`pocketclaw/README.md`](./pocketclaw/README.md) — workspace guide for local development and implementation-facing docs
  - `pocketclaw/app/` — mobile application code
  - `pocketclaw/packages/` — reusable transport, adapter, and core modules

## Language policy

English is the primary language for repository content.
Chinese versions may be added alongside English where useful.
