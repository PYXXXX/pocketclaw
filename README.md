# PocketClaw

PocketClaw 是一个兼容现有 OpenClaw Gateway 的原生移动客户端项目。

当前阶段原则：

- 不修改 Gateway
- 不依赖私有补丁或新增 Gateway API
- 优先复用现有 Gateway WebSocket / Control UI 已有能力
- 先做手机端体验，再评估手表特化版本 `WristClaw`

## 当前目录

- `docs/`：产品、架构、兼容性与开发记录
- `app/`：未来移动端应用代码
- `packages/`：未来可复用核心模块（协议、状态管理、适配层）

## 当前已确认方向

- 项目名：PocketClaw
- 多会话思路：通过自定义 `sessionKey` 切换/新建会话，不改 Gateway
- 目标兼容设备：手机优先，同时为不同 DPI 设备与安卓手表保留适配空间
