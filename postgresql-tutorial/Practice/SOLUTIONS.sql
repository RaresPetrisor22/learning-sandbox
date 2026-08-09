-- ===========================================================================
-- Solutions to EXERCISES.md
-- ===========================================================================
--
-- One reasonable answer per exercise, not the only one. Where an exercise
-- asks for two approaches, both are here so you can compare them side by
-- side. Anything that writes is wrapped in BEGIN/ROLLBACK so this file is
-- safe to run start to finish -- except Set 10, which needs a second psql
-- session as the application role and is left as commented notes.
--
-- Shorthand used below:
--   S1 = 11111111-1111-1111-1111-111111111111  (Aperture North)
--   S2 = 22222222-2222-2222-2222-222222222222  (Vela Studio)
--   G1 = 11111111-0000-4000-8001-000000000001  etc.
-- ===========================================================================


-- ###########################################################################
-- Set 1 -- SELECT, WHERE, ORDER BY, LIMIT
-- ###########################################################################

-- 1.1
SELECT name, slug, created_at
FROM studios
ORDER BY created_at DESC;

-- 1.2
SELECT email, role
FROM users
ORDER BY email;

-- 1.3  IS NULL, never = NULL.
SELECT email, created_at
FROM users
WHERE email_verified_at IS NULL
ORDER BY created_at;

-- 1.4
SELECT title, status, created_at
FROM galleries
WHERE studio_id = '11111111-1111-1111-1111-111111111111'
  AND status <> 'archived'
ORDER BY created_at DESC;

-- 1.5  (position, id) is the display order the index is built for.
SELECT position, id, original_filename, status
FROM assets
WHERE gallery_id = '11111111-0000-4000-8001-000000000001'
ORDER BY position, id;

-- 1.6
SELECT gallery_id,
       original_filename,
       status,
       round(extract(epoch FROM now() - created_at) / 86400)::int AS age_days
FROM assets
WHERE status NOT IN ('ready', 'processing')
ORDER BY created_at;

-- 1.7  NULL > 5000000 is NULL, so unfinalized rows are filtered out for free.
SELECT original_filename,
       round(size_bytes / 1024.0 / 1024.0, 1) AS mb
FROM assets
WHERE size_bytes > 5 * 1024 * 1024
ORDER BY size_bytes DESC;

-- 1.8
SELECT audience_email, label, expires_at
FROM grants
WHERE expires_at < now()
ORDER BY expires_at;

-- 1.9
SELECT audience_email, label, created_at
FROM grants
WHERE last_seen_at IS NULL;

-- 1.10  three spellings of the same predicate
SELECT original_filename FROM assets WHERE lower(original_filename) LIKE '%.jpg';
SELECT original_filename FROM assets WHERE original_filename ILIKE '%.jpg';
SELECT original_filename FROM assets WHERE original_filename ~* '\.jpg$';
-- ILIKE reads best for a simple suffix; the regex wins the moment the
-- pattern grows a second condition.


-- ###########################################################################
-- Set 2 -- Aggregation
-- ###########################################################################

-- 2.1
SELECT status, count(*) AS n
FROM assets
GROUP BY status
ORDER BY n DESC, status;

-- 2.2
SELECT s.name,
       round(sum(a.size_bytes) / 1024.0 / 1024.0, 1) AS mb
FROM studios s
JOIN assets a ON a.studio_id = s.id
GROUP BY s.name
ORDER BY mb DESC;

-- 2.3  FILTER is the clean way to write a conditional aggregate.
SELECT g.title,
       count(a.id)                                  AS assets,
       count(*) FILTER (WHERE a.status = 'ready')   AS ready,
       round(sum(a.size_bytes) FILTER (WHERE a.status = 'ready')
             / 1024.0 / 1024.0, 1)                  AS ready_mb
FROM galleries g
JOIN assets a ON a.gallery_id = g.id
GROUP BY g.id, g.title
ORDER BY assets DESC;

-- 2.4  HAVING filters groups that exist...
SELECT g.title, count(*) AS n
FROM galleries g
JOIN assets a ON a.gallery_id = g.id
GROUP BY g.id, g.title
HAVING count(*) > 4;
-- ...and a gallery with zero assets produces no group at all under an inner
-- join, so HAVING count(*) = 0 can never match. See 3.3.

-- 2.5
SELECT s.name,
       round(avg(a.size_bytes) / 1024.0 / 1024.0, 2) AS avg_mb,
       round(min(a.size_bytes) / 1024.0 / 1024.0, 2) AS min_mb,
       round(max(a.size_bytes) / 1024.0 / 1024.0, 2) AS max_mb
FROM studios s
JOIN assets a ON a.studio_id = s.id
GROUP BY s.name
ORDER BY s.name;

-- 2.6a  long form
SELECT g.title, a.status, count(*) AS n
FROM galleries g
JOIN assets a ON a.gallery_id = g.id
GROUP BY g.title, a.status
ORDER BY g.title, a.status;

