CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS memory_items (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  summary TEXT,
  source TEXT,
  actor TEXT,
  session_id TEXT,
  topic TEXT,
  tags TEXT[] NOT NULL DEFAULT '{}',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  embedding VECTOR(1024),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_memory_items_updated_at ON memory_items;
CREATE TRIGGER trg_memory_items_updated_at
BEFORE UPDATE ON memory_items
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE INDEX IF NOT EXISTS idx_memory_items_created_at ON memory_items (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_memory_items_tags_gin ON memory_items USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_memory_items_metadata_gin ON memory_items USING GIN (metadata);
CREATE INDEX IF NOT EXISTS idx_memory_items_topic ON memory_items (topic);
CREATE INDEX IF NOT EXISTS idx_memory_items_session_id ON memory_items (session_id);

CREATE INDEX IF NOT EXISTS idx_memory_items_fts
ON memory_items
USING GIN (to_tsvector('simple', coalesce(content, '') || ' ' || coalesce(summary, '')));

CREATE INDEX IF NOT EXISTS idx_memory_items_embedding_ivfflat
ON memory_items
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
