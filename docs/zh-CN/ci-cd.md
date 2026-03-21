# CI / CD

本文说明 **这个仓库当前通过 GitHub Actions 实际验证了什么**，以及贡献者应该如何理解这些信号。

更偏工作区内部实现的说明，见 [`../../pocketclaw/docs/ci-cd.md`](../../pocketclaw/docs/ci-cd.md)。

## 当前策略

PocketClaw 当前把 **GitHub Actions 作为主要验证环境**。

这样做是有意的：

- 并不是每个贡献者本地都有完整的 Flutter / Dart 工具链
- 实际应用工作区位于 `pocketclaw/` 下
- 对早期测试来说，Android 构建产物是当前最实用的可下载成果

## 当前 workflow

### `flutter-ci.yml`

触发条件：

- push 到 `main`
- pull request

当前职责：

- 在 runner 上安装 Flutter、Dart 和 Java
- 从 `pocketclaw/` 工作区拉起依赖
- 检查 `app/` 与 `packages/` 的 Dart 格式
- 通过 Melos 运行静态分析
- 通过 Melos 运行测试
- 生成供测试使用的 Android release APK
- 上传按 ABI 拆分的 APK artifact

实际理解上，这个 workflow 主要回答的是：**“这个改动在预期的 Flutter 环境里还能不能过验证？”**

### `release-android.yml`

触发条件：

- 匹配 `v*` 的版本 tag
- 手动 `workflow_dispatch`

当前职责：

- 准备 Android app scaffold
- 构建拆分后的 Android release APK
- 作为 GitHub Release 资产发布
- 在 tag release 时自动生成 GitHub release notes

如果要看一份更适合人阅读的仓库级变更摘要，也可以参考 [`../../CHANGELOG.md`](../../CHANGELOG.md)。

## 当前 CI 比较可靠覆盖的内容

目前可以把 GitHub Actions 视为这些方面的主要验证来源：

- 仓库集成后的 Flutter / Dart 环境准备
- 主工作区格式一致性
- 工作区范围内的静态分析
- 已存在的单元测试和 package 级测试
- Android 测试安装包产出

## 当前 CI **还不代表** 的内容

这些 workflow 目前**不应被解读为**以下保证：

- iOS 发布已经就绪
- 真机端到端行为已经完整验证
- 生产签名或应用商店分发已经准备完成
- 当前 MVP 之外的产品能力已经成熟

## 给贡献者的建议

如果你本地具备工具链，常用检查命令是：

```bash
cd pocketclaw
flutter pub get
~/.pub-cache/bin/melos run analyze
~/.pub-cache/bin/melos run test
```

如果你本地**没有** Flutter / Dart 环境，就尽量保持改动聚焦，并让 GitHub Actions 提供基础验证信号。

## 如何理解失败

workflow 失败通常意味着以下几类问题之一：

- 格式漂移
- analyzer 失败
- 测试回归
- 构建假设与当前工作区结构不再一致

如果你改到了仓库结构、README / docs 表达或 workflow 行为，最好在同一个 PR 里同步更新对应文档。