-- 2.6b  pivoted
SELECT g.title,
       count(*) FILTER (WHERE a.status = 'pending')    AS pending,
       count(*) FILTER (WHERE a.status = 'uploaded')   AS uploaded,
       count(*) FILTER (WHERE a.status = 'processing') AS processing,
       count(*) FILTER (WHERE a.status = 'ready')      AS ready,
       count(*) FILTER (WHERE a.status = 'failed')     AS failed,
       count(*) FILTER (WHERE a.status = 'orphaned')   AS orphaned
FROM galleries g
LEFT JOIN assets a ON a.gallery_id = g.id
GROUP BY g.id, g.title
ORDER BY g.title;

-- 2.7  count(*) counts rows; count(col) counts non-null values of col.
SELECT count(*) AS rows_total, count(content_hash) AS with_hash
FROM assets;

-- 2.8
SELECT s.name,
       round(COALESCE((SELECT sum(size_bytes) FROM assets     WHERE studio_id = s.id), 0) / 1024.0 / 1024.0, 1) AS originals_mb,
       round(COALESCE((SELECT sum(size_bytes) FROM renditions WHERE studio_id = s.id), 0) / 1024.0 / 1024.0, 1) AS renditions_mb
FROM studios s
ORDER BY s.name;


-- ###########################################################################
-- Set 3 -- Joins
-- ###########################################################################

-- 3.1
SELECT s.name AS studio, g.title, g.status, g.created_at
FROM galleries g
JOIN studios s ON s.id = g.studio_id
ORDER BY g.created_at DESC;

-- 3.2
SELECT s.name AS studio, g.title AS gallery, a.original_filename, a.status
FROM assets a
JOIN galleries g ON g.id = a.gallery_id
JOIN studios   s ON s.id = a.studio_id
WHERE a.gallery_id = '11111111-0000-4000-8001-000000000002'
ORDER BY a.position;

-- 3.3  LEFT JOIN keeps the empty galleries; count(a.id) counts non-null
-- children, so they land on 0 rather than 1.
SELECT g.title, count(a.id) AS assets
FROM galleries g
LEFT JOIN assets a ON a.gallery_id = g.id
GROUP BY g.id, g.title
ORDER BY assets DESC, g.title;

-- 3.4  anti-join
SELECT g.title, g.status
FROM galleries g
LEFT JOIN grants gr ON gr.gallery_id = g.id
WHERE gr.id IS NULL
ORDER BY g.title;

-- 3.5  the lightbox-will-break query
SELECT g.title, a.original_filename
FROM assets a
JOIN galleries g ON g.id = a.gallery_id
LEFT JOIN renditions r ON r.asset_id = a.id AND r.kind = 'preview'
WHERE a.status = 'ready' AND r.id IS NULL
ORDER BY g.title, a.position;

-- 3.6  which kinds are missing, per asset
SELECT a.id, a.original_filename, array_agg(k.kind ORDER BY k.kind) AS missing
FROM assets a
CROSS JOIN (VALUES ('thumb'), ('grid'), ('preview')) AS k(kind)
LEFT JOIN renditions r ON r.asset_id = a.id AND r.kind = k.kind
WHERE a.status = 'ready' AND r.id IS NULL
GROUP BY a.id, a.original_filename
ORDER BY a.original_filename;

-- 3.7
SELECT u.email
FROM users u
LEFT JOIN sessions se ON se.user_id = u.id
WHERE se.id IS NULL;

-- 3.8
SELECT g.title, gr.audience_email, count(f.id) AS favorites
FROM grants gr
JOIN galleries g ON g.id = gr.gallery_id
LEFT JOIN favorites f ON f.grant_id = gr.id
GROUP BY gr.id, g.title, gr.audience_email
ORDER BY favorites DESC, g.title;

-- 3.9
SELECT s.name AS studio, g.title AS gallery, a.original_filename, gr.audience_email
FROM favorites f
JOIN grants    gr ON gr.id = f.grant_id
JOIN assets    a  ON a.id  = f.asset_id
JOIN galleries g  ON g.id  = a.gallery_id
JOIN studios   s  ON s.id  = f.studio_id
ORDER BY s.name, g.title, a.original_filename;

-- 3.10  self-join: a.id < b.id emits each pair once
SELECT a.original_filename AS file_a, b.original_filename AS file_b, a.content_hash
FROM assets a
JOIN assets b
  ON b.gallery_id = a.gallery_id
 AND b.content_hash = a.content_hash
 AND b.id > a.id;

-- 3.11  the cluster form
SELECT content_hash, count(*) AS copies, array_agg(original_filename ORDER BY original_filename)
FROM assets
WHERE content_hash IS NOT NULL
GROUP BY content_hash
HAVING count(*) > 1;
-- Pairs are what a "merge these two" UI needs; clusters are what a
-- "you uploaded this 4 times" banner needs.


