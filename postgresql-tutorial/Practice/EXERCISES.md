# Pixhaus SQL exercises

Fifty-two exercises against the real Pixhaus schema (from the pixhaus github repository)
(`packages/db/migrations/0001_initial_schema.sql`) and the practice data in
`seed_practice.sql`. They are ordered so that each set uses what the previous
one taught, and almost every question is a query the product would actually
need — the dashboard list, the orphan sweep, the proofing selection, the
tenant wall.

Solutions are in `SOLUTIONS.sql`. Try to get a query to run before you look;
there is usually more than one right answer.

---

## Setup

```bash
# Load the seed as the database OWNER (the migration role), not the app role.
psql "$DATABASE_URL" -f packages/db/practice/seed_practice.sql
psql "$DATABASE_URL"
```

Useful psql commands while you work:

| Command       | What it does                                              |
| ------------- | --------------------------------------------------------- |
| `\dt`         | list tables                                               |
| `\d assets`   | describe a table: columns, indexes, constraints, triggers |
| `\d+ grants`  | same, plus comments and storage                           |
| `\x`          | toggle expanded output — essential for wide rows          |
| `\timing`     | show how long each query took                             |
| `\e`          | open the last query in an editor                          |
| `\i file.sql` | run a file                                                |

The data is fixed relative to `now()`, so "expired" and "stale" stay true
whenever you run it. Re-running the seed file resets everything.

**Handy ids** (you will paste these a lot):

```
studio 1  Aperture North  11111111-1111-1111-1111-111111111111
studio 2  Vela Studio     22222222-2222-2222-2222-222222222222
G1 full set    11111111-0000-4000-8001-000000000001
G2 proofs      11111111-0000-4000-8001-000000000002
G3 okonkwo     11111111-0000-4000-8001-000000000003
G5 ramos       22222222-0000-4000-8001-000000000005
```

---

## Set 1 — Reading rows: SELECT, WHERE, ORDER BY, LIMIT

_Learn: filtering, `NULL` semantics, sorting with ties, `LIMIT`/`OFFSET`._

**1.1** List every studio: name, slug, and creation date, newest first.

**1.2** List all users' email and role, sorted by email.

**1.3** Find every user who has **not** verified their email.
Hint: `email_verified_at` is nullable on purpose — `= NULL` never matches
anything. _(2 rows)_

**1.4** List all galleries in Aperture North that are not archived, newest
first.

**1.5** Show every asset in gallery G1 in display order — that means
`position` ascending, with `id` as the tiebreaker (two assets share position
3; without the tiebreaker their relative order is undefined between runs).

**1.6** Find every asset whose upload never completed — anything not in
`('ready', 'processing')`. Show gallery id, filename, status, age in days.
Hint: `now() - created_at` gives an interval; `extract(day from ...)` or
`date_trunc` will tidy it.

**1.7** Show assets larger than 5 MB. Express the size in MB rounded to one
decimal. Watch out: `size_bytes` is `NULL` for unfinalized rows, and
`NULL > 5000000` is `NULL`, not `false` — confirm those rows drop out.

**1.8** List grants that have already expired. _(2 rows)_

**1.9** List grants that have never been opened (`last_seen_at IS NULL`).
_(1 row)_

**1.10** Find assets whose filename ends in `.jpg`, case-insensitively. Do it
twice: once with `LIKE`, once with `ILIKE`. Then do it a third way with
`~*` (POSIX regex) and note which one you find most readable.

---

## Set 2 — Aggregation: COUNT, SUM, GROUP BY, HAVING

_Learn: the difference between `count(_)`and`count(col)`, grouping, filtering
groups vs filtering rows, `FILTER`.\*

**2.1** How many assets exist per status? Order by count descending.

**2.2** Total bytes stored per studio, counting originals only (`assets`), for
assets that actually have bytes. Show it in MB.

**2.3** Per gallery: asset count, ready count, and total ready bytes. Use
`count(*) FILTER (WHERE status = 'ready')` — the Postgres way to write a
conditional aggregate, and much cleaner than `sum(CASE WHEN ... END)`.

**2.4** Which galleries have more than 4 assets? Now do it again returning
galleries with **zero** assets and notice why `HAVING` alone cannot answer
that (you need Set 3).

**2.5** For each studio, the average, min and max asset size in MB, rounded to
2 decimals. Ignore `NULL` sizes — aggregates already do, which is the point.

