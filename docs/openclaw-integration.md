# OpenClaw 接入（MVP）

## 目标
- 消息入站前检索共享记忆
- 回复后写回关键结论

## 入站检索
```bash
bash /Users/ggsk/memory-hub/scripts/openclaw_memory.sh retrieve "${USER_QUERY}"
```

## 出站写回
```bash
bash /Users/ggsk/memory-hub/scripts/openclaw_memory.sh write "${ASSISTANT_SUMMARY}" feishu
```

## 建议写回字段
- `content`: 本轮结论或决策
- `topic`: channel 或业务域（如 `feishu`, `ops`, `project-a`）
- `tags`: `openclaw`, `decision`, `incident` 等
- `session_id`: 对应会话 ID（若可取到）
