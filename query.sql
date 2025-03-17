-- SQLC queries

-- Cache operations
-- name: CreateCache :one
INSERT INTO caches (id, name)
VALUES (?, ?)
RETURNING *;

-- name: GetCache :one
SELECT * FROM caches
WHERE name = ? LIMIT 1;

-- NAR operations
-- name: GetNarByHash :one
SELECT * FROM nars
WHERE nar_hash = ? LIMIT 1;

-- name: GetNarsInCacheByStorePath :many
SELECT n.* 
FROM nars n
JOIN cache_nars cn ON n.id = cn.nar_id
JOIN caches c ON cn.cache_id = c.id
WHERE c.name = ? AND n.store_path = ?
ORDER BY n.created_at DESC;

-- name: ListNarsInCache :many
SELECT n.* 
FROM nars n
JOIN cache_nars cn ON n.id = cn.nar_id
JOIN caches c ON cn.cache_id = c.id
WHERE c.name = ?
ORDER BY n.store_path;

-- name: FindConflictingStorePaths :many
SELECT n.store_path, 
       COUNT(DISTINCT n.nar_hash) as version_count,
       GROUP_CONCAT(DISTINCT c.name) as cache_names
FROM nars n
JOIN cache_nars cn ON n.id = cn.nar_id
JOIN caches c ON cn.cache_id = c.id
GROUP BY n.store_path
HAVING COUNT(DISTINCT n.nar_hash) > 1;

-- name: GetStorePathVersions :many
SELECT n.*, c.name as cache_name
FROM nars n
JOIN cache_nars cn ON n.id = cn.nar_id
JOIN caches c ON cn.cache_id = c.id
WHERE n.store_path = ?
ORDER BY n.created_at DESC;

-- name: InsertNar :one
INSERT INTO nars (
    id, store_path, nar_hash, 
    nar_size, chunk_count
)
VALUES (?, ?, ?, ?, ?)
RETURNING *;

-- name: AddNarToCache :exec
INSERT INTO cache_nars (cache_id, nar_id)
VALUES (?, ?)
ON CONFLICT DO NOTHING;

-- Chunk operations
-- name: InsertChunk :one
INSERT INTO chunks (
    id, chunk_hash, size, 
    compression_type, s3_key, etag
)
VALUES (?, ?, ?, ?, ?, ?)
RETURNING *;

-- name: InsertNarChunk :exec
INSERT INTO nar_chunks (
    nar_id, chunk_id, chunk_index, offset
)
VALUES (?, ?, ?, ?);

-- Garbage collection helpers
-- name: GetOrphanedNars :many
SELECT n.*
FROM nars n
LEFT JOIN cache_nars cn ON n.id = cn.nar_id
WHERE cn.cache_id IS NULL;

-- name: GetNarsByStorePath :many
SELECT n.*, 
       c.name as cache_name,
       c.id as cache_id
FROM nars n
JOIN cache_nars cn ON n.id = cn.nar_id
JOIN caches c ON cn.cache_id = c.id
WHERE n.store_path = ?
ORDER BY n.created_at DESC;

-- name: RemoveNarFromCache :exec
DELETE FROM cache_nars
WHERE cache_id = ? AND nar_id = ?;
