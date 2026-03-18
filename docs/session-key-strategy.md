# Session Key 策略（草案）

PocketClaw 不依赖 Gateway 新增会话接口，当前采用“客户端控制 sessionKey”的方式实现多会话。

## 基本原则

- 复用现有 Gateway 的 `sessionKey` 语义
- 新建会话时生成新的自定义 key
- 不影响已有会话
- 不依赖 `/new` / `/reset` 才能获得多会话体验

## 推荐格式

```text
agent:<agentId>:<clientKey>
```

例如：

- `agent:main:pc-home`
- `agent:main:pc-20260318-a1b2`
- `agent:gowithclaw:pc-test`

## 避免使用

避免直接占用这些已有语义：

- `main`
- `global`
- `cron:*`
- `subagent:*`

## 客户端本地状态

建议客户端本地维护：

- `currentSessionKey`
- `recentSessionKeys`
- `pinnedSessionKeys`
- `draftBySessionKey`
- `displayTitleBySessionKey`

其中标题建议只保存在客户端本地，不直接写进 `sessionKey`。