-- ###########################################################################
-- Set 4 -- Subqueries
-- ###########################################################################

-- 4.1
SELECT g.title
FROM galleries g
WHERE EXISTS (SELECT 1 FROM assets a WHERE a.gallery_id = g.id AND a.status = 'failed');

-- 4.2  same answer, three shapes
SELECT title FROM galleries
WHERE id IN (SELECT gallery_id FROM assets WHERE status = 'failed');

SELECT DISTINCT g.title
FROM galleries g JOIN assets a ON a.gallery_id = g.id
WHERE a.status = 'failed';
-- Note the DISTINCT the join needs and the other two do not: EXISTS and IN
-- ask a yes/no question, a join multiplies rows.

-- 4.3
SELECT a.original_filename
FROM assets a
WHERE NOT EXISTS (SELECT 1 FROM favorites f WHERE f.asset_id = a.id)
ORDER BY a.original_filename;

-- 4.4
SELECT original_filename FROM assets
WHERE id NOT IN (SELECT asset_id FROM favorites);

SELECT 1 WHERE 3 NOT IN (1, 2, NULL);
-- Returns no row: 3 <> NULL is UNKNOWN, not TRUE, so the AND-chain behind
-- NOT IN can never be TRUE -- it is UNKNOWN, and WHERE only passes TRUE.
-- One NULL in the subquery makes NOT IN return nothing, silently.

-- 4.5  cover asset per gallery
SELECT g.title, cover.id, cover.original_filename
FROM galleries g
LEFT JOIN LATERAL (
  SELECT a.id, a.original_filename
  FROM assets a
  WHERE a.gallery_id = g.id AND a.status = 'ready'
  ORDER BY a.position, a.id
  LIMIT 1
) AS cover ON true
ORDER BY g.title;

-- 4.6  top 3 newest per studio, LATERAL flavour
SELECT s.name, t.original_filename, t.created_at
FROM studios s
LEFT JOIN LATERAL (
  SELECT a.original_filename, a.created_at
  FROM assets a
  WHERE a.studio_id = s.id
  ORDER BY a.created_at DESC, a.id
  LIMIT 3
) AS t ON true
ORDER BY s.name, t.created_at DESC;

-- 4.7
SELECT g.title,
       (SELECT count(*)
        FROM favorites f
        JOIN assets a ON a.id = f.asset_id
        WHERE a.gallery_id = g.id) AS favorite_count
FROM galleries g
ORDER BY favorite_count DESC, g.title;

-- 4.8
SELECT gr.audience_email, g.title
FROM grants gr
JOIN galleries g ON g.id = gr.gallery_id
WHERE EXISTS (
  SELECT 1 FROM assets a
  WHERE a.gallery_id = gr.gallery_id AND a.status <> 'ready'
)
ORDER BY g.title;


-- ###########################################################################
-- Set 5 -- Expressions
-- ###########################################################################

-- 5.1
SELECT CASE
         WHEN expires_at < now()                      THEN 'expired'
         WHEN expires_at < now() + interval '7 days'  THEN 'expiring soon'
         ELSE 'active'
       END AS bucket,
       count(*)
FROM grants
GROUP BY 1
ORDER BY 2 DESC;

-- 5.2  epoch/86400 keeps the fractional part; extract(day ...) throws it away
SELECT audience_email,
       extract(day FROM expires_at - now())::int          AS whole_days_only,
       floor(extract(epoch FROM expires_at - now()) / 86400)::int AS days_remaining
FROM grants
ORDER BY days_remaining;

-- 5.3
SELECT original_filename,
       COALESCE(width::text || '×' || height::text, 'unknown') AS dimensions
FROM assets
ORDER BY original_filename;
-- COALESCE works here because width::text || ... is NULL if either side is.

-- 5.4
SELECT original_filename,
       CASE
         WHEN width IS NULL OR height IS NULL THEN 'unknown'
         WHEN width > height                  THEN 'landscape'
         WHEN width < height                  THEN 'portrait'
         ELSE                                      'square'
       END AS orientation
FROM assets
ORDER BY orientation, original_filename;

-- 5.5
SELECT original_filename, round(width * height / 1e6, 1) AS megapixels
FROM assets
WHERE width IS NOT NULL
ORDER BY megapixels DESC;

SELECT g.title, round(avg(a.width * a.height) / 1e6, 1) AS avg_mp
FROM galleries g JOIN assets a ON a.gallery_id = g.id
WHERE a.width IS NOT NULL
GROUP BY g.title
ORDER BY avg_mp DESC;

-- 5.6
SELECT to_char(created_at AT TIME ZONE 'UTC',              'YYYY-MM-DD HH24:MI') AS utc,
       to_char(created_at AT TIME ZONE 'Europe/Bucharest',  'YYYY-MM-DD HH24:MI') AS bucharest
