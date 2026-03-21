<div align="center">

# PocketClaw Workspace

**PocketClaw 移动客户端的 Flutter / Dart 工作区。**

*如果你要看项目定位、仓库文档、贡献方式或支持入口，请优先从仓库根目录开始。*

[仓库总览](../README.zh-CN.md) · [English](./README.md) · [本地开发](./docs/local-setup.md) · [CI / CD](./docs/ci-cd.md) · [架构文档](./docs/architecture.md)

![状态](https://img.shields.io/badge/status-active%20prototype-7c3aed)
![工作区](https://img.shields.io/badge/workspace-Flutter%20%2B%20Dart-02569B?logo=flutter&logoColor=white)
![Monorepo](https://img.shields.io/badge/managed%20with-Melos-4B32C3)

</div>

## 这份 README 是干什么的

这份 README 是 `pocketclaw/` 目录下代码的 **实现层说明入口**。

下面这些内容请优先看**根目录 README**：

- 项目定位
- 面向仓库门面的文档入口
- 贡献与支持入口
- 公共协作规则

这份 README 更适合看：

- 本地工作区启动方式
- app / packages 结构
- 偏实现层的文档
- Flutter / Dart 验证命令

## 工作区快速开始

```bash
cd pocketclaw
flutter pub get
~/.pub-cache/bin/melos run analyze
~/.pub-cache/bin/melos run test
```

如果本地没有 Flutter / Dart 工具链，请以仓库级 GitHub Actions 验证为准，说明见 [`../docs/zh-CN/ci-cd.md`](../docs/zh-CN/ci-cd.md)。

## 工作区结构

- `app/pocketclaw_app/` —— Flutter 应用壳与 app 侧 UI 代码
- `packages/gateway_transport/` —— Gateway 传输层基础模块
- `packages/gateway_adapter/` —— 面向当前 OpenClaw Gateway 的兼容适配层
- `packages/pocketclaw_core/` —— 共享领域逻辑与会话相关基础模块
- `docs/` —— 偏实现层的 setup、CI/CD、技术栈与下一步说明
- `melos.yaml` —— 工作区脚本与包管理编排
- `pubspec.yaml` —— Dart workspace 定义

## 常用工作区命令

```bash
cd pocketclaw
flutter pub get
~/.pub-cache/bin/melos run analyze
~/.pub-cache/bin/melos run test
```

常用路径：

- app 入口：`app/pocketclaw_app/lib/main.dart`
- app 测试：`app/pocketclaw_app/test/`
- package 测试：`packages/*/test/`

## 工作区文档

- [`docs/local-setup.md`](./docs/local-setup.md) —— 本地开发说明
- [`docs/ci-cd.md`](./docs/ci-cd.md) —— 工作区视角的 CI/CD 说明
- [`docs/tech-stack.md`](./docs/tech-stack.md) —— 实现技术栈选择
- [`docs/next-steps.md`](./docs/next-steps.md) —— 当前实现层后续事项
- [`docs/repo-plan.md`](./docs/repo-plan.md) —— repo / workspace 组织说明
- [`docs/architecture.md`](./docs/architecture.md) —— 客户端分层与模块方向
- [`docs/roadmap.md`](./docs/roadmap.md) —— 工作区内同步保留的路线图上下文

## 范围提醒

这个工作区仍然遵循根仓库的核心边界：

- mobile-first OpenClaw 客户端
- 兼容当前 Gateway 能力面
- 默认不引入 custom backend
- 优先做小而可 review 的改动，而不是大范围重写
