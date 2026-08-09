# PostgreSQL Tutorial

**Source:** https://neon.com/postgresql/tutorial (Neon's PostgreSQL articles)

## Tech Stack

- PostgreSQL
- psql / VS Code SQLTools
- `dvdrental` sample database (tutorial), plus my own Pixhaus schema (practice)

## What I Learned

- Querying data: `SELECT`, column aliases, concatenation, `ORDER BY` (incl. `NULLS FIRST/LAST`) and `SELECT DISTINCT` / `DISTINCT ON`.
- Filtering data: `WHERE` with comparison and logical operators, `IN`, `BETWEEN`, `LIKE` / `ILIKE`, `IS NULL`, and paging with `LIMIT` / `OFFSET`.
- Joining tables: inner, left, right, full outer, cross and self joins, and how `USING` differs from `ON`.
- Grouping and aggregation: `GROUP BY` with aggregate functions and filtering groups with `HAVING`.
- Applying all of it in a set of practice exercises written against a real project schema.

## Folder Structure

- `Querying Data/` - `SELECT`, `ORDER BY`, `DISTINCT ON`
- `Filtering Data/` - `WHERE`, `LIMIT` / `OFFSET`
- `Joins and Groups/` - joins, `GROUP BY`, `HAVING`
- `Practice/` - exercises, seed data and solutions against the Pixhaus schema

## How to Run

1. Install PostgreSQL and restore the `dvdrental` sample database.
2. Connect with `psql -U postgres -d dvdrental` (or through the SQLTools connections in `.vscode/settings.json`).
3. Run the statements from any `.sql` file.
4. For the practice set: load `Practice/seed_practice.sql` into the practice database, then work through `Practice/EXERCISES.md` (solutions in `Practice/SOLUTIONS.sql`).
