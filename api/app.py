import os
from typing import Any, Optional

import psycopg
from psycopg.types.json import Jsonb
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field


DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "memoryhub")
DB_USER = os.getenv("DB_USER", "memoryhub")
DB_PASSWORD = os.getenv("DB_PASSWORD", "change_me")
TSV_CONFIG = os.getenv("PG_TSV_CONFIG", "simple")
API_TOKEN = os.getenv("MEMORY_API_TOKEN", "").strip()


def dsn() -> str:
    return (
        f"host={DB_HOST} port={DB_PORT} dbname={DB_NAME} "
        f"user={DB_USER} password={DB_PASSWORD}"
    )


class MemoryWrite(BaseModel):
    content: str = Field(min_length=1)
    summary: Optional[str] = None
    source: Optional[str] = None
    actor: Optional[str] = None
    session_id: Optional[str] = None
    topic: Optional[str] = None
    tags: list[str] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
    embedding: Optional[list[float]] = None


class MemorySearch(BaseModel):
    query: str = Field(min_length=1)
    limit: int = Field(default=8, ge=1, le=50)
    tags: list[str] = Field(default_factory=list)
    session_id: Optional[str] = None
    topic: Optional[str] = None
    since_days: Optional[int] = Field(default=None, ge=1, le=3650)
    query_embedding: Optional[list[float]] = None
    alpha: float = Field(default=0.65, ge=0.0, le=1.0)


app = FastAPI(title="Memory Hub API", version="0.1.0")


def verify_api_token(
    authorization: Optional[str] = Header(default=None),
    x_api_token: Optional[str] = Header(default=None),
) -> None:
    if not API_TOKEN:
        return

    bearer_token = None
    if authorization and authorization.lower().startswith("bearer "):
        bearer_token = authorization[7:].strip()

    provided_token = x_api_token or bearer_token
    if provided_token != API_TOKEN:
        raise HTTPException(status_code=401, detail="unauthorized")


@app.get("/health")
def health(
    authorization: Optional[str] = Header(default=None),
    x_api_token: Optional[str] = Header(default=None),
) -> dict[str, str]:
    verify_api_token(authorization, x_api_token)
    try:
        with psycopg.connect(dsn()) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        return {"status": "ok"}
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"db not ready: {exc}") from exc


@app.post("/write")
def write_memory(
    payload: MemoryWrite,
    authorization: Optional[str] = Header(default=None),
    x_api_token: Optional[str] = Header(default=None),
) -> dict[str, Any]:
    verify_api_token(authorization, x_api_token)
    sql = """
    INSERT INTO memory_items (
      content, summary, source, actor, session_id, topic, tags, metadata, embedding
    ) VALUES (
      %(content)s, %(summary)s, %(source)s, %(actor)s, %(session_id)s,
      %(topic)s, %(tags)s, %(metadata)s, %(embedding)s
    )
    RETURNING id, created_at;
    """
    params = payload.model_dump()
    params["metadata"] = Jsonb(params.get("metadata", {}))

    try:
        with psycopg.connect(dsn()) as conn:
            with conn.cursor() as cur:
                cur.execute(sql, params)
                row = cur.fetchone()
            conn.commit()
        return {"id": row[0], "created_at": row[1].isoformat()}
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"write failed: {exc}") from exc


@app.post("/search")
def search_memory(
    payload: MemorySearch,
    authorization: Optional[str] = Header(default=None),
    x_api_token: Optional[str] = Header(default=None),
) -> dict[str, Any]:
    verify_api_token(authorization, x_api_token)
    filters = ["TRUE"]
    params: dict[str, Any] = {
        "query": payload.query,
        "limit": payload.limit,
        "alpha": payload.alpha,
        "tsv_cfg": TSV_CONFIG,
    }

    if payload.tags:
        filters.append("tags && %(tags)s::text[]")
        params["tags"] = payload.tags
    if payload.session_id:
        filters.append("session_id = %(session_id)s")
        params["session_id"] = payload.session_id
    if payload.topic:
        filters.append("topic = %(topic)s")
        params["topic"] = payload.topic
    if payload.since_days:
        filters.append("created_at >= now() - (%(since_days)s || ' days')::interval")
        params["since_days"] = payload.since_days

    where_clause = " AND ".join(filters)

    if payload.query_embedding:
        params["query_embedding"] = payload.query_embedding
        sql = f"""
        WITH ranked AS (
          SELECT
            id, content, summary, source, actor, session_id, topic, tags, metadata, created_at,
            ts_rank_cd(
              to_tsvector(%(tsv_cfg)s::regconfig, coalesce(content, '') || ' ' || coalesce(summary, '')),
              plainto_tsquery(%(tsv_cfg)s::regconfig, %(query)s)
            ) AS keyword_score,
            CASE
              WHEN embedding IS NULL THEN 0
              ELSE (1 - (embedding <=> %(query_embedding)s::vector))
            END AS vector_score
          FROM memory_items
          WHERE {where_clause}
        )
        SELECT
          id, content, summary, source, actor, session_id, topic, tags, metadata, created_at,
          keyword_score, vector_score,
          (%(alpha)s * vector_score + (1 - %(alpha)s) * keyword_score) AS final_score
        FROM ranked
        ORDER BY final_score DESC, created_at DESC
        LIMIT %(limit)s;
        """
    else:
        sql = f"""
        SELECT
          id, content, summary, source, actor, session_id, topic, tags, metadata, created_at,
          ts_rank_cd(
            to_tsvector(%(tsv_cfg)s::regconfig, coalesce(content, '') || ' ' || coalesce(summary, '')),
            plainto_tsquery(%(tsv_cfg)s::regconfig, %(query)s)
          ) AS keyword_score,
          0::float AS vector_score,
          ts_rank_cd(
            to_tsvector(%(tsv_cfg)s::regconfig, coalesce(content, '') || ' ' || coalesce(summary, '')),
            plainto_tsquery(%(tsv_cfg)s::regconfig, %(query)s)
          ) AS final_score
        FROM memory_items
        WHERE {where_clause}
        ORDER BY final_score DESC, created_at DESC
        LIMIT %(limit)s;
        """

    try:
        with psycopg.connect(dsn()) as conn:
            with conn.cursor() as cur:
                cur.execute(sql, params)
                rows = cur.fetchall()

        items = []
        for row in rows:
            items.append(
                {
                    "id": row[0],
                    "content": row[1],
                    "summary": row[2],
                    "source": row[3],
                    "actor": row[4],
                    "session_id": row[5],
                    "topic": row[6],
                    "tags": row[7],
                    "metadata": row[8],
                    "created_at": row[9].isoformat(),
                    "keyword_score": float(row[10] or 0),
                    "vector_score": float(row[11] or 0),
                    "final_score": float(row[12] or 0),
                }
            )

        return {"count": len(items), "items": items}
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"search failed: {exc}") from exc