FROM assets
ORDER BY created_at DESC
LIMIT 5;
-- The stored value is one instant. AT TIME ZONE only chooses the wall clock
-- you render it against -- which is exactly why the column is timestamptz and
-- never timestamp: a naked timestamp would have thrown the instant away.

-- 5.7
SELECT date_trunc('week', created_at)::date AS week, count(*)
FROM assets
GROUP BY 1
ORDER BY 1 DESC;

-- 5.8
SELECT lower(split_part(original_filename, '.', 2)) AS ext, count(*)
FROM assets
GROUP BY 1 ORDER BY 2 DESC;
-- More robust when a filename contains several dots:
SELECT lower(regexp_replace(original_filename, '^.*\.', '')) AS ext, count(*)
FROM assets
GROUP BY 1 ORDER BY 2 DESC;

-- 5.9
SELECT storage_key,
       split_part(storage_key, '/', -1)              AS basename_split,
       regexp_replace(storage_key, '^.*/', '')       AS basename_regexp
FROM assets
LIMIT 5;
SELECT version();

-- 5.10
SELECT u.email,
       s.expires_at < now()                                            AS expired,
       floor(extract(epoch FROM now() - s.last_seen_at) / 3600)::int   AS hours_idle,
       CASE WHEN s.ip IS NULL THEN NULL
            ELSE host(network(set_masklen(s.ip, 24))) || '/24' END     AS ip_net
FROM sessions s
JOIN users u ON u.id = s.user_id
ORDER BY s.last_seen_at DESC;


-- ###########################################################################
-- Set 6 -- Window functions
-- ###########################################################################

-- 6.1
SELECT gallery_id,
       row_number() OVER (PARTITION BY gallery_id ORDER BY position, id) AS n,
       position, original_filename
FROM assets
ORDER BY gallery_id, n;

-- 6.2
SELECT position,
       original_filename,
       row_number() OVER w AS rn,
       rank()       OVER w AS rnk,
       dense_rank() OVER w AS drnk
FROM assets
WHERE gallery_id = '11111111-0000-4000-8001-000000000001'
WINDOW w AS (ORDER BY position)
ORDER BY position;
-- At the tied position 3: row_number gives 3 and 4 arbitrarily, rank gives
-- 3 and 3 then skips to 5, dense_rank gives 3 and 3 then 4. Ties are only
-- arbitrary because the ORDER BY is incomplete -- add id and row_number
-- becomes deterministic, which is the whole argument for the (position, id)
-- index.

-- 6.3  you cannot put a window function in WHERE: it is computed after WHERE
WITH ranked AS (
  SELECT studio_id, original_filename, size_bytes,
         row_number() OVER (PARTITION BY studio_id ORDER BY size_bytes DESC NULLS LAST) AS rn
  FROM assets
)
SELECT s.name, r.original_filename, r.size_bytes
FROM ranked r JOIN studios s ON s.id = r.studio_id
WHERE r.rn <= 3
ORDER BY s.name, r.rn;

-- 6.4
SELECT s.name, a.created_at, a.size_bytes,
       sum(a.size_bytes) OVER (PARTITION BY a.studio_id ORDER BY a.created_at, a.id) AS running_bytes
FROM assets a JOIN studios s ON s.id = a.studio_id
WHERE a.size_bytes IS NOT NULL
ORDER BY s.name, a.created_at;

-- 6.5
SELECT gallery_id, original_filename, created_at,
       created_at - lag(created_at) OVER (PARTITION BY gallery_id ORDER BY created_at, id) AS gap
FROM assets
ORDER BY gallery_id, created_at;

-- 6.6
SELECT gallery_id, original_filename,
       round(100 * size_bytes::numeric
             / sum(size_bytes) OVER (PARTITION BY gallery_id), 1) AS pct_of_gallery
FROM assets
WHERE size_bytes IS NOT NULL
ORDER BY gallery_id, pct_of_gallery DESC;

-- 6.7
SELECT gallery_id, position, original_filename,
       first_value(original_filename) OVER w                    AS first_in_gallery,
       last_value(original_filename)  OVER w                    AS last_wrong,
       last_value(original_filename)  OVER (PARTITION BY gallery_id ORDER BY position, id
                                            ROWS BETWEEN UNBOUNDED PRECEDING
                                                     AND UNBOUNDED FOLLOWING) AS last_right
FROM assets
WINDOW w AS (PARTITION BY gallery_id ORDER BY position, id)
ORDER BY gallery_id, position;
-- The default frame with an ORDER BY is RANGE UNBOUNDED PRECEDING TO CURRENT
-- ROW, so last_value sees only up to the current row -- it returns the
-- current row. Widening the frame is what makes it mean "last of the group".

-- 6.8
SELECT g.title, gr.audience_email, gr.last_seen_at,
       row_number() OVER (PARTITION BY gr.gallery_id
                          ORDER BY gr.last_seen_at DESC NULLS LAST) AS recency_rank
FROM grants gr JOIN galleries g ON g.id = gr.gallery_id
ORDER BY g.title, recency_rank;


