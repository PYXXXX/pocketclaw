# PocketClaw

[English](./README.md) | [简体中文](./README.zh-CN.md)

> 一个面向 OpenClaw Gateway 部署的原生移动客户端 —— 在**不改 Gateway**的前提下提供真正适合手机的使用体验。

PocketClaw 是一个以手机为优先的 OpenClaw 客户端，聚焦聊天、会话控制与轻量移动操作。
项目围绕一个硬约束设计：**不修改 Gateway、不依赖私有补丁、不新增自定义后端**。

## 为什么是 PocketClaw

OpenClaw 已经有能力不错的 Gateway，但现有交互面并不是为原生移动体验优先设计的。
PocketClaw 的目标，就是在**不改变服务端语义**的前提下，把这一块补上。

它想做的是一个真正的移动客户端，而不是浏览器套壳，也不是另起一套后端产品。

## 当前状态

**Active prototype / 活跃原型阶段。**

整体架构方向与兼容性边界已经明确，当前主线是完成 **Chat MVP**：

- 连接、鉴权与 pairing
- 聊天历史和消息发送
- 流式回复展示
- Tool call 渲染
- 会话切换与客户端创建新会话
- 图片发送
- 基础 session override（`model`、`thinking`、`fast`、`verbose`）

## 核心原则

- **Gateway-compatible first** —— 以兼容现有 OpenClaw Gateway 行为为第一优先级。
- **No custom backend** —— 不新增中间后端，直接连接 Gateway 现有能力。
- **Mobile-first** —— 先把手机端体验做好，再扩展到更多控制能力。
- **本地凭据加密** —— 连接配置与设备侧认证材料优先放进系统提供的安全存储。
- **通过客户端控制 sessionKey 实现多会话** —— 不改变 Gateway 语义。
- **可扩展到穿戴设备** —— 为未来 `WristClaw` 之类的手表客户端保留架构空间。
- **Fully vibe coded** —— 明确采用 AI-first、快速迭代的开发方式。

## PocketClaw 当前不做什么

在当前阶段，PocketClaw **不假设** 以下能力：

- Gateway 侧新功能开发
- 私有存储层 hack
- archive restore API
- 通过 WebView 套壳来实现产品

## 架构方向

PocketClaw 会继续把协议层、状态层、UI 层拆开，避免客户端逐渐变成和 Gateway payload 强耦合的界面胶水。

建议中的模块结构：

```text
app/
  mobile_ui/
packages/
  gateway_transport/
  gateway_auth/
  gateway_adapter/
  pocketclaw_core/
```

详情见 [`docs/architecture.md`](./docs/architecture.md)。

## 仓库结构

- `docs/` —— 产品、架构、兼容性与规划文档
- `app/` —— 移动端应用代码
- `packages/` —— 可复用的协议、状态和适配层模块

## 关键文档

- [`docs/architecture.md`](./docs/architecture.md)
- [`docs/mvp-scope.md`](./docs/mvp-scope.md)
- [`docs/compatibility.md`](./docs/compatibility.md)
- [`docs/session-key-strategy.md`](./docs/session-key-strategy.md)
- [`docs/gateway-surface-map.md`](./docs/gateway-surface-map.md)
- [`docs/development-workflow.md`](./docs/development-workflow.md)
- [`docs/official-android-reference.md`](./docs/official-android-reference.md)
- [`docs/connect-flow-plan.md`](./docs/connect-flow-plan.md)
- [`docs/roadmap.md`](./docs/roadmap.md)

## 语言策略

仓库内容以英文为主。
在有帮助的情况下，可同时提供中文版本。
