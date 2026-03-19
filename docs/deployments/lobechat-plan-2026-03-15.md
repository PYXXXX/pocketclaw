# LobeChat 部署记录与方案（2026-03-15）

## 目标
- 前端域名：`chat.bilirec.com`（仅 DNS，用户直连）
- S3 API 域名：`s3.bilirec.com`（仅 DNS）
- S3 UI 域名：`s3-ui.bilirec.com`（仅 DNS）
- 身份认证：Cloudflare Zero Trust OIDC / SSO
- 模型后端：同机 AIClient-2-API，优先走内网
- 数据持久化：统一落到 `/data/lobechat`

## 已创建目录
- `/data/lobechat/compose`
- `/data/lobechat/postgres`
- `/data/lobechat/rustfs`
- `/data/lobechat/redis`
- `/data/lobechat/backups`
- `/data/lobechat/logs`

## 已获取文件
- `/data/lobechat/compose/docker-compose.yml`
- `/data/lobechat/compose/docker-compose.override.yml`
- `/data/lobechat/compose/.env`
- `/data/lobechat/compose/bucket.config.json`
- `/data/lobechat/compose/searxng-settings.yml`

## 当前设计
### 容器暴露策略
- LobeChat: `127.0.0.1:3210 -> 3210`
- RustFS API: `127.0.0.1:9000 -> 9000`
- RustFS UI: `127.0.0.1:9001 -> 9001`
- PostgreSQL: 不对宿主暴露
- Redis: 不对宿主暴露

### 数据目录
- Postgres: `/data/lobechat/postgres`
- Redis: `/data/lobechat/redis`
- RustFS: `/data/lobechat/rustfs`

### 公开 URL
- `APP_URL=https://chat.bilirec.com`
- `INTERNAL_APP_URL=http://lobe:3210`
- `S3_ENDPOINT=https://s3.bilirec.com`

### 模型代理
- 当前暂定：`OPENAI_PROXY_URL=http://172.19.0.2:3000/v1`
- 当前模型列表：`OPENAI_MODEL_LIST=-all,+gpt-5.4`
- 说明：`172.19.0.2` 是当前 `aiclient2api` 容器在其现有 Docker 网络中的 IP。上线前需要再验证该地址从 LobeChat 容器可达，若不可达则改为：
  - 让 LobeChat 加入同一网络并用服务名访问；或
  - 改为宿主桥接可达地址。

## 已补充的敏感配置（值本身不再写入文档）
1. Cloudflare Zero Trust `Client ID`
2. Cloudflare Zero Trust `Client Secret`
3. Cloudflare Zero Trust `Issuer URL`
4. AIClient-2-API API Key（用于 `OPENAI_API_KEY`）

## 当前执行进度
1. 已为 `chat.bilirec.com` / `s3.bilirec.com` / `s3-ui.bilirec.com` 申请到证书
2. 已将 `.env` 补齐 SSO 与 OpenAI 兼容 API 凭据
3. 已切换 nginx 站点到 HTTPS 反代配置
4. 正在启动 `docker compose`
5. 待验证数据库迁移、S3 bucket 初始化、LobeChat 页面打开、SSO 登录、模型连通性

## 当前生成并已开始启用的 nginx 配置
- `/etc/nginx/conf.d/chat.bilirec.com.conf`
- `/etc/nginx/conf.d/s3.bilirec.com.conf`
- `/etc/nginx/conf.d/s3-ui.bilirec.com.conf`

## 当前阻塞
- 证书文件不存在：`/etc/letsencrypt/live/chat.bilirec.com/fullchain.pem` 等，导致 `nginx -t` 失败
- SSO 凭据未填
- API Key 未填

## 维护提醒
- 所有后续改动优先记录到本文件和对应日记 `memory/2026-03-15.md`
- 真正上线后补充：最终生效的 `.env` 变量说明（不要写明文敏感值）、证书获取方式、实际容器网络关系、验证结果和回滚方式
