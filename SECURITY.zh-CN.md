# 安全策略

PocketClaw 当前仍处于 **活跃原型阶段**。
这个文件用于说明仓库在现阶段的安全问题处理方式。

## 当前支持范围

PocketClaw 目前没有同时维护多条长期支持版本线。
实际理解上，安全修复主要会针对最新的 `main` 状态，以及存在时的最新 tag/release。

## 什么问题值得报告

例如以下问题都属于安全相关范围：

- secret、凭据或认证材料被意外暴露
- device token、password 或本地凭据存储处理不安全
- connect、auth、pairing、session 流程中的安全敏感缺陷
- workflow、release 或仓库行为可能泄露私有数据

## 当前如何报告

这个仓库 **暂时还没有公开一个专门的私密安全上报通道**。

在专门通道被明确写出来之前，请遵守这些规则：

1. **不要** 在公开 issue 或 PR 中贴出 secret。
2. **不要** 公开 live token、password、私有 endpoint、内部主机名或私有日志。
3. 如果问题可以在“已脱敏”的前提下安全描述，可以提交一个公开 issue，但只保留最小必要信息。
4. 如果这个问题无法在不暴露敏感信息的情况下安全描述，就**不要**把细节发到公开 issue 里。

## 公开 issue 的写法建议

如果你要为安全相关问题开一个公开 issue，建议：

- 保持内容最小化、已脱敏
- 聚焦受影响区域、影响范围，以及安全的复现边界
- 不要直接粘贴原始凭据、环境文件或私有基础设施细节

一个合适的公开报告，通常只需要说明受影响区域，例如：

- `pocketclaw/app/pocketclaw_app`
- `pocketclaw/packages/gateway_adapter`
- `.github/workflows/`
- 文档中涉及 credential / token 处理的流程

## 范围说明

PocketClaw 的定位是一个 **mobile-first 的 OpenClaw 客户端**。
不要默认把一个有效的安全问题理解为一定要：

- 新增 backend 服务
- 发明新的 Gateway 协议行为
- 做与真实漏洞无关的大规模架构重写

## 披露预期

由于项目仍在快速演进：

- 修复可能首先落到最新活跃分支状态
- 必要时会同步更新相关文档
- 在发布模型稳定之前，支持版本承诺会保持保守
