# PocketClaw 仓库方案（草案）

## 仓库定位

社区维护的 OpenClaw 原生移动客户端：

- 直连现有 OpenClaw Gateway
- 不新增中间后端
- 不修改 Gateway
- 优先保证聊天与多会话体验

## 建议仓库名

- `pocketclaw`

## 建议可见性

- 先建为 **private**，初始化结构与基础文档后再按需要切 public
- 如果你希望从第一天就公开记录开发过程，也可以直接 public

## 建议 owner

优先级建议：

1. 你的个人账号先建仓
2. 后续如有需要，再迁到组织

这样启动最快，也最少阻力。

## 建议初始化内容

创建仓库时建议带上：

- README
- .gitignore（后续按技术栈调整；如果上 Flutter，可换成 Flutter 模板）
- MIT 或 Apache-2.0 许可证（二选一）

## 首批仓库内容

建议先提交：

1. 项目 README
2. `docs/repo-plan.md`
3. `docs/architecture.md`
4. `docs/session-key-strategy.md`
5. 基础目录结构

## 后续开发分期

### Phase 1
- 协议摸底
- Gateway 兼容层
- 连接 / 鉴权 / pairing

### Phase 2
- Chat MVP
- 多 session 切换
- 图片发送
- 停止生成

### Phase 3
- 轻量控制台
- sessions / cron / nodes / logs

### Phase 4
- 手表适配预研
- WristClaw 拆分评估
