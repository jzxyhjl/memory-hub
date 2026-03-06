# memory-hub

一个给 Codex + OpenClaw 共用的长期记忆中枢（可自托管）。

## 功能
- 统一记忆写入：`/write`
- 混合检索：`/search`（关键词 + 可选向量重排）
- 健康检查：`/health`
- Postgres + pgvector 持久化

## 架构
- `memory-db`: Postgres(带 pgvector)
- `memory-api`: FastAPI + psycopg
- `scripts/`: Codex/OpenClaw 调用封装

## 快速开始
```bash
cd /Users/ggsk/memory-hub
cp .env.example .env
bash scripts/start.sh
```

## 验证
```bash
make health
make test-write
make test-search
```

## 最小鉴权（可选）
1. 在 `.env` 设置固定 Token：
```bash
MEMORY_API_TOKEN=your_long_random_token
```
2. 重启 API：
```bash
docker compose up -d
```
3. 调用时携带请求头（Bearer）：
```bash
curl -sS -X POST http://127.0.0.1:8787/search \
  -H "authorization: Bearer $MEMORY_API_TOKEN" \
  -H "content-type: application/json" \
  -d '{"query":"smoke test","limit":5}'
```

说明：`MEMORY_API_TOKEN` 为空时，鉴权关闭（保持原行为）。

## 记忆记录触发条件（建议固化流程）
- 会话开始前：先 `search` 拉取 3-8 条相关记忆做上下文补全。
- 关键决策落地时：写入“决策 + 原因 + 影响范围”。
- 问题闭环时：写入“现象 + 根因 + 修复 + 验证结果”。
- 会话结束时：补 1-3 条“可复用结论 / 下一步 / 风险”。

单条记录建议：
- 长度 1-3 句，只写可复用事实，不写完整对话流水。
- 必带 `topic` 与 `tags`，便于后续过滤检索。

## 目录
- `api/app.py`: API 实现
- `sql/001_init.sql`: 表结构与索引
- `docs/openclaw-integration.md`: OpenClaw 接入
- `docs/codex-integration.md`: Codex 接入
- `skills/context-bootstrap/`: 跨窗口/跨机器上下文恢复 skill
- `scripts/install_context_skill.sh`: 一键安装 skill 到 `~/.codex/skills`

## Skill 同步与安装
将仓库中的 skill 安装到当前机器：
```bash
cd /Users/ggsk/memory-hub
bash scripts/install_context_skill.sh
```

安装后可直接执行：
```bash
bash ~/.codex/skills/context-bootstrap/scripts/bootstrap_context.sh "飞书 联调 鉴权 记忆" 5
```

## 生产建议
- 使用反向代理（Nginx/Caddy）+ Token 鉴权
- 定期备份 Postgres 数据卷
- 按 topic/tag 做租户隔离或命名约定
