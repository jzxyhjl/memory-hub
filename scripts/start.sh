#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon 未运行，请先启动 Docker Desktop。"
  exit 1
fi

cp -n .env.example .env

docker compose up -d

echo "等待 API 就绪..."
for i in {1..30}; do
  if curl -sS http://127.0.0.1:8787/health >/dev/null 2>&1; then
    echo "Memory Hub 已就绪: http://127.0.0.1:8787"
    exit 0
  fi
  sleep 1
done

echo "API 未在预期时间内就绪，请检查: docker compose logs"
exit 1
