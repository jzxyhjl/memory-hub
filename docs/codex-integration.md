# Codex 接入（MVP）

## 会话开始
1. 读取 `/Users/ggsk/.codex/SESSION_CONTEXT.md`
2. 调用检索补全远古记忆

```bash
bash /Users/ggsk/memory-hub/scripts/codex_memory.sh search "飞书 联调 决策" 8
```

## 会话结束/关键节点写回
```bash
bash /Users/ggsk/memory-hub/scripts/codex_memory.sh write "已确认网关探测恢复，下一步验证业务流量" feishu
```

## 建议策略
- 只写“可复用决策”与“关键失败原因”，不要写全部对话。
- 每次写回 1-3 条，保证记忆密度。
