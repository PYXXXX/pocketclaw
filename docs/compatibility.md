# Compatibility

## Compatibility target

PocketClaw targets the currently available OpenClaw Gateway surface.

It does not rely on:

- new Gateway endpoints
- Gateway-side patches
- storage-level hacks
- unofficial archive restore behavior

## Current integration assumptions

PocketClaw expects the Gateway to already support the behaviors used by current Control UI / WebChat flows, including:

- WebSocket `connect` handshake
- chat operations scoped by `sessionKey`
- chat and agent event streams
- session listing and patching
- model listing
- agent identity lookup

## Compatibility strategy

### Feature detection over hard assumptions

The client should prefer runtime capability checks and tolerant parsing over brittle field assumptions.

### Adapter isolation

All raw Gateway payload handling should be isolated inside a compatibility adapter layer.

### Regression checklist

At minimum, each tested Gateway version should be verified against:

- connection and auth
- pairing
- `chat.history`
- `chat.send`
- `chat.abort`
- chat delta/final/error handling
- tool event handling
- `sessions.list`
- `sessions.patch`
- `models.list`
- `agent.identity.get`

## Planned version policy

The repository should maintain a simple tested-version matrix once implementation begins.

Example structure:

| Gateway Version | Status | Notes |
| --- | --- | --- |
| x.y.z | tested | baseline |
| x.y.z+1 | tested | no adapter changes |
| x.y.z+2 | partial | event parsing changed |

---

## 中文摘要

PocketClaw 的兼容策略是：

- 只兼容现有 Gateway 能力
- 不依赖新增接口
- 通过适配层隔离 Gateway payload 变化
- 用回归清单而不是“想当然”来做版本兼容
