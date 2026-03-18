# Architecture

## Objective

PocketClaw is a native client for existing OpenClaw Gateway deployments.
The architecture is intentionally client-centric and compatibility-driven.

## Constraints

- no Gateway changes
- no custom backend
- no dependency on undocumented storage mutations
- no assumption that upstream mobile APIs will be added

## High-level layers

### 1. Gateway transport layer

Responsibilities:

- WebSocket connection lifecycle
- challenge / connect handshake
- request / response framing
- event subscription and dispatch
- reconnect handling
- protocol error handling

### 2. Authentication and device identity layer

Responsibilities:

- token / password bootstrap
- device identity generation and persistence
- challenge signing
- device token storage
- pairing flow handling

### 3. Gateway compatibility adapter

Responsibilities:

- isolate PocketClaw from raw Gateway payload details
- wrap currently used methods such as `chat.*`, `sessions.*`, `models.list`, and `agent.identity.get`
- provide a stable internal interface for the app even if Gateway payloads evolve

### 4. Domain state layer

Responsibilities:

- session state
- streaming message assembly
- tool call stream state
- fallback / compaction state
- draft and local metadata handling

### 5. Presentation layer

Responsibilities:

- phone-first UI
- compact layouts for narrow or high-DPI devices
- future watch-friendly interaction boundaries

## Session model

PocketClaw uses client-controlled `sessionKey` values to create and switch conversations.
This avoids dependence on Gateway-side session creation changes.

## Device classes

### Phone

Primary target.

### Compact small-screen devices

Supported through adaptive layout and density-aware rendering.

### Wearables

Not a launch target, but architecture should keep core logic reusable for future watch-specific clients such as `WristClaw`.

## Suggested module direction

```text
app/
  mobile_ui/
packages/
  gateway_transport/
  gateway_auth/
  gateway_adapter/
  pocketclaw_core/
```

## Engineering style

The project is intentionally developed as a fully vibe-coded codebase:

- fast iteration
- AI-first scaffolding and refinement
- strong emphasis on visible feedback loops
- compatibility checks over speculative abstraction
