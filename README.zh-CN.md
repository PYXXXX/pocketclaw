# PocketClaw

[English](./README.md) | [简体中文](./README.zh-CN.md)

PocketClaw 是一个面向现有 OpenClaw Gateway 部署的原生移动客户端。

项目围绕一个硬约束设计：**兼容当前已经存在的 Gateway**。
项目**不依赖** Gateway 改动、私有补丁或新增服务端 API。

## 当前状态

早期脚手架阶段。

## 核心原则

- **Gateway-compatible first** —— 以兼容现有 OpenClaw Gateway 行为为第一优先级。
- **No custom backend** —— 不新增中间后端，直接连接 Gateway 现有能力。
- **Mobile-first** —— 先把手机端体验做好，再扩展到更多控制能力。
- **本地凭据加密** —— 连接配置与设备侧认证材料优先放进系统提供的安全存储。
- **通过客户端控制 sessionKey 实现多会话** —— 不改变 Gateway 语义。
- **可扩展到穿戴设备** —— 为未来 `WristClaw` 之类的手表客户端保留架构空间。
- **Fully vibe coded** —— 项目明确采用 AI-first、快速迭代的开发方式。

## 项目范围

PocketClaw 会先从聊天优先、控制面适度的移动客户端做起。

当前优先事项：

1. 连接、鉴权与 pairing
2. 聊天历史和消息发送
3. 流式回复展示
4. Tool call 渲染
5. 会话切换与客户端创建新会话
6. 图片发送
7. 基础 session override（`model`、`thinking`、`fast`、`verbose`）

## 当前非目标

在当前阶段，PocketClaw 不假设以下能力：

- Gateway 侧新功能开发
- 私有存储层 hack
- archive restore API
- 通过 WebView 套壳来实现产品

## 仓库结构

- `docs/` —— 产品、架构、兼容性与规划文档
- `app/` —— 未来移动端应用代码
- `packages/` —— 未来可复用的协议、状态和适配层模块

## 关键文档

- [`docs/architecture.md`](./docs/architecture.md)
- [`docs/mvp-scope.md`](./docs/mvp-scope.md)
- [`docs/compatibility.md`](./docs/compatibility.md)
- [`docs/session-key-strategy.md`](./docs/session-key-strategy.md)
- [`docs/gateway-surface-map.md`](./docs/gateway-surface-map.md)
- [`docs/development-workflow.md`](./docs/development-workflow.md)
- [`docs/official-android-reference.md`](./docs/official-android-reference.md)
- [`docs/connect-flow-plan.md`](./docs/connect-flow-plan.md)

## 语言策略

仓库内容以英文为主。
在有帮助的情况下，可同时提供中文版本。
