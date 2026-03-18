# Repository Plan

## Positioning

PocketClaw is a community-maintained native client for OpenClaw Gateway.

The repository focuses on client implementation only:

- direct Gateway connectivity
- no intermediate backend
- no Gateway modifications
- compatibility with current Gateway behavior

## Recommended repository settings

- **Name:** `pocketclaw`
- **Visibility:** public
- **Primary language:** English
- **Secondary language:** Chinese when helpful

## Initial document set

- `README.md`
- `docs/architecture.md`
- `docs/mvp-scope.md`
- `docs/compatibility.md`
- `docs/session-key-strategy.md`

## Recommended development phases

### Phase 1 — compatibility foundation

- document the current Gateway surface used by the client
- build the Gateway transport and auth adapter
- support connection, authentication, pairing, and reconnect behavior

### Phase 2 — chat MVP

- session selection
- client-created sessions via custom session keys
- chat history
- message sending
- streaming output
- tool call rendering
- image sending
- stop / abort

### Phase 3 — lightweight control surface

- sessions overview
- selected session controls
- minimal cron / nodes / logs surfaces where mobile value is clear

### Phase 4 — wearable follow-up

- assess watch-specific layouts and interaction patterns
- decide whether `WristClaw` should live in the same repository or a sibling repository

## Tone and writing style

Repository content should read from a neutral owner / maintainer perspective:

- objective
- implementation-oriented
- free of private chat context
- free of conversational references
- suitable for public open-source readers
