---
name: context-bootstrap
description: Bootstrap cross-session context for Codex/Claude by reading SESSION_CONTEXT.md and retrieving relevant long-term memories from memory-hub. Use when starting a new window, switching machine/environment, or recovering from interrupted work.
---

# Context Bootstrap

## Overview

Use this skill to rebuild working context in a new session with deterministic steps.
It combines short-term state from `SESSION_CONTEXT.md` and long-term state from `memory-hub`.

## When To Use

- New chat window or session restart
- New machine/environment setup
- Handoff from one model to another (for example Codex -> Claude)
- User says context was lost, interrupted, or unclear

## Workflow

1. Run the bootstrap script:
```bash
context-bootstrap "<query>" <limit>
```

2. Use script output to build startup prompt:
- Goal
- Current Status
- Known Issue / Risk
- Next TODO
- Recent Decisions
- Memory-hub retrieval results

3. Continue execution from `Next TODO`.

## Defaults And Assumptions

- `SESSION_CONTEXT.md` path auto-discovery order:
  - `SESSION_CONTEXT_FILE` (if provided)
  - `./SESSION_CONTEXT.md`
  - `~/.codex/SESSION_CONTEXT.md`
  - `~/.context-bootstrap/SESSION_CONTEXT.md`
  - `<memory-hub>/SESSION_CONTEXT.md`
- memory API defaults to `http://127.0.0.1:8787`
- If `MEMORY_API_TOKEN` is missing, the script tries `.env` auto-discovery.
- If memory search fails, continue with file context only (do not block)

## Script

Use:
- `scripts/bootstrap_context.sh`
