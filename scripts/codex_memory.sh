#!/usr/bin/env bash
set -euo pipefail

API_BASE="${MEMORY_API_BASE:-http://127.0.0.1:8787}"
CMD="${1:-}"

if [[ -z "$CMD" ]]; then
  echo "Usage: $0 write|search [args...]"
  exit 1
fi

case "$CMD" in
  write)
    CONTENT="${2:-}"
    if [[ -z "$CONTENT" ]]; then
      echo "Usage: $0 write \"content\" [topic]"
      exit 1
    fi
    TOPIC="${3:-general}"
    curl -sS -X POST "$API_BASE/write" \
      -H 'content-type: application/json' \
      -d "{\"content\":\"${CONTENT}\",\"source\":\"codex\",\"actor\":\"codex\",\"topic\":\"${TOPIC}\",\"tags\":[\"codex\",\"decision\"]}"
    ;;
  search)
    QUERY="${2:-}"
    if [[ -z "$QUERY" ]]; then
      echo "Usage: $0 search \"query\" [limit]"
      exit 1
    fi
    LIMIT="${3:-8}"
    curl -sS -X POST "$API_BASE/search" \
      -H 'content-type: application/json' \
      -d "{\"query\":\"${QUERY}\",\"limit\":${LIMIT},\"tags\":[\"codex\",\"openclaw\"]}"
    ;;
  *)
    echo "Unknown command: $CMD"
    exit 1
    ;;
esac
