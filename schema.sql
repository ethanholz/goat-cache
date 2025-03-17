-- SQLite schema for Nix NARs and their chunks
-- Supporting duplicate store paths across caches

-- Table to store caches (collections of NARs)
CREATE TABLE caches (
    id TEXT PRIMARY KEY,           -- UUID stored as text
    name TEXT NOT NULL UNIQUE,     -- Human readable cache name
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_accessed_at TEXT,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Table to store information about complete NARs
CREATE TABLE nars (
    id TEXT PRIMARY KEY,           -- UUID stored as text
    store_path TEXT NOT NULL,      -- The Nix store path
    nar_hash TEXT NOT NULL,        -- Hash of the complete NAR
    nar_size INTEGER NOT NULL,     -- Total size of the NAR
    chunk_count INTEGER NOT NULL,  -- Number of chunks this NAR is split into
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_accessed_at TEXT,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Table to map NARs to caches
CREATE TABLE cache_nars (
    cache_id TEXT NOT NULL REFERENCES caches(id),
    nar_id TEXT NOT NULL REFERENCES nars(id),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (cache_id, nar_id)
);

-- Table to store individual chunks
CREATE TABLE chunks (
    id TEXT PRIMARY KEY,           -- UUID stored as text
    chunk_hash TEXT NOT NULL UNIQUE,  -- Hash of this chunk's content
    size INTEGER NOT NULL,         -- Size of this chunk in bytes
    compression_type TEXT,         -- e.g., 'xz', 'bzip2', null for uncompressed
    s3_key TEXT NOT NULL UNIQUE,   -- The S3 key where this chunk is stored
    etag TEXT NOT NULL,            -- S3 ETag for consistency checking
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Table to map which chunks belong to which NARs
CREATE TABLE nar_chunks (
    nar_id TEXT NOT NULL REFERENCES nars(id),
    chunk_id TEXT NOT NULL REFERENCES chunks(id),
    chunk_index INTEGER NOT NULL,  -- Order of chunks within the NAR
    offset INTEGER NOT NULL,       -- Offset within the NAR where this chunk starts
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (nar_id, chunk_index),
    UNIQUE (nar_id, chunk_id)
);

-- Indices for common query patterns
CREATE INDEX idx_nars_store_path ON nars(store_path);
CREATE INDEX idx_nars_nar_hash ON nars(nar_hash);
CREATE INDEX idx_cache_nars_nar_id ON cache_nars(nar_id);
CREATE INDEX idx_chunks_chunk_hash ON chunks(chunk_hash);
CREATE INDEX idx_nar_chunks_chunk_id ON nar_chunks(chunk_id);