-- ###########################################################################
-- Set 7 -- CTEs, set operations, pagination
-- ###########################################################################

-- 7.1  see 6.3 -- already written as a CTE, which is the point.

-- 7.2a
SELECT asset_id FROM favorites WHERE grant_id = '11111111-0000-4000-8004-000000000003'
INTERSECT
SELECT asset_id FROM favorites WHERE grant_id = '11111111-0000-4000-8004-000000000004';

-- 7.2b  generalises to "picked by at least N of the grants on this gallery"
SELECT f.asset_id, a.original_filename, count(DISTINCT f.grant_id) AS voters
FROM favorites f
JOIN assets a ON a.id = f.asset_id
WHERE a.gallery_id = '11111111-0000-4000-8001-000000000002'
GROUP BY f.asset_id, a.original_filename
HAVING count(DISTINCT f.grant_id) = 2;

-- 7.3
SELECT asset_id FROM favorites WHERE grant_id = '11111111-0000-4000-8004-000000000003'
EXCEPT
SELECT asset_id FROM favorites WHERE grant_id = '11111111-0000-4000-8004-000000000004';

-- 7.4  UNION ALL, because UNION would deduplicate and pay for a sort to do it
SELECT 'asset uploaded' AS kind, a.created_at AS at, a.original_filename AS subject
FROM assets a WHERE a.studio_id = '11111111-1111-1111-1111-111111111111'
UNION ALL
SELECT 'grant issued', gr.created_at, gr.audience_email
FROM grants gr WHERE gr.studio_id = '11111111-1111-1111-1111-111111111111'
UNION ALL
SELECT 'favorite added', f.created_at, a.original_filename
FROM favorites f JOIN assets a ON a.id = f.asset_id
WHERE f.studio_id = '11111111-1111-1111-1111-111111111111'
ORDER BY at DESC
LIMIT 15;

-- 7.5  page 1
SELECT position, id, original_filename
FROM assets
WHERE gallery_id = '11111111-0000-4000-8001-000000000001'
ORDER BY position, id
LIMIT 3;

-- 7.6  page 2, keyset. The cursor is the last row of page 1: (3, ...0003).
SELECT position, id, original_filename
FROM assets
WHERE gallery_id = '11111111-0000-4000-8001-000000000001'
  AND (position, id) > (3, '11111111-0000-4000-8002-000000000003'::uuid)
ORDER BY position, id
LIMIT 3;
-- The row-value comparison is the trick: (position, id) > (3, X) means
-- "position > 3, OR position = 3 and id > X". A naive `position > 3` would
-- skip the second asset sitting at position 3.

-- 7.7  page 2, offset
SELECT position, id, original_filename
FROM assets
WHERE gallery_id = '11111111-0000-4000-8001-000000000001'
ORDER BY position, id
OFFSET 3 LIMIT 3;
-- Same answer today. Insert an asset at position 1 between the two requests
-- and OFFSET 3 re-counts from a shifted list: the row that was last on page 1
-- reappears as the first row of page 2. The keyset version is immune, because
-- its cursor names a row rather than a count -- and it stays O(log n) instead
-- of scanning and discarding OFFSET rows.

-- 7.8
WITH asset_stats AS (
  SELECT gallery_id,
         count(*)                                AS assets,
         count(*) FILTER (WHERE status='ready')  AS ready,
         COALESCE(sum(size_bytes), 0)            AS bytes
  FROM assets GROUP BY gallery_id
),
grant_stats AS (
  SELECT gallery_id, count(*) AS grants FROM grants GROUP BY gallery_id
),
favorite_stats AS (
  SELECT a.gallery_id, count(*) AS favorites
  FROM favorites f JOIN assets a ON a.id = f.asset_id
  GROUP BY a.gallery_id
)
SELECT g.title, g.status,
       COALESCE(a.assets, 0)                        AS assets,
       COALESCE(a.ready, 0)                         AS ready,
       round(COALESCE(a.bytes, 0)/1024.0/1024.0, 1) AS mb,
       COALESCE(gs.grants, 0)                       AS grants,
       COALESCE(fs.favorites, 0)                    AS favorites
FROM galleries g
LEFT JOIN asset_stats    a  ON a.gallery_id  = g.id
LEFT JOIN grant_stats    gs ON gs.gallery_id = g.id
LEFT JOIN favorite_stats fs ON fs.gallery_id = g.id
ORDER BY g.created_at DESC;

-- 7.9  dense series: the generate_series is the spine, the data hangs off it
WITH days AS (
  SELECT generate_series(current_date - 13, current_date, interval '1 day')::date AS day
)
SELECT d.day, count(a.id) AS uploads
FROM days d
LEFT JOIN assets a
  ON a.created_at::date = d.day
 AND a.studio_id = '11111111-1111-1111-1111-111111111111'
GROUP BY d.day
ORDER BY d.day;


