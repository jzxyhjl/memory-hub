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

## 目录
- `api/app.py`: API 实现
- `sql/001_init.sql`: 表结构与索引
- `docs/openclaw-integration.md`: OpenClaw 接入
- `docs/codex-integration.md`: Codex 接入

## 生产建议
- 使用反向代理（Nginx/Caddy）+ Token 鉴权
- 定期备份 Postgres 数据卷
- 按 topic/tag 做租户隔离或命名约定
