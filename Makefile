SHELL := /bin/bash

.PHONY: up down logs health test-write test-search

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=120

health:
	@AUTH_HEADER=(); \
	if [[ -n "$$MEMORY_API_TOKEN" ]]; then AUTH_HEADER=(-H "authorization: Bearer $$MEMORY_API_TOKEN"); fi; \
	curl -sS "$${AUTH_HEADER[@]}" http://127.0.0.1:8787/health

test-write:
	@AUTH_HEADER=(); \
	if [[ -n "$$MEMORY_API_TOKEN" ]]; then AUTH_HEADER=(-H "authorization: Bearer $$MEMORY_API_TOKEN"); fi; \
	curl -sS -X POST "$${AUTH_HEADER[@]}" http://127.0.0.1:8787/write \
	  -H 'content-type: application/json' \
	  -d '{"content":"memory-hub smoke test","source":"manual","actor":"tester","topic":"smoke","tags":["smoke","manual"]}'

test-search:
	@AUTH_HEADER=(); \
	if [[ -n "$$MEMORY_API_TOKEN" ]]; then AUTH_HEADER=(-H "authorization: Bearer $$MEMORY_API_TOKEN"); fi; \
	curl -sS -X POST "$${AUTH_HEADER[@]}" http://127.0.0.1:8787/search \
	  -H 'content-type: application/json' \
	  -d '{"query":"smoke test","limit":5}'
