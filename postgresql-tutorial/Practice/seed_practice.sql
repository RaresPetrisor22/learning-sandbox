-- ===========================================================================
-- Pixhaus SQL practice seed
-- ===========================================================================
--
-- Deterministic sample data for practising queries against
-- migrations/0001_initial_schema.sql. Every id is a hand-written uuid so the
-- exercises can refer to rows by name, and every timestamp is expressed
-- relative to now() so "expired", "stale" and "last 30 days" stay true
-- whenever you run this.
--
-- ---------------------------------------------------------------------------
-- HOW TO LOAD IT
-- ---------------------------------------------------------------------------
--
-- Run this as the DATABASE OWNER (the role the migration runner uses), not as
-- the application role. The owner bypasses the row-level security policies at
-- the bottom of the migration; the app role does not, so a plain load as the
-- app role would insert nothing visible and would be rejected by the
-- WITH CHECK clauses the moment app.studio_id disagrees with a row.
--
--     psql "$DATABASE_URL" -f packages/db/practice/seed_practice.sql
--
-- While practising, you can also work as the owner and ignore RLS entirely --
-- it is off for you. Exercise set 10 is where you deliberately turn it back on
-- by connecting as the app role.
--
-- ---------------------------------------------------------------------------
-- ID SCHEME  (so you can read a uuid and know what it is)
-- ---------------------------------------------------------------------------
--
--   <tenant>-0000-4000-<kind>-<counter>
--
--   tenant : 11111111 = Aperture North, 22222222 = Vela Studio,
--            33333333 = Harbor Light
--   kind   : 8000 users     8001 galleries  8002 assets
--            8004 grants    8005 favorites
--
-- Studios themselves are 11111111-1111-... , 22222222-2222-... , etc.
-- Rendition ids are generated -- you never need to name one.
--
-- ---------------------------------------------------------------------------
-- WHAT IS DELIBERATELY WEIRD IN THIS DATA  (each quirk is an exercise)
-- ---------------------------------------------------------------------------
--
--   * three tenants, two of them busy, one nearly empty
--   * two assets in gallery G1 share position 3      -> keyset pagination
--   * two assets in gallery G6 share a content_hash  -> duplicate detection
--   * some ready assets are missing a 'preview'      -> anti-joins
--   * one gallery has no assets, one has no grants   -> LEFT JOIN vs INNER
--   * a pending asset is 40 days old                 -> orphan sweep
--   * grants: expired, revoked (epoch > 0), never opened, selection submitted
--   * one user has never had a session                -> NOT EXISTS
--   * favorites overlap between two grants            -> consensus picks
--
-- ---------------------------------------------------------------------------
-- RESET
-- ---------------------------------------------------------------------------
--
-- Deleting the three studios cascades to everything else:
--
--     DELETE FROM studios WHERE slug IN
--       ('aperture-north', 'vela-studio', 'harbor-light');
--
-- ===========================================================================

BEGIN;

-- Idempotent: wipe any previous load of this seed before inserting.
DELETE FROM studios WHERE slug IN ('aperture-north', 'vela-studio', 'harbor-light');


-- ===========================================================================
-- 1. studios
-- ===========================================================================

INSERT INTO studios (id, name, slug, created_at, updated_at) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Aperture North',    'aperture-north', now() - interval '420 days', now() - interval '30 days'),
  ('22222222-2222-2222-2222-222222222222', 'Vela Studio',       'vela-studio',    now() - interval '160 days', now() - interval '5 days'),
  ('33333333-3333-3333-3333-333333333333', 'Harbor Light Photo','harbor-light',   now() - interval '95 days',  now() - interval '95 days');


-- ===========================================================================
-- 2. users
-- ===========================================================================
--
-- u3 (the intern) and u5 (Luc) have never verified their email.
-- u3 has never had a session at all.