-- ###########################################################################
-- Set 8 -- The rights bitmask
-- ###########################################################################

-- 8.1
SELECT audience_email, rights_mask FROM grants WHERE rights_mask & 2 <> 0;

-- 8.2
SELECT audience_email, rights_mask FROM grants WHERE rights_mask & 4 <> 0;

-- 8.3
SELECT audience_email FROM grants WHERE rights_mask = 1;
-- `rights_mask & 1 <> 0` asks "may view"; `= 1` asks "may ONLY view".

-- 8.4
SELECT audience_email,
       (rights_mask & 1) <> 0 AS can_view,
       (rights_mask & 2) <> 0 AS can_download,
       (rights_mask & 4) <> 0 AS can_favorite
FROM grants
ORDER BY audience_email;

-- 8.5
SELECT audience_email,
       array_remove(ARRAY[
         CASE WHEN rights_mask & 1 <> 0 THEN 'view'     END,
         CASE WHEN rights_mask & 2 <> 0 THEN 'download' END,
         CASE WHEN rights_mask & 4 <> 0 THEN 'favorite' END
       ], NULL) AS rights
FROM grants
ORDER BY audience_email;

-- 8.6
SELECT array_remove(ARRAY[
         CASE WHEN rights_mask & 1 <> 0 THEN 'view'     END,
         CASE WHEN rights_mask & 2 <> 0 THEN 'download' END,
         CASE WHEN rights_mask & 4 <> 0 THEN 'favorite' END
       ], NULL) AS rights,
       count(*) AS n
FROM grants
GROUP BY 1
ORDER BY n DESC;

-- 8.7  expected: zero rows, and that is the answer
SELECT gr.audience_email, g.title
FROM grants gr JOIN galleries g ON g.id = gr.gallery_id
WHERE gr.rights_mask & 4 <> 0 AND g.status = 'archived';

-- 8.8  set a bit without disturbing the others
BEGIN;
UPDATE grants
SET rights_mask = rights_mask | 2
WHERE gallery_id = '11111111-0000-4000-8001-000000000002'
RETURNING audience_email, rights_mask;
ROLLBACK;


-- ###########################################################################
-- Set 9 -- Writing data  (everything here rolls back)
-- ###########################################################################

-- 9.1
BEGIN;
INSERT INTO galleries (studio_id, title)
VALUES ('22222222-2222-2222-2222-222222222222', 'Kestrel Portraits')
RETURNING id, title, status, created_at;
ROLLBACK;

-- 9.2 / 9.3 / 9.4  the presign -> finalize lifecycle
BEGIN;
INSERT INTO assets (gallery_id, studio_id, storage_key, original_filename)
VALUES ('22222222-0000-4000-8001-000000000005',
        '22222222-2222-2222-2222-222222222222',
        'studios/vela/originals/practice.jpg',
        'practice.jpg')
RETURNING id, status, content_type, size_bytes, created_at, updated_at;

UPDATE assets
SET status       = 'uploaded',
    content_type = 'image/jpeg',
    content_hash = repeat('ab', 32),
    size_bytes   = 3145728,
    width        = 4000,
    height       = 3000
WHERE original_filename = 'practice.jpg'
RETURNING id, status, created_at, updated_at;
-- updated_at moved even though the UPDATE never named it: that is the
-- assets_set_updated_at trigger.

-- 9.4  rejected by CHECK (content_type LIKE 'image/%')
-- UPDATE assets SET content_type = 'application/pdf'
-- WHERE original_filename = 'practice.jpg';
ROLLBACK;

-- 9.5  idempotent heart -- the UNIQUE (grant_id, asset_id) index is the
-- conflict target, and it exists precisely so this is one statement.
BEGIN;
INSERT INTO favorites (grant_id, asset_id, studio_id)
VALUES ('11111111-0000-4000-8004-000000000004',
        '11111111-0000-4000-8002-000000000009',
        '11111111-1111-1111-1111-111111111111')
ON CONFLICT (grant_id, asset_id) DO NOTHING;
-- run the identical statement again: INSERT 0 0
INSERT INTO favorites (grant_id, asset_id, studio_id)
VALUES ('11111111-0000-4000-8004-000000000004',
        '11111111-0000-4000-8002-000000000009',
        '11111111-1111-1111-1111-111111111111')
ON CONFLICT (grant_id, asset_id) DO NOTHING;
ROLLBACK;

-- 9.6
BEGIN;
DELETE FROM favorites
WHERE grant_id = '11111111-0000-4000-8004-000000000003'
  AND asset_id = '11111111-0000-4000-8002-000000000009'
RETURNING *;
ROLLBACK;

-- 9.7  make room at position 3, then insert there
BEGIN;
UPDATE assets
SET position = position + 1
WHERE gallery_id = '11111111-0000-4000-8001-000000000001' AND position >= 3;

