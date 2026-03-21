# 获取支持

如果你在 PocketClaw 上遇到问题，优先走**最轻、最直接**的路径。

## 1. 先看关键文档

大多数问题先看这些入口最快：

- [`README.zh-CN.md`](./README.zh-CN.md) —— 项目概览与当前定位
- [`docs/zh-CN/README.md`](./docs/zh-CN/README.md) —— 文档导航
- [`docs/compatibility.md`](./docs/compatibility.md) —— 与当前 OpenClaw Gateway 的兼容性边界
- [`docs/mvp-scope.md`](./docs/mvp-scope.md) —— 当前 MVP 在做什么 / 不做什么
- [`docs/zh-CN/ci-cd.md`](./docs/zh-CN/ci-cd.md) —— GitHub Actions 当前实际验证了什么
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) —— 如何提出适合本仓库的改动

## 2. 选择合适的 issue 类型

如果文档没有解决你的问题，请用最接近的模板提 issue：

- **Bug report** —— 用于可复现的 app、packages、docs 或 workflow 问题
- **Docs or repo maintenance** —— 用于 README 清晰度、文档过时、命名整理、仓库门面优化等问题
- **Feature proposal** —— 用于仍然符合 PocketClaw 当前范围的聚焦提案

## 3. 尽量带上这些上下文

一个高质量的求助或 issue，通常应包含：

- 你想做什么
- 你预期会发生什么
- 实际发生了什么
- 受影响的是哪一层（`docs/`、`.github/`、`pocketclaw/app/`、`pocketclaw/packages/` 等）
- 相关截图、日志、workflow 链接，或设备 / 工具链信息

## 范围提醒

PocketClaw 当前是一个**刻意保持克制**的项目。

默认不应把 support / issue 理解为一定要引入：

- 新 backend 服务
- 新的 Gateway 协议行为
- 大规模架构重写
- 脱离当前 mobile-first 客户端方向的产品路线

## 什么时候提 issue，什么时候提 PR

- 当你发现问题、不一致、或有一个想先讨论的小提案时，先开 **issue**
- 当你已经有一个小而明确、可以直接 review 的改动时，开 **pull request**

## 安全提醒

如果涉及安全敏感问题，请遵循 [`SECURITY.zh-CN.md`](./SECURITY.zh-CN.md)。

简而言之：不要在公开 issue 中贴出 secret、token、私有 endpoint、内部主机名或内部凭据。
