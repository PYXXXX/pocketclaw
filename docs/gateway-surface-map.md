# Gateway Surface Map

This document records the current Gateway surface that PocketClaw intends to use.

The purpose is practical compatibility, not protocol redesign.

## Transport

### Primary transport

- Gateway WebSocket
- request / response / event framing
- `connect.challenge` followed by `connect`

### Supporting HTTP endpoints currently worth knowing

- `GET /__openclaw/control-ui-config.json`
- `GET /avatar/<agentId>?meta=1`

PocketClaw should treat HTTP helpers as optional and avoid hard-coupling when equivalent Gateway RPC calls exist.

## Core RPC methods

### Chat

- `chat.history`
- `chat.send`
- `chat.abort`
- `chat.inject` (documented, not required for MVP)

### Sessions

- `sessions.list`
- `sessions.patch`
- `sessions.reset`
- `sessions.delete`
- `sessions.compact`
- `sessions.usage`
- `sessions.usage.timeseries`
- `sessions.usage.logs`

### Agent / model identity

- `agents.list`
- `agent.identity.get`
- `models.list`
- `tools.catalog`

### Cron / device / node / diagnostics

These are not all MVP-critical, but are part of the currently available control surface:

- `cron.status`
- `cron.list`
- `cron.add`
- `cron.update`
- `cron.run`
- `cron.remove`
- `cron.runs`
- `node.list`
- `device.pair.list`
- `device.pair.approve`
- `device.pair.reject`
- `device.token.rotate`
- `device.token.revoke`
- `status`
- `health`
- `logs.tail`

## Event streams

### Chat events

PocketClaw should expect chat-related event states such as:

- `delta`
- `final`
- `aborted`
- `error`

### Agent events

PocketClaw should expect agent event traffic for:

- tool call lifecycle
- tool partial/result output
- fallback status
- compaction status

### Other operational events

The broader Gateway stream may also emit:

- `presence`
- `cron`
- `device.pair.requested`
- `device.pair.resolved`
- `exec.approval.requested`
- `exec.approval.resolved`
- `update.available`

## MVP dependency set

PocketClaw MVP should depend primarily on this smaller stable subset:

- WebSocket handshake
- `chat.history`
- `chat.send`
- `chat.abort`
- `sessions.list`
- `sessions.patch`
- `models.list`
- `agent.identity.get`
- chat events
- agent tool events

## Compatibility note

This map should be maintained as an implementation reference.
If Gateway behavior changes, update this file before widening the client contract.