**2.6** Count assets per gallery per status in one result set: gallery title,
status, count. Then produce the same information pivoted — one row per
gallery, one column per status — using `count(*) FILTER (...)`.

**2.7** `count(*)` vs `count(content_hash)` on `assets`: run both in one
query and explain to yourself why the numbers differ. _(27 vs 23)_

**2.8** Storage per studio broken into originals and renditions, as two
columns on one row per studio. Hint: two scalar subqueries, or two aggregates
over a `UNION ALL`.

---

## Set 3 — Joins: INNER, LEFT, and the anti-join

_Learn: when a row disappears from an inner join, when `LEFT JOIN` keeps it,
and how `LEFT JOIN ... WHERE right.id IS NULL` becomes "find what's missing"._

**3.1** List every gallery with its studio name, newest first.

**3.2** Every asset in G2 with its studio name and gallery title.

**3.3** Galleries with their asset counts — **including galleries with zero
assets**. This is exercise 2.4's second half, done properly. _(8 rows, two of
them zero)_

**3.4** Galleries that have no grants at all — nobody has ever been given a
link. Do it with a `LEFT JOIN ... IS NULL` anti-join. _(2 rows)_

**3.5** Ready assets that are missing a `preview` rendition. This is the
"which images will the lightbox fail to open" query. _(7 rows)_

**3.6** Ready assets missing **any** of the three kinds. Return the asset and
which kinds are missing, as an array. Hint: `CROSS JOIN` a `VALUES` list of
the three kinds, then anti-join renditions, then `array_agg`.

**3.7** Users with no session ever recorded. _(1 row)_

**3.8** For each grant: gallery title, audience email, and the number of
favorites recorded under it. Grants with no favorites must still appear with 0.

**3.9** Every favorite, joined all the way up: studio name → gallery title →
asset filename → the audience email that hearted it. Four joins. Sort by
studio, then gallery, then filename.

**3.10** A self-join: find pairs of assets in the same gallery that share a
`content_hash` — duplicate uploads. Return each pair once, not twice. Hint:
join `assets a` to `assets b` on the hash and `a.id < b.id`. _(1 pair)_

**3.11** Now the same duplicate question with `GROUP BY content_hash HAVING
count(*) > 1`. Compare the two shapes — the self-join gives you pairs, the
group-by gives you clusters. Which would you use to build a "merge these"
UI?

---

## Set 4 — Subqueries: IN, EXISTS, NOT EXISTS, scalar and lateral

_Learn: correlated vs uncorrelated subqueries, why `NOT IN` is a trap with
nulls, and `LATERAL` for top-N-per-group._

**4.1** Galleries that contain at least one `failed` asset, using `EXISTS`.

**4.2** The same with `IN (SELECT gallery_id ...)`. Then rewrite it as a join
and confirm all three agree.

**4.3** Assets that nobody has ever favorited, using `NOT EXISTS`.

**4.4** Now write 4.3 with `NOT IN (SELECT asset_id FROM favorites)`. It works
here because `favorites.asset_id` is `NOT NULL`. Prove to yourself why it
would break otherwise:

```sql
SELECT 1 WHERE 3 NOT IN (1, 2, NULL);   -- returns nothing, not a row
```

Explain that result in one sentence in a comment. This is the single most
common SQL bug in production code.

**4.5** For each gallery, the id and filename of its **cover** asset — the
ready asset with the lowest `(position, id)`. Use `LEFT JOIN LATERAL (...)
ON true` with `ORDER BY ... LIMIT 1`. Galleries with no ready asset should
still appear, with nulls.

