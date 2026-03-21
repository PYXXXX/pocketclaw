<div align="center">

# PocketClaw

<img src="./assets/pocketclaw-logo.svg" alt="PocketClaw logo" width="120" />

**用手机便捷连接您的 OpenClaw 龙虾 🦞**

*一个使用 Flutter 开发、以手机为优先的 OpenClaw 客户端 —— 纯前端实现，无须额外后端依赖。*

[English](./README.md) · [简体中文](./README.zh-CN.md) · [文档导航](./docs/zh-CN/README.md) · [架构文档](./docs/architecture.md) · [路线图](./docs/roadmap.md) · [参与贡献](./CONTRIBUTING.md) · [获取支持](./SUPPORT.zh-CN.md)

![PocketClaw banner](./assets/pocketclaw-banner.svg)

![状态](https://img.shields.io/badge/status-active%20prototype-7c3aed)
![架构](https://img.shields.io/badge/architecture-pure%20frontend-0f766e)
![技术栈](https://img.shields.io/badge/built%20with-Flutter-02569B?logo=flutter&logoColor=white)
![兼容性](https://img.shields.io/badge/OpenClaw-compatible-black)

</div>

## 一眼看懂

- **原生手机体验优先** —— 为真正的移动端使用而做，不是浏览器套壳。
- **兼容现有 Gateway** —— 不修改 Gateway，不依赖私有补丁。
- **纯前端实现** —— 不加 custom backend，不增加中间服务层。
- **先把 Chat MVP 做实** —— 当前重点是连接、聊天、流式输出、工具事件和会话切换。
- **为后续扩展留结构空间** —— 核心架构仍保留向紧凑设备和穿戴端扩展的可能性。

## 预览方向

PocketClaw 正在被打磨成一个 **干净、紧凑、适合手机使用的 OpenClaw 原生客户端**。
当前预期的体验方向是：

- 更快的连接流程
- 更易读的流式聊天体验
- 轻量但清晰的 tool event 展示
- 更顺手的会话切换
- 在小屏上依然自然的紧凑控制设计

![PocketClaw UI mockup](./assets/pocketclaw-ui-mockup.svg)

> UI 预览素材会随着应用界面逐步稳定而继续迭代。

## 为什么要做 PocketClaw

OpenClaw 已经有能力不错的 Gateway，但现有交互面并不是为原生移动体验优先设计的。
PocketClaw 的目标，是在**不改变服务端语义**的前提下，让 OpenClaw 在手机上用起来更自然。

这个项目想做的事情其实很克制：

- 保持现有部署模型不变
- 提供真正适合手机的原生体验
- 保持架构清晰，而不是做成一次性的 app 壳子

## 当前状态

> **Active prototype / 活跃原型阶段** —— 架构方向已经定下来，当前重点是把移动端聊天主界面做得真正可用。

当前 Chat MVP 主线包括：

- 连接、鉴权与 pairing
- 聊天历史和消息发送
- 流式回复展示
- Tool call 渲染
- 会话切换与客户端创建新会话
- 图片发送
- 基础 session override（`model`、`thinking`、`fast`、`verbose`）

## 设计原则

- **兼容性优先** —— 优先适配现有 OpenClaw Gateway 行为，而不是反过来发明新的服务端假设。
- **不引入 custom backend** —— 直接连接 Gateway 现有能力面。
- **Mobile-first** —— 先把手机端体验做好，再扩展到更多控制能力。
- **本地凭据安全存储** —— 连接配置与设备侧认证材料优先放进系统提供的安全存储。
- **客户端控制会话** —— 在不改变 Gateway 语义的前提下支持多会话。
- **快，但不失控** —— 保持迭代速度，同时守住兼容性边界。

## FAQ

### 为什么不直接套 Web UI？

因为 PocketClaw 想做的是一个真正适合手机的客户端。
套壳当然也能工作，但它无法替代为手机场景专门设计的导航、流式展示、会话切换和紧凑交互。

### 为什么不加一个自定义后端？

因为这个项目的核心承诺之一，就是严格围绕今天已有的 OpenClaw Gateway 能力来构建。
额外加后端会增加部署复杂度，也会削弱这个项目最重要的兼容性立场。

### 为什么选 Flutter？

Flutter 很适合做跨平台但仍然精致的移动 UI，同时能保持应用架构清晰、迭代速度快。

### 这是要替代 OpenClaw WebChat 吗？

不是。
PocketClaw 更像一个面向移动端的 companion surface，而不是说所有 OpenClaw 交互都应该搬到手机上。

## 项目地图

如果你只想先抓住几个主要入口，建议从这里开始：

- [`docs/zh-CN/README.md`](./docs/zh-CN/README.md) —— 完整文档导航
- [`CHANGELOG.md`](./CHANGELOG.md) —— 重要仓库维护改动汇总
- [`pocketclaw/README.md`](./pocketclaw/README.md) —— 本地开发与实现层说明入口

核心产品与仓库文档：

- [`docs/architecture.md`](./docs/architecture.md) · [中文](./docs/zh-CN/architecture.md)
- [`docs/roadmap.md`](./docs/roadmap.md) · [中文](./docs/zh-CN/roadmap.md)
- [`docs/mvp-scope.md`](./docs/mvp-scope.md)
- [`docs/compatibility.md`](./docs/compatibility.md)

实现与协作上下文：

- [`docs/session-key-strategy.md`](./docs/session-key-strategy.md)
- [`docs/gateway-surface-map.md`](./docs/gateway-surface-map.md)
- [`docs/connect-flow-plan.md`](./docs/connect-flow-plan.md)
- [`docs/development-workflow.md`](./docs/development-workflow.md)
- [`docs/zh-CN/ci-cd.md`](./docs/zh-CN/ci-cd.md)
- [`docs/official-android-reference.md`](./docs/official-android-reference.md)

## 架构方向

PocketClaw 会继续把 **协议层**、**状态层**、**UI 层** 拆开，避免客户端逐渐变成和 Gateway payload 强耦合的界面胶水。

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

## PocketClaw 当前不做什么

在当前阶段，PocketClaw **不假设** 以下能力：

- Gateway 侧新功能开发
- 私有存储层 hack
- archive restore API
- 通过 WebView 套壳来实现产品

## 社区关注

[![GitHub Repo stars](https://img.shields.io/github/stars/PYXXXX/pocketclaw?style=social)](https://github.com/PYXXXX/pocketclaw/stargazers)

完整趋势可在 [Star History](https://www.star-history.com/#PYXXXX/pocketclaw&Date) 查看。

## 仓库结构

- `assets/` —— 仓库 banner、UI mockup 与社交分享图素材
- `docs/` —— 面向仓库门面的产品、架构、兼容性与规划文档
- `pocketclaw/` —— 项目实际的 Flutter/Dart 工作区
  - [`pocketclaw/README.md`](./pocketclaw/README.md) —— 本地开发与实现层文档入口
  - `pocketclaw/app/` —— 移动端应用代码
  - `pocketclaw/packages/` —— 可复用的传输、适配与核心模块

## 语言策略

仓库内容以英文为主。
在有帮助的情况下，可同时提供中文版本。
