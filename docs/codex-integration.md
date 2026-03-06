# Codex 接入（MVP）

## 统一启动（推荐）
先执行统一上下文恢复命令（与 Claude 相同）：
```bash
context-bootstrap "飞书 联调 决策" 8
```

## 会话开始
1. 读取 `SESSION_CONTEXT.md`（由 `context-bootstrap` 自动完成）
2. 调用检索补全远古记忆

```bash
bash scripts/codex_memory.sh search "飞书 联调 决策" 8
```

## 会话结束/关键节点写回
```bash
bash scripts/codex_memory.sh write "已确认网关探测恢复，下一步验证业务流量" feishu
```

## 触发时机（执行侧约定）
1. 会话开始前：先检索，再开工。
2. 关键决策落地时：立即写回 1 条决策记忆。
3. 故障闭环时：立即写回 1 条根因/修复记忆。
4. 会话结束时：补写 1-3 条可复用结论。

可直接复用命令：
```bash
bash scripts/codex_memory.sh write "已确认<决策/根因>，条件=<前提>，影响=<范围>" <topic>
```

## 建议策略
- 只写“可复用决策”与“关键失败原因”，不要写全部对话。
- 每次写回 1-3 条，保证记忆密度。