INSERT INTO assets (gallery_id, studio_id, storage_key, original_filename, position)
VALUES ('11111111-0000-4000-8001-000000000001',
        '11111111-1111-1111-1111-111111111111',
        'studios/aperture-north/originals/inserted.jpg', 'inserted.jpg', 3);

SELECT position, original_filename FROM assets
WHERE gallery_id = '11111111-0000-4000-8001-000000000001'
ORDER BY position, id;
ROLLBACK;
-- Racy without SELECT ... FOR UPDATE or a serializable transaction: two
-- concurrent reorders can interleave and produce duplicate positions.

-- 9.8  the orphan sweep
BEGIN;
UPDATE assets
SET status = 'orphaned'
WHERE status = 'pending' AND created_at < now() - interval '1 day'
RETURNING id, original_filename, created_at;
ROLLBACK;

-- 9.9  DELETE ... USING to reach the joined table
BEGIN;
DELETE FROM sessions s
USING users u
WHERE u.id = s.user_id AND s.expires_at < now()
RETURNING s.id, u.email, s.expires_at;
ROLLBACK;

-- 9.10  revoke = bump the epoch
BEGIN;
UPDATE grants
SET revocation_epoch = revocation_epoch + 1
WHERE id = '11111111-0000-4000-8004-000000000001'
RETURNING audience_email, revocation_epoch;
ROLLBACK;
-- A DELETE would destroy the record of what was shared with whom, and the
-- audit question "who had access to this gallery in March" is exactly the one
-- you get asked after something leaks.

-- 9.11  cascade tour
BEGIN;
SELECT (SELECT count(*) FROM assets     WHERE studio_id = '22222222-2222-2222-2222-222222222222') AS assets,
       (SELECT count(*) FROM renditions WHERE studio_id = '22222222-2222-2222-2222-222222222222') AS renditions,
       (SELECT count(*) FROM grants     WHERE studio_id = '22222222-2222-2222-2222-222222222222') AS grants,
       (SELECT count(*) FROM favorites  WHERE studio_id = '22222222-2222-2222-2222-222222222222') AS favorites;

DELETE FROM studios WHERE id = '22222222-2222-2222-2222-222222222222';

SELECT (SELECT count(*) FROM assets     WHERE studio_id = '22222222-2222-2222-2222-222222222222') AS assets,
       (SELECT count(*) FROM renditions WHERE studio_id = '22222222-2222-2222-2222-222222222222') AS renditions,
       (SELECT count(*) FROM grants     WHERE studio_id = '22222222-2222-2222-2222-222222222222') AS grants,
       (SELECT count(*) FROM favorites  WHERE studio_id = '22222222-2222-2222-2222-222222222222') AS favorites;
ROLLBACK;
-- studios -> galleries -> assets -> renditions/favorites, and
-- galleries -> grants -> favorites. Every hop is ON DELETE CASCADE.

-- 9.12  constraint tour -- each of these should fail. Run them one at a time.
-- BEGIN;
-- INSERT INTO users (studio_id, email, password_hash)
--   VALUES ('11111111-1111-1111-1111-111111111111', 'Loud@Example.com', 'x');
--   -- users_email_check: email = lower(email)
-- INSERT INTO studios (name, slug) VALUES ('Nope', 'Not A Slug');
--   -- studios_slug_check: the slug regex
-- INSERT INTO sessions (id, user_id, studio_id, expires_at)
--   VALUES (repeat('z', 63), '11111111-0000-4000-8000-000000000001',
--           '11111111-1111-1111-1111-111111111111', now() + interval '1 day');
--   -- sessions_id_check: length(id) = 64
-- UPDATE grants SET rights_mask = 8 WHERE id = '11111111-0000-4000-8004-000000000001';
--   -- grants_rights_mask_check: 0 < mask < 8
-- INSERT INTO favorites (grant_id, asset_id, studio_id)
--   VALUES ('11111111-0000-4000-8004-000000000003',      -- studio 1 grant
--           '22222222-0000-4000-8002-000000000021',      -- studio 2 asset
--           '11111111-1111-1111-1111-111111111111');
--   -- FK violation on (asset_id, studio_id): the pair does not exist in
--   -- assets. No single-column constraint could have caught this -- the
--   -- composite foreign key is what makes cross-tenant favorites impossible.
-- ROLLBACK;