**4.6** The three most recently created assets **per studio**, using
`LATERAL`. (Set 6 does this again with window functions — do both, then
decide which you'd rather maintain.)

**4.7** Scalar subquery: list galleries with a column `favorite_count` that
counts favorites across all of that gallery's assets.

**4.8** Grants whose gallery contains at least one asset that is _not_ ready —
i.e. links you have handed out over an incomplete gallery. Correlated
`EXISTS` two levels deep.

---

## Set 5 — Expressions: CASE, COALESCE, dates, strings, types

_Learn: shaping output, interval arithmetic, null handling, casting._

**5.1** Classify each grant as `'expired'`, `'expiring soon'` (within 7 days)
or `'active'` with a `CASE` expression. Count how many fall into each bucket.

**5.2** For each grant, days remaining until expiry as an integer (negative if
past). Hint: `extract(day from expires_at - now())` truncates; consider
`date_part` on the epoch and dividing, and decide which you want.

**5.3** Show each asset's dimensions as `'6000×4000'`, or `'unknown'` when
they are null. Use `COALESCE` and a cast.

**5.4** Add an `orientation` column: `landscape`, `portrait`, `square`, or
`unknown`.

**5.5** Megapixels per asset, one decimal place, for assets with dimensions.
Then the average megapixels per gallery.

**5.6** Format `created_at` as `'2026-03-14 09:31'` in UTC using `to_char`.
Then do it again in `Europe/Bucharest` with `AT TIME ZONE`. Explain the
difference to yourself — this is why the schema uses `timestamptz` everywhere.

**5.7** Bucket assets by upload week: `date_trunc('week', created_at)` and a
count, most recent week first.

**5.8** Extract the file extension from `original_filename` (lowercased) and
count assets per extension. Hint: `split_part`, or `regexp_replace` with
`'^.*\.'`.

**5.9** From `storage_key`, return just the last path segment. Two ways:
`split_part(storage_key, '/', -1)` and `regexp_replace`. Note that
`split_part` accepting a negative index is a modern Postgres feature — check
your version with `SELECT version();`.

**5.10** Session hygiene: for each session show whether it is expired, how
long since `last_seen_at` in whole hours, and the `/24` network of its IP
(`inet` supports `set_masklen(ip, 24)` and `host()`, `network()`,
`masklen()`). Skip null ips gracefully.

---

## Set 6 — Window functions

_Learn: `OVER (PARTITION BY ... ORDER BY ...)`, ranking, running totals, `lag`,
and the fact that a window function does not collapse rows._

**6.1** Number the assets within each gallery in display order:
`row_number() OVER (PARTITION BY gallery_id ORDER BY position, id)`.

**6.2** `rank()` vs `dense_rank()` vs `row_number()` over `PARTITION BY
gallery_id ORDER BY position` — put all three in one result for G1 and
explain, in a comment, why they differ at position 3.

**6.3** The largest three assets per studio by `size_bytes`, using
`row_number()` in a subquery/CTE and filtering `<= 3` outside. (You cannot
filter on a window function in `WHERE` — try it and read the error, it is a
useful error to have seen once.)

**6.4** A running total of bytes uploaded per studio over time: studio,
`created_at`, `size_bytes`, and
`sum(size_bytes) OVER (PARTITION BY studio_id ORDER BY created_at)`.

**6.5** For each asset in a gallery, the time gap since the previous asset was
created in the same gallery, using `lag(created_at) OVER (...)`. Bursts of
uploads should show tiny gaps.

**6.6** Each asset's size as a percentage of its gallery's total:
`size_bytes::numeric / sum(size_bytes) OVER (PARTITION BY gallery_id)`.

**6.7** `first_value` / `last_value`: for each asset, the filename of the first
asset in its gallery in display order. Then try `last_value` and discover it
gives the wrong answer until you write the frame clause
`ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`. Understanding
_why_ is the exercise.

**6.8** Rank grants within each gallery by how recently they were seen, nulls
last: `ORDER BY last_seen_at DESC NULLS LAST`.

---

## Set 7 — CTEs, set operations, and pagination

_Learn: `WITH` for readability, `UNION`/`INTERSECT`/`EXCEPT`, and keyset
pagination — the reason `assets_gallery_position_idx` is `(gallery_id,
position, id)`._

**7.1** Rewrite 6.3 (top three per studio) using a `WITH` clause instead of a
subquery. Same plan, better prose.

**7.2** The consensus picks in G2: assets favorited by **both** grants on that
gallery. Do it with `INTERSECT`, then again with `GROUP BY asset_id HAVING
count(DISTINCT grant_id) = 2`. _(2 assets)_

**7.3** Assets Ana picked but Dev did not, using `EXCEPT`.

**7.4** A single "activity feed" for studio 1: union of
`('asset uploaded', created_at, filename)`, `('grant issued', created_at,
audience_email)` and `('favorite added', created_at, asset filename)`, sorted
newest first, limit 15. Use `UNION ALL` — and be able to say why not `UNION`.

**7.5** **Keyset pagination, page 1.** First 3 assets of G1 in display order.

**7.6** **Keyset pagination, page 2.** Continue after the last row of page 1
using a row-value comparison:

```sql
WHERE gallery_id = :g AND (position, id) > (:last_position, :last_id)
ORDER BY position, id
LIMIT 3
```

Fill in the values by hand from page 1. Confirm the two assets sharing
position 3 are not skipped or duplicated — that is exactly the bug `OFFSET`
and single-column keysets produce.

**7.7** Do the same page 2 with `OFFSET 3` and compare. Then explain in a
comment what happens to an `OFFSET` pager when someone inserts an asset at
position 1 between requests.

**7.8** A multi-CTE report: per gallery, one row with title, status, asset
count, ready count, total MB, grant count, favorite count. Build it as three
or four CTEs joined at the end, and keep each CTE doing one thing.

**7.9** `generate_series` to build a dense daily time series: uploads per day
for the last 14 days for studio 1, **including days with zero uploads**. Hint:
`generate_series(current_date - 13, current_date, interval '1 day')` LEFT
JOINed to a grouped count.

---

## Set 8 — The grants bitmask

_Learn: integer bit operations, and modelling capability sets without a join
table._

`rights_mask`: `1` view, `2` download, `4` favorite.

**8.1** All grants that include the **download** right (`rights_mask & 2 <>
0`). _(4 rows)_

**8.2** All grants that include **favorite**. _(5 rows)_

**8.3** Grants that are view-only — the mask is exactly `1`. Note the
difference between "includes view" and "is only view".

**8.4** Decode the mask into three boolean columns `can_view`, `can_download`,
`can_favorite`.

**8.5** Decode it into a text array, e.g. `{view,favorite}`. Hint: build it
with `array_remove(ARRAY[ CASE WHEN ... END, ... ], NULL)`.

**8.6** Count grants by decoded rights combination, most common first.

**8.7** Find grants that violate a product rule you can invent: any grant with
the favorite right on a gallery whose status is `archived` (should be none
here — write the query and confirm the empty result, which is a perfectly good
answer).

**8.8** `UPDATE` practice (inside a transaction you `ROLLBACK`): add the
download right to every proofing grant on G2 without touching their other
bits — `rights_mask = rights_mask | 2`. Verify with a `RETURNING` clause, then
roll back.

---

## Set 9 — Writing data

_Learn: `INSERT ... RETURNING`, `ON CONFLICT`, `UPDATE ... FROM`, `DELETE ...
USING`, and transactions. Run these inside `BEGIN; ... ROLLBACK;` until you
mean it._

**9.1** Insert a new gallery for studio 2 and return the generated id and
`created_at` in one statement with `RETURNING`.

**9.2** Insert an asset row the way the API does at presign time: gallery,
studio, `storage_key`, `original_filename`, and nothing else — status defaults
to `pending` and every server-observed column stays null. Return the id.

**9.3** Finalize that asset: set status to `uploaded`, `content_type`,
`content_hash`, `size_bytes`, `width`, `height`. Then `SELECT` it back and
confirm `updated_at` moved on its own — that is the `set_updated_at` trigger,
not your statement.

**9.4** Try to finalize it with `content_type = 'application/pdf'`. Read the
CHECK constraint violation carefully; that error message is the schema doing
its job.

**9.5** Idempotent hearting: `INSERT INTO favorites ... ON CONFLICT (grant_id,
asset_id) DO NOTHING`. Run it twice, confirm the second run affects 0 rows.
Which index makes that conflict target legal?

**9.6** An "unheart" that is a real delete: remove one favorite and return the
deleted row.

**9.7** Reorder a gallery: shift every asset at position ≥ 3 in G1 up by one
in a single `UPDATE`, then insert a new asset at position 3. Wrap it in a
transaction and inspect the ordering before you roll back.

**9.8** `UPDATE ... FROM`: mark as `orphaned` every asset that is still
`pending` and older than 24 hours — the sweep job. Use `RETURNING` to see what
it would touch, then roll back. _(1 row: `IMG_0088.jpg`)_

**9.9** `DELETE ... USING`: delete expired sessions, returning the user email
each belonged to. _(3 rows)_

**9.10** Revoke a grant the way the ADR says to: bump `revocation_epoch`,
do **not** delete the row. Write it, and write the one-line comment explaining
why a delete would be the wrong call.

**9.11** Cascade demonstration, in a transaction: count assets, renditions,
grants and favorites for studio 2, `DELETE FROM studios WHERE id = <studio
2>`, count everything again, then `ROLLBACK`. Every count should be zero
before the rollback. Trace which foreign keys made that happen.

**9.12** Constraint tour — try each of these and read the error:

- a user with an uppercase email
- a studio slug of `'Not A Slug'`
- a session id that is 63 characters
- a `rights_mask` of `8`
- a favorite whose `grant_id` and `asset_id` belong to **different studios**

The last one is the interesting one: it is rejected by the composite foreign
keys, not by any single-column constraint. That is the mechanism described in
the migration's comment on `favorites`.

---

## Set 10 — Postgres in anger: RLS, indexes, EXPLAIN, JSON

_Learn: the tenant wall as the database enforces it, and how to tell whether
your query is actually using an index._

**10.1** Connect as the **application role** (not the owner). Run
`SELECT count(*) FROM galleries;` before setting any tenant. You should get
`0` — not an error. Understand why an empty result is the correct and
dangerous-feeling behaviour of RLS.

**10.2** Now set the tenant and re-run:

```sql
SET app.studio_id = '11111111-1111-1111-1111-111111111111';
SELECT count(*) FROM galleries;
```

Then set it to studio 2 and re-run. Same query, different universe.

**10.3** Use `SET LOCAL` inside a transaction instead, and confirm the setting
does not leak past `COMMIT`. This is what the API must do per request on a
pooled connection — explain to yourself what breaks if it uses plain `SET`
with a connection pool.

**10.4** With the tenant set to studio 1, try
`INSERT INTO galleries (studio_id, title) VALUES ('<studio 2 id>', 'oops');`
Read the error. Which half of the policy — `USING` or `WITH CHECK` — stopped
you?

**10.5** With the tenant set to studio 1, try to `SELECT` a studio-2 asset by
its exact id. Then try to `UPDATE` it. Confirm you cannot even see it to
target it.

**10.6** `SELECT current_studio_id();` with the setting unset. It should be
`NULL`, not an error — read the `current_setting('app.studio_id', true)` call
in the migration and explain what the `true` does.

**10.7** `EXPLAIN (ANALYZE, BUFFERS)` the gallery grid query:

```sql
SELECT id, storage_key, position FROM assets
WHERE gallery_id = '11111111-0000-4000-8001-000000000001'
ORDER BY position, id LIMIT 20;
```

At this data size Postgres will likely choose a sequential scan — 27 rows fit
in one page and an index would be slower. Confirm with
`SET enable_seqscan = off;` that `assets_gallery_position_idx` _can_ serve it
with no sort step, then set it back. The lesson: `EXPLAIN` output is about
this data, not about your schema in production.

**10.8** `EXPLAIN` the orphan sweep:
`SELECT * FROM assets WHERE status = 'pending' AND created_at < now() -
interval '1 day';`
Then look at `\d assets` and find `assets_pending_created_idx`. Why is a
_partial_ index the right shape here, and what does it cost when an asset
leaves `pending`?

**10.9** Build the client-facing gallery payload as a single JSON document:
gallery title, status, and an array of assets each with id, filename,
dimensions and a nested array of its renditions. Use `json_agg`,
`json_build_object`, and a `LEFT JOIN LATERAL` for the nested level. This is
one round trip instead of three.

**10.10** `jsonb_pretty` your 10.9 result to read it. Then decide: would you
actually build the response in SQL, or in the API layer? Write your reasoning
in two sentences — both answers are defensible, and knowing why you chose is
the point.

**10.11** Look at `pg_indexes` for the `assets` table
(`SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'assets';`).
For each index, name the query in this exercise file it exists to serve. Any
index you cannot map to a query is a write cost with no reader.

**10.12** Finally, `SELECT` from `pg_policies WHERE schemaname = 'public';`
and read all eight policies as data. Confirm each has both a `qual` (the
`USING` half) and a `with_check` half, and that `studios` is the one keyed on
`id` rather than `studio_id`.

---

## Where to go after this

The things this file does not cover, roughly in the order they will bite you
in a real project:

- **Transactions and isolation** — `READ COMMITTED` vs `REPEATABLE READ`,
  `SELECT ... FOR UPDATE`, and why the reorder in 9.7 is racy without it.
- **Advisory locks** and job queues (`FOR UPDATE SKIP LOCKED`) — how the
  rendition worker should claim work.
- **`EXPLAIN` at scale** — generate 100k assets with `generate_series` and
  re-run Set 10; every plan changes.
- **Full-text search** — `tsvector` over gallery titles and filenames.
- **Migrations as a discipline** — adding a nullable column vs a `NOT NULL`
  with a default, and which of those locks the table.