INSERT INTO users (id, studio_id, email, password_hash, role, email_verified_at, created_at, updated_at) VALUES
  ('11111111-0000-4000-8000-000000000001', '11111111-1111-1111-1111-111111111111', 'maya@aperturenorth.example.com',   '$argon2id$v=19$m=65536,t=3,p=4$c2VlZHNhbHQwMQ$aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'owner',  now() - interval '419 days', now() - interval '420 days', now() - interval '90 days'),
  ('11111111-0000-4000-8000-000000000002', '11111111-1111-1111-1111-111111111111', 'theo@aperturenorth.example.com',   '$argon2id$v=19$m=65536,t=3,p=4$c2VlZHNhbHQwMg$bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', 'member', now() - interval '299 days', now() - interval '300 days', now() - interval '60 days'),
  ('11111111-0000-4000-8000-000000000003', '11111111-1111-1111-1111-111111111111', 'intern@aperturenorth.example.com', '$argon2id$v=19$m=65536,t=3,p=4$c2VlZHNhbHQwMw$cccccccccccccccccccccccccccccccc', 'member', NULL,                        now() - interval '10 days',  now() - interval '10 days'),

  ('22222222-0000-4000-8000-000000000001', '22222222-2222-2222-2222-222222222222', 'sofia@velastudio.example.com',     '$argon2id$v=19$m=65536,t=3,p=4$c2VlZHNhbHQwNA$dddddddddddddddddddddddddddddddd', 'owner',  now() - interval '159 days', now() - interval '160 days', now() - interval '20 days'),
  ('22222222-0000-4000-8000-000000000002', '22222222-2222-2222-2222-222222222222', 'luc@velastudio.example.com',       '$argon2id$v=19$m=65536,t=3,p=4$c2VlZHNhbHQwNQ$eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee', 'member', NULL,                        now() - interval '3 days',   now() - interval '3 days'),

  ('33333333-0000-4000-8000-000000000001', '33333333-3333-3333-3333-333333333333', 'nils@harborlight.example.com',     '$argon2id$v=19$m=65536,t=3,p=4$c2VlZHNhbHQwNg$ffffffffffffffffffffffffffffffff', 'owner',  now() - interval '94 days',  now() - interval '95 days',  now() - interval '95 days');


-- ===========================================================================
-- 3. sessions
-- ===========================================================================
--
-- sessions.id is CHECK (length(id) = 64), so the ids are built with repeat()
-- rather than typed out: repeat('a1', 32) is 64 characters and each two-char
-- pattern gives a distinct id.
--
-- Three of these are already expired. u3 has none.

INSERT INTO sessions (id, user_id, studio_id, ip, user_agent, created_at, last_seen_at, expires_at) VALUES
  (repeat('a1', 32), '11111111-0000-4000-8000-000000000001', '11111111-1111-1111-1111-111111111111', '203.0.113.10',  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Safari/605.1.15', now() - interval '2 days',  now() - interval '3 hours',  now() + interval '12 days'),
  (repeat('a2', 32), '11111111-0000-4000-8000-000000000001', '11111111-1111-1111-1111-111111111111', '203.0.113.11',  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5) Safari/604.1',           now() - interval '1 day',   now() - interval '20 minutes', now() + interval '13 days'),
  (repeat('a3', 32), '11111111-0000-4000-8000-000000000001', '11111111-1111-1111-1111-111111111111', '203.0.113.10',  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Safari/605.1.15', now() - interval '40 days', now() - interval '35 days',  now() - interval '5 days'),
  (repeat('b1', 32), '11111111-0000-4000-8000-000000000002', '11111111-1111-1111-1111-111111111111', '198.51.100.7',  'Mozilla/5.0 (X11; Linux x86_64) Firefox/127.0',                   now() - interval '6 hours', now() - interval '5 minutes', now() + interval '14 days'),
  (repeat('b2', 32), '11111111-0000-4000-8000-000000000002', '11111111-1111-1111-1111-111111111111', NULL,            NULL,                                                              now() - interval '90 days', now() - interval '80 days',  now() - interval '76 days'),
  (repeat('c1', 32), '22222222-0000-4000-8000-000000000001', '22222222-2222-2222-2222-222222222222', '2001:db8::42',  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/126.0',          now() - interval '4 days',  now() - interval '1 hour',   now() + interval '10 days'),
  (repeat('c2', 32), '22222222-0000-4000-8000-000000000002', '22222222-2222-2222-2222-222222222222', '198.51.100.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/125.0',          now() - interval '3 days',  now() - interval '3 days',   now() - interval '2 days'),
  (repeat('d1', 32), '33333333-0000-4000-8000-000000000001', '33333333-3333-3333-3333-333333333333', '192.0.2.55',    'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) Chrome/126.0',       now() - interval '9 days',  now() - interval '9 days',   now() + interval '5 days');


-- ===========================================================================
-- 4. galleries
-- ===========================================================================
--
--   G1 Marlow Wedding -- Full Set   active,   8 assets, 2 grants
--   G2 Marlow Wedding -- Proofs     active,   5 assets, 2 grants (proofing)
--   G3 Okonkwo Family Session       draft,    4 assets, 1 grant
--   G4 Brand Shoot: Fjord Coffee    archived, 3 assets, 1 expired grant
--   G5 Ramos Engagement             active,   4 assets, 2 grants
--   G6 Product -- Aster Ceramics    active,   3 assets, 1 expired grant
--   G7 Untitled gallery             draft,    0 assets, 0 grants
--   G8 Sample gallery               draft,    0 assets, 0 grants  (studio 3)

INSERT INTO galleries (id, studio_id, title, status, created_at, updated_at) VALUES
  ('11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', 'Marlow Wedding — Full Set',   'active',   now() - interval '60 days', now() - interval '55 days'),
  ('11111111-0000-4000-8001-000000000002', '11111111-1111-1111-1111-111111111111', 'Marlow Wedding — Proofs',     'active',   now() - interval '58 days', now() - interval '3 days'),
  ('11111111-0000-4000-8001-000000000003', '11111111-1111-1111-1111-111111111111', 'Okonkwo Family Session',      'draft',    now() - interval '41 days', now() - interval '1 day'),
  ('11111111-0000-4000-8001-000000000004', '11111111-1111-1111-1111-111111111111', 'Brand Shoot: Fjord Coffee',   'archived', now() - interval '200 days', now() - interval '100 days'),

  ('22222222-0000-4000-8001-000000000005', '22222222-2222-2222-2222-222222222222', 'Ramos Engagement',            'active',   now() - interval '15 days', now() - interval '2 days'),
  ('22222222-0000-4000-8001-000000000006', '22222222-2222-2222-2222-222222222222', 'Product — Aster Ceramics',    'active',   now() - interval '5 days',  now() - interval '1 day'),
  ('22222222-0000-4000-8001-000000000007', '22222222-2222-2222-2222-222222222222', 'Untitled gallery',            'draft',    now() - interval '2 days',  now() - interval '2 days'),

  ('33333333-0000-4000-8001-000000000008', '33333333-3333-3333-3333-333333333333', 'Sample gallery',              'draft',    now() - interval '1 day',   now() - interval '1 day');


-- ===========================================================================
-- 5. assets
-- ===========================================================================
--
-- Remember the rule from the migration: anything the browser could have
-- forged stays NULL until finalize. So 'pending' and 'failed' rows have no
-- content_type, no hash, no size, no dimensions.
--
-- Note a03 and a04 both sit at position 3 -- that collision is why the
-- pagination exercises page by (position, id) and not by position alone.
--
-- Note a25 and a26 share a content_hash: the same jpeg was uploaded twice.

INSERT INTO assets (id, gallery_id, studio_id, status, storage_key, original_filename,
                    content_type, content_hash, size_bytes, width, height, blurhash, position,
                    created_at, updated_at) VALUES

  -- G1 Marlow Wedding — Full Set ------------------------------------------
  ('11111111-0000-4000-8002-000000000001', '11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', 'ready',      'studios/aperture-north/originals/a01.jpg', 'DSC_4101.jpg', 'image/jpeg', repeat('11', 32), 4823992, 6000, 4000, 'L6PZfSi_.AyE_3t7t7R**0o#DgR4', 1, now() - interval '59 days', now() - interval '59 days'),
  ('11111111-0000-4000-8002-000000000002', '11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', 'ready',      'studios/aperture-north/originals/a02.jpg', 'DSC_4102.jpg', 'image/jpeg', repeat('12', 32), 5120344, 6000, 4000, 'L9AS}j^+0K9F%MRjWBt7~qofM{WB', 2, now() - interval '59 days', now() - interval '59 days'),
  ('11111111-0000-4000-8002-000000000003', '11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', 'ready',      'studios/aperture-north/originals/a03.jpg', 'DSC_4103.jpg', 'image/jpeg', repeat('13', 32), 3998120, 4000, 6000, 'LEHV6nWB2yk8pyo0adR*.7kCMdnj', 3, now() - interval '59 days', now() - interval '58 days'),
  ('11111111-0000-4000-8002-000000000004', '11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', 'ready',      'studios/aperture-north/originals/a04.jpg', 'DSC_4104.jpg', 'image/jpeg', repeat('14', 32), 4402118, 4000, 6000, 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH', 3, now() - interval '59 days', now() - interval '58 days'),
  ('11111111-0000-4000-8002-000000000005', '11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', 'ready',      'studios/aperture-north/originals/a05.jpg', 'DSC_4105.jpg', 'image/jpeg', repeat('15', 32), 6110002, 6000, 4000, 'L5H2EC=PM+yV0g-mq.wG9c010J}I', 4, now() - interval '58 days', now() - interval '58 days'),
  ('11111111-0000-4000-8002-000000000006', '11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', 'ready',      'studios/aperture-north/originals/a06.jpg', 'DSC_4106.jpg', 'image/jpeg', repeat('16', 32), 2201900, 3000, 2000, 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.', 5, now() - interval '58 days', now() - interval '58 days'),
  ('11111111-0000-4000-8002-000000000007', '11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', 'processing', 'studios/aperture-north/originals/a07.jpg', 'DSC_4107.jpg', 'image/jpeg', repeat('17', 32), 7300551, 6000, 4000, NULL,                             6, now() - interval '57 days', now() - interval '2 hours'),
  ('11111111-0000-4000-8002-000000000008', '11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', 'failed',     'studios/aperture-north/originals/a08.jpg', 'DSC_4108.jpg', NULL,         NULL,             NULL,    NULL, NULL, NULL,                             7, now() - interval '57 days', now() - interval '57 days'),

  -- G2 Marlow Wedding — Proofs ---------------------------------------------
  ('11111111-0000-4000-8002-000000000009', '11111111-0000-4000-8001-000000000002', '11111111-1111-1111-1111-111111111111', 'ready', 'studios/aperture-north/originals/a09.jpg', 'proof_001.jpg', 'image/jpeg', repeat('21', 32), 1204880, 2400, 1600, 'L8B|+2%20K9F%MRjWBt7~qofM{WB', 1, now() - interval '57 days', now() - interval '57 days'),
  ('11111111-0000-4000-8002-000000000010', '11111111-0000-4000-8001-000000000002', '11111111-1111-1111-1111-111111111111', 'ready', 'studios/aperture-north/originals/a10.jpg', 'proof_002.jpg', 'image/jpeg', repeat('22', 32), 1188402, 2400, 1600, 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH', 2, now() - interval '57 days', now() - interval '57 days'),
  ('11111111-0000-4000-8002-000000000011', '11111111-0000-4000-8001-000000000002', '11111111-1111-1111-1111-111111111111', 'ready', 'studios/aperture-north/originals/a11.jpg', 'proof_003.jpg', 'image/jpeg', repeat('23', 32), 1310551, 2400, 1600, 'LEHV6nWB2yk8pyo0adR*.7kCMdnj', 3, now() - interval '57 days', now() - interval '57 days'),
  ('11111111-0000-4000-8002-000000000012', '11111111-0000-4000-8001-000000000002', '11111111-1111-1111-1111-111111111111', 'ready', 'studios/aperture-north/originals/a12.jpg', 'proof_004.jpg', 'image/jpeg', repeat('24', 32), 1099003, 1600, 2400, 'L6PZfSi_.AyE_3t7t7R**0o#DgR4', 4, now() - interval '56 days', now() - interval '56 days'),
  ('11111111-0000-4000-8002-000000000013', '11111111-0000-4000-8001-000000000002', '11111111-1111-1111-1111-111111111111', 'ready', 'studios/aperture-north/originals/a13.jpg', 'proof_005.jpg', 'image/jpeg', repeat('25', 32), 1450210, 1600, 2400, 'L9AS}j^+0K9F%MRjWBt7~qofM{WB', 5, now() - interval '56 days', now() - interval '56 days'),

  -- G3 Okonkwo Family Session ----------------------------------------------
  -- a14 is a 40-day-old 'pending': a presigned URL nobody ever used.
  -- a15 is a 'pending' from ten minutes ago: a real upload in flight.
  ('11111111-0000-4000-8002-000000000014', '11111111-0000-4000-8001-000000000003', '11111111-1111-1111-1111-111111111111', 'pending',  'studios/aperture-north/originals/a14.jpg', 'IMG_0088.jpg', NULL,        NULL,             NULL,    NULL, NULL, NULL, 1, now() - interval '40 days',   now() - interval '40 days'),
  ('11111111-0000-4000-8002-000000000015', '11111111-0000-4000-8001-000000000003', '11111111-1111-1111-1111-111111111111', 'pending',  'studios/aperture-north/originals/a15.jpg', 'IMG_0089.jpg', NULL,        NULL,             NULL,    NULL, NULL, NULL, 2, now() - interval '10 minutes', now() - interval '10 minutes'),
  ('11111111-0000-4000-8002-000000000016', '11111111-0000-4000-8001-000000000003', '11111111-1111-1111-1111-111111111111', 'uploaded', 'studios/aperture-north/originals/a16.jpg', 'IMG_0090.jpg', 'image/jpeg', repeat('31', 32), 3300120, 5000, 3333, NULL, 3, now() - interval '2 hours',    now() - interval '1 hour'),
  ('11111111-0000-4000-8002-000000000017', '11111111-0000-4000-8001-000000000003', '11111111-1111-1111-1111-111111111111', 'ready',    'studios/aperture-north/originals/a17.jpg', 'IMG_0091.jpg', 'image/jpeg', repeat('32', 32), 2900430, 5000, 3333, 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.', 4, now() - interval '1 day', now() - interval '1 day'),

  -- G4 Brand Shoot: Fjord Coffee -------------------------------------------
  ('11111111-0000-4000-8002-000000000018', '11111111-0000-4000-8001-000000000004', '11111111-1111-1111-1111-111111111111', 'ready',    'studios/aperture-north/originals/a18.jpg', 'fjord_01.jpg', 'image/jpeg', repeat('41', 32), 8880231, 7000, 4667, 'L5H2EC=PM+yV0g-mq.wG9c010J}I', 1, now() - interval '199 days', now() - interval '199 days'),
  ('11111111-0000-4000-8002-000000000019', '11111111-0000-4000-8001-000000000004', '11111111-1111-1111-1111-111111111111', 'ready',    'studios/aperture-north/originals/a19.jpg', 'fjord_02.jpg', 'image/png',  repeat('42', 32), 12400900, 7000, 4667, 'LEHV6nWB2yk8pyo0adR*.7kCMdnj', 2, now() - interval '199 days', now() - interval '199 days'),
  ('11111111-0000-4000-8002-000000000020', '11111111-0000-4000-8001-000000000004', '11111111-1111-1111-1111-111111111111', 'orphaned', 'studios/aperture-north/originals/a20.jpg', 'fjord_03.jpg', NULL,         NULL,             NULL,     NULL, NULL, NULL, 3, now() - interval '198 days', now() - interval '150 days'),

  -- G5 Ramos Engagement (studio 2) -----------------------------------------
  ('22222222-0000-4000-8002-000000000021', '22222222-0000-4000-8001-000000000005', '22222222-2222-2222-2222-222222222222', 'ready', 'studios/vela/originals/a21.jpg', 'ramos_01.jpg', 'image/jpeg', repeat('51', 32), 3990112, 5472, 3648, 'L6PZfSi_.AyE_3t7t7R**0o#DgR4', 1, now() - interval '14 days', now() - interval '14 days'),
  ('22222222-0000-4000-8002-000000000022', '22222222-0000-4000-8001-000000000005', '22222222-2222-2222-2222-222222222222', 'ready', 'studios/vela/originals/a22.jpg', 'ramos_02.jpg', 'image/jpeg', repeat('52', 32), 4120880, 5472, 3648, 'L9AS}j^+0K9F%MRjWBt7~qofM{WB', 2, now() - interval '14 days', now() - interval '14 days'),
  ('22222222-0000-4000-8002-000000000023', '22222222-0000-4000-8001-000000000005', '22222222-2222-2222-2222-222222222222', 'ready', 'studios/vela/originals/a23.jpg', 'ramos_03.jpg', 'image/jpeg', repeat('53', 32), 3550420, 3648, 5472, 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH', 3, now() - interval '13 days', now() - interval '13 days'),
  ('22222222-0000-4000-8002-000000000024', '22222222-0000-4000-8001-000000000005', '22222222-2222-2222-2222-222222222222', 'ready', 'studios/vela/originals/a24.jpg', 'ramos_04.jpg', 'image/jpeg', repeat('54', 32), 5001233, 3648, 5472, 'LEHV6nWB2yk8pyo0adR*.7kCMdnj', 4, now() - interval '13 days', now() - interval '13 days'),

  -- G6 Product — Aster Ceramics (studio 2) ---------------------------------
  -- a25 and a26 are byte-identical: the same file uploaded twice.
  ('22222222-0000-4000-8002-000000000025', '22222222-0000-4000-8001-000000000006', '22222222-2222-2222-2222-222222222222', 'ready', 'studios/vela/originals/a25.jpg', 'aster_mug.jpg',      'image/jpeg', repeat('61', 32), 2200110, 4000, 4000, 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.', 1, now() - interval '4 days', now() - interval '4 days'),
  ('22222222-0000-4000-8002-000000000026', '22222222-0000-4000-8001-000000000006', '22222222-2222-2222-2222-222222222222', 'ready', 'studios/vela/originals/a26.jpg', 'aster_mug_copy.jpg', 'image/jpeg', repeat('61', 32), 2200110, 4000, 4000, 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.', 2, now() - interval '4 days', now() - interval '4 days'),
  ('22222222-0000-4000-8002-000000000027', '22222222-0000-4000-8001-000000000006', '22222222-2222-2222-2222-222222222222', 'ready', 'studios/vela/originals/a27.webp','aster_bowl.webp',    'image/webp', repeat('62', 32), 1800900, 4000, 3000, 'L5H2EC=PM+yV0g-mq.wG9c010J}I', 3, now() - interval '3 days', now() - interval '3 days');


-- ===========================================================================
-- 6. renditions
-- ===========================================================================
--
-- Written with INSERT ... SELECT instead of a wall of literals: the worker
-- derives renditions from the asset, so the seed does too. The CROSS JOIN
-- against a VALUES list is the "for each asset, for each kind" loop.
--
-- The three NOT (...) clauses are the deliberate gaps:
--   * a05 and a06 never got a preview  (the worker died mid-job)
--   * G5 has thumb and grid only       (previews still queued)
--   * G3's one ready asset has a thumb only

INSERT INTO renditions (asset_id, studio_id, kind, storage_key, format, width, height, size_bytes, created_at)
SELECT
  a.id,
  a.studio_id,
  k.kind,
  'renditions/' || a.id || '/' || k.kind || '.webp',
  'webp',
  greatest(1, (a.width  * k.scale)::int),
  greatest(1, (a.height * k.scale)::int),
  greatest(1, (a.size_bytes * k.scale * k.scale)::bigint),
  a.created_at + interval '4 minutes'
FROM assets a
CROSS JOIN (VALUES ('thumb', 0.05), ('grid', 0.25), ('preview', 0.5)) AS k(kind, scale)
WHERE a.status = 'ready'
  AND NOT (a.id IN ('11111111-0000-4000-8002-000000000005',
                    '11111111-0000-4000-8002-000000000006') AND k.kind = 'preview')
  AND NOT (a.gallery_id = '22222222-0000-4000-8001-000000000005' AND k.kind = 'preview')
  AND NOT (a.gallery_id = '11111111-0000-4000-8001-000000000003' AND k.kind <> 'thumb');


-- ===========================================================================
-- 7. grants
-- ===========================================================================
--
-- rights_mask: 1 view, 2 download, 4 favorite.
--   3 = view+download  (delivery)
--   5 = view+favorite  (proofing)
--   7 = everything
--   1 = view only
--
-- token_hash is CHECK (length = 64), so it is built with repeat() like
-- sessions.id.

INSERT INTO grants (id, gallery_id, studio_id, token_hash, audience_email, label,
                    rights_mask, revocation_epoch, expires_at, last_seen_at,
                    selection_submitted_at, created_at, updated_at) VALUES

  -- G1, delivery
  ('11111111-0000-4000-8004-000000000001', '11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', repeat('7a', 32), 'ana.marlow@example.com',     'Bride',             3, 0, now() + interval '30 days', now() - interval '2 days',  NULL, now() - interval '55 days', now() - interval '2 days'),
  -- G1, view only, never opened
  ('11111111-0000-4000-8004-000000000002', '11111111-0000-4000-8001-000000000001', '11111111-1111-1111-1111-111111111111', repeat('7b', 32), 'parents.marlow@example.com', 'Bride''s parents',  1, 0, now() + interval '30 days', NULL,                       NULL, now() - interval '55 days', now() - interval '55 days'),
  -- G2, proofing, selection already submitted
  ('11111111-0000-4000-8004-000000000003', '11111111-0000-4000-8001-000000000002', '11111111-1111-1111-1111-111111111111', repeat('7c', 32), 'ana.marlow@example.com',     'Bride — proofs',    5, 0, now() + interval '10 days', now() - interval '3 days',  now() - interval '3 days', now() - interval '54 days', now() - interval '3 days'),
  -- G2, proofing, still choosing
  ('11111111-0000-4000-8004-000000000004', '11111111-0000-4000-8001-000000000002', '11111111-1111-1111-1111-111111111111', repeat('7d', 32), 'dev.marlow@example.com',     'Groom — proofs',    5, 0, now() + interval '10 days', now() - interval '1 day',   NULL, now() - interval '54 days', now() - interval '1 day'),
  -- G3, full rights, revoked once and re-issued (epoch 1)
  ('11111111-0000-4000-8004-000000000005', '11111111-0000-4000-8001-000000000003', '11111111-1111-1111-1111-111111111111', repeat('7e', 32), 'chidi@example.com',          'Chidi',             7, 1, now() + interval '7 days',  now() - interval '6 hours', NULL, now() - interval '30 days', now() - interval '6 hours'),
  -- G4, expired 100 days ago, revoked twice
  ('11111111-0000-4000-8004-000000000006', '11111111-0000-4000-8001-000000000004', '11111111-1111-1111-1111-111111111111', repeat('7f', 32), 'ops@fjordcoffee.example.com','Marketing team',    3, 2, now() - interval '100 days', now() - interval '150 days', NULL, now() - interval '198 days', now() - interval '100 days'),

  -- studio 2
  ('22222222-0000-4000-8004-000000000007', '22222222-0000-4000-8001-000000000005', '22222222-2222-2222-2222-222222222222', repeat('8a', 32), 'ramos@example.com',          'Couple',            5, 0, now() + interval '14 days', now() - interval '1 day',  NULL, now() - interval '14 days', now() - interval '1 day'),
  ('22222222-0000-4000-8004-000000000008', '22222222-0000-4000-8001-000000000005', '22222222-2222-2222-2222-222222222222', repeat('8b', 32), 'mother.ramos@example.com',   'Mother of bride',   5, 0, now() + interval '14 days', now() - interval '2 days', now() - interval '2 days', now() - interval '14 days', now() - interval '2 days'),
  ('22222222-0000-4000-8004-000000000009', '22222222-0000-4000-8001-000000000006', '22222222-2222-2222-2222-222222222222', repeat('8c', 32), 'buyer@asterceramics.example.com', 'Client',       3, 0, now() - interval '1 day',   now() - interval '2 days', NULL, now() - interval '4 days',  now() - interval '2 days');


-- ===========================================================================
-- 8. favorites
-- ===========================================================================
--
-- Two grants on G2 picked overlapping sets: a10 and a12 were chosen by both.
-- Same shape on G5, where a22 is the shared pick.

INSERT INTO favorites (id, grant_id, asset_id, studio_id, created_at) VALUES
  -- Ana's proofing selection (grant 03): a09, a10, a12, a13
  ('11111111-0000-4000-8005-000000000001', '11111111-0000-4000-8004-000000000003', '11111111-0000-4000-8002-000000000009', '11111111-1111-1111-1111-111111111111', now() - interval '4 days'),
  ('11111111-0000-4000-8005-000000000002', '11111111-0000-4000-8004-000000000003', '11111111-0000-4000-8002-000000000010', '11111111-1111-1111-1111-111111111111', now() - interval '4 days'),
  ('11111111-0000-4000-8005-000000000003', '11111111-0000-4000-8004-000000000003', '11111111-0000-4000-8002-000000000012', '11111111-1111-1111-1111-111111111111', now() - interval '3 days'),
  ('11111111-0000-4000-8005-000000000004', '11111111-0000-4000-8004-000000000003', '11111111-0000-4000-8002-000000000013', '11111111-1111-1111-1111-111111111111', now() - interval '3 days'),

  -- Dev's proofing selection (grant 04): a10, a11, a12
  ('11111111-0000-4000-8005-000000000005', '11111111-0000-4000-8004-000000000004', '11111111-0000-4000-8002-000000000010', '11111111-1111-1111-1111-111111111111', now() - interval '2 days'),
  ('11111111-0000-4000-8005-000000000006', '11111111-0000-4000-8004-000000000004', '11111111-0000-4000-8002-000000000011', '11111111-1111-1111-1111-111111111111', now() - interval '2 days'),
  ('11111111-0000-4000-8005-000000000007', '11111111-0000-4000-8004-000000000004', '11111111-0000-4000-8002-000000000012', '11111111-1111-1111-1111-111111111111', now() - interval '1 day'),

  -- Chidi (grant 05) hearted the one ready asset in G3
  ('11111111-0000-4000-8005-000000000008', '11111111-0000-4000-8004-000000000005', '11111111-0000-4000-8002-000000000017', '11111111-1111-1111-1111-111111111111', now() - interval '6 hours'),

  -- Ramos couple (grant 07): a21, a22, a23
  ('22222222-0000-4000-8005-000000000009', '22222222-0000-4000-8004-000000000007', '22222222-0000-4000-8002-000000000021', '22222222-2222-2222-2222-222222222222', now() - interval '3 days'),
  ('22222222-0000-4000-8005-000000000010', '22222222-0000-4000-8004-000000000007', '22222222-0000-4000-8002-000000000022', '22222222-2222-2222-2222-222222222222', now() - interval '3 days'),
  ('22222222-0000-4000-8005-000000000011', '22222222-0000-4000-8004-000000000007', '22222222-0000-4000-8002-000000000023', '22222222-2222-2222-2222-222222222222', now() - interval '2 days'),

  -- Mother of the bride (grant 08): a22, a24
  ('22222222-0000-4000-8005-000000000012', '22222222-0000-4000-8004-000000000008', '22222222-0000-4000-8002-000000000022', '22222222-2222-2222-2222-222222222222', now() - interval '2 days'),
  ('22222222-0000-4000-8005-000000000013', '22222222-0000-4000-8004-000000000008', '22222222-0000-4000-8002-000000000024', '22222222-2222-2222-2222-222222222222', now() - interval '2 days');


COMMIT;


-- ===========================================================================
-- Sanity check -- run this after loading. Expected:
--   studios 3 | users 6 | sessions 8 | galleries 8 | assets 27
--   renditions 55 | grants 9 | favorites 13
-- ===========================================================================
--
-- SELECT
--   (SELECT count(*) FROM studios    WHERE slug IN ('aperture-north','vela-studio','harbor-light')) AS studios,
--   (SELECT count(*) FROM users)      AS users,
--   (SELECT count(*) FROM sessions)   AS sessions,
--   (SELECT count(*) FROM galleries)  AS galleries,
--   (SELECT count(*) FROM assets)     AS assets,
--   (SELECT count(*) FROM renditions) AS renditions,
--   (SELECT count(*) FROM grants)     AS grants,
--   (SELECT count(*) FROM favorites)  AS favorites;
