#!/usr/bin/env bash
set -euo pipefail

# Example wrapper for OpenClaw command/hook integration.
# Inbound message retrieval:
#   openclaw_memory.sh retrieve "user query"
# After reply write-back:
#   openclaw_memory.sh write "assistant conclusion" "feishu"

API_BASE="${MEMORY_API_BASE:-http://127.0.0.1:8787}"
CMD="${1:-}"

if [[ -z "$CMD" ]]; then
  echo "Usage: $0 retrieve|write ..."
  exit 1
fi

if [[ "$CMD" == "retrieve" ]]; then
  QUERY="${2:-}"
  [[ -n "$QUERY" ]] || { echo "Usage: $0 retrieve \"query\""; exit 1; }
  curl -sS -X POST "$API_BASE/search" \
    -H 'content-type: application/json' \
    -d "{\"query\":\"${QUERY}\",\"limit\":6,\"tags\":[\"openclaw\",\"codex\"]}"
elif [[ "$CMD" == "write" ]]; then
  CONTENT="${2:-}"
  CHANNEL="${3:-feishu}"
  [[ -n "$CONTENT" ]] || { echo "Usage: $0 write \"content\" [channel]"; exit 1; }
  curl -sS -X POST "$API_BASE/write" \
    -H 'content-type: application/json' \
    -d "{\"content\":\"${CONTENT}\",\"source\":\"openclaw\",\"actor\":\"assistant\",\"topic\":\"${CHANNEL}\",\"tags\":[\"openclaw\",\"${CHANNEL}\"]}"
else
  echo "Unknown command: $CMD"
  exit 1
fi
