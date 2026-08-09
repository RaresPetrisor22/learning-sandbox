-- ================================================================
-- SET 1                                                         ==
-- ================================================================

-- 1.1
SELECT 
    name,
    slug,
    created_at::date
FROM
    studios
ORDER BY
    created_at::date DESC;

-- 1.2
SELECT email, role
FROM users
ORDER BY email;


-- 1.3
SELECT id, created_at
FROM users
WHERE email_verified_at IS NULL;

-- 1.4
SELECT id, title, status
FROM galleries
WHERE studio_id = '11111111-1111-1111-1111-111111111111' AND status <> 'archived'; 

-- 1.5
SELECT id, original_filename, created_at::date
FROM assets
WHERE gallery_id = '11111111-0000-4000-8001-000000000001'
ORDER BY position, id;

-- 1.6
SELECT gallery_id, original_filename, status, EXTRACT(DAY FROM NOW() - created_at) AS days
FROM assets
WHERE status NOT IN ('ready', 'processing');

-- 1.7
SELECT id, original_filename, created_at, ROUND(size_bytes / 1024.0 / 1024.0, 1) as mb 
FROM assets
WHERE size_bytes > 5 * 1024 * 1024
ORDER BY size_bytes DESC;

-- 1.10
SELECT original_filename
FROM assets
WHERE lower(original_filename) LIKE '%.jpg';

SELECT original_filename
FROM assets
WHERE original_filename ILIKE '%.jpg';

SELECT original_filename
FROM assets
WHERE original_filename ~* '\.jpg$';

-- ================================================================
-- SET 2                                                         ==
-- ================================================================

-- 2.1
SELECT status, COUNT(*) nr_of_assets
FROM assets
GROUP BY status
ORDER BY nr_of_assets DESC;

-- 2.2
SELECT studio_id, ROUND(SUM(size_bytes / 1024.0 / 1024.0),2) total_mb_stored
FROM assets
WHERE size_bytes IS NOT NULL
GROUP BY studio_id
ORDER BY total_mb_stored DESC;

-- 2.3
SELECT s.name,
       round(sum(a.size_bytes) / 1024.0 / 1024.0, 1) AS mb
FROM studios s
JOIN assets a ON a.studio_id = s.id
GROUP BY s.name
ORDER BY mb DESC;

-- 2.3
SELECT g.title,
       COUNT(*) asset_count,
       COUNT(*) FILTER (WHERE a.status = 'ready') ready_count,
       ROUND(SUM(a.size_bytes) FILTER (WHERE a.status = 'ready') / 1024.0 / 1024.0, 1) ready_size_mb
FROM assets a 
JOIN galleries g on g.id = a.gallery_id
GROUP BY g.title
ORDER BY asset_count DESC;

-- 2.4  
SELECT g.title, count(*) AS n
FROM galleries g
JOIN assets a ON a.gallery_id = g.id
GROUP BY g.id, g.title
HAVING count(*) > 4;

-- 2.7  count(*) counts rows; count(col) counts non-null values of col.
SELECT count(*) AS rows_total, count(content_hash) AS with_hash
FROM assets;


-- ================================================================
-- SET 3                                                         ==
-- ================================================================


-- 3.1
SELECT title, studios.name studio_name
FROM galleries
JOIN studios ON studios.id = studio_id

-- 3.2
SELECT s.name AS studio, g.title AS gallery, a.original_filename, a.status
FROM assets a
JOIN galleries g ON g.id = a.gallery_id
JOIN studios   s ON s.id = a.studio_id
WHERE a.gallery_id = '11111111-0000-4000-8001-000000000002'
ORDER BY a.position;

-- 3.3
SELECT g.title,
       COUNT(a.id) asset_count
FROM assets a
RIGHT JOIN galleries g ON a.gallery_id = g.id
GROUP BY g.id, g.title
ORDER BY asset_count DESC;

-- 3.4
SELECT g.title,
       g.status
FROM galleries g
LEFT JOIN grants gr ON g.id = gr.gallery_id
WHERE gr.id IS NULL
ORDER BY g.title;

-- 3.5
SELECT a.original_filename,
       a.status
FROM assets a 
LEFT JOIN renditions r ON r.asset_id = a.id AND r.kind = 'preview'
WHERE a.status = 'ready' AND r.id IS NULL;

-- 3.6
SELECT a.id, a.original_filename, array_agg(k.kind ORDER BY k.kind) AS missing
FROM assets a
CROSS JOIN (VALUES ('thumb'), ('grid'), ('preview')) AS k(kind)
LEFT JOIN renditions r ON r.asset_id = a.id AND r.kind = k.kind
WHERE a.status = 'ready' AND r.id IS NULL
GROUP BY a.id, a.original_filename
ORDER BY a.original_filename;