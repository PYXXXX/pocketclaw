# 文档导航

这里是 PocketClaw 的 **仓库对外文档入口**。
它应该保持精简、准确，并且让第一次进入仓库的人能迅速看懂项目。

## 这里适合放什么

根目录 `docs/` 更适合放这些内容：

- 项目方向
- 架构边界
- 兼容性承诺
- MVP 范围
- 面向贡献者的规划说明

## 这里不适合放什么

不要把根目录 `docs/` 变成杂乱的随手记录区。
一次性部署笔记、临时实验记录、仅对本地操作者有用的备忘，不应该混进公共产品文档面，除非它确实直接服务于 PocketClaw 贡献者。

## 文档索引

| 文档 | 作用 |
| --- | --- |
| [`architecture.md`](../architecture.md) | 客户端分层与模块方向 |
| [`roadmap.md`](./roadmap.md) | 近期与中期路线 |
| [`mvp-scope.md`](../mvp-scope.md) | 当前 Chat MVP 边界 |
| [`compatibility.md`](../compatibility.md) | 与当前 OpenClaw Gateway 的兼容性约束 |
| [`session-key-strategy.md`](../session-key-strategy.md) | 基于客户端 `sessionKey` 的多会话策略 |
| [`gateway-surface-map.md`](../gateway-surface-map.md) | 客户端当前封装的 Gateway 方法与假设 |
| [`connect-flow-plan.md`](../connect-flow-plan.md) | 移动端连接与配对流程规划 |
| [`development-workflow.md`](../development-workflow.md) | 仓库开发方式与迭代原则 |
| [`official-android-reference.md`](../official-android-reference.md) | 官方 Android 侧交互参考 |

## 关于 `pocketclaw/docs/`

实际的 Flutter/Dart 工作区位于 [`../pocketclaw/`](../../pocketclaw/)。
其中的 `pocketclaw/docs/` 可以放更多偏实现层的说明，例如本地开发、CI/CD 细节、下一步计划等。

一个简单判断规则：

- **根目录 `docs/`** = 对外仓库说明
- **`pocketclaw/docs/`** = 工作区实现说明
