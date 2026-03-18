# Session Key Strategy

PocketClaw implements multi-session behavior without requiring new Gateway APIs.

The client treats `sessionKey` as the core session identity and manages session creation and switching entirely on the client side.

## Goals

- support multiple concurrent conversations
- avoid interfering with an existing active session
- avoid reliance on `/new`, `/reset`, or archive restore semantics
- stay compatible with current Gateway routing behavior

## Core model

PocketClaw creates and switches sessions by selecting a different `sessionKey`.

Recommended format:

```text
agent:<agentId>:<clientKey>
```

Examples:

- `agent:main:pc-home`
- `agent:main:pc-20260318-a1b2`
- `agent:gowithclaw:pc-test`

## Reserved patterns to avoid

Client-generated keys should avoid names that already carry Gateway semantics:

- `main`
- `global`
- `cron:*`
- `subagent:*`

## Local client state

PocketClaw should maintain at least the following local state:

- `currentSessionKey`
- `recentSessionKeys`
- `pinnedSessionKeys`
- `draftBySessionKey`
- `displayTitleBySessionKey`

At minimum, the client should persist:

- the local session registry
- the currently selected session key
- client-side display titles

Display titles should remain client-side metadata rather than being encoded into the session key.

## Why this approach

This strategy provides a practical multi-session UX today because the current Gateway surface already supports session-scoped chat operations such as:

- `chat.history(sessionKey)`
- `chat.send(sessionKey)`
- `chat.abort(sessionKey)`

As a result, PocketClaw can create a new conversation by choosing a new `sessionKey`, without changing Gateway behavior.

---

## 中文摘要

PocketClaw 的多会话方案基于客户端直接控制 `sessionKey`，不依赖新增 Gateway 接口。

推荐格式：`agent:<agentId>:<clientKey>`。

核心目标：

- 不影响已有会话
- 不依赖 `/new`、`/reset` 或归档恢复
- 直接兼容现有 Gateway 行为