-- ###########################################################################
-- Set 10 -- RLS, EXPLAIN, JSON
-- ###########################################################################
--
-- 10.1 - 10.6 need a session as the APPLICATION role. Connect with the app
-- credentials from docker/postgres/init/01-create-app-role.sh, then:
--
--   SELECT count(*) FROM galleries;                 -- 0: no tenant set
--   SET app.studio_id = '11111111-1111-1111-1111-111111111111';
--   SELECT count(*) FROM galleries;                 -- 4
--   SET app.studio_id = '22222222-2222-2222-2222-222222222222';
--   SELECT count(*) FROM galleries;                 -- 3
--
-- 10.1  Zero rows, not an error: a policy is a filter, not a permission
--       check. That is why RLS is a safety net and not a substitute for the
--       repository layer refusing to build a query without tenant context --
--       a silent empty result is a bug that looks like "no data yet".
--
-- 10.3  SET LOCAL, inside a transaction:
--         BEGIN;
--         SET LOCAL app.studio_id = '11111111-1111-1111-1111-111111111111';
--         SELECT count(*) FROM galleries;   -- 4
--         COMMIT;
--         SELECT count(*) FROM galleries;   -- 0, the setting is gone
--       With a pooled connection, a plain SET outlives the request and the
--       next request to borrow that connection inherits the previous
--       tenant's context. That is a cross-tenant data leak with a one-word
--       cause: LOCAL.
--
-- 10.4  INSERT INTO galleries (studio_id, title)
--         VALUES ('22222222-...', 'oops');
--       -> new row violates row-level security policy for table "galleries"
--       The WITH CHECK half stops it. USING filters what you can read;
--       without WITH CHECK you could not see studio 2's rows but could still
--       write rows tagged with its id.
--
-- 10.5  SELECT returns zero rows; UPDATE reports UPDATE 0. You cannot target
--       what the USING clause has already filtered away.
--
-- 10.6  SELECT current_studio_id();  -- NULL
--       current_setting('app.studio_id', true) -- the `true` is
--       missing_ok: without it, an unset GUC raises instead of returning
--       NULL, and every query on an unauthenticated connection would error
--       instead of returning nothing.

-- 10.7
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, storage_key, position FROM assets
WHERE gallery_id = '11111111-0000-4000-8001-000000000001'
ORDER BY position, id LIMIT 20;

SET enable_seqscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, storage_key, position FROM assets
WHERE gallery_id = '11111111-0000-4000-8001-000000000001'
ORDER BY position, id LIMIT 20;
RESET enable_seqscan;
-- With the index forced, the plan is an Index Scan with no Sort node: the
-- index is already in (gallery_id, position, id) order, so ORDER BY is free.
-- On 27 rows the planner is right to ignore it -- one heap page beats any
-- index. Plans are a function of the data, which is why you profile against
-- production-shaped volumes, not against a seed file.

-- 10.8
EXPLAIN
SELECT * FROM assets
WHERE status = 'pending' AND created_at < now() - interval '1 day';
-- assets_pending_created_idx is partial: WHERE status = 'pending'. It
-- indexes the handful of uploads in flight rather than every asset ever
-- uploaded, so it stays tiny and cache-resident. The cost is on the write
-- side: finalizing an asset deletes its entry from the index -- which is
-- exactly the behaviour you want, since a finalized asset is never a sweep
-- candidate again.

-- 10.9  the whole client payload in one round trip
SELECT json_build_object(
  'id',     g.id,
  'title',  g.title,
  'status', g.status,
  'assets', COALESCE((
     SELECT json_agg(json_build_object(
              'id',         a.id,
              'filename',   a.original_filename,
              'width',      a.width,
              'height',     a.height,
              'blurhash',   a.blurhash,
              'renditions', COALESCE((
                 SELECT json_agg(json_build_object('kind', r.kind,
                                                   'key',  r.storage_key,
                                                   'w',    r.width,
                                                   'h',    r.height)
                                 ORDER BY r.kind)
                 FROM renditions r WHERE r.asset_id = a.id), '[]'::json)
            ) ORDER BY a.position, a.id)
     FROM assets a
     WHERE a.gallery_id = g.id AND a.status = 'ready'), '[]'::json)
) AS payload
FROM galleries g
WHERE g.id = '11111111-0000-4000-8001-000000000001';

-- 10.10
SELECT jsonb_pretty(payload::jsonb) FROM (
  SELECT json_build_object('id', g.id, 'title', g.title) AS payload
  FROM galleries g WHERE g.id = '11111111-0000-4000-8001-000000000001'
) t;
-- Worth knowing both. In the API layer the shape is typed, testable and
-- reviewable; in SQL it is one round trip and no N+1. A reasonable rule:
-- aggregate in SQL when the alternative is N+1 queries, and shape in the API
-- when the alternative is business logic hiding in a string.

-- 10.11
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'assets';
-- assets_pkey                  -> lookup by id, and the FK targets
-- assets_id_studio_id_key      -> the composite FK target for renditions and
--                                 favorites (exercise 9.12's last case)
-- assets_gallery_position_idx  -> 1.5, 7.5, 7.6, 10.7 -- the gallery grid
-- assets_pending_created_idx   -> 9.8, 10.8 -- the orphan sweep

-- 10.12
SELECT tablename, policyname, cmd, qual, with_check
FROM pg_policies WHERE schemaname = 'public'
ORDER BY tablename;
-- Eight policies, one per table, each FOR ALL with both halves populated.
-- studios is the odd one: its qual reads `id = current_studio_id()` because
-- it is the tenant rather than a child of one.
