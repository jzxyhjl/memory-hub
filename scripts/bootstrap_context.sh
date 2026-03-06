#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MEMORY_API_BASE="${MEMORY_API_BASE:-http://127.0.0.1:8787}"
MEMORY_API_TOKEN="${MEMORY_API_TOKEN:-}"
QUERY="${1:-当前任务 上下文 决策 TODO}"
LIMIT="${2:-8}"
MEMORY_ENV_FILE="${MEMORY_ENV_FILE:-}"
SESSION_CONTEXT_FILE="${SESSION_CONTEXT_FILE:-}"

pick_first_existing_file() {
  local candidate
  for candidate in "$@"; do
    [[ -n "${candidate}" && -f "${candidate}" ]] && { echo "${candidate}"; return 0; }
  done
  return 1
}

if [[ -z "${SESSION_CONTEXT_FILE}" ]]; then
  SESSION_CONTEXT_FILE="$(pick_first_existing_file \
    "${PWD}/SESSION_CONTEXT.md" \
    "${HOME}/.codex/SESSION_CONTEXT.md" \
    "${HOME}/.context-bootstrap/SESSION_CONTEXT.md" \
    "${REPO_ROOT}/SESSION_CONTEXT.md" \
  || true)"
fi

if [[ -z "${SESSION_CONTEXT_FILE}" || ! -f "${SESSION_CONTEXT_FILE}" ]]; then
  echo "[ERROR] SESSION_CONTEXT.md not found."
  echo "Set SESSION_CONTEXT_FILE or place it in one of:"
  echo "  - ./SESSION_CONTEXT.md"
  echo "  - ~/.codex/SESSION_CONTEXT.md"
  echo "  - ~/.context-bootstrap/SESSION_CONTEXT.md"
  echo "  - <memory-hub>/SESSION_CONTEXT.md"
  exit 1
fi

if [[ -z "${MEMORY_API_TOKEN}" ]]; then
  if [[ -n "${MEMORY_ENV_FILE}" && -f "${MEMORY_ENV_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${MEMORY_ENV_FILE}"
    set +a
  else
    auto_env_file="$(pick_first_existing_file \
      "${REPO_ROOT}/.env" \
      "${PWD}/.env" \
      "${HOME}/memory-hub/.env" \
      "${HOME}/.context-bootstrap/.env" \
    || true)"
    if [[ -n "${auto_env_file}" ]]; then
      set -a
      # shellcheck disable=SC1090
      source "${auto_env_file}"
      set +a
    fi
  fi
fi

AUTH_HEADER=()
if [[ -n "${MEMORY_API_TOKEN}" ]]; then
  AUTH_HEADER=(-H "authorization: Bearer ${MEMORY_API_TOKEN}")
fi

print_section() {
  local title="$1"
  local start_pattern="$2"
  local end_pattern="$3"
  echo "## ${title}"
  awk -v start="${start_pattern}" -v end="${end_pattern}" '
    BEGIN {p=0}
    $0 ~ start {p=1}
    $0 ~ end {if (p==1) {exit}}
    p==1 {print}
  ' "${SESSION_CONTEXT_FILE}" | sed '1d'
  echo
}

echo "# Bootstrap Context"
echo "Generated at: $(date '+%F %T %z')"
echo

print_section "Goal" "^## 1\\) Goal" "^## 2\\)"
print_section "Current Status" "^## 2\\) Current Status" "^## 3\\)"
print_section "Known Issue / Risk" "^## 3\\) Known Issue / Risk" "^## 4\\)"
print_section "Next TODO" "^## 4\\) Next TODO" "^## 5\\)"

echo "## Recent Decisions (latest 8)"
awk '
  BEGIN {p=0}
  /^## 6\) Decisions Log/ {p=1; next}
  /^## 7\)/ {p=0}
  p==1 && /^- / {print}
' "${SESSION_CONTEXT_FILE}" | tail -n 8
echo

echo "## Memory Search"
echo "Query: ${QUERY}"
echo "Limit: ${LIMIT}"

payload="$(python3 -c 'import json,sys; print(json.dumps({"query":sys.argv[1], "limit":int(sys.argv[2])}, ensure_ascii=False))' "${QUERY}" "${LIMIT}")"

set +e
search_result="$(curl -sS -X POST "${MEMORY_API_BASE}/search" \
  "${AUTH_HEADER[@]}" \
  -H 'content-type: application/json' \
  -d "${payload}")"
search_exit=$?
set -e

if [[ ${search_exit} -ne 0 ]]; then
  echo "Search failed: cannot reach memory-api at ${MEMORY_API_BASE}"
  exit 0
fi

python3 - "${search_result}" <<'PY'
import json
import sys

raw = sys.argv[1].strip()
if not raw:
    print("Search returned empty response")
    raise SystemExit(0)

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print(raw)
    raise SystemExit(0)

if isinstance(data, dict) and "detail" in data:
    print(f"Search error: {data['detail']}")
    raise SystemExit(0)

items = data.get("items", []) if isinstance(data, dict) else []
print(f"Matched: {data.get('count', len(items))}")
for i, item in enumerate(items[:8], 1):
    content = (item.get("content") or "").replace("\n", " ").strip()
    created = item.get("created_at", "")
    topic = item.get("topic", "")
    tags = ",".join(item.get("tags") or [])
    if len(content) > 120:
        content = content[:117] + "..."
    print(f"{i}. [{created}] topic={topic} tags={tags} :: {content}")
PY
