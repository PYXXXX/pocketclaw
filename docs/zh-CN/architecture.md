# 架构

## 目标

PocketClaw 是一个面向现有 OpenClaw Gateway 部署的原生客户端。
整体架构采用明确的客户端中心设计，并以兼容性为第一原则。

## 约束

- 不修改 Gateway
- 不新增 custom backend
- 不依赖未文档化的存储变更
- 不假设上游会额外提供移动端 API

## 高层分层

### 1. Gateway 传输层

职责：

- WebSocket 连接生命周期
- challenge / connect 握手
- request / response 封装
- 事件订阅与分发
- 重连处理
- 协议错误处理

### 2. 鉴权与设备身份层

职责：

- token / password 启动方式
- 基于系统安全存储的本地凭据保存
- 设备身份生成与持久化
- challenge 签名
- device token 存储
- pairing 流程处理

### 3. Gateway 兼容适配层

职责：

- 隔离原始 Gateway payload 细节
- 封装当前用到的方法，例如 `chat.*`、`sessions.*`、`models.list`、`agent.identity.get`
- 即使 Gateway payload 演化，也为应用层提供稳定接口

### 4. 领域状态层

职责：

- 会话状态
- 流式消息组装
- tool call 流状态
- fallback / compaction 状态
- draft 与本地元数据处理

### 5. 展示层

职责：

- 手机优先 UI
- 面向窄屏和高 DPI 设备的紧凑布局
- 为未来手表等穿戴端保留交互边界

## 会话模型

PocketClaw 通过客户端控制的 `sessionKey` 创建和切换会话。
这样可以避免依赖 Gateway 新增会话创建能力。

## 设备类型

### 手机

当前主目标。

### 紧凑小屏设备

通过自适应布局和密度感知渲染来支持。

### 穿戴设备

不是首发目标，但架构会保持核心逻辑可复用，以支持未来像 `WristClaw` 这样的手表客户端。

## 建议模块方向

```text
app/
  mobile_ui/
packages/
  gateway_transport/
  gateway_auth/
  gateway_adapter/
  pocketclaw_core/
```

## 工程风格

项目明确采用一种 fully vibe-coded 的开发方式：

- 快速迭代
- AI-first 脚手架与重构
- 强调可见反馈回路
- 优先做兼容性校验，而不是过度预抽象
