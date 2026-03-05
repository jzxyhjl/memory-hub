SHELL := /bin/bash

.PHONY: up down logs health test-write test-search

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=120

health:
	curl -sS http://127.0.0.1:8787/health

test-write:
	curl -sS -X POST http://127.0.0.1:8787/write \
	  -H 'content-type: application/json' \
	  -d '{"content":"memory-hub smoke test","source":"manual","actor":"tester","topic":"smoke","tags":["smoke","manual"]}'

test-search:
	curl -sS -X POST http://127.0.0.1:8787/search \
	  -H 'content-type: application/json' \
	  -d '{"query":"smoke test","limit":5}'
