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
